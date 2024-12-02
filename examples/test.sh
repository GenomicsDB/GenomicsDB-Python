#!/bin/bash
#
# test query script
#
# The MIT License
#
# Copyright (c) 2024 dātma, inc™
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#
#

# Tests run on a workspace importing 5 or more samples from the TCGA 1000G dataset
#   ALL.all_fixed.phase3_shapeit2_mvncall_integrated_v5a.20130502.genotypes.HG00096.vcf.gz
#   ALL.all_fixed.phase3_shapeit2_mvncall_integrated_v5a.20130502.genotypes.HG00097.vcf.gz
#   ALL.all_fixed.phase3_shapeit2_mvncall_integrated_v5a.20130502.genotypes.HG00099.vcf.gz
#   ALL.all_fixed.phase3_shapeit2_mvncall_integrated_v5a.20130502.genotypes.HG00100.vcf.gz
#   ALL.all_fixed.phase3_shapeit2_mvncall_integrated_v5a.20130502.genotypes.HG00101.vcf.gz
# To create a workspace for testing, do the following
# ~/GenomicsDB/install/bin/vcf2genomicsdb_init -w ws -S ~/vcfs -n 1000
# ~/GenomicsDB/install/bin/vcf2genomicsdb -r 0 ws/loader.json
# ~/GenomicsDB/install/bin/vcf2genomicsdb -r 1 ws/loader.json
# ~/GenomicsDB/install/bin/vcf2genomicsdb -r 2 ws/loader.json
# ~/GenomicsDB/install/bin/vcf2genomicsdb -r 80 ws/loader.json

WORKSPACE=${WORKSPACE:-ws}
INTERVAL_ARGS="-i 1:1-40000000 -i 2:3000-40000 -i 2:40001 -i 3"
SAMPLE_ARGS="-s HG00096 -s HG00097 -s HG00099"
VIDMAP_FILE=vidmap_file.json
LOADER_FILE=loader_file.json
FILTER='ISHOMREF'


if [[ $(uname) == "Darwin" ]]; then
  TEMP_DIR=$(mktemp -d -t test-examples)
else
  TEMP_DIR=$(mktemp -d -t test-examples-XXXXXXXXXX)
fi

OUTPUT="$TEMP_DIR/out"

cleanup() {
  rm -fr $TEMP_DIR
}

die() {
  cleanup
  if [[ $# -eq 1 ]]; then
    echo $1
  fi
  exit 1
}

# run_command
#    $1 : command to be executed
#    $2 : optional - 0(default) if command should return successfully
#                    any other value if the command should return a failure
run_command() {
  echo $EMPTY > $TEMP_DIR/output
  declare -i EXPECT_NZ
  declare -i GOT_NZ
  EXPECT_NZ=0
  GOT_NZ=0
  if [[ $# -eq 2 && $2 -ne 0 ]]; then
    EXPECT_NZ=1
  fi
  # Execute the command redirecting all output to $TEMP_DIR/output
  $($1 &> $TEMP_DIR/output)
  retval=$?

  if [[ $retval -ne 0 ]]; then
    GOT_NZ=1
  fi

  if [[ $(($GOT_NZ ^ $EXPECT_NZ)) -ne 0 ]]; then
    cat $TEMP_DIR/output
    die "command '`echo $1`' returned $retval unexpectedly"
  fi
}

PATH=.:$PATH
run_command "genomicsdb_query" 2
run_command "genomicsdb_query -h"
run_command "genomicsdb_query --version"
run_command "genomicsdb_query --list-samples" 2
run_command "genomicsdb_query --list-contigs" 2
run_command "genomicsdb_query -w $WORKSPACE" 1
run_command "genomicsdb_query -w $WORKSPACE -i xx -S XX" 1

if [[ ! -d $WORKSPACE ]]; then
  echo "Specify an existing workspace in env WORKSPACE"
  exit 1
fi

genomicsdb_query -w $WORKSPACE --list-contigs > $TEMP_DIR/contigs.list
genomicsdb_query -w $WORKSPACE --list-samples > $TEMP_DIR/samples.list

declare -a FILES
FILES=("1-1-40000000", "1-1-40000000_1", "2-3000-40000", "2-40001")
run_command "genomicsdb_query -w $WORKSPACE $INTERVAL_ARGS -o $OUTPUT"
for FILE in "${INTERVALS[@]}"
do
  if [[ ! -f $OUTPUT_$FILE.csv ]]; then
    echo "Could not find file=$OUTPUT_$FILE.csv"
    exit 1
  fi
done
run_command "genomicsdb_query -w $WORKSPACE $INTERVAL_ARGS -o $OUTPUT --output-type json" 
for FILE in "${INTERVALS[@]}"
do
  if [[ ! -f $OUTPUT_$FILE.json ]]; then
    echo "Could not find file=$OUTPUT_$FILE.json"
    exit 1
  fi
done

run_command "genomicsdb_query -w $WORKSPACE -I $TEMP_DIR/contigs.list -s HG00096"
run_command "genomicsdb_query -w $WORKSPACE -I $TEMP_DIR/contigs.list -s HG00097 -s HG00100 -s HG00096"
run_command "genomicsdb_query -w $WORKSPACE -I $TEMP_DIR/contigs.list -s HG00096 -s NON_EXISTENT_SAMPLE"
run_command "genomicsdb_query -w $WORKSPACE -I $TEMP_DIR/contigs.list -s NON_EXISTENT_SAMPLE"
run_command "genomicsdb_query -w $WORKSPACE -I $TEMP_DIR/contigs.list -S $TEMP_DIR/samples.list"
run_command "genomicsdb_query -w $WORKSPACE $INTERVAL_ARGS -S $TEMP_DIR/samples.list"
run_command "genomicsdb_query -w $WORKSPACE $INTERVAL_ARGS -S $TEMP_DIR/samples.list -f $FILTER"

cleanup