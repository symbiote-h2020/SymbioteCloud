#!/bin/bash

dbs=(
    'symbiote-aam-database'
    'symbiote-registration-handler'
    'resources_db'
    'symbiote-cloud-monitoring-database'
    'symbiote-cloud-fm-database'
    'symbiote-cloud-pr-database'
    'symbiote-cloud-sm-database'
    'symbiote-cloud-tm-database'
    'symbiote-bt-database'
)
backup_dir="mongo_backups"

echo "Creating directory $backup_dir"
mkdir $backup_dir

for db in ${dbs[*]}; do
    echo "Dumping database $db";
    mongodump --db $db --out $backup_dir/$db
done
