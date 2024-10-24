## GenomicsDB simple query tool

Simple GenomicsDB query tool, given a workspace and genomic intervals of the form `<CONTIG>:<START>-<END>`.  The intervals at a minimum need to have the contig specified, start and end are optional. e.g chr1:100-1000, chr1:100 and chr1 are all valid. Start defaults to 1 if not specified and end defaults to the length of the contig if not specified.

Assumption : The workspace should have been created with the `vcf2genomicsdb` tool or with `gatk GenomicsDBImport` and should exist.

For ease of use, open run.sh and change the `WORKSPACE` and the `INTERVALS` variables to what is desired before invoking it. run.sh calls genomicsdb_query, the tool does the querying of the workspace for the intervals specified and outputs one csv file per input interval.

``` 
~/GenomicsDB-Python/examples: ./genomicsdb_query --help
usage: query [options]

GenomicsDB simple query

options:
  -h, --help            show this help message and exit
  --version             print GenomicsDB native library version and exit
  -w WORKSPACE, --workspace WORKSPACE
                        URL to GenomicsDB workspace, e.g. -w my_workspace or -w az://my_container/my_workspace or -w s3://my_bucket/my_workspace or -w
                        gs://my_bucket/my_workspace
  -v VIDMAP, --vidmap VIDMAP
                        Optional - URL to vid mapping file. Defaults to vidmap.json in workspace
  -l LOADER, --loader LOADER
                        Optional - URL to loader file. Defaults to loader.json in workspace
  -L INTERVAL, --interval INTERVAL
                        One or more genomic intervals over which to operate. This argument may be specified 1 or more times e.g -L chr1:1-10000 -L 1:100001 -L chr2 -L chr3:1000
  -o OUTPUT, --output OUTPUT
                        a prefix filename to csv outputs from the tool. The filenames will be suffixed with the interval and .csv

```

```
~/GenomicsDB-Python/examples: ./genomicsdb_query -w  /Users/nalini/GenomicsDB.develop.1/install/bin/ws  -L 1:100-100000 -L 1:100001 -L 2 -o query_output
~/GenomicsDB-Python/examples: ls query_output*
query_output_1-100-100000.csv  query_output_1-100001.csv      query_output_2.csv

```
