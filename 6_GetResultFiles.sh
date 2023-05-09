#!/bin/bash

src_dir="/vast/projects/lab_davidson/data/TCGA-OV/MINTIE"
dst_dir=${PWD}

while read line; do
  prefix="${line:2:7}"
  for dir in "${src_dir}"/*; do
    if [[ -d "${dir}" && "${dir##*/}" =~ ^"${prefix}".* ]]; then
      echo "${prefix} matches a directory in ${src_dir}"
      result_files=$(find "${dir}" -type f -name "*_results.tsv")
      if [[ -n "${result_files}" ]]; then
        echo "result file found:"
        echo "${result_files}"
        cp ${result_files} "${dst_dir}"
      else
        echo "no result file found"
      fi
      break
    fi
  done
done < "${dst_dir}/filelistfornoCOSVgenes.txt"
