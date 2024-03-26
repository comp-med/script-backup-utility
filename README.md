# Project Scripts Backup

## Introduction

This is a small collection of bash scripts that can be used to create a backup
of specific files in a common directory. It does so by doing the following:

1. Starting from a specific base directory, it traverses all subdirectories and
   identify directories that are named `script[s]` (case-insensitive)
2. Within these directories, search for files with specific extensions
3. Starting from the base directory, mirror the directories containing files
   with the specified extensions to a `backup/` directory within the base path,
   copying only these files

The scripts are currently still highly dependent on the directory structure
they were designed for and are not expected to work anywhere else than they
were initially intended to.

## Prerequisites

The scripts depend on several non-standard command-line tools. These can be
easily installed either as pre-compiled binary or using the `conda` package
manager.

* `micromamba` (to install necessary software)
* `fd` (to find directories and files)
* `sd` (to modify strings)
* `rsync` (to copy files to the target `backup/` directory)

## Usage

Currently, the scripts only create the copies of the target files and they are
not yet saved to a remote location.

```bash
# 
base_dir=</PATH/TO/DIRECTORY/ROOT>
./src/01_sc_hpc_file_search.sh $base_dir

file_list=output/script_file_list_size_inclusive
./src/02_sync_files.sh $base_dir $file_list
```

Several intermediate files are in the `output/` directory. In addition to the
base directory, for running the script `src/02_sync_files.sh`, either
`output/script_file_list_inclusive` or `output/script_file_list_exclusive`need
to be passed as the `$file_list` variable. This will determine whether only
files with certain matching file extensions (`exclusive`) or all files except
those matching (`inclusive`) will be saved. The difference will be that in the
`inclusive` list, additional files with uncommen file extensions will also be
backed-up.
