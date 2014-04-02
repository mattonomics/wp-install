#! /bin/bash

# Since the wp command will simply work in the present directory, there is no need for a path
# So, let's start with the critical parts, then allow you to change all the options

# database name (required)
DBNAME=""

# database username (required)
DBUSER=""

# database password (required for this script)
DBPASS=""

# site url. (required)
URL=""

# site title. escape spaces with "\" (ex: Testing\ My\ Script!) (required)
TITLE=""

# admin username (required)
ADMINUSER=""

# admin password (required)
ADMINPASSWORD=""

# admin email (required)
ADMINEMAIL=""

# for a multisite install, set this to 1
MULTISITE=0

# if you want to use subdomains, set this to 1 (don't change this unless you KNOW it will work)
SUBDOMAINS=0

# install theme unit test content. (recommended)
THEMEUNIT=1

#---- Optional Options ----#

##-- Database --##
# database host (default: localhost)
DBHOST=""

# database table prefix (default: wp_)
DBPREFIX=""

# database charset (default: utf8)
DBCHARSET=""

# database collation (default: '')
DBCOLLATE=""

# language constant
LOCALE=""

######------ No need to change anything down here! ------######

# did we get the database things we NEED?
if [ -z "$DBNAME" ] || [ -z "$DBUSER" ] || [ -z "$DBPASS" ]; then
	echo 'You did not properly set the required database variables.'
	exit;
fi

# set up the config command
CONFIG="--dbname=${DBNAME} --dbuser=${DBUSER} --dbpass=${DBPASS}"

# start testing to see which options were passed
if [[ "$DBHOST" ]]; then
	CONFIG+=" --dbhost=${DBHOST}";
fi
if [[ "$DBPREFIX" ]]; then
	CONFIG+=" --dbprefix=${DBPREFIX}";
fi
if [[ "$DBCHARSET" ]]; then
	CONFIG+=" --dbcharset=${DBCHARSET}";
fi
if [[ "$DBCOLLATE" ]]; then
	CONFIG+=" --dbcollate=${DBCOLLATE}";
fi
if [[ "$LOCALE" ]]; then
	CONFIG+=" --locale=${LOCALE}";
fi

# now let's see if we got the install stuff we needed

if [ -z "$URL" ] || [ -z "$TITLE" ] || [ -z "$ADMINUSER" ] || [ -z "$ADMINPASSWORD" ] || [ -z "$ADMINEMAIL" ]; then
	echo 'Please check that you properly set URL, TITLE, ADMINUSER, ADMINPASSWORD and ADMINEMAIL'
	exit;
fi

INSTALL="--url=${URL} --title=${TITLE} --admin_user=${ADMINUSER} --admin_password=${ADMINPASSWORD} --admin_email=${ADMINEMAIL}"

if which wp>/dev/null; then
	# do the download
	wp core download;

	# set up the config file
	eval "wp core config ${CONFIG}";

	# see if multisite is requested
	if [[ MULTISITE -ge 1 ]];
	then
		if [[ SUBDOMAINS -ge 1 ]]; then
			INSTALL+=" --subdomains"
		fi
		eval "wp core multisite-install ${INSTALL}";
	else
		eval "wp core install ${INSTALL}";
	fi
	
	# now that core is installed, check to see if we should install the theme unit test data
	if [[ THEMEUNIT -ge 1 ]]; then
		#install the importer
		wp plugin install wordpress-importer
		
		# activate the importer
		wp plugin activate wordpress-importer
		
		# path to this script 
		WPINSTALLPATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
		
		# replace the username in the csv template and create a new file
		sed "s/@@user@@/${ADMINUSER}/g" "${WPINSTALLPATH}/assets/user-map-template.csv" > "${WPINSTALLPATH}/assets/user-map.csv"
		
		# import the content and map over the users
		eval "wp import ${WPINSTALLPATH}/assets/theme-unit-test-data.xml --authors=${WPINSTALLPATH}/assets/user-map.csv"
	fi	
	
else
	echo 'wp-cli is not installed.'
fi

