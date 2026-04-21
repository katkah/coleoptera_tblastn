#!/bin/bash

# Script uses edirect utilities to download assembly genomes based on a list of GCA numbers.
# It saves the assemblies to "donwloaded_assemblies" 
# It requieres edirect to be installed and loaded as a module
# It requieres python3.6 to be installed and loaded as a module


##########################################################################################
# SET VARIABLES IN THIS SECTION 

# Set the directory for outputs -> the directory is going to be created in the next step
RESULT_DIR="/path/to/your/project/coleoptera_homology_heatmap/"

# Set the input csv file
# One "GenBank Assembly ID" number per line, e.g.:
#GCA_024364675.1
#GCA_024364675.1
#GCA_917563875.2
#GCA_939628115.1
#GCA_947389935.1
#GCA_921294245.1
#GCA_917563865.1
#GCA_031307605.1

INPUT_LIST="/path/to/your/project/coleoptera_homology_heatmap/GCA_list.txt"


############################################################################################

# Create the directory for outputs
mkdir -p $RESULT_DIR
mkdir -p $RESULT_DIR/downloaded_assemblies
cd $RESULT_DIR/downloaded_assemblies
# Set the temporary CSV file
output_csv=$RESULT_DIR/downloaded_assemblies/output_tmp.csv
# Save the header of a temporary file
echo "GCA,name" > ${output_csv}

# Step1: Download assemblies in FASTA formats and retrieve scientific names

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
    echo -n "${f}," >> "${output_csv}"
    
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
        echo "fetching taxon for and ${taxid} was unsuccessful"
    fi
    #Save scientific name to output_csv
    echo "${taxon}" >> "${output_csv}"
   
    # Downloading assembly file
    max_attempts=3
    attempts=0

    while [ "$attempts" -lt "$max_attempts" ]; do
        wget "$line/$fname"

        if [ $? -eq 0 ]; then
            echo "File downloaded successfully"
            break  # Break out of the loop if download is successful
        else
            echo "Error: File download failed, retrying..."
            attempts=$((attempts + 1))
        fi
    done
      
       if [ "$attempts" -ge "$max_attempts" ]; then
        echo "Error: Maximum download attempts reached. File download unsuccessful."
    fi
    echo "Finished processing line."

        
done   

# Step2: Unzip downloaded files
for file in *genomic.fna.gz
do
    gunzip "$file"
done


