#!/bin/bash -eu

# Matthew Bashton 2017
# Generates a run list from an input file for arbitrary programs
# Sample ID is first element on input line, followed by files

# This run list is then supplied to GNU parallel --jobs

# Note: you'll need to have the get_fragment_length.py and flatten_json.py
# script from Pizzly in: /usr/local/bin/ for this script to work, you
# can set it's location below:
SCRIPT_PATH="/usr/local/bin"

hostname
date

[ $# -ne 2 ] && { echo -en "\n*** This script generates jobs for GNU parallel. *** \n\n Error Nothing to do, usage: < input tab delimited list > < output run list file >\n\n" ; exit 1; }
set -o pipefail

# Get command-line args
INPUT_LIST=$1
OUTPUT=$2

# Set counter
COUNT=1
END=$(wc -l $INPUT_LIST | awk '{print $1}')

echo " "
echo " * Input file is: $INPUT_LIST"
echo " * Number of runs: $END"
echo " * Output for GNU parallel saved to: $OUTPUT"
echo " "

# Main bit of command-line for job
CMD="pizzly -k 31 -a 2 --insert-size"

# Main Loop
[ -e $OUTPUT ] && rm $OUTPUT
while [ $COUNT -le $END ];
do
    LINE=$(awk "NR==$COUNT" $INPUT_LIST | grep -oP '^\S+')
    # Get insert size from python script
    SIZE=$(python /usr/local/bin/get_fragment_length.py ${LINE}/abundance.h5)
    # Make file list
    echo "Working on $COUNT of $END Sample ID: $LINE, insert size is: $SIZE"
    echo "$CMD $SIZE --fasta Homo_sapiens.GRCh38.cdna.all.fa --gtf Homo_sapiens.GRCh38.89.gtf --output ${LINE}_fusion_GRCh38 ${LINE}/fusion.txt; python $SCRIPT_PATH/flatten_json.py ${LINE}_fusion_GRCh38.json ${LINE}_fusion_GRCh38_flattened.txt" >> $OUTPUT
    ((COUNT++))
done
