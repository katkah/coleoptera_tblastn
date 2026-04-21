import os
import subprocess


# Directory containing the genomic files
input_directory = "/path/to/your/project/coleoptera_homology_heatmap/downloaded_assemblies/"

# Directory to save the BLAST databases
db_directory = "/path/to/your/project/coleoptera_homology_heatmap/blast_database/"

# Ensure the database directory exists
os.makedirs(db_directory, exist_ok=True)


# Function to create a BLAST database
def create_blast_db(fasta_file):
    # Extract the base name without extension for naming the BLAST database
    db_name = os.path.splitext(fasta_file)[0]

    
    # Construct the command to create the BLAST database
    cmd = [
        "makeblastdb",
        "-in", os.path.join(input_directory, fasta_file),
        "-dbtype", "nucl",
        "-out", os.path.join(db_directory, db_name)
    ]
    
    # Run the command using subprocess
    subprocess.run(cmd, check=True)
    print(f"Created BLAST database for {fasta_file} with name {db_name}")

    return db_name

# List all files in the directory
files = os.listdir(input_directory)

# Filter files ending with *genomic.fna
genomic_files = [f for f in files if f.endswith("genomic.fna")]

# Create BLAST database for each genomic file
for genomic_file in genomic_files:
    create_blast_db(genomic_file)


