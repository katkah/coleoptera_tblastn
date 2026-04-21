import os
import subprocess
from Bio import SeqIO

# Directory containing the genomic files
input_directory = "/path/to/your/project/coleoptera_homology_heatmap/downloaded_assemblies/"
# Directory containing the BLAST databases
db_directory = "/path/to/your/project/coleoptera_homology_heatmap/blast_database/"
# Directory to save the tblastn results
output_directory = "/path/to/your/project/coleoptera_homology_heatmap/tblastn_resultsTERTs/"
# Protein query file
protein_query = "/path/to/your/project/coleoptera_homology_heatmap/scripts/query_TERTs.fasta"

# Ensure the output directories exists
os.makedirs(output_directory, exist_ok=True)

# Make list of all organisms:
# List all files in the directory
files = os.listdir(input_directory)
# Filter files ending with *genomic.fna
genomic_files = [f for f in files if f.endswith("genomic.fna")]

db_names = []
for genomic_file in genomic_files:
    db_name = os.path.splitext(genomic_file)[0]
    db_names.append(db_name)


# Function to run tblastn
""""
# outfmt options:
 -outfmt <String>
   alignment view options:
     0 = Pairwise,
     1 = Query-anchored showing identities,
     2 = Query-anchored no identities,
     3 = Flat query-anchored showing identities,
     4 = Flat query-anchored no identities,
     5 = BLAST XML,
     6 = Tabular,
     7 = Tabular with comment lines,
     8 = Seqalign (Text ASN.1),
     9 = Seqalign (Binary ASN.1),
    10 = Comma-separated values,
    11 = BLAST archive (ASN.1),
    12 = Seqalign (JSON),
    13 = Multiple-file BLAST JSON,
    14 = Multiple-file BLAST XML2,
    15 = Single-file BLAST JSON,
    16 = Single-file BLAST XML2,
    18 = Organism Report
"""
def run_tblastn(query_file, query_name, db_name, outfmt):
    output_file = os.path.join(output_directory, f"{query_name}_{db_name}_format_{outfmt}_tblastn.txt")
    
    cmd = [
        "tblastn",
        "-query", query_file,
        "-db", os.path.join(db_directory, db_name),
        "-out", output_file,
        "-evalue", "1e-5",
        "-outfmt", outfmt,
        "-num_threads", "5",
        "-max_target_seqs", "10"
    ]
    
     
    subprocess.run(cmd, check=True)
    print(f"Ran tblastn for query {query_name} against database {db_name}, results saved to {output_file}")
    
    
   

    
# Loop through each query in the protein query file
for record in SeqIO.parse(protein_query, "fasta"):
    query_name = record.id
    query_file = os.path.join(output_directory, f"{query_name}.fasta")
    
    # Write the individual query to a  file
    with open(query_file, "w") as f:
        SeqIO.write(record, f, "fasta")
    
    
    # Run tblastn for each database
    for db_name in db_names:
        run_tblastn(query_file, query_name, db_name, "0")
        run_tblastn(query_file, query_name, db_name, "6")
        
    # Remove the temporary query file
    os.remove(query_file)
        
