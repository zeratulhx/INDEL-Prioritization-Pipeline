#!/usr/bin/env bash

MINTIE_VCF_FilePath=$(pwd)

if [[ -d "$MINTIE_VCF_FilePath" ]]; then

    for VCFFile in ${1}; do
        # Generate unique file ID, copy the header to a newly generated output file
        header_lines_to_copy=$(head -n 7 "$VCFFile")
        sample_ID=$(grep -Eo "FORMAT[^\t]*" <<< "$header_lines_to_copy" | awk -F'\t' '{print $2}'| tr -d '\n' )
	timestamp=$(date +%Y%m%d_%H%M%S%3N)
        filename="${sample_ID}_${timestamp}"

        echo "$header_lines_to_copy" > "${filename}.txt"

        # Go through the MINTIE VCF file and pull out insertions, add them to the output file. Change the below to get deletions. 
        while read -r line; do
            if [[ "$line" =~ "SVTYPE=INS" ]]; then
                echo "$line" >> "${filename}.txt"
            fi
        done < "$VCFFile"

    done
else
    echo "File ${MINTIE_VCF_FilePath} does not exist. Please check your file path."
fi



