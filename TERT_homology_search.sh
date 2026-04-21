#!/bin/bash

# Load required modules
# It requieres python3.6 to be installed and loaded as a module
# It requieres blast/2.10.0 to be installed and loaded as a module

# Runs tblastn searches of TERT sequence against assemblies downloaded based on GCA list

python3 /path/to/your/project/coleoptera_homology_heatmap/scripts/01_makeblastdb_coleoptera.py
python3 /path/to/your/project/coleoptera_homology_heatmap/scripts/02_tblastn_coleoptera.py
python3 /path/to/your/project/coleoptera_homology_heatmap/scripts/03_parse_blast_results.py
