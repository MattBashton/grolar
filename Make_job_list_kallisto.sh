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
END=$(wc -l $INPUT_LIST | awk '{print $1}')

echo " "
echo " * Input file is: $INPUT_LIST"
echo " * Number of runs: $END"
echo " * Output job list for GNU parallel saved to: $OUTPUT"
echo " "

# Main bit of command-line for job
CMD="kallisto quant -i GRCh38v89.idx --bias --fusion --fr-stranded -t 1"

# Main Loop
[ -e $OUTPUT ] && rm $OUTPUT
while [ $COUNT -le $END ];
do
    LINE=( $(awk "NR==$COUNT" $INPUT_LIST) )
    # Make file list
    echo "Working on $COUNT of $END Sample ID: ${LINE[0]}, Files ${LINE[@]:1}"
    echo "$CMD -o ${LINE[0]} ${LINE[@]:1}" >> $OUTPUT
    ((COUNT++))
done
