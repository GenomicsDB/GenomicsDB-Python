#!/bin/bash
#
# query script
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

WORKSPACE=${WORKSPACE:-my_workspace}
export CALLSET_FILE=${CALLSET_FILE:-$WORKSPACE/callset.json}
export VIDMAP_FILE=${VIDMAP_FILE:-$WORKSPACE/vidmap.json}
export LOADER_FILE=${LOADER_FILE:-$WORKSPACE/loader.json}

declare -a INTERVALS
INTERVALS=("1:1-1000000")
#INTERVALS=("1:1-1000000" "1:1000001-2000000" "1:2000001-3137454")
#INTERVALS=("chr1:1-200000")
#INTERVALS=("1:1-3137454")
#INTERVALS=("1:1-40000000")
#INTERVALS=("1:1-4000000" "1:8000001-16000000" "1:16000001-24000000" "1:24000001-32000000" "1:32000001-40000000" "2:3000" "3")
#INTERVALS=("1:1-12549816")
#INTERVALS=("1:1-3137454" "1:3137455-6274908" "1:6274909-9412362" "1:9412363-12549816")

#declare -a SAMPLES
#SAMPLES=("HG00096" "HG00097" "HG00099")

#FILTER='resolve(GT, REF, ALT) &= "T/T"'

export OUTPUT_FILE=${OUTPUT_FILE:-my_output}
export OUTPUT_FILE_TYPE=${OUTPUT_FILE_TYPE:-json}

export TILEDB_CACHE=1
NTHREADS=${NTHREADS:-8}

###########################################
# Should not have to change anything below
###########################################

if [[ ! -d env ]]; then
  python3 -m venv env
  source env/bin/activate
  pip install genomicsdb
else
  source env/bin/activate
fi

PATH=$(dirname $0):$PATH

if [[ ! -z ${SAMPLES} ]]; then
  for SAMPLE in "${SAMPLES[@]}"
  do
    SAMPLE_ARGS="$SAMPLE_ARGS -s $SAMPLE"
  done
fi

if [[ ! -z ${FILTER} ]]; then
  FILTER_EXPR="-f $FILTER"
fi

echo  $LOADER_FILE  $CALLSET_FILE   $VIDMAP_FILE

rm -f loader.json callset.json vidmap.json
for INTERVAL in "${INTERVALS[@]}"
do
  INTERVAL_LIST="$INTERVAL_LIST -i  $INTERVAL"
done

genomicsdb_cache -w $WORKSPACE -l $LOADER_FILE  -c $CALLSET_FILE -v $VIDMAP_FILE $INTERVAL_LIST

if [[ -f loader.json ]]; then
  export LOADER_FILE="loader.json"
fi
if [[ -f callset.json ]]; then
  export CALLSET_FILE="callset.json"
fi
if [[ -f vidmap.json ]]; then
  export VIDMAP_FILE="vidmap.json"
fi

run_query() {
  INTERVAL=$1
  OUTPUT_FILE=$2
  echo genomicsdb_query -w $WORKSPACE -l $LOADER_FILE -c $CALLSET_FILE -v $VIDMAP_FILE -i $INTERVAL $SAMPLE_ARGS $FILTER_EXPR -o $OUTPUT_FILE -t $OUTPUT_FILE_TYPE
  /usr/bin/time -l genomicsdb_query -w $WORKSPACE -l $LOADER_FILE -c $CALLSET_FILE -v $VIDMAP_FILE -i $INTERVAL $SAMPLE_ARGS $FILTER_EXPR -o $OUTPUT_FILE -t $OUTPUT_FILE_TYPE
}

export -f run_query  
parallel -j${NTHREADS} run_query {} $OUTPUT_FILE ::: ${INTERVALS[@]}

deactivate
