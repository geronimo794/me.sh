#!/bin/bash

# Load environment variables from export_db.env file
if [ -f export_db.env ]; then
    echo "Loading environment variables from export_db.env file..."
    export $(grep -v '^#' export_db.env | xargs)
else
    echo "❌ Error: export_db.env file not found!"
    echo "Please create a export_db.env file with the following variables:"
    echo "CONTAINER_NAME=your_container_name_or_id"
    echo "MYSQL_USER=your_mysql_username"
    echo "MYSQL_PASSWORD=your_mysql_password"
    exit 1
fi

# Validate required environment variables
if [ -z "$CONTAINER_NAME" ] || [ -z "$MYSQL_USER" ] || [ -z "$MYSQL_PASSWORD" ]; then
    echo "❌ Error: Missing required environment variables!"
    echo "Please ensure your export_db.env file contains:"
    echo "CONTAINER_NAME=your_container_name_or_id"
    echo "MYSQL_USER=your_mysql_username" 
    echo "MYSQL_PASSWORD=your_mysql_password"
    exit 1
fi

# Configuration
BACKUP_DIR="./backups"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

# Function to perform complete database backup
backup_database() {
    local db_name=$1
    local output_file="$BACKUP_DIR/${db_name}_complete_backup_${TIMESTAMP}.sql"
    
    echo "Starting backup of database: $db_name"
    echo "Output file: $output_file"
    
    # Complete backup with all database objects
    echo "root_password" | sudo docker exec -i $CONTAINER_NAME mysqldump \
        -u $MYSQL_USER -p$MYSQL_PASSWORD \
        --single-transaction \
        --routines \
        --triggers \
        --events \
        --add-drop-database \
        --create-options \
        --disable-keys \
        --extended-insert \
        --quick \
        --lock-tables=false \
        --complete-insert \
        --hex-blob \
        --default-character-set=utf8mb4 \
        $db_name > "$output_file"
    
    if [ $? -eq 0 ]; then
        echo "✅ Backup completed successfully: $output_file"
        echo "File size: $(du -h "$output_file" | cut -f1)"
    else
        echo "❌ Backup failed for database: $db_name"
        return 1
    fi
}

# Function to backup all databases at once (alternative approach)
backup_all_databases() {
    local output_file="$BACKUP_DIR/all_databases_complete_backup_${TIMESTAMP}.sql"
    
    echo "Starting backup of ALL databases..."
    echo "Output file: $output_file"
    
    echo "$MYSQL_PASSWORD" | sudo docker exec -i $CONTAINER_NAME mysqldump \
        -u $MYSQL_USER -p$MYSQL_PASSWORD \
        --all-databases \
        --single-transaction \
        --routines \
        --triggers \
        --events \
        --add-drop-database \
        --create-options \
        --disable-keys \
        --extended-insert \
        --quick \
        --lock-tables=false \
        --complete-insert \
        --hex-blob \
        --default-character-set=utf8mb4 > "$output_file"
    
    if [ $? -eq 0 ]; then
        echo "✅ Complete backup finished: $output_file"
        echo "File size: $(du -h "$output_file" | cut -f1)"
    else
        echo "❌ Complete backup failed"
        return 1
    fi
}

# Main execution
echo "=== MySQL Complete Database Backup Tool ==="
echo "Container: $CONTAINER_NAME"
echo "MySQL User: $MYSQL_USER"
echo "Backup Directory: $BACKUP_DIR"
echo "Timestamp: $TIMESTAMP"
echo

# Backup individual databases
backup_database "sarana_lms_internal_db"
backup_database "admin_mejakerja"

# Uncomment the line below if you want to backup ALL databases in one file
# backup_all_databases

echo
echo "=== Backup process completed ==="
echo "Backup files are located in: $BACKUP_DIR"
