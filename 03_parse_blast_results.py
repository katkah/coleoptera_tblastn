import os
import pandas as pd
import subprocess
from Bio import SeqIO
import numpy as np

#Parses all results from tblastn and creates a table of e-values with databases as rows and query as columns

# Directory containing the genomic files
input_directory = "/path/to/your/project/coleoptera_homology_heatmap/downloaded_assemblies/"
# Protein query file
protein_query = "/path/to/your/project/coleoptera_homology_heatmap/scripts/query_TERTs.fasta"
# Directory with the tblastn results
output_directory = "/path/to/your/project/coleoptera_homology_heatmap/tblastn_resultsTERTs/"


queries = []
# Loop through each query in the protein query file and save the query name
for record in SeqIO.parse(protein_query, "fasta"):
    query_name = record.id
    queries.append(query_name)


db_names = []
# List all files in the directory
files = os.listdir(input_directory)
# Filter files ending with *genomic.fna
genomic_files = [f for f in files if f.endswith("genomic.fna")]
for genomic_file in genomic_files:
    db_name = os.path.splitext(genomic_file)[0]
    db_names.append(db_name)

#all_files = os.listdir(output_directory)    
#f6_files = [f for f in all_files if "_format_6_" in f]




#function to check if the file is not empty
def is_non_zero_file(fpath):
    #If fpath is not a valid file path, this function will raise an error, which is why os.path.isfile is checked first  
#   It checks whether the file size is greater than 0 bytes, meaning the file is not empty
    return os.path.isfile(fpath) and os.path.getsize(fpath) > 0

def parse_file(tblastn):
    if is_non_zero_file(tblastn):
        t = pd.read_csv(tblastn, sep='\t', header=None)
        # Extract the 11th column(number 10 in pandas), sort values, take the lowest e-value
        return t.iloc[:, 10].sort_values()[0]
    else:
        print(f"file {tblastn} is empty")
        return np.nan
          

df = pd.DataFrame(columns=["db_name","GCA"] + queries)

for db in db_names:
    row = {}
    row['db_name'] = db
    row['GCA'] = db.split('_')[0] + '_' + db.split('_')[1]
    for q in queries: 
        tblastn = os.path.join(output_directory, f"{q}_{db}_format_6_tblastn.txt")
        evalue = parse_file(tblastn)
        row[q] = evalue
    df.loc[len(df)] = row

out_file = os.path.join(output_directory, f"tblastn_evalues_summary.csv")
df.to_csv(out_file, index=False)        

out_file = os.path.join(output_directory, f"gca_list.csv")
df['GCA'].to_csv(out_file, index=False)    
