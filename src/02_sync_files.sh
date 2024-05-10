#! /bin/bash

# Environment containing the utilities used
eval "$(micromamba shell hook --shell bash)"

# Check if an argument is provided
if [ $# -ne 3 ]; then
    echo "Usage: $0 <BASE_DIR> <FILE_LIST> <BACKUP_DIR>"
    exit 1
fi

base_dir=$1
source_file=$2
backup_dir=$3

sd_bin='/usr/bin/sd'
rsync_bin='/usr/bin/rsync'

printf -v date '%(%Y-%m-%d)T' -1

target_dir="$backup_dir/$date"
mkdir -p $target_dir

echo "[LOG] Backing up files based on file: \`${source_file}\`."
echo "[LOG] Truncating input list."
sd_flags='-F'
sd_find=$base_dir
truncated_file="${source_file}_truncated"
cp $source_file $truncated_file
$sd_bin $sd_flags $sd_find '' $truncated_file

rsync_log_file="$backup_dir/rsync_log"
rsync_flags="-u -q --delete --log-file=$rsync_log_file"
rsync_src=$truncated_file
rsync_dst=$target_dir
rsync_cmd="${rsync_bin} ${rsync_flags} --files-from=${rsync_src} ${base_dir} ${rsync_dst}"

echo "[LOG] Using the following command for \`rsync\` to backup files:"
echo "[LOG] $rsync_cmd"

$rsync_cmd

echo "[LOG] Creating archive from backup."
zip -r "${target_dir}.zip" $target_dir
rm -rf $target_dir

echo "[LOG] Done!"
