module github.com/wolfi-dev/os

go 1.19

// Forked to only support SVG, remove deps that had liceses issues.
replace github.com/goccy/go-graphviz => github.com/n3wscott/go-graphviz v0.0.10-0.20211216184452-fd4faf331d28

require (
	github.com/goccy/go-graphviz v0.0.9
	gopkg.in/yaml.v3 v3.0.1
)

require (
	github.com/fogleman/gg v1.3.0 // indirect
	github.com/golang/freetype v0.0.0-20170609003504-e2365dfdc4a0 // indirect
	github.com/pkg/errors v0.9.1 // indirect
	golang.org/x/image v0.0.0-20200119044424-58c23975cae1 // indirect
)
