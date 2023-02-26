#!/usr/bin/env bash

arrVar=()

for f in py3*.yaml; do
  echo "---" "${f}"

  # Check that every name-version-epoch is defined in Makefile
  name=$(yq '.package.name' "${f}")
  version=$(yq '.package.version' "${f}")
  url=$(yq .pipeline[0].with.uri "${f}")
  epoch=$(yq '.package.epoch' $f)
  want="build-package,${name},${version}-r${epoch}"
  echo $name

  realname=$(echo $name | awk '{split($0,a,"-"); print a[2]}')
  if [ ! -f "generated/py3.10-${realname}.yaml" ];then
    mconvert python $realname --package-version "${version}" --python-version 3.10
    if [ $? -ne 0 ]; then
        arrVar+=($realname)
      else
        mconvert python $realname  --package-version "${version}" --python-version 3.11

       if grep -q packages.wolfi.dev/os "generated/py3.10-${realname}.yaml"; then
          yq -i 'del(.environment.contents.repositories)' "generated/py3.10-${realname}.yaml"
          yq -i 'del(.environment.contents.keyring)' "generated/py3.10-${realname}.yaml"
        fi

        if grep -q packages.wolfi.dev/os "generated/py3.11-${realname}.yaml"; then
          yq -i 'del(.environment.contents.repositories)' "generated/py3.11-${realname}.yaml"
          yq -i 'del(.environment.contents.keyring)' "generated/py3.11-${realname}.yaml"
        fi
      fi
  fi

  for i in generated/py3*.yaml; do

    name=$(yq '.package.name' "${i}")
    version=$(yq '.package.version' "${i}")
    epoch=$(yq '.package.epoch' "${i}")
    update="build-package,${name},${version}-${epoch}"

    if grep -q $want Makefile; then # update in place
      lineNum=$(grep -n $want Makefile | cut -d: -f1)
      sed -i "s/$name/$update/g" Makefile
    else #new file put at the bottom
      want="build-package,gradle-8,8.0.1-r0"
      lineNum=$(grep -n $want Makefile | cut -d: -f1)
      update="\$(eval \$(call build-package,${name},${version}-${epoch}))"
      sed -i "$lineNum i $update" Makefile
    fi
  done
done

for i in generated/py3*.yaml; do

  name=$(yq '.package.name' "${i}")
  version=$(yq '.package.version' "${i}")
  epoch=$(yq '.package.epoch' "${i}")
  update="build-package,${name},${version}-${epoch}"

  if grep -q $name Makefile; then # update in place
    lineNum=$(grep -n $name Makefile | cut -d: -f1)
    sed -i "s/$name/$update/g" Makefile
  else #new file put at the bottom
    want="build-package,gradle-8,8.0.1-r0"
    lineNum=$(grep -n $want Makefile | cut -d: -f1)
    update="\$(eval \$(call build-package,${name},${version}-${epoch}))"
    sed -i "$lineNum i $update" Makefile
  fi
done

echo "Manual updates needed for "
for i in "${arrVar[@]}"; do
  echo "$i"
done

# Ensure advisory data and secfixes data are in sync.
echo "

Looking for files with out-of-sync advisory and secfixes data...
"
wolfictl advisory sync-secfixes --warn generated/py3*.yaml

# And if we make it this far...
echo "All python modules converted"
