#!/usr/bin/env bash
#
# Push a new Inferno version to inferno-template GitHub Repository via SSH.
#
# USAGE:
#   ./publish_template.sh

set -e
set -x


REPO_URL=${1:-git@github.com:inferno-framework/inferno-template.git}
VERSION=$(bundle exec ./bin/inferno version)
BRANCH=$(echo "Update $VERSION" | tr ' [:upper:]' '-[:lower:]')


cd ./tmp
git clone $REPO_URL ./inferno-template
git -C ./inferno-template branch $BRANCH
git -C ./inferno-template checkout $BRANCH

rm -f ./inferno-template/Gemfile.lock

bundle exec ../bin/inferno new inferno-template --author "Inferno Template" --force

git -C ./inferno-template add --all
git -C ./inferno-template commit --message "Update to $VERSION"
git -C ./inferno-template push --set-upstream origin $BRANCH
mv ./inferno-template "./inferno-template-$BRANCH"
cd ..

echo "Pushed to branch $BRANCH, please put up a pull request and merge to main."
