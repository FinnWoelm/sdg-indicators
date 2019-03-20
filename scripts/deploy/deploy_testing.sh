#!/bin/bash
set -e # Exit with nonzero exit code if anything fails

echo "TRAVIS_BRANCH = " $TRAVIS_BRANCH
echo "TRAVIS_PULL_REQUEST_BRANCH = " $TRAVIS_PULL_REQUEST_BRANCH
echo "TRAVIS_TAG = " $TRAVIS_TAG

if [ "$TRAVIS_PULL_REQUEST" != "false" -o "$TRAVIS_BRANCH" = "master" ]; then
    echo "Skipping deploy; just doing a build."
    exit 0
fi

# Slugify branch name to directory except for staging
if [ "$TRAVIS_BRANCH" = "develop" ]; then
  BASEURL="sdg-indicators"
else
  BASEURL=$TRAVIS_BRANCH
  BASEURL=$(echo "$BASEURL" | iconv -t ascii//TRANSLIT | sed -r s/[^a-zA-Z0-9]+/-/g | sed -r s/^-+\|-+$//g | tr A-Z a-z)
fi

# Keys
scripts/deploy/decrypt_keys.sh
eval `ssh-agent -s`
ssh-add scripts/deploy/deploy_key_test

# Push the files over, removing anything existing already.
ssh -oStrictHostKeyChecking=no travis@$TEST_SERVER "rm -rf ~/www/$BASEURL || true"
rsync -rvzh -e "ssh -i scripts/deploy/deploy_key_test -oStrictHostKeyChecking=no" --checksum --link-dest="../sdg-indicators" _site/ travis@$TEST_SERVER:~/www/$BASEURL
rm scripts/deploy/deploy_key*
