#!/bin/bash

FILE=${1}

tags="model species parameter compartment reaction"

for tag in ${tags}; do

IFS=$'\n' lines=( `egrep "<$tag[ ]" ${FILE}` )
n=${#lines[@]}
for ((i=0;i<n;i++)); do
    svstr="${lines[i]}"
    if [[ $svstr =~ id=\"([^\"]+)\" ]]; then
	id[i]="${BASH_REMATCH[1]}"
    else
	echo "warning: id not found in «${svstr}»"
    fi
    if [[ $svstr =~ name=\"([^\"]+)\" ]]; then
	name[i]="${BASH_REMATCH[1]}"
    else
	echo "warning: name not found in «${svstr}»"
	name[i]="${tag}_${i}"
    fi
    if [[ "${id[i]}" ]]; then
	sed -i -e "s/${id[i]}/${name[i]}/g" ${FILE}
    fi
done

echo "id: ${id[*]}"
echo "name: ${name[*]}"
echo "done"

done
