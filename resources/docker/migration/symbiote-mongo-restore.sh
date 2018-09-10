#!/bin/bash

backup_dir="/home/mongo_backups"
dbs=$(ls $backup_dir)

for db in $dbs; do
    mongorestore --db $db --drop $backup_dir/$db/$db
done
