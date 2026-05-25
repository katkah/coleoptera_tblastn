# TERT Homology Search across Coleoptera

Supplementary code and data for:

> Fajkus P., Štefanovič B., Závodník M., Havlová K., Fojtová M., Peška V., & Fajkus J. (2026).
> **The Missing Piece: Functional Telomerase Restored in the Beetle Model.**
> *Genome Biology and Evolution.*

This repository contains the full workflow used to survey Telomerase Reverse Transcriptase (TERT)
homologs across 420 coleopteran genome assemblies representing 60 beetle families, and to produce
the phylogenetically-sorted heatmap of tblastn e-values included in the paper.

---

## Overview

Telomerase activity and TERT gene presence vary across insect lineages. To map TERT conservation
across Coleoptera, we queried 12 reference TERT protein sequences (spanning major beetle
superfamilies) against all publicly available coleopteran genome assemblies from NCBI using
tblastn. Results are summarised as a matrix of best-hit e-values (genomes × query sequences)
and visualised as a heatmap grouped by beetle family.

**12 TERT query sequences** (from `query_TERTs.fasta`):

| Species | Superfamily |
|---|---|
| *Trechiama lewisi* | Caraboidea |
| *Coccinella septempunctata* | Cucujoidea |
| *Onthophagus taurus* | Scarabaeoidea |
| *Agrilus planipennis* | Buprestoidea |
| *Nicrophorus vespilloides* | Staphylinoidea |
| *Abscondita terminalis* | Elateroidea |
| *Cylas formicarius* | Curculionoidea |
| *Aethina tumida* | Cucujoidea |
| *Anoplophora glabripennis* | Chrysomeloidea |
| *Tribolium castaneum* | Tenebrionoidea |
| *Dorcus parallelipipedus* | Scarabaeoidea |
| *Holotrichia parallela* | Scarabaeoidea |

---

## Repository contents

```
.
├── GCA_list.txt                        # 420 NCBI GenBank Assembly accessions
├── query_TERTs.fasta                   # 12 TERT protein query sequences
├── taxonomy.csv                        # Family / species / GCA mapping (419 rows)
├── tblastn_evalues_summary.csv         # Final results: best e-value per genome × query
│
├── TERT_homology_search.sh             # Master script (runs steps 01–03 in sequence)
├── 00_download_fasta_from_GCA_list.sh  # Download genome assemblies from NCBI
├── 00_GCA_list_to_taxonomy_quick.sh    # Retrieve family-level taxonomy for each GCA
├── 01_makeblastdb_coleoptera.py        # Build BLAST nucleotide databases
├── 02_tblastn.py                       # Run tblastn (all queries × all genomes)
├── 03_parse_blast_results.py           # Parse results → tblastn_evalues_summary.csv
└── 04_heatmap.ipynb                    # Visualisation notebook → heatmap figure
```

The summary table (`tblastn_evalues_summary.csv`) and taxonomy file (`taxonomy.csv`) are included
so the heatmap notebook (`04_heatmap.ipynb`) can be run directly without repeating the BLAST
searches.

---

## Dependencies

| Tool | Version used | Notes |
|---|---|---|
| BLAST+ | 2.10.0 | provides `makeblastdb` and `tblastn` |
| NCBI E-Direct | any recent | provides `esearch`, `efetch`, `xtract` |
| Python | 3.6+ | |
| Biopython | 1.79+ | `pip install biopython` |
| pandas | 1.3+ | `pip install pandas` |
| NumPy | 1.21+ | `pip install numpy` |
| Seaborn | 0.11+ | `pip install seaborn` |
| Matplotlib | 3.4+ | `pip install matplotlib` |
| Jupyter | any | for `04_heatmap.ipynb` |

---

## Reproducing the analysis

### 1. Configure paths

All scripts use a `RESULT_DIR` / path variable at the top. Set this to your working directory
before running each script. The expected directory layout is:

```
RESULT_DIR/
├── GCA_list.txt
├── query_TERTs.fasta
├── downloaded_assemblies/   # created by step 00
├── blast_database/          # created by step 01
└── tblastn_resultsTERTs/    # created by step 02
```

### 2. Download genome assemblies (~420 FASTA files)

```bash
bash 00_download_fasta_from_GCA_list.sh
```

Fetches each assembly from NCBI via FTP using the accessions in `GCA_list.txt`. Downloads are
retried up to 3 times on failure. Runtime depends on network speed; expect several hours for
the full set.

### 3. Build taxonomy table

```bash
bash 00_GCA_list_to_taxonomy_quick.sh
```

Queries NCBI Taxonomy for the family rank of each accession and writes `taxonomy.csv`.

### 4. Build BLAST databases

```bash
python3 01_makeblastdb_coleoptera.py
```

Runs `makeblastdb -dbtype nucl` on every `*_genomic.fna` file in `downloaded_assemblies/`.

### 5. Run tblastn

```bash
python3 02_tblastn.py
```

Queries each of the 12 TERT sequences against each genome database. Parameters: e-value
threshold 1×10⁻⁵, up to 10 target sequences per query, 5 threads per search. Output is saved
in both pairwise (format 0) and tabular (format 6) formats. This step is the bottleneck;
runtime scales with the number of genomes and available CPU cores.

### 6. Parse results

```bash
python3 03_parse_blast_results.py
```

Aggregates the tabular tblastn output into `tblastn_evalues_summary.csv`. For each
genome × query pair the best (lowest) e-value is recorded; pairs with no hit above the
threshold are recorded as NaN.

Alternatively, steps 4–6 can be run in sequence via:

```bash
bash TERT_homology_search.sh
```

### 7. Generate the heatmap

Open `04_heatmap.ipynb` in Jupyter and run all cells. The notebook reads
`tblastn_evalues_summary.csv` and `taxonomy.csv` directly, so this step can be run
independently of steps 1–6 using the result files already present in the repository.

E-values are log₁₀-transformed for visualisation. Exact matches (e-value = 0) are replaced
with the second-smallest observed value (2.89×10⁻¹⁷⁹) prior to transformation. Rows are
sorted by beetle family, with families ordered by descending number of represented species.

---

## Output

`tblastn_evalues_summary.csv` — 419 rows (genomes) × 14 columns:

| Column | Description |
|---|---|
| `db_name` | Genome assembly filename stem |
| `GCA` | NCBI GenBank Assembly accession |
| *query columns* (×12) | Best tblastn e-value for that query, or NaN if no hit |

---

## Citation

If you use these scripts or data, please cite the paper above.
