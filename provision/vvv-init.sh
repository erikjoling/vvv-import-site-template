#!/usr/bin/env bash
# Provision a wordpress website to import

# Get the first host specified in vvv-custom.yml. Fallback: <site-name>.test
DOMAIN=`get_primary_host "${VVV_SITE_NAME}".test`

# Get the hosts specified in vvv-custom.yml. Fallback: DOMAIN value
DOMAINS=`get_hosts "${DOMAIN}"`

# Get the database name specified in vvv-custom.yml. Fallback: site-name
DB_NAME=`get_config_value 'db_name' "${VVV_SITE_NAME}"`
DB_NAME=${DB_NAME//[\\\/\.\<\>\:\"\'\|\?\!\*-]/}

# Get the source url (to search-and-replace)
SOURCE_URL=`get_config_value 'source_url' "http://www.${VVV_SITE_NAME}.nl"`

# Get the table_prefix
DB_TABLE_PREFIX=`get_config_value 'db_table_prefix' "wp_"`

# Site import
SITE_IMPORT="/srv/www/_import/${VVV_SITE_NAME}"

# Get database backup file
DB_BACKUP="/srv/database/backups/${VVV_SITE_NAME}.sql"

# Steps:
# 0. WordPress files need to live in `www/${VVV_SITE_NAME}/public_html/`
# 1. Change name of wp-config if it exists
# 2. Create new wp-config
# 3. Import database
#    a. If database not exist, create one
#    b. Import sql
#    c. search-replace

# Import the site if no wp-config exists
if [[ ! -f "${VVV_PATH_TO_SITE}/public_html/wp-config.php" ]]; then

    # Copy the files from 
    echo "Importing website from '${SITE_IMPORT}'"
    echo "Depending on the size of the website this could take a while..."
    cp -r "${SITE_IMPORT}" "${VVV_PATH_TO_SITE}/"

    # Rename directory to `public_html`
    mv "${VVV_PATH_TO_SITE}/${VVV_SITE_NAME}" "${VVV_PATH_TO_SITE}/public_html" 

    # Change name of current wp-config.php to wp-config-backup.php
    echo "Backing up wp-config.php"
    mv "${VVV_PATH_TO_SITE}/public_html/wp-config.php" "${VVV_PATH_TO_SITE}/public_html/wp-config-backup.php"
fi

# Create new wp-config if no wp-config exists
if [[ ! -f "${VVV_PATH_TO_SITE}/public_html/wp-config.php" ]]; then
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
fi

# Skip if website is already installed
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

    # Search and replace database
    echo -e "\nSearch-replace database '${DB_NAME}'"
    echo -e "\nwp search-replace '${SOURCE_URL}' 'http://${DOMAIN}' --all-tables-with-prefix"
    noroot wp search-replace "${SOURCE_URL}" "http://${DOMAIN}" --all-tables-with-prefix

    # -----------

    # Nginx Logs
    mkdir -p ${VVV_PATH_TO_SITE}/log
    touch ${VVV_PATH_TO_SITE}/log/error.log
    touch ${VVV_PATH_TO_SITE}/log/access.log

    cp -f "${VVV_PATH_TO_SITE}/provision/vvv-nginx.conf.tmpl" "${VVV_PATH_TO_SITE}/provision/vvv-nginx.conf"
    sed -i "s#{{DOMAINS_HERE}}#${DOMAINS}#" "${VVV_PATH_TO_SITE}/provision/vvv-nginx.conf"
else
    echo -e "\nWebsite '${VVV_SITE_NAME}' already installed according to wp-cli"
fi
