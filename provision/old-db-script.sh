# # Move into the newly mapped backups directory, where mysqldump(ed) SQL files are stored
# printf "\nStart MySQL Database Import\n"
# cd "/srv/database/backups/"

# # Check if backup file exists
# if [ -s "$DB_BACKUP" ]; then
#   mysql_cmd='SHOW TABLES FROM `'$DB_NAME'`' # Required to support hypens in database names
#   db_exist=`mysql -u root -proot --skip-column-names -e "$mysql_cmd"`
#   # db_exist=`mysql -u root -proot --skip-column-names -e "SHOW TABLES FROM '$DB_NAME'"`

#   if [ "$?" != "0" ] # $? is a variable holding the return value of the last command you ran.
#   then
#       # Database exists and holds tables. Do nothing
#       printf "  * Error - Database $DB_NAME does not exist. That means no importing\n"
#   else
#       if [ "" == "$db_exist" ]; then
#           # Database does exist but has no tables. Import sql-backup
#           printf "mysql -u root -proot $DB_NAME < $DB_BACKUP\n"
#           mysql -u root -proot $DB_NAME < $DB_BACKUP
#           printf "  * Import of $DB_NAME successful\n"
#       else
#           # Database exists and holds tables. Do nothing
#           printf "  * Skipped import of $DB_NAME - tables exist\n"
#       fi
#   fi

# fi

# # Move back to project directory
# cd ${VVV_PATH_TO_SITE}