## GenomicsDB simple query tool

Simple GenomicsDB query tool `genomicsdb_query`, given a workspace and genomic intervals of the form `<CONTIG>:<START>-<END>`.  The intervals at a minimum need to have the contig specified, start and end are optional. e.g chr1:100-1000, chr1:100 and chr1 are all valid. Start defaults to 1 if not specified and end defaults to the length of the contig if not specified.

Assumption : The workspace should have been created with the `vcf2genomicsdb` tool or with `gatk GenomicsDBImport` and should exist.
 
* [Caching for enhanced performance](#caching)
* [Filters and Attributes](#filters)

``` 
~/GenomicsDB-Python/examples: ./genomicsdb_query --help
usage: query [options]

GenomicsDB simple query with samples/intervals/attributes/filter as inputs

options:
  -h, --help            show this help message and exit
  --version             print GenomicsDB native library version and exit
  -w WORKSPACE, --workspace WORKSPACE
                        URL to GenomicsDB workspace 
                        e.g. -w my_workspace or -w az://my_container/my_workspace or -w s3://my_bucket/my_workspace or -w gs://my_bucket/my_workspace
  -v VIDMAP, --vidmap VIDMAP
                        Optional - URL to vid mapping file. Defaults to vidmap.json in workspace
  -c CALLSET, --callset CALLSET
                        Optional - URL to callset mapping file. Defaults to callset.json in workspace
  -l LOADER, --loader LOADER
                        Optional - URL to loader file. Defaults to loader.json in workspace
  --list-samples        List samples ingested into the workspace and exit
  --list-contigs        List contigs configured in vid mapping for the workspace and exit
  --list-fields         List genomic fields configured in vid mapping for the workspace and exit
  --list-partitions     List interval partitions(genomicsdb arrays in the workspace) for the given intervals(-i/--interval or -I/--interval-list) or all the intervals for the workspace and exit
  --no-cache            Do not use cached metadata and files with the genomicsdb query
  -i INTERVAL, --interval INTERVAL
                        genomic intervals over which to operate. The intervals should be specified in the <CONTIG>:<START>-<END> format with START and END optional.
                        This argument may be specified 0 or more times e.g -i chr1:1-10000 -i chr2 -i chr3:1000. 
                        Note: 
                        	1. -i/--interval and -I/--interval-list are mutually exclusive 
                        	2. either samples and/or intervals using -i/-I/-s/-S options has to be specified
  -I INTERVAL_LIST, --interval-list INTERVAL_LIST
                        genomic intervals listed in a file over which to operate.
                        The intervals should be specified in the <CONTIG>:<START>-<END> format, with START and END optional one interval per line. 
                        Note: 
                        	1. -i/--interval and -I/--interval-list are mutually exclusive 
                        	2. either samples and/or intervals using -i/-I/-s/-S options has to be specified
  -s SAMPLE, --sample SAMPLE
                        sample names over which to operate. This argument may be specified 0 or more times e.g -s HG00097 -s HG00090. 
                        Note: 
                        	1. -s/--sample and -S/--sample-list are mutually exclusive 
                        	2. either samples and/or intervals using -i/-I/-s/-S options has to be specified
  -S SAMPLE_LIST, --sample-list SAMPLE_LIST
                        sample file containing list of samples, one sample per line, to operate upon. 
                        Note: 
                        	1. -s/--sample and -S/--sample-list are mutually exclusive 
                        	2. either samples and/or intervals using -i/-I/-s/-S options has to be specified
  -a ATTRIBUTES, --attributes ATTRIBUTES
                        Optional - comma separated list of genomic attributes(REF, ALT) and fields described in the vid mapping for the query, eg. GT,AC,PL,DP... Defaults to REF,GT
  -f FILTER, --filter FILTER
                        Optional - genomic filter expression for the query, e.g. 'ISHOMREF' or 'ISHET' or 'REF == "G" && resolve(GT, REF, ALT) &= "T/T" && ALT |= "T"'
  -n NPROC, --nproc NPROC
                        Optional - number of processing units for multiprocessing(default: 8). Run nproc from command line to print the number of processing units available to a process for the user
  --chunk-size CHUNK_SIZE
                        Optional - hint to split number of samples for  multiprocessing used in conjunction with -n/--nproc and when -s/-S/--sample/--sample-list is not specified (default: 10240)
  -t {csv,json,arrow}, --output-type {csv,json,arrow}
                        Optional - specify type of output for the query (default: csv)
  -j {all,all-by-calls,samples-with-num-calls,samples,num-calls}, --json-output-type {all,all-by-calls,samples-with-num-calls,samples,num-calls}
                        Optional - used in conjunction with -t/--output-type json (default: samples-with-num-calls)
  -z MAX_ARROW_BYTE_SIZE, --max-arrow-byte-size MAX_ARROW_BYTE_SIZE
                        Optional - used in conjunction with -t/--output-type arrow as hint for buffering parquet files(default: 64MB)
  -o OUTPUT, --output OUTPUT
                        a prefix filename to outputs from the tool. The filenames will be suffixed with the interval and .csv/.json/... (default: query_output)
  -d, --dryrun          displays the query that  will be run without actually executing the query (default: False)
  -b, --bypass-intersecting-intervals-phase
                        iterate only once bypassing the intersecting intervals phase (default: False)
```

Run `genomicsdb_query` with the -w and --list-samples/--list-contigs to figure out legitimate samples and contigs over which the query can operate. These can be used with the --samples/--intervals options later to run the actual query.

```
~/GenomicsDB-Python/examples: ./genomicsdb_query --list-contigs -w my_workspace
1
2
...
MT
X
Y
~/GenomicsDB-Python/examples: ./genomicsdb_query --list-samples -w my_workspace
HG00096
HG00097
HG00099
```

Example actual query :

```
~/GenomicsDB-Python/examples: ./genomicsdb_query -w my_workspace -i 1:100-100000 -i 1:100001 -i 2 -i 3 -f ISHOMREF -o query_output
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

<a name="caching"></a>
### Caching for enhanced performance

Locally caching artifacts from cloud URLs is optional for GenomicsDB metadata and helps with performance for metadata/artifacts which can be accessed multiple times. There is a separate caching tool `genomicsdb_cache` which takes as inputs the workspace, optionally callset/vidmap/loader.json and also optionally the intervals or intervals with the -i/--interval/-I/--interval-list option. Note that the json files are downloaded to the current working directory whereas other metadata are persisted in `$TMPDIR` or in `/tmp`. This is envisioned to be done once before the first start of the queries for the interval. Set the env variable `TILEDB_CACHE` to `1` and explicitly use `-c callset.json -v vidmap.json -l loader.json` with the `genomicsdb_query` command to access locally cached GenomicsDB metadata and json artifacts.

```
~/GenomicsDB-Python/examples: ./genomicsdb_cache -h
usage: cache [options]

Cache GenomicsDB metadata and generated callset/vidmap/loader json artifacts for workspace cloud URLs

options:
  -h, --help            show this help message and exit
  --version             print GenomicsDB native library version and exit
  -w WORKSPACE, --workspace WORKSPACE
                        URL to GenomicsDB workspace 
                        e.g. -w my_workspace or -w az://my_container/my_workspace or -w s3://my_bucket/my_workspace or -w gs://my_bucket/my_workspace
  -v VIDMAP, --vidmap VIDMAP
                        Optional - URL to vid mapping file. Defaults to vidmap.json in workspace
  -c CALLSET, --callset CALLSET
                        Optional - URL to callset mapping file. Defaults to callset.json in workspace
  -l LOADER, --loader LOADER
                        Optional - URL to loader file. Defaults to loader.json in workspace
  -i INTERVAL, --interval INTERVAL
                        Optional - genomic intervals over which to operate. The intervals should be specified in the <CONTIG>:<START>-<END> format with START and END optional.
                        This argument may be specified 0 or more times e.g -i chr1:1-10000 -i chr2 -i chr3:1000. 
                        Note: 
                        	1. -i/--interval and -I/--interval-list are mutually exclusive 
                        	2. either samples and/or intervals using -i/-I/-s/-S options has to be specified
  -I INTERVAL_LIST, --interval-list INTERVAL_LIST
                        Optional - genomic intervals listed in a file over which to operate.
                        The intervals should be specified in the <CONTIG>:<START>-<END> format, with START and END optional one interval per line. 
                        Note: 
                        	1. -i/--interval and -I/--interval-list are mutually exclusive 
                        	2. either samples and/or intervals using -i/-I/-s/-S options has to be specified
```

<a name="filters"></a>
### Filters and Attributes

Filters can be specified via an optional argument(`-f/--filter`) to `genomicsdb_query`. They are genomic filter expressions for the query and are based on the genomic attributes specified for the query.  Genomic attributes are all the fields and `REF` and `ALT` specified during import of the variant files into GenomicsDB. Note that any attribute used in the filter expression should also be specified as an attribute to the query via `-a/--attribute` argument if they are not the defaults(`REF` and `GT`).

The expressions themselves are enhanced algebraic expressions using the attributes and the values for those attributes at the locus(contig+position) for the sample. The supported operators are all the binary, algebraic operators, e.g. `==, !=, >, <, >=, <=...` and custom operators `|=` to use with `ALT` for a match with any of the alternate alleles and `&=` to match a resolved `GT` field with respect to `REF` and `ALT`. The expressions can also contain [predefined aliases](#predefined_aliases)  for often used operations. Also see [supported operators](#supported_operators) and try listing the fields(`--list-fields`) to help build the filter expression. See [examples](#examples) for sample filter expressions.

```
~/GenomicsDB-Python/examples: genomicsdb_query -w my_workspace --list-fields
Field                Class      Type       Length     Description
-----                -----      ----       ------     -----------
PASS                 FILTER     Integer    1          "All filters passed"
q10                  FILTER     Integer    1          "Quality below 10"
s50                  FILTER     Integer    1          "Less than 50\% \of samples have data"
NS                   INFO       Integer    1          "Number of Samples With Data"
DP                   INFO       Integer    1          "Total Depth"
AF                   INFO       Float      A          "Allele Frequency"
AA                   INFO       String     var        "Ancestral Allele"
DB                   INFO       Flag       1          "dbSNP membership
H2                   INFO       Flag       1          "HapMap2 membership"
GT                   FORMAT     Integer    PP         "Genotype"
VAF                  FORMAT     Float      1          "Variant Allele Fraction"
VP                   FORMAT     Integer    1          "Variant Priority or clinical significance"
--
Abbreviations : 
  A: Number of alternate alleles
  R: Number of alleles (including reference allele)
  G: Number of possible genotypes
  PP or P: Ploidy
  VAR or var: variable length
```

<a name="predefined_aliases"></a>
#### Predefined aliases
1. ISCALL   : is a variant call, filters out `GT="./."` for example
2. ISHOMREF : homozygous with the reference allele(REF)
3. ISHOMALT : both the alleles are non-REF (ALT)
4. ISHET    : heterozygous when the alleles in GT are different
5. resolve  : resolves the GT field specified as `0/0` or `1|2` into alleles with respect to REF and ALT. Phase separator is also considered for the comparison.

<a name="supported_operators"></a>
#### Supported operators

* Standard operators: +, -, *, /, ^
* Assignment operators: =, +=, -=, *=, /=
* Logical operators: &&, ||, ==, !=, >, <, <=, >=
* Bit manipulation: &, |, <<, >>
* String concatenation: //
* if then else conditionals with lazy evaluation: ?:
* Type conversions: (float), (int)
* Array index operator(for use with arrays of Integer/Float): e.g. AF[0]
* Standard functions abs, sin, cos, tan, sinh, cosh, tanh, ln, log, log10, exp, sqrt
* Unlimited number of arguments: min, max, sum
* String functions: str2dbl, strlen, toupper
* Array functions: sizeof and by index e.g. AF[2]
* Custom operators: |= used with ALT, &= used with resolve(GT, REF, ALT) 

<a name="examples"></a>
#### Example filters:

* ISCALL && !ISHOMREF: Filter out no-calls and variant calls that are not homozygous reference.
* ISCALL && (REF == "G" && ALT |= "T" && resolve(GT, REF, ALT) &= "T/T"): Filter out no-calls and only keep variants where the REF is G, ALT contains T and the genotype is T/T.
* ISCALL && (DP>0 && resolve(GT, REF, ALT) &= "T/T"): Filter out no-calls and only keep variants where the genotype is T/T and DP is greater than 0
* ISCALL && AF[0] > 0.5
