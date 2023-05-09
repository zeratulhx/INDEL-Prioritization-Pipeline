# INDEL Prioritization Pipeline

## What does this pipeline do?
###############################################################################

This command-line pipeline processes a .vcf file containing variants identified by a variant caller (e.g., MINTIE) and prioritizes INDELs that are more likely to impact proteins.

- The pipeline generates a list of variants within the cohort (or sample) that are causally associated with cancer, based on The Cancer Gene Census (CGC) (https://cancer.sanger.ac.uk/census).
- The pipeline also creates a prioritized list of coding region variants not found in COSMIC or dbSNP, potentially identifying novel variants.
- The pipeline produces a list of cancers and associated variants linked to genes identified as containing a novel variant.

## How do I run this pipeline?
################################################################################

- The pipeline runs offline, requiring several large downloads (a download script will be added in the future).
- Download all scripts and `renv.lock`.
- Install Ensembl VEP: https://asia.ensembl.org/info/docs/tools/vep/script/vep_download.html
- Download the VEP cache: https://asia.ensembl.org/info/docs/tools/vep/script/vep_cache.html#cache
    (https://ftp.ensembl.org/pub/release-109/variation/indexed_vep_cache/) - Bio::DB::HTS required.
- Install SQLite: https://sqlite.org/index.html
- Download `CosmicMutantExportCensus.tsv.gz` from https://cancer.sanger.ac.uk/cosmic/download (this file needs to be indexed based on the COSV identifier and renamed to `a_census_db.db` with a table called `a_census_table`. A script for this will be added in the future.)
- Install Nextflow: https://www.nextflow.io/docs/latest/getstarted.html
- Install R: https://cloud.r-project.org/ (R environment variables need to be added to the nextflow.config so they are not harded coded into the Nextflow script). 
- Place your .vcf files in a chosen directory and set their location in `nextflow.config`.
- Set the location for files containing VAF, control counts, and case counts in `6_GetResultFiles.sh`.
- Run `Insertion_Pipeline.sh`.
- Test files to be added. 

## How long will it take and what is the output?
################################################################################

- The processing time is machine-dependent. In tests with no resource allocation, it took approximately 12 minutes to process 200 files. (Configuration options to be added).
- The pipeline generates a `results_summary.pdf` file (additional output formats, such as command-line information or text files, will be added in the future).



