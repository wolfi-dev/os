package main

import (
	"io/fs"
	"log"
	"os"
	"path/filepath"
	"sort"
	"strings"

	"github.com/goccy/go-graphviz"
	"gopkg.in/yaml.v3"
)

type Graph struct {
	Nodes       map[string]struct{}
	Edges, Back map[string][]string
}

func NewGraph() Graph {
	return Graph{
		Nodes: make(map[string]struct{}),
		Edges: make(map[string][]string),
		Back:  make(map[string][]string),
	}
}

func (g Graph) Add(pkg string) {
	g.Nodes[pkg] = struct{}{}
}

func (g Graph) AddEdge(src, dst string) {
	if src == "" || dst == "" {
		log.Fatalf("empty %q -> %q", src, dst)
	}
	g.Nodes[src] = struct{}{}
	g.Nodes[dst] = struct{}{}
	g.Edges[src] = append(g.Edges[src], dst)
	g.Back[dst] = append(g.Back[dst], src)
}

type config struct {
	Package struct {
		Name string
	}
	Environment struct {
		Contents struct {
			Packages []string
		}
	}
	Subpackages []struct {
		Name string
	}
}

func main() {
	g := NewGraph()
	if err := filepath.Walk(".", func(path string, info fs.FileInfo, err error) error {
		if err != nil {
			return err
		}
		// Don't walk into directories.
		if path != "." && info.IsDir() {
			return filepath.SkipDir
		}
		if strings.HasSuffix(path, ".yaml") {
			f, err := os.Open(path)
			if err != nil {
				return err
			}
			defer f.Close()
			var c config
			if err := yaml.NewDecoder(f).Decode(&c); err != nil {
				return err
			}
			this := c.Package.Name
			if this == "" {
				log.Fatalf("no package name in %q", path)
			}
			for _, pkg := range c.Environment.Contents.Packages {
				if pkg == "" {
					log.Fatalf("empty package name in %q", path)
				}
				g.Add(pkg)
				g.AddEdge(this, pkg)
			}
			for _, subpkg := range c.Subpackages {
				g.Add(subpkg.Name)
				g.AddEdge(subpkg.Name, this)
			}
		}
		return nil

	}); err != nil {
		log.Fatalf("walk: %v", err)
	}

	log.Println("nodes:", len(g.Nodes))
	e := 0
	for node := range g.Nodes {
		e += len(g.Edges[node])
	}
	log.Println("edges:", e)

	// Validate all edges point to existing nodes.
	for from, to := range g.Edges {
		if _, found := g.Nodes[from]; !found {
			log.Fatalf("%q", from)
		}
		for _, too := range to {
			if _, found := g.Nodes[too]; !found {
				log.Fatalf("%q -> %q: %q not found", from, too, too)
			}
		}
	}

	if len(os.Args) == 1 {
		g.Viz()
	} else {
		sg := NewGraph()
		for _, node := range os.Args[1:] {
			sg.Add(node)
			for _, dep := range g.Edges[node] {
				sg.Add(dep)
				sg.AddEdge(node, dep)
			}
			for _, parent := range g.Back[node] {
				sg.Add(parent)
				sg.AddEdge(parent, node)
			}
		}
		sg.Viz()
	}
}

func (g Graph) Viz() {
	v := graphviz.New()
	gr, err := v.Graph()
	if err != nil {
		log.Fatalf("graphviz: %v", err)
	}
	defer func() {
		if err := gr.Close(); err != nil {
			log.Fatal(err)
		}
		v.Close()
	}()

	// Sort nodes for deterministic output.
	nodes := []string{}
	for node := range g.Nodes {
		nodes = append(nodes, node)
	}
	sort.Strings(nodes)

	for _, src := range nodes {
		srcn, err := gr.CreateNode(src)
		if err != nil {
			log.Fatalf("graphviz: %v", err)
		}

		// Sort nodes for deterministic output.
		dsts := g.Edges[src]
		sort.Strings(dsts)

		for _, dst := range dsts {
			dstn, err := gr.CreateNode(dst)
			if err != nil {
				log.Fatalf("graphviz: %v", err)
			}

			if _, err := gr.CreateEdge("e", srcn, dstn); err != nil {
				log.Fatal(err)
			}
		}
	}
	if err := v.Render(gr, "dot", os.Stdout); err != nil {
		log.Fatal(err)
	}
}
