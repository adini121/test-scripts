#! /bin/bash

# Description: Selenium tests script for Moodle, takes as input : 
# Author: Aditya
# ChangeLog: 
# Date: 1.09.15



run tests
save results to a file with ./command.sh 2>&1 | tee command.log
if repository exists,
	git pull
	git add file to repository
	git commit
	git push
else create repository
	git init
	git add 
	git commit
	git push