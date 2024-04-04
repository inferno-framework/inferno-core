#!/usr/bin/env bash
#
# Push a new Inferno version to inferno-template GitHub Repository via SSH.
#
# USAGE:
#   ./publish_template.sh
#       OR
#   ./publish_template.sh [your/github/fork/url]
#       OR
#   GITHUB_ACCESS_TOKEN="PUT_YOUR_TOKEN_HERE" ./publish_template.sh

set -e


REPO_URL=${1:-git@github.com:inferno-framework/inferno-template.git}
VERSION=$(bundle exec ./bin/inferno version)
TITLE="Update $VERSION"
BRANCH=$(echo $TITLE | tr ' [:upper:]' '-[:lower:]')


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

if [[ ! -z "${GITHUB_ACCESS_TOKEN}" ]]; then
  ENDPOINT=${REPO_URL%.git}
  ENDPOINT=${ENDPOINT#git@github.com:}

  curl \
    --request POST \
    --header "Content-type: application/json" \
    --header "Authorization: Bearer ${GITHUB_ACCESS_TOKEN}" \
    --header "X-GitHub-Api-Version: 2022-11-28" \
    --data "{ \"title\":\"$TITLE\", \"head\":\"${BRANCH}\", \"base\":\"main\"}" \
    "https://api.github.com/repos/$ENDPOINT/pulls"
  echo "Put up pull request: $TITLE. Please merge it to main."
else
  echo "No GITHUB_ACCESS_TOKEN found, skipping pull request"
  echo "Pushed to branch $BRANCH, please put up a pull request and merge to main."
fi
