#!/usr/bin/env bash
# Provision a wordpress website to import

DEFAULT_DOMAIN="${VVV_SITE_NAME}.dev"
DOMAIN=`get_primary_host "${DEFAULT_DOMAIN}"`
DOMAINS=`get_hosts "${DOMAIN}"`

DB_NAME=`get_config_value 'db_name' "${VVV_SITE_NAME}"`
DB_NAME=${DB_NAME//[\\\/\.\<\>\:\"\'\|\?\!\*-]/}
DB_BACKUP="${VVV_SITE_NAME}.sql"

# Make a database, if we don't already have one
echo -e "\nCreating database '${DB_NAME}' (if it's not already there)"
mysql -u root --password=root -e "CREATE DATABASE IF NOT EXISTS ${DB_NAME}"
mysql -u root --password=root -e "GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO wp@localhost IDENTIFIED BY 'wp';"
echo -e "\n DB operations done.\n\n"

# Move into the newly mapped backups directory, where mysqldump(ed) SQL files are stored
printf "\nStart MySQL Database Import\n"
cd "/srv/database/backups/"

# Check if backup file exists
if [ -s "$DB_BACKUP" ]; then
	mysql_cmd='SHOW TABLES FROM `'$DB_NAME'`' # Required to support hypens in database names
	db_exist=`mysql -u root -proot --skip-column-names -e "$mysql_cmd"`
	# db_exist=`mysql -u root -proot --skip-column-names -e "SHOW TABLES FROM '$DB_NAME'"`

	if [ "$?" != "0" ] # $? is a variable holding the return value of the last command you ran.
	then
		# Database exists and holds tables. Do nothing
		printf "  * Error - Database $DB_NAME does not exist. That means no importing\n"
	else
		if [ "" == "$db_exist" ]; then
			# Database does exist but has no tables. Import sql-backup
			printf "mysql -u root -proot $DB_NAME < $DB_BACKUP\n"
			mysql -u root -proot $DB_NAME < $DB_BACKUP
			printf "  * Import of $DB_NAME successful\n"
		else
			# Database exists and holds tables. Do nothing
			printf "  * Skipped import of $DB_NAME - tables exist\n"
		fi
	fi

fi

# Move back to project directory
cd ${VVV_PATH_TO_SITE}


# Nginx Logs
mkdir -p ${VVV_PATH_TO_SITE}/log
touch ${VVV_PATH_TO_SITE}/log/error.log
touch ${VVV_PATH_TO_SITE}/log/access.log

cp -f "${VVV_PATH_TO_SITE}/provision/vvv-nginx.conf.tmpl" "${VVV_PATH_TO_SITE}/provision/vvv-nginx.conf"
sed -i "s#{{DOMAINS_HERE}}#${DOMAINS}#" "${VVV_PATH_TO_SITE}/provision/vvv-nginx.conf"
