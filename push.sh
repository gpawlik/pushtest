#!/usr/bin/env bash

set -e

eval $(cat .env | sed 's/^/export /')

pull () {
  echo "Checking if any changes"
  if [ -n "$(git status --porcelain)" ]; then
    echo "There are new changes coming from Smartling"
    gitpush
    gitpr | jq -r '.number'
    PR_NUMBER=2
    gitlabel PR_NUMBER
  else
    echo "There are no changes";
  fi
}

gitpush () {
  echo "Commit changes"
  git add -A
  git commit -m "$COMMIT_MESSAGE"
  git push origin $TRANSLATIONS_BRANCH
}

gitpr () {
  echo "Create a pull request"
  curl --header "Authorization: token $GITHUB_AUTH_TOKEN" \
      --header "Content-Type: application/json" \
      --data '{"title":"'"$PR_TITLE"'", "head": "'"$TRANSLATIONS_BRANCH"'", "base": "'"$BASE_BRANCH"'", "body": "'"$PR_BODY"'"}' \
      --request POST \
      https://api.github.com/repos/"$REPO_ORG"/"$REPO_SLUG"/pulls
}

gitlabel () {
  #PR_NUMBER="$(gitpr | jq -r '.number')"

  #echo "pr ${PR_NUMBER}"

  #if PR number
  echo "Update pull request label"
  curl --header "Authorization: token $GITHUB_AUTH_TOKEN" \
      --header "Content-Type: application/json" \
      --data '["translations"]' \
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
