input_vcf = Channel.fromPath(params.input_data)

process Get_Insertions{
	tag "Step 1: Processing file: ${input_vcf}"
	
	memory '16 GB'	
	
	input:
    each input_vcf
	
    output:
    path '*'

    """
	chmod +x $PWD/1_Get_INSDEL.sh 
	$PWD/11_Get_INSDEL.sh  $input_vcf output/
	"""

}
process Combine_Insertions {
    tag 'Step 2: Concating DataFrames'

	memory '16 GB'	
	
	input:
	path output_ins

	//publishDir params.outputDir, mode: 'copy'

	output:
	path 'Variant_info.csv'
	
	"""
	chmod +x $PWD/combine_files.py 
	python $PWD/combine_files.py -f ${output_ins.join(',')}
    """

} 

process Run_VEP_Analysis{
	tag "Step 3: Modifying file: ${MINTIE_Insertion_file}"
	
	memory '16 GB'

	input:
	path MINTIE_Insertion_file

	output:
	path '*'
	//publishDir params.tempDir, mode: 'copy'

	"""
	
	module load ensembl-vep/98.3
	
	vep --offline --cache --cache_version 109 --no_check_variants_order --dir_cache /home/users/allstaff/pan.h/lab_share/database -i "${MINTIE_Insertion_file}" -o "${MINTIE_Insertion_file.baseName}_output.txt" --force_overwrite --vcf --sift b --uniprot --check_existing --pubmed 
	
	if [ -e "*warnings.txt" ]; then
		rm *warnings.txt
	else
		echo  "No warnings generated by VEP analysis"
	
	fi
	
	rm *.html	

	"""	
}

process Run_R_Analysis{
	tag "Step 4: Analyzing data in R"
 	
	memory '16 GB'
	
	input:
	path VEP_Files 

	output:
	
	path 'summary_df.csv'	

	publishDir params.outputDir, mode: 'copy'
		
	"""
	module load python
	export R_ENVIRON_USER='$HOME/scratch/R_cache'
	chmod +x $PWD/2_RScript.sh
	export R_LIBS_USER='*/R/x86_64-pc-linux-gnu-library/4.2/'
	export RENV_PATHS_CACHE='*/R_cache'
	chmod +x $PWD/6_GetResultFiles.sh
	$PWD/2_RScript.sh ${VEP_Files}
	chmod +x $PWD/8_Generate_df.py
	python $PWD/8_Generate_df.py -d ${Cosmic_tab}
	"""

}




workflow {
   def input_vcf = Channel.fromPath(params.input_data)
   Get_Insertions(input_vcf) 
   Run_VEP_Analysis(Get_Insertions.out)
   Combine_Insertions(Get_Insertions.out.collect())
   Run_R_Analysis(Run_VEP_Analysis.out.collect())
}
