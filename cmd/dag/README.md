# `dag`

`dag` generates Graphviz digraphs for package dependencies.

To generate `dag.svg`:

```
go run ./cmd/dag
```

## Subgraphs

`dag` can also generate subgraphs for only some packages.

To generate a graph for only one package:

```
go run ./cmd/dag brotli
```

To generate a graph for only some packages:

```
go run ./cmd/dag brotli git-lfs attr
```

### Output

`dag` writes a file called `dag.svg` by default.

To change this, pass `-f` _before any positional args_.

```
go run ./cmd/dag -f brotli.svg brotli
```

If the filename ends in `.png`, a PNG file will be generated.
If the filename ends in `.svg`, an SVG will be generated.
If the filename ends in anything else, the output will be DOT format, which the `graphviz` tool can consume.
