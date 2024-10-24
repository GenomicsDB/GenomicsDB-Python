## GenomicsDB simple query tool

Simple GenomicsDB query tool, given a workspace and genomic intervals of the form `<CONTIG>:<START>-<END>`.  The intervals at a minimum need to have the contig specified, start and end are optional. e.g chr1:100-1000, chr1:100 and chr1 are all valid. Start defaults to 1 if not specified and end defaults to the length of the contig if not specified.

Assumption : The workspace should have been created with the `vcf2genomicsdb` tool or with `gatk GenomicsDBImport` and should exist.

For ease of use, open run.sh and change the `WORKSPACE`, `INTERVALS` and optionally `FILTER` variables to what is desired before invoking it. Variables `VIDMAP_FILE` and `LOADER_FILE` need to be set only if they are not in the workspace. run.sh calls genomicsdb_query, the tool does the querying of the workspace for the intervals specified and outputs one csv file per input interval.

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
  -f FILTER, --filter FILTER
                        Optional - genomic filter expression for the query, e.g. 'ISHOMREF' or 'ISHET' or 'REF == "G" && resolve(GT, REF, ALT) &= "T/T" && ALT |= "T"'
  -L INTERVAL, --interval INTERVAL
                        One or more genomic intervals over which to operate. This argument may be specified 1 or more times e.g -L chr1:1-10000 -L 1:100001 -L chr2 -L chr3:1000
  -o OUTPUT, --output OUTPUT
                        a prefix filename to csv outputs from the tool. The filenames will be suffixed with the interval and .csv

```

```
~/GenomicsDB-Python/examples: ./genomicsdb_query -w my_workspace  -L 1:100-100000 -L 1:100001 -L 2 -L 3 -f ISHOMREF -o query_output
Starting genomicsdb_query for workspace(my_workspace) and intervals(['1:100-100000', '1:100001', '2', '3'])
Processing interval(1:100-100000)...
	Arrays:['1$1$249250621'] under consideration for interval(1:100-100000)
Processing interval(1:100001)...
	Arrays:['1$1$249250621'] under consideration for interval(1:100001)
Processing interval(2)...
    Arrays:['2$1$243199373'] under consideration for interval(2)
Processing interval(3)...
	Arrays:['3$1$198022430'] under consideration for interval(3)
	Array(3$1$198022430) not imported into workspace(my_workspace) for interval(3)
Starting genomicsdb_query for workspace(my_workspace) and intervals(['1:100-100000', '1:100001', '2', '3']) DONE
~/GenomicsDB-Python/examples: ls query_output*
query_output_1-100-100000.csv  query_output_1-100001.csv      query_output_2.csv

```
