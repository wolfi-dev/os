#!/bin/bash
# This script loops over every yaml file package, fetches the complete list of subpackages, and prints out
# the names of all the resulting apks
for f in $(make list-yaml); do
    melange query $f $PREFIX/"{{.Package.Name}}-{{.Package.Version}}-r{{.Package.Epoch}}.apk "
    melange query $f "{{range .Subpackages}}$PREFIX/{{.Name}}-{{$.Package.Version}}-r{{$.Package.Epoch}}.apk {{end}}"
done