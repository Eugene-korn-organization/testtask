#!/bin/bash

# Make variable for backup.
BACKUP_COMMIT=$(git rev-parse HEAD)

# Make functions to frequently using commands.
turn_off_mm () {				# Turn off maintenance mode.
	drush sset system.maintenance_mode FALSE
}
git_checkout_to_backup () {		# Undo to previous working checkout.
	git checkout $BACKUP_COMMIT
}
composer_install () {			# Installing composer.
	composer install -o -n
}

# Turn on Drupal maintenance mode.
drush sset system.maintenance_mode TRUE

# Make db backup.
drush sql-dump --structure-tables-list=cache,cache_* --gzip --result-file=/backup/automatic_cicd_$DUMP_NAME-$(date +"%Y-%m-%d").sql

# If the database dump commadnd outputs an error.
if [ `echo $?` != 0 ]; then
	turn_off_mm
	printf "${RED} [ERROR] Failed to make a database dump. ${NO_COLOR}"
	exit 1
fi
# Deleting more than 5 dump files.
rm `ls -1t /backup/automatic_cicd_$DUMP_NAME* | sed -e '1,5d' | tr "\n" " "` || printf "rm:${GREEN} There is no extra files to remove ${NO_COLOR}"

# Fetch and checkout on new commit hash.
git fetch $GITHUB_REPO_URL
git checkout $GITHUB_SHA

# If git pull made an error.
if [ `echo $?` != 0 ]; then
	git_checkout_to_backup
	turn_off_mm
	printf "\n\n\n\n ${RED} [ERROR] Git error ${NO_COLOR}\n\n\n\n\n"
	exit 1
fi

# Download all needed modules.
composer_install

# If composer install made an error.
if [ `echo $?` != 0 ]; then
	git_checkout_to_backup	
	composer_install
	turn_off_mm
	printf "\n\n\n\n ${RED} [ERROR] Composer install error ${NO_COLOR}\n\n\n\n\n"
	exit 1
fi

# Final stage of deployment.
drush deploy -v -y

# If drush deploy made an error.
if [ `echo $?` != 0 ]; then
	git_checkout_to_backup	
	composer_install
	# Restore deployment.
	drush deploy -v -y
	turn_off_mm
	printf "\n\n\n\n ${RED} [ERROR] Drush deploy error ${NO_COLOR}\n\n\n\n\n"
	exit 1
fi

# Turn off Drupal maintence mode.
turn_off_mm

printf "\n\n\n\n ${GREEN} [SUCCESS] DEPLOYMENT IS SUCCESSFULL ${NO_COLOR}\n\n\n\n\n"
