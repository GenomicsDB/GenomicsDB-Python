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
declare -a INTERVALS
INTERVALS=("1:1-40000000" "2:3000" "3")
#declare -a SAMPLES
#SAMPLES=("HG00096" "HG00097" "HG00099")
#VIDMAP_FILE=my_vidmap_file.json
#LOADER_FILE=my_loader_file.json
#FILTER='resolve(GT, REF, ALT) &= "T/T"'
OUTPUT_FILE=my_output


###########################################
# Should not have to change anything below
###########################################

if [[ ! -d env ]]; then
  python3.11 -m venv env
  source env/bin/activate
  pip install genomicsdb
else
  source env/bin/activate
fi

for INTERVAL in "${INTERVALS[@]}"
do
   INTERVAL_ARGS="$INTERVAL_ARGS -i $INTERVAL"
done

if [[ ! -z ${SAMPLES} ]]; then
  for SAMPLE in "${SAMPLES[@]}"
  do
    SAMPLE_ARGS="$SAMPLE_ARGS -s $SAMPLE"
  done
fi

if [[ ! -z ${FILTER} ]]; then
  FILTER_EXPR="-f $FILTER"
fi

if [[ -z ${VIDMAP_FILE} && -z ${LOADER_FILE} ]]; then
  ./genomicsdb_query -w $WORKSPACE $INTERVAL_ARGS $SAMPLE_ARGS $FILTER_EXPR -o $OUTPUT_FILE
elif  [[ -z ${VIDMAP_FILE} ]]; then
  ./genomicsdb_query -w $WORKSPACE $INTERVAL_ARGS $SAMPLE_ARGS -v $VIDMAP_FILE $FILTER_EXPR -o $OUTPUT_FILE
else
  ./genomicsdb_query -w $WORKSPACE $INTERVAL_ARGS $SAMPLE_ARGS-v $VIDMAP_FILE -l $LOADER_FILE $FILTER_EXPR -o $OUTPUT_FILE
fi

deactivate
