import os

MINTIE_VCF_FilePath = input("Please enter the file path of the VCF files for processing: ")


if os.path.exists(MINTIE_VCF_FilePath):
    count = 0

  
    for VCFFile in os.listdir(MINTIE_VCF_FilePath):

        #If the file in the folder location is a vcf, generate unique file ID, open the file and copy the header to a newly generated output file
        if VCFFile.endswith('.vcf'):
            
            count += 1
            filename = "Processedfile" + str(count)

            
            MINTIE_Output_File = os.path.join(MINTIE_VCF_FilePath, VCFFile)
            with open(MINTIE_Output_File, 'r') as file:
                header_lines_to_copy = file.readlines()[:7]
            with open (f'{filename}.txt', 'w')  as file:
                file.writelines(header_lines_to_copy)

            #Go through the MINTIE VCF file and pull out insertions and deletions and add to the output file.
            with open(MINTIE_Output_File, 'r') as file:   
                for line in file:
                    if 'SVTYPE=INS' in line:
                        with open(f'{filename}.txt','a') as file:
                            file.write(f'{line}')


            #Remove original files

            os.remove(MINTIE_Output_File)               
                                
            """
                    
                elif 'SVTYPE=DEL' in line:
                    with open('all.txt','a') as file:
                        file.write(f'{line}')
            """
        
else:

    print(f"File{MINTIE_VCF_FilePath} does not exist. Please check your file path.")

