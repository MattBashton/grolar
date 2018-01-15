## Grolar ##
Grolar is a downstream parser script for the [Pizzly](https://github.com/pmelsted/pizzly) RNA-Seq fusion detector implemented in R.  It flattens Pizzly JSON output using [jsonlite](https://cran.r-project.org/web/packages/jsonlite/index.html) package in R. It also adds in co-ordinates for gene A and gene B of a fusion, and calculates gene distances (where fusions take place on the same chromosome) using the [ensembldb](http://bioconductor.org/packages/release/bioc/html/ensembldb.html) bioconductor package.

### Utility shell scripts for GNU parallel ###
The two provided bash script are also of utility, allowing both Kallisto and Pizzly to be run on multiple cores for an arbitrary number of samples using [GNU parallel](https://www.gnu.org/software/parallel/).  The input for both these scripts is a tab delimited flat file taking the form of:

```
sample_1	sample_1_R1.fastq.gz	sample_1_R2.fastq.gz
sample_2	sample_2_R1.fastq.gz	sample_2_R2.fastq.gz
sample_3	sample_3_R1.fastq.gz	sample_3_R2.fastq.gz
```

If more than one pair of fastq files exists for each sample simply add these on as extra tab delimited columns.

Having made such a file you can create a job lists for GNU parallel like so:

```
Make_job_list_kallisto.sh sample_list.txt kallisto_jobs
Make_job_list_pizzly.sh sample_list.txt pizzly_jobs
```

Each of these lists can then be run with GNU parallel like so:

```
parallel --progress --jobs 12 --joblog kallisto_joblog.txt < kallisto_jobs
```

The above example would set of a maximum of 12 jobs simultaneously sourced from `kallisto_jobs` writing log info to the `kallisto_joblog.txt` file.  Note that defaults such as command-line arguments and `.gft` and `index files` need to be set by editing the two shell scripts.  The `--progress` argument will give the following info on the terminal `Computer:jobs running/jobs completed/%of started jobs/Average seconds to complete`. Full documentation for GNU parallel can be found [here](https://www.gnu.org/software/parallel/man.html).
