#!/usr/bin/env bash
#
# Push a new branch to inferno-template GitHub Repository with Inferno updates
# USAGE:
#   run ./publish_template
#   submit and merge a pull request from the new branch on GitHub

set -e
set -v

REPO_URL=git@github.com:inferno-framework/inferno-template.git
TIMESTAMP=$(date -I)

mkdir -p tmp
cd tmp
rm -rf inferno-template
git clone $REPO_URL inferno-template
rm -f inferno-template/Gemfile.lock
git -C ./inferno-template checkout -b update-$TIMESTAMP
bundle exec ../bin/inferno new inferno-template --author 'Inferno Template' --force
git -C ./inferno-template add --all
git -C ./inferno-template commit -m "update inferno-template via inferno new on $TIMESTAMP"
git -C ./inferno-template push -u origin update-$TIMESTAMP --force
cd ..
