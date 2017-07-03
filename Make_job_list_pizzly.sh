#!/bin/bash -eu

# Matthew Bashton 2017
# Generates a run list from an input file for arbitrary programs
# Sample ID is first element on input line, followed by files

# This run list is then supplied to GNU parallel --jobs

hostname
date

[ $# -ne 2 ] && { echo -en "\n*** This script generates jobs for GNU parallel. *** \n\n Error Nothing to do, usage: < input tab delimited list > < output run list file >\n\n" ; exit 1; }
set -o pipefail

# Get command-line args
INPUT_LIST=$1
OUTPUT=$2

# Set counter
COUNT=1
END=$(wc -l $INPUT_LIST | awk '{print $1}' | grep -oP '^\S+')

echo " "
echo " * Input file is: $INPUT_LIST"
echo " * Number of runs: $END"
echo " * Output job list for GNU parallel saved to: $OUTPUT"
echo " "

# Main bit of command-line for job
CMD="pizzly -k 31 -a 2 --insert-size 400 --fasta Homo_sapiens.GRCh38.cdna.all.fa --gtf Homo_sapiens.GRCh38.89.gtf --output"

# Main Loop
[ -e $OUTPUT ] && rm $OUTPUT
while [ $COUNT -le $END ];
do
    LINE=$(awk "NR==$COUNT" $INPUT_LIST)
    # Make file list
    echo "Working on $COUNT of $END Sample ID: $LINE"
    echo "$CMD ${LINE}_fusion_GRCh38 ${LINE}/fusion.txt" >> $OUTPUT
    ((COUNT++))
done
