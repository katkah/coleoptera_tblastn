#!/bin/bash

# The script uses edirect utilities to create taxonomy.csv (info about family, taxon)based on a list of GCA numbers
# It requieres edirect to be installed and loaded as a module
# It requieres python3.6 to be installed and loaded as a module
##########################################################################################
# SET VARIABLES IN THIS SECTION 

# Set the directory for outputs -> the directory is going to be created in the next step
# The outputs are: downloaded files and taxonomy.csv
RESULT_DIR="/path/to/your/project/coleoptera_homology_heatmap"

#Set the input csv file. It should contain one "GenBank Assembly ID" number per line, e.g.:
#GCA_024364675.1
#GCA_024364675.1
#GCA_917563875.2

INPUT_LIST="/path/to/your/project/coleoptera_homology_heatmap/GCA_list.txt"

############################################################################################

# Create the directory for outputs
mkdir -p $RESULT_DIR
mkdir -p $RESULT_DIR/downloaded_assemblies
cd $RESULT_DIR/downloaded_assemblies

# Set the temporary CSV file
output_csv=$RESULT_DIR/downloaded_assemblies/taxonomy.csv

# Only fetch Family rank - the only taxonomy rank we need
taxonomy_ranks=("Family")

# Add the header to CSV - only the three columns we need
echo "family,ScientificName,GCA" > "${output_csv}"

# Download assemblies in FASTA formats and retrieve scientific names

#Using "GenBank Assembly ID" as query
#esearch -db assembly -query "GCA_024364675.1[Assembly Accession]" | esummary | xtract -pattern DocumentSummary -sep ';' -element Taxid,FtpPath_GenBank
#Result: 
#116153;ftp://ftp.ncbi.nlm.nih.gov/genomes/all/GCA/024/364/675/GCA_024364675.1_icAetTumi1.1

for row in $(cat $INPUT_LIST); do
    # get taxid and FtpPath, in case there are more hits in database, only first one is taken
    res=$(esearch -db assembly -query "$row[Assembly Accession]" | esummary | xtract -pattern DocumentSummary -sep ';' -element Taxid,FtpPath_GenBank | head -n 1)
    taxid=$(echo "$res" | cut -d ';' -f 1)
    line=$(echo "${res#*;}") 
    
    # It greps only GCA file name from line e.g. ftp://ftp.ncbi.nlm.nih.gov/genomes/all/GCA/024/708/375/GCA_024708375.1_oxalis_stricta_v0.1
    f=$(echo $line | grep -o 'GCA_.*' )
    fname=$(echo $line | grep -o 'GCA_.*' | sed 's/$/_genomic.fna.gz/')
    echo "Processing $taxid"
    echo "Processing $line"

    # Fetch only Family rank information using Taxid
    echo "Fetching family info:"
    family_info=$(esearch -db taxonomy -query "${taxid} [taxID]" | efetch -format native -mode xml | xtract -pattern Taxon -block "*/Taxon" -if Rank -equals "Family" -element ScientificName)

    # Check if family_info is empty and set it to "NA" if true
    max_attempts=100
    attempts=0

    while [ "$attempts" -lt "$max_attempts" ]; do
        # If family_info length not zero then fetching info was success and break the loop
        if [ -n "$family_info" ]; then
            break
        fi
        family_info=$(esearch -db taxonomy -query "${taxid} [taxID]" | efetch -format native -mode xml | xtract -pattern Taxon -block "*/Taxon" -if Rank -equals "Family" -element ScientificName)
        attempts=$((attempts + 1))
    done
    # If family_info length is zero then it was unsuccess even after the x-th attempt and set it to NA
    if [ -z "$family_info" ]; then
        family_info="NA"
        echo "fetching family_info for ${taxid} was unsuccessful"
    fi

    # Fetch the "ScientificName" information using Taxid
    taxon=$(efetch -db taxonomy -id "${taxid}" -format xml | xtract -pattern Taxon -element ScientificName)
    max_attempts=100
    attempts=0

    while [ "$attempts" -lt "$max_attempts" ]; do
        if [ -n "$taxon" ]; then
            break
        fi
        taxon=$(efetch -db taxonomy -id "${taxid}" -format xml | xtract -pattern Taxon -element ScientificName)
        attempts=$((attempts + 1))
    done    
    
    # Check if taxon is empty and set it to "NA" if true       
    if [ -z "$taxon" ]; then
        taxon="NA"
        echo "fetching taxon for ${taxid} was unsuccessful"
    fi
    
    # Get GCA number
    GCA=$(echo "${fname}" | cut -d '_' -f2)
    
    # Write the three columns: family,ScientificName,GCA
    echo "${family_info},${taxon},GCA_${GCA}" >> "${output_csv}"
   
    echo "Finished processing line."

        
done   



