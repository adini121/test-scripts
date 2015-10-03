#! /bin/bash

# Description
# Author: Adi
# ChangeLog: 
# Date: 29.08.15

repo=$1

git init
git add .
git commit -m 'First commit'
curl -u 'adini121' https://api.github.com/user/repos -d '{"name":"'$repo'"}'
git remote add origin git@github.com:adini121/'$repo'.git
git push origin master