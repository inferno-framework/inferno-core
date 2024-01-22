#!/usr/bin/env bash
#
# Push a new Inferno version to inferno-template GitHub Repository via SSH.
#
# USAGE:
#   ./publish_template

set -e
set -x

if [ -d ./inferno-template ]; then
  echo "ERROR: detected inferno-template directory, please remove or rename it to run this script."
  exit 1;
fi;

REPO_URL=git@github.com:inferno-framework/inferno-template.git
VERSION="$(bundle exec ./bin/inferno version)"

git clone $REPO_URL ./inferno-template
rm -f ./inferno-template/Gemfile.lock

bundle exec ./bin/inferno new inferno-template --author 'Inferno Template' --force

git -C ./inferno-template add --all
git -C ./inferno-template commit --message "update inferno-template to v$VERSION"
git -C ./inferno-template push origin main

rm -rf ./inferno-template
