#! /bin/bash

# Check if an argument is provided
if [ $# -ne 1 ]; then
    echo "Usage: $0 <BASE_DIR>"
    exit 1
fi

# Environment containing the utilities used
eval "$(micromamba shell hook --shell bash)"

# This is specific to my account (obviously)
fd_bin='/usr/bin/fd'

# Variables and files
base_dir=$1
backup_dir="${base_dir}/00_BACKUP"
output_dir="${backup_dir}/output"
dir_list_file="${output_dir}/script_dir_list"
dir_list_file_sorted="${output_dir}/script_dir_list_sorted"
dir_list_file_size="${output_dir}/script_dir_list_size"
dir_list_file_size_filtered="${output_dir}/script_dir_list_size_filtered"

# Searching for all files except those in $exclude_extensions
file_list_inclusive="${output_dir}/script_file_list_inclusive"
file_list_size_inclusive="${output_dir}/script_file_list_size_inclusive"

# Searching for all files except those in $include_extensions
file_list_exclusive="${output_dir}/script_file_list_exclusive"
file_list_size_exclusive="${output_dir}/script_file_list_size_exclusive"


# Directory to look for that contains scripts
search_term='/script[s]?'

# Collect file extensions to in- and exclude
include_extensions=(R r sh smk py qmd ipynb)
exclude_extensions=(tsv csv txt xls xlsx png pdf feather parquet RData html log out)
exclude_files=(.RData)
exclude_dirs=(renv globus x86_64-pc-linux-gnu-library x86_64-conda-linux-gnu-library .ipynb_checkpoints)

# Set-up directories to exclude from the backup
unset exclude_dirs_flag
for dir in ${exclude_dirs[@]}; do
    fd_exclude_flag+="-E=$dir "
done

# Search for directories bsaed on the search term
fd_flags_dirs='-i -p -t d --prune'

echo "[LOG] Using \`$search_term\` as searcht term."
echo "[LOG] Running directory search."

# Search all `scripts` directories (NOTE: Takes a while)
$fd_bin $fd_flags_dirs $fd_exclude_flag $search_term $base_dir > $dir_list_file

echo "[LOG] Finished directory search."
log_number_of_dirs=$(cat $dir_list_file | wc -l)
echo "[LOG] Found ${log_number_of_dirs} directories based on search term."

# create an overview list 
sort $dir_list_file > $dir_list_file_sorted

# Create a list of the directories sorted by size
du_call='du -ch '
sort_call='sort -rh '
cat $dir_list_file_sorted | xargs $du_call | $sort_call > $dir_list_file_size

directory_size=$(head $dir_list_file_size -n 1 | awk '{print $1}')
echo "[LOG] Full size of found directories: $directory_size"

# Create the exclude flags for the directory size list
# For file extensions
unset fd_exclude_extensions_flag
unset du_exclude_extensions_flag
for ext in ${exclude_extensions[@]}; do
    du_exclude_extensions_flag+="--exclude=*.${ext} "
    fd_exclude_extensions_flag+="-E *.${ext} "
done

# For whole files
unset fd_exclude_files_flag
unset du_exclude_files_flag
for file in ${exclude_files[@]}; do
    du_exclude_files_flag+="--exclude=${file} "
    fd_exclude_files_flag+="-E ${file} "
done

cat $dir_list_file  | xargs $du_call \
    $du_exclude_files_flag \
    $du_exclude_extensions_flag | \
    $sort_call > $dir_list_file_size_filtered
directory_size_filtered=$(head $dir_list_file_size_filtered -n 1 | awk '{print $1}')

echo "[LOG] Size of found directories exluding large files: $directory_size_filtered"

# -----------------------------------------------------------------------------
# Based on the list of directories, create a list of all files to be backed up

echo "[LOG] Searching for specific file extensions used in scripts."
echo "[LOG] Excluding specific files based on file extension."

# For whole files
unset fd_include_extensions_flag
for ext in ${include_extensions[@]}; do
    fd_include_extensions_flag+="-e ${ext} "
done

unset fd_exclude_extensions_flag
for ext in ${exclude_extensions[@]}; do
    fd_exclude_extensions_flag+="-E *.${ext} "
done

fd_flags_files='-i -p -t f --prune'
$fd_bin $fd_flags_files $fd_exclude_flag $fd_exclude_extensions_flag ./ $(<$dir_list_file) > $file_list_inclusive
$fd_bin $fd_flags_files $fd_exclude_flag $fd_include_extensions_flag ./ $(<$dir_list_file) > $file_list_exclusive

log_file_number_inclusive=$(cat $file_list_inclusive | wc -l)
log_file_number_exclusive=$(cat $file_list_exclusive | wc -l)

echo "[LOG] Found $log_file_number_inclusive files based on an inclusive search (i.e. excluding certain file types)."
echo "[LOG] Found $log_file_number_exclusive directories based on an exclusive search (i.e. only including certain file types)."

# Enclose the files in quotation marks so `du` can handle them
file_list_inclusive_quoted="${file_list_inclusive}_quoted"
file_list_exclusive_quoted="${file_list_exclusive}_quoted"
rm -f $file_list_inclusive_quoted $file_list_exclusive_quoted
while IFS= read -r dir; do
    echo "\"$dir\"" >> "$file_list_inclusive_quoted"
done < "$file_list_inclusive"
while IFS= read -r dir; do
    echo "\"$dir\"" >> "$file_list_exclusive_quoted"
done < "$file_list_exclusive"

# Compare the size of the file lists
cat $file_list_inclusive_quoted | \
    xargs $du_call | \
    $sort_call > $file_list_size_inclusive
cat $file_list_exclusive_quoted | \
    xargs $du_call | \
    $sort_call > $file_list_size_exclusive
log_file_size_inclusive=$(head $file_list_size_inclusive -n 1 | awk '{print $1}')
log_file_size_exclusive=$(head $file_list_size_exclusive -n 1 | awk '{print $1}')

echo "[LOG] Size of all files: Inclusive: $log_file_size_inclusive, Exclusive: $log_file_size_exclusive"
echo "[LOG] Done!"
