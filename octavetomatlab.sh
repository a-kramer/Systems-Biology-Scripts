#!/bin/bash

INFILE=${1:-main.m}
OUTFILE=${2:-matlab_${INFILE}}

if [[ -z ${2} ]]; then
   OPT="-i"
   echo "performing the substitutions in place"
fi
   
if [[ -f "$INFILE" ]]; then
    sed -E ${OPT} \
    --expression='s/\<end/end%/' \
    --expression='s/#/%/g' \
    --expression="s/\"/'/g" \
    --expression='s/\<printf\(/fprintf(/g' \
    --expression='s/\<columns\((\w+)\)/size(\1,2)/g' \
    --expression='s/\<rows\((\w+)\)/size(\1,1)/g' \
    ${INFILE} > ${OUTFILE}
fi
