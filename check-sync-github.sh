#!/bin/bash

## filename     check-sync-github.sh
## description: check if the latest refs of github and packagist
##              are the same. otherwise trigger an update
## author:      jonas.hess@mailbox.org
## =============================================================

USER=$(jq -r '.username' config.json)
TOKEN=$(jq -r '.apitoken' config.json)

for row in $(jq -r '.packages[] | @base64' config.json ); do
    _jq() {
     echo "${row}" | base64 --decode | jq -r "${1}"
    }
  packagename=$(_jq '.name')
  echo
  echo '------------------------------'
  echo "Package: $packagename"
  echo '------------------------------'

  packagistrepourl="https://repo.packagist.org/p2/$packagename.json"
  # echo $packagistrepourl

  latestrefpackagist=$(curl -s "$packagistrepourl" | jq --arg name "$packagename" '.packages[][] | select(.name==$name) .source .reference')
  echo "-- Latest Ref on Packagist: $latestrefpackagist"

  latestgithubzip=$(curl -s "$packagistrepourl" | jq '.packages ."swag/paypal"[0] .dist .url' | tr -d '"')
  # echo "-- Githubzip:  $latestgithubzip"

  githubtagsurl=$(echo "$latestgithubzip" | sed -E 's/zipball\/.{40}/git\/refs\/tags/' | tr -d '"')
  # echo "-- GitHub-Tags: $githubtagsurl"

  latestrefgithub=$(curl -s "$githubtagsurl" |  jq '.[-1] .object .sha')
  echo "-- Latest Ref on GitHub:    $latestrefgithub"

  if [ "$latestrefgithub" = "$latestrefpackagist" ]; then
      echo "-- Strings are equal. Nothing todo"
  else
      echo "-- Strings are not equal. I will do a sync immediately."
      packagistupdateurl="https://packagist.org/api/update-package?username=$USER&apiToken=$TOKEN"
      apipostdata='{"repository":{"url":"'"https://packagist.org/packages/$packagename"'"}}'
      curl -XPOST -H 'content-type:application/json' "$packagistupdateurl" -d "$apipostdata"
  fi
  echo
done
