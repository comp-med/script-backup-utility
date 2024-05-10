# Project Scripts Backup

## Introduction

This is a small collection of bash scripts that can be used to create a backup
of specific files in a common directory. It does so by doing the following:

1. Starting from a specific base directory, it traverses all subdirectories and
   identify directories that are named `script[s]` (case-insensitive)
2. Within these directories, search for files with specific extensions
3. Starting from the base directory, mirror the directories containing files
   with the specified extensions to a specified directory within the base path,
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

To backup all scripts in the `people` directory, 

```bash
# Takes a long time, looks for all script files
base_dir=</PATH/TO/DIRECTORY/ROOT>
./src/01_sc_hpc_file_search.sh $base_dir

# This creates a copy of all script files
file_list=output/script_file_list_inclusive
source_dir='</PATH/TO/BACKUP/TO>'
./src/02_sync_files.sh $base_dir $file_list $source_dir
```

Several intermediate files are in the `output/` directory. In addition to the
base directory, for running the script `src/02_sync_files.sh`, either
`output/script_file_list_inclusive` or `output/script_file_list_exclusive`need
to be passed as the `$file_list` variable. This will determine whether only
files with certain matching file extensions (`exclusive`) or all files except
those matching (`inclusive`) will be saved. The difference will be that in the
`inclusive` list, additional files with uncommen file extensions will also be
backed-up.

the script `src/03_run_backup.sh` contains a call to the script
`src/02_sync_files.sh` with the input set up to backup all files to an external
hard drive that is used in a periodically executing `cronjob`.

## Setup

To run the backup on an encrypted hard drive, the device needs to be configured
first. To do this, connect the device and check the mountpoints and disk
properties.

```bash
lsblk -f
#> NAME  FSTYPE  FSVER  LABEL  UUID  FSAVAIL  FSUSE%  MOUNTPOINTS
#> sda                                                                                       
#> └─sda1  exfat  1.0  T7  0610-6E6F  931.4G  0%  /run/media/carl/T7
#> [...]

sudo fdisk -l /dev/sda
#> Disk /dev/sda: 931.51 GiB, 1000204886016 bytes, 1953525168 sectors
#> Disk model: PSSD T7         
#> Units: sectors of 1 * 512 = 512 bytes
#> Sector size (logical/physical): 512 bytes / 512 bytes
#> I/O size (minimum/optimal): 512 bytes / 33553920 bytes
#> Disklabel type: dos
#> Disk identifier: 0x9fe999a9
#> 
#> Device     Boot Start        End    Sectors   Size Id Type
#> /dev/sda1        2048 1953522112 1953520065 931.5G  7 HPFS/NTFS/exFAT
```

We will use the default `exFAT` filesystem on a single partition to save the
backups on.

```bash
sudo umount /run/media/carl/T7
sudo fdisk /dev/sda
```

We will use a `cronjob` to execute the backup periodically. For this, we need
the package `cronie`.

```bash
# Install the package using your systems package manager
sudo pacman -S cronie

# Check that the command is available
crond -V
#> cronie 1.7.2

# Enable and start the sytemd daemon
sudo systemctl enable cronie.service
sudo systemctl start cronie.service

# Check the status
systemctl status cronie.service
```

We can now setup a weekly cronjob to do the backup. This will set the backup to
every Thursday, 3 PM.

```bash
# Open the cron file
crontab -e

# Add the line
0 15 * * 4 </PATH/TO/>/03_run_backup.sh
```
