import pandas as pd
import numpy as np
import os
import re

string='chr1\tpos1\tstrand1\tchr2\tpos2\tstrand2\tvariant_type\toverlapping_genes\tsample\tvariant_id\tpartner_id\tvars_in_contig\tVAF\tvarsize\tcontig_varsize\tcpos\tlarge_varsize\tis_contig_spliced\tspliced_exon\toverlaps_exon\toverlaps_gene	motif\tvalid_motif\tcase_CPM\tTPM\tmean_WT_TPM\tlogFC\tPValue\tFDR\tec_names\tn_contigs_in_ec\tcontigs_in_EC\tcase_reads\tcontrols_total_reads\tcontig_id\tunique_contig_ID\tcontig_len\tcontig_cigar\tseq_loc1	seq_loc2\tseq1\tseq2'
string=string.split('\t')

df= pd.read_csv('resultlines.txt',sep='\t',names=string,low_memory=False)
print(len(df))


#print(df[df['FDR']=='FDR'])
df['FDR'] = pd.to_numeric(df['FDR'], errors='coerce')
#print(df.head(5))
#print(df.FDR.dtype)
#print(df.FDR[df.FDR.apply(lambda x: isinstance(x, str))])
df=df.sort_values('FDR')
df=df.drop_duplicates('variant_id')
df1=pd.read_csv('zdf_split.txt',sep=',')
print(len(df))
df1=df1[['V1','V3','col3','ExistingVariant','col2']]
df1=df1.drop_duplicates('V3')
print(len(df1))
#exit()
new_df=pd.merge(left=df1,right=df,left_on=['V3','V1'],right_on=['variant_id','chr1'])
print(len(new_df))
new_df=new_df[['variant_id','col3','col2','ExistingVariant','overlapping_genes','VAF','case_reads','controls_total_reads','contig_cigar','contig_len']]
COSMIC_df=pd.read_csv(os.path.join(args.database_dir,'Census_cosmic_gene.csv'),sep=',')
#new_df=new_df.fillna(0)
for index,row in new_df.iterrows():
    #cosmic gene info extraction
    try:
        gene_name=row['overlapping_genes'].split('|')
    except:
        print('not str')
        print(row['overlapping_genes'])
        gene_name=['']
    for i in gene_name:
        cosmic_info='none'
        try:
            cosmic_row_df=(COSMIC_df[COSMIC_df['Gene Symbol']==i])
            cosmic_info=cosmic_row_df['Tier'].values[0]
        except:
            cosmic_info='none'
        new_df.loc[index,'COSMIC_Tier']=cosmic_info
    new_df.loc[index,'gene_counts']=len(gene_name)
    #cigar info calculation
    #segments in cigar
    cigar_indicator='MIDNSHP'
    cnt=0
    for i in row['contig_cigar']:
        if(i in cigar_indicator):
            cnt+=1
    new_df.loc[index,'Segs']=int(row['contig_len'])/cnt
    #nearest distance between I & D
    I_count=row['contig_cigar'].count('I')
    pattern = r'(\d+)([A-Z])'
    matches = re.findall(pattern, row['contig_cigar'])
    result=[]
    value=0
    flg=0
    fflg=0
    current_sum=0
    for match in matches:
        value = int(match[0])
        letter = match[1]
        current_sum+=value
        if(letter == 'D'):
            if(fflg!=1):
                flg=1
                current_sum=0
                continue
            elif(flg==1):
                current_sum=0
                continue
            else:
                result.append(current_sum)
                current_sum=0
                fflg=0
                continue
        if(letter =='I'):
            if(flg!=1):
                fflg=1
                current_sum=0
                continue
            else:
                current_sum-=value
                result.append(current_sum)
                current_sum=0
                continue
    final_num=0
    for i in result:
        final_num+=int(i)
    if(final_num==0):
        final_num=99999
    new_df.loc[index,'nearest_D_from_I']=final_num


    


#df=df[df['variant_type']=='INS']
new_df.to_csv('summary_df.csv',sep='\t')
print(new_df.columns)
