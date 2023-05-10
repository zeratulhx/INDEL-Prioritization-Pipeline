# INDEL Prioritization Pipeline

## What does this do?
###############################################################################

This command-line pipeline processes a .vcf file containing variants identified by a variant caller (e.g., MINTIE https://github.com/Oshlack/MINTIE) and prioritizes INDELs that are more likely to impact proteins.

- The pipeline generates a list of known variants within the cohort (or sample) that are causally associated with cancer, based on The Cancer Gene Census (CGC) (https://cancer.sanger.ac.uk/census).
- The pipeline also creates a prioritized list of coding region variants not found in COSMIC or dbSNP, potentially identifying novel variants.
- The pipeline produces a list of cancers and associated variants linked to genes identified as containing a novel variant.

## How do I run this?
################################################################################

The pipeline runs offline, but requires several large files to do so.

- Download all scripts and `renv.lock`. Ensure everything is in the same directory. 
- Install Ensembl VEP: https://asia.ensembl.org/info/docs/tools/vep/script/vep_download.html
- Download the VEP cache: https://asia.ensembl.org/info/docs/tools/vep/script/vep_cache.html#cache
    (https://ftp.ensembl.org/pub/release-109/variation/indexed_vep_cache/) - Bio::DB::HTS required.
- Install SQLite: https://sqlite.org/index.html
- Download `CosmicMutantExportCensus.tsv.gz` from https://cancer.sanger.ac.uk/cosmic/download (this file needs to be indexed based on the COSV identifier and renamed to `a_census_db.db` with a table called `a_census_table`.  Without indexing the pipeline will be very slow).
- Install Nextflow: https://www.nextflow.io/docs/latest/getstarted.html
- Install R: https://cloud.r-project.org/. 
- Place your .vcf files in a chosen directory and set their location in `nextflow.config`.
- Set the location for files containing VAF, control counts, and case counts in `6_GetResultFiles.sh`. These files should end in .tsv. 
- Run `Insertion_Pipeline.sh`.
- Edit 1_Get_INSDEL.sh for deletions.
- Test files to be added. 

## How long will it take and what is the output?
################################################################################

- The processing time is machine-dependent. In tests with no resource allocation, it took approximately 12 minutes to process 200 files. 
- The pipeline generates a `results_summary.pdf` file.

*****Warning******

Pipeline is in a very rough draft stage. See issues.  

