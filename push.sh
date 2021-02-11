#!/usr/bin/env bash

set -e

eval $(cat .env | sed 's/^/export /')

pull () {
  echo "Checking if there is any changes"
  if [ -n "$(git status --porcelain)" ]; then
    echo "There are new changes coming from Smartling"
    gitpush
    echo "Create a pull request"
    PR_NUMBER=$(gitpr)
    if [ "${PR_NUMBER}" != "null" ]; then
        echo "Label pull request"
        gitlabel $PR_NUMBER
    else
      echo "PR already existed";
    fi
  else
    echo "There are no changes";
  fi
}

gitpush () {
  echo "Commit changes and push to branch"
  git add -A
  git commit -m "$COMMIT_MESSAGE"
  git push origin $TRANSLATIONS_BRANCH
}

gitpr () {
  curl \
      --header "Authorization: token $GITHUB_AUTH_TOKEN" \
      --header "Content-Type: application/json" \
      --data '{"title":"'"$PR_TITLE"'", "head": "'"$TRANSLATIONS_BRANCH"'", "base": "'"$BASE_BRANCH"'", "body": "'"$PR_BODY"'"}' \
      --request POST \
      https://api.github.com/repos/"$REPO_ORG"/"$REPO_SLUG"/pulls | jq '.number'
}

gitlabel () {
  echo "Update pull request label $1"
  curl --header "Authorization: token $GITHUB_AUTH_TOKEN" \
      --header "Content-Type: application/json" \
      --data '["something else"]' \
      --request POST \
      https://api.github.com/repos/"$REPO_ORG"/"$REPO_SLUG"/issues/$1/labels
}

if [[ $# -ne 1 ]]; then
  # run start by default
  setup
else
  # based on the COMMAND if it exists as a function
  # run said function `COMMAND` defined above
  # otherwise run `npm run COMMAND`
  if [ -n "$(type -t $@)" ] && [ "$(type -t $@)" = function ]; then
    $@
  fi
fi
