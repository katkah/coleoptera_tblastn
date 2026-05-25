#!/bin/bash

# Load required modules
# It requieres python3.6 to be installed and loaded as a module
# It requieres blast/2.10.0 to be installed and loaded as a module

# Runs tblastn searches of TERT sequence against assemblies downloaded based on GCA list

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

python3 "$BASE_DIR/01_makeblastdb_coleoptera.py"
python3 "$BASE_DIR/02_tblastn.py"
python3 "$BASE_DIR/03_parse_blast_results.py"
