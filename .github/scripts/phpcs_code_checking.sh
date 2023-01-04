#!/bin/bash

GREEN='\033[0;32m'
NO_COLOR='\033[0m'

# Checking is PHPCS has something to check.
grep -e php -e module -e inc -e install -e test -e profile -e theme -e info -e yml /tmp/check > /tmp/grep_checking
[ -s /tmp/grep_checking ]
if [ `echo $?` != 0 ]; then
    rm /tmp/grep_checking
	printf "${GREEN} PHPCS has nothing to check. ${NO_COLOR}"
	exit 0
fi

# Running PHPCS code standards checking.
~/.composer/vendor/bin/phpcs \
--extensions=css,inc,install,module,php,profile,test,theme \
--report=checkstyle --standard=Drupal,DrupalPractice \
`cat /tmp/check` |\
reviewdog \
-f="checkstyle" -name="PHPCS" \
-reporter="github-pr-review" \
-fail-on-error \
-filter-mode=nofilter -tee 
