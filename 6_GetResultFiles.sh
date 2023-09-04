#!/bin/bash
src_dir="*/MINTIE_out"
dst_dir=${PWD}
while read line; do
  prefix="${line:2:7}"
  #echo "$prefix"
  for dir in "${src_dir}"/*; do
    #echo "$dir"
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
done < "${dst_dir}/zdf_name.txt"

#!/bin/bash

src_dir="${PWD}"
text_file="${PWD}/zdf_filename.txt"
dst_file="${PWD}/resultlines.txt"

echo "Source dir : ${src_dir}"
echo "Dest file: ${dst_file}"

while read line; do
  filename="${line%%	*}"
  prefix="${filename:2:5}"
  echo "The prefix is : ${prefix}"
  value="${line#*	}" 
  echo "The second value is :${value}"
  for tsv_file in "${src_dir}"/*_results.tsv; do
    echo "Processing TSV file: ${tsv_file}"
    if [[ "${tsv_file##*/}" =~ ^"${prefix}".* ]]; then
      echo "Matching TSV file found: ${tsv_file}"
      if [[ $(grep -i -e "${value}" "${tsv_file}") ]]; then
        echo "Value found in ${tsv_file}"
        grep -i -e "${value}" "${tsv_file}" | while read -r matched_line; do
	printf "%s\t%s\n" "${filename}" "${matched_line}" >> "${dst_file}"
     	done
      else
        echo "Value not found in ${tsv_file}"
      fi
    else
      echo "TSV file does not match the prefix: ${tsv_file}"
    fi
  done
done < "${text_file}"
