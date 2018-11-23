#!/usr/bin/env bash
# Provision a wordpress website

# Requirements:
# - a website file-backup: `/www/imports/${VVV_SITE_NAME}/`
# - a website db-backup: `/database/backups/${VVV_SITE_NAME}.sql`
#
# Process:
# 1. Import Website
#    - Copy the contents of www/imports/${VVV_SITE_NAME}/ to www/${VVV_SITE_NAME}/public_html/
#    - Backup and remove wp-config
#    - Backup and remove htaccess 
#    - Create new wp-config
# 2. Import Database + server stuff
#    - If database not exist, create one
#    - Import sql
#    - search-replace
# 3. NGINX

# Get the first host specified in vvv-custom.yml. Fallback: <site-name>.test
DOMAIN=`get_primary_host "${VVV_SITE_NAME}".test`

# Get the hosts specified in vvv-custom.yml. Fallback: DOMAIN value
DOMAINS=`get_hosts "${DOMAIN}"`

# Get the database name specified in vvv-custom.yml. Fallback: site-name
DB_NAME=`get_config_value 'db_name' "${VVV_SITE_NAME}"`
DB_NAME=${DB_NAME//[\\\/\.\<\>\:\"\'\|\?\!\*-]/}

# Get the source url (to search-and-replace)
SOURCE_URL=`get_config_value 'source_url' "false"`

# Get the table_prefix
DB_TABLE_PREFIX=`get_config_value 'db_table_prefix' "wp_"`

# Site import
SITE_IMPORT="/srv/www/imports/${VVV_SITE_NAME}"

# Get database backup file
DB_BACKUP="/srv/database/backups/${VVV_SITE_NAME}.sql"

#
# START
#
echo -e "\nStart importing website..."

#
# WEBSITE FILES
#

# Only import if there is no website
if [[ ! -f "${VVV_PATH_TO_SITE}/public_html/wp-config.php" ]]; then

    # Copy the files from 
    echo "Importing website from '${SITE_IMPORT}'"
    echo "Depending on the size of the website this could take a while..."
    cp -r "${SITE_IMPORT}" "${VVV_PATH_TO_SITE}/"

    # Rename directory to `public_html`
    mv "${VVV_PATH_TO_SITE}/${VVV_SITE_NAME}" "${VVV_PATH_TO_SITE}/public_html" 

    # Backup and remove wp-config
    if [[ ! -f "${VVV_PATH_TO_SITE}/public_html/wp-config.php" ]]; then        
        echo "Backing up wp-config.php"
        mv "${VVV_PATH_TO_SITE}/public_html/wp-config.php" "${VVV_PATH_TO_SITE}/public_html/wp-config-backup.php"
    fi
    
    # Backup and remove .htaccess
    if [[ ! -f "${VVV_PATH_TO_SITE}/public_html/.htaccess" ]]; then        
        echo "Backing up .htaccess"
        mv "${VVV_PATH_TO_SITE}/public_html/.htaccess" "${VVV_PATH_TO_SITE}/public_html/.htaccess-backup"
    fi

    echo "Configuring WordPress..."
    noroot wp config create --dbname="${DB_NAME}" --dbuser=wp --dbpass=wp --dbprefix="${DB_TABLE_PREFIX}" --quiet --extra-php <<PHP
/**
 * CUSTOM 
 */

/** Main debug setting */
define( 'WP_DEBUG', true );

if (WP_DEBUG) {
    define('SCRIPT_DEBUG', true);
    define('WP_DEBUG_LOG', true);
}

/** Only activate when researching (heavy on resources) */
define( 'SAVEQUERIES', false );

/** Limit post revisions to 5 at max */
define( 'WP_POST_REVISIONS', 5 );

/** Don't allow file editing from inside WordPress */
define( 'DISALLOW_FILE_EDIT', true );

/**
 * END CUSTOM
 */
PHP
else
    echo -e "\nSkip importing files..."
fi


#
# DATABASE
#

# Only import if there is not an installed website
if ( ! $(noroot wp core is-installed) ); then

    # Database setup and import

    # Make a database, if we don't already have one
    echo -e "\nCreating database '${DB_NAME}' (if it's not already there)"
    mysql -u root --password=root -e "CREATE DATABASE IF NOT EXISTS ${DB_NAME}"
    mysql -u root --password=root -e "GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO wp@localhost IDENTIFIED BY 'wp';"
    echo -e "\n DB operations done.\n\n"

    # Import database
    echo -e "\nImporting database '${DB_BACKUP}'"
    echo -e "\nwp db import '${DB_BACKUP}'"
    noroot wp db import "${DB_BACKUP}"

    # # If there is a source_url, match it with current domain. try search and replace database
    # if [ -z "${SOURCE_URL}" ]; then

        # echo -e "\nSearch-replace database '${DB_NAME}'"
        # echo -e "\nwp search-replace '${SOURCE_URL}' 'http://${DOMAIN}' --all-tables-with-prefix"
        # noroot wp search-replace "${SOURCE_URL}" "http://${DOMAIN}" --all-tables-with-prefix

    # fi

else
    echo -e "\nSkip importing database..."
fi

#
# NGINX Server
#

# Setup logs
if [[ ! -d "${VVV_PATH_TO_SITE}/provision/log" ]]; then
    # Nginx Logs
    echo "Setting up logs..."
    mkdir -p ${VVV_PATH_TO_SITE}/log
    touch ${VVV_PATH_TO_SITE}/log/error.log
    touch ${VVV_PATH_TO_SITE}/log/access.log
fi

# Setup configuration
if [[ ! -f "${VVV_PATH_TO_SITE}/provision/vvv-nginx.conf" ]]; then

    # Nginx Configuration
    echo "Setting up configuration..."
    cp -f "${VVV_PATH_TO_SITE}/provision/vvv-nginx.conf.tmpl" "${VVV_PATH_TO_SITE}/provision/vvv-nginx.conf"

    # SSL/TLS
    echo "Setting up ssl/tls..."
    if [ -n "$(type -t is_utility_installed)" ] && [ "$(type -t is_utility_installed)" = function ] && `is_utility_installed core tls-ca`; then
        sed -i "s#{{TLS_CERT}}#ssl_certificate /vagrant/certificates/${VVV_SITE_NAME}/dev.crt;#" "${VVV_PATH_TO_SITE}/provision/vvv-nginx.conf"
        sed -i "s#{{TLS_KEY}}#ssl_certificate_key /vagrant/certificates/${VVV_SITE_NAME}/dev.key;#" "${VVV_PATH_TO_SITE}/provision/vvv-nginx.conf"
    else
        sed -i "s#{{TLS_CERT}}##" "${VVV_PATH_TO_SITE}/provision/vvv-nginx.conf"
        sed -i "s#{{TLS_KEY}}##" "${VVV_PATH_TO_SITE}/provision/vvv-nginx.conf"
    fi

else
    echo -e "\nSkip setting up NGINX..."
fi

