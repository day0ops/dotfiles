#!/bin/bash -ex

# clone down all my public repos from github

cd ~/Projects/personal/opensource/github.com/day0ops
GH_USER=day0ops
PAGE=1
curl "https://api.github.com/users/$GH_USER/repos?page=$PAGE&per_page=100" | grep -e 'clone_url*' | cut -d \" -f 4 | xargs -L1 git clone --recursive
