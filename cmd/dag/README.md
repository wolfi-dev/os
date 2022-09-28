# `dag`

`dag` generates Graphviz digraphs for package dependencies.

To generate a png:

```
go run ./cmd/dag | dot -Tpng > dag.png
```

To generate an SVG:

```
go run ./cmd/dag | dot -Tsvg > dag.svg
```

## Subgraphs

`dag` can also generate subgraphs for only some packages.

To generate a graph for only one package:

```
go run ./cmd/dag brotli | dot -Tsvg > dag.svg
```

To generate a graph for only some packages:

```
go run ./cmd/dag brotli git-lfs attr | dot -Tsvg > dag.svg
```
