#!/bin/bash
#
# Copyright © 2022 Thiago Moreira (tmoreira2020@gmail.com)
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
set -e

echo $(date "+%Y/%m/%d %H:%M:%S")" Job get started"

umask 0

set -e

: ${DATA_PATH:="/data"}
: ${BACKUP_GITLAB_API_ENDPOINT:?"BACKUP_GITLAB_API_ENDPOINT env variable is required"}
: ${BACKUP_GITLAB_ACCESS_TOKEN:?"BACKUP_GITLAB_ACCESS_TOKEN env variable is required"}

if [[ "$GENERATE_BACKUP_EMPTY_FILES" -eq "true" ]]; then
    echo $(date "+%Y/%m/%d %H:%M:%S")" Generating backup empty files."

    echo "SELECT 1;" > /tmp/lportal.sql | gzip > $DATA_PATH/dump.sql.gz
    tar -czvf $DATA_PATH/data.tgz --files-from=/dev/null
else 
    LATEST=${LATEST}

    if [[ -z "$LATEST" ]]; then
        echo $(date "+%Y/%m/%d %H:%M:%S")" Retrieving date of the latest backup."

        is_there_backup=$(curl -L --header "PRIVATE-TOKEN: $BACKUP_GITLAB_ACCESS_TOKEN" $BACKUP_GITLAB_API_ENDPOINT/liferay-backup/$ENVIRONMENT/LATEST -o /tmp/LATEST -w '%{http_code}\n' -s)

        if [[ $is_there_backup -eq 200 ]]; then
            latest=$(head -n 1 /tmp/LATEST)
        else
            echo $(date "+%Y/%m/%d %H:%M:%S")" [WARN] No backup was found"
        fi
    else
        latest=$LATEST
    fi

    echo $(date "+%Y/%m/%d %H:%M:%S")" Looking for backups at date: $latest"

    dump_file_path=$(head -n 2 /tmp/LATEST | tail -n 1)

    is_there_dump_file=$(curl -L --header "PRIVATE-TOKEN: $BACKUP_GITLAB_ACCESS_TOKEN" $dump_file_path -o /tmp/dump.sql.gz -w '%{http_code}\n' -s)

    if [[ $is_there_dump_file -eq 200 ]]; then
        cp /tmp/dump.sql.gz $DATA_PATH/dump.sql.gz
    else
        echo $(date "+%Y/%m/%d %H:%M:%S")" [WARN] No backup dump file at path $dump_file_path was found"
    fi

    data_file_path=$(head -n 3 /tmp/LATEST | tail -n 1)

    is_there_data_file=$(curl -L --header "PRIVATE-TOKEN: $BACKUP_GITLAB_ACCESS_TOKEN" $data_file_path -o /tmp/data.tgz -w '%{http_code}\n' -s)

    if [[ $is_there_data_file -eq 200 ]]; then
        cp /tmp/data.tgz $DATA_PATH/data.tgz
    else
        echo $(date "+%Y/%m/%d %H:%M:%S")" [WARN] No backup data file at path $data_file_path was found"
    fi
fi
echo $(date "+%Y/%m/%d %H:%M:%S")" Job get finished: $(date)"