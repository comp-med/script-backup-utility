#! /bin/bash

# Environment containing the utilities used
eval "$(micromamba shell hook --shell bash)"
micromamba activate nvim

# Check if an argument is provided
if [ $# -ne 1 ]; then
    echo "Usage: $0 <FILE_LIST>"
    exit 1
fi

base_dir='/sc-projects/sc-proj-computational-medicine/people/'
backup_dir='/sc-projects/sc-proj-computational-medicine/people/00_BACKUP'
target_dir="$backup_dir/backup/"
mkdir -p $target_dir
source_file=$1

echo "[LOG] Backing up files based on file: \`${source_file}\`."
echo "[LOG] Truncating input list."
sd_flags='-F'
sd_find=$base_dir
sd_replace=" "
sd_bin=/home/cabe12/micromamba/envs/nvim/bin/sd
truncated_file="${source_file}_truncated"
cp $source_file $truncated_file
$sd_bin $sd_flags $sd_find '' $truncated_file

rsync_bin='/usr/bin/rsync'
rsync_log_file="$backup_dir/output/rsync_log"
rsync_flags="-u -v --log-file=$rsync_log_file"
rsync_src=$truncated_file
rsync_dst=$target_dir
rsync_cmd="${rsync_bin} ${rsync_flags} --files-from=${rsync_src} ${base_dir} ${rsync_dst}"
echo "[LOG] Using the following command for \`rsync\` to backup files:"
echo "[LOG] $rsync_cmd"
$rsync_cmd
