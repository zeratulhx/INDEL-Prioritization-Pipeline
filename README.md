# AutomatedITD



Requires Python 3 to run. 

Requires GRCh38 to run, depending on how VEP is installed, you may need this file with your documents (or if you want the latest version). Due to server limitations where the file is hosted, this takes a long time. This can be downloaded through the terminal and run as a background download using "nohup wget -c https://ftp.ensembl.org/pub/release-109/variation/indexed_vep_cache/homo_sapiens_vep_109_GRCh38.tar.gz > download.og &". This runs the download as a background task that will not be interuppted by closing of the terminal. The download can be checked using "tail -f download.log" in the directory where the file is being downloaded to. 
