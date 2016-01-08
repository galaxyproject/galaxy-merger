#!/bin/bash

#TODO: galaxyproject
UPSTREAM_GITHUB_ACCOUNT="${UPSTREAM_GITHUB_ACCOUNT:-jmchilton}"
#TODO: galaxybot
TARGET_GITHUB_ACCOUNT="${TARGET_GITHUB_ACCOUNT:-jmchilton}"

PROJECT_NAME="${PROJECT_NAME:-galaxy}"
HUB_EXEC=`which hub`
if [ -z "$HUB_EXEC" ];
then
    HUB_EXEC="./hub/hub"
fi

ORIGIN_GALAXY_REPO="${ORIGIN_GALAXY_REPO:-git@github.com:${UPSTREAM_GITHUB_ACCOUNT}/${PROJECT_NAME}.git}"
TARGET_GALAXY_REPO="${TARGET_GALAXY_REPO:-git@github.com:${TARGET_GITHUB_ACCOUNT}/${PROJECT_NAME}.git}"

VERSION="$2"
PREVIOUS_VERSION="$1"
MESSAGE="Automated merge of '$PREVIOUS_VERSION' into '$VERSION'."

TEMP_DIR=`mktemp -d`
RANDOM_STRING=`basename $TEMP_DIR`
MERGE_BRANCH="automated-merge-$RANDOM_STRING"
GALAXY_DIR="$TEMP_DIR/galaxy"
git clone "$GALAXY_REPO" "$GALAXY_DIR"
cd $GALAXY_DIR
git remote add target "$TARGET_GALAXY_REPO"
git checkout -b "$MERGE_BRANCH" "$MERGE_BRANCH"
git merge -m "$MESSAGE" "$PREVIOUS_VERSION"
merge_command_failed=$?
git status | grep -q ahead
nothing_merged=$?

if [ $merge_command_failed ];
then
    echo "Merge conflict found, creating issue."
    hub issue create -m "Failed to automatically merge '$PREVIOUS_VERSION' into '$VERSION'."
elif [ $nothing_merged ];
then
    echo "Nothing to merge, moving on."
else
    echo "Open a pull request with merge."
    git push target "$MERGE_BRANCH"
    hub pull-request -m "$MESSAGE" -b "origin/$VERSION" -h "target/$MERGE_BRANCH"
fi
