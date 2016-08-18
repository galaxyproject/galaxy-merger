#!/bin/bash

set -e


#TODO: galaxyproject
UPSTREAM_GITHUB_ACCOUNT="${UPSTREAM_GITHUB_ACCOUNT:-galaxybot}"
#TODO: galaxybot
TARGET_GITHUB_ACCOUNT="${TARGET_GITHUB_ACCOUNT:-galaxybot}"

PROJECT_NAME="${PROJECT_NAME:-galaxy}"

WORKING_DIR="${WORKING_DIR:-working}"
if [ ! -d "$WORKING_DIR" ];
then
    mkdir -p "$WORKING_DIR"
fi

DATABASE_DIR="${DATABASE_DIR:-${PROJECT_NAME}-processed}"
if [ ! -d "$DATABASE_DIR" ];
then
    mkdir -p "$DATABASE_DIR"
fi

HUB_EXEC=`which hub | echo ''`
if [ -z "$HUB_EXEC" ];
then
    HUB_EXEC="./hub/hub"
fi
echo "Using hub executable $HUB_EXEC"
ORIGIN_GALAXY_REPO="${ORIGIN_GALAXY_REPO:-git@github.com:${UPSTREAM_GITHUB_ACCOUNT}/${PROJECT_NAME}.git}"
TARGET_GALAXY_REPO="${TARGET_GALAXY_REPO:-git@github.com:${TARGET_GITHUB_ACCOUNT}/${PROJECCT_NAME}.git}"

VERSION="$2"
PREVIOUS_VERSION="$1"

ORIGIN_COMMIT=`git rev-parse HEAD`
ORIGIN_RECORD="$DATABASE_DIR"/"$ORIGIN_COMMIT"
echo $ORIGIN_RECORD
if [ -f "$ORIGIN_RECORD" ];
then
    echo "Skipping, previously processed $ORIGIN_COMMIT"
    exit 0
else
    touch "$ORIGIN_RECORD"
    ls "$ORIGIN_RECORD"
fi

MESSAGE="Automated merge of '$PREVIOUS_VERSION' into '$VERSION'."
TEMP_DIR=`mktemp -d`
RANDOM_STRING=`basename $TEMP_DIR`
MERGE_BRANCH="automated-merge-$RANDOM_STRING"
GALAXY_DIR="${TEMP_DIR}/galaxy"
ORIGIN_DIR="${WORKING_DIR}/origin-${PROJECT_NAME}"
ORIGIN_DIR=$(cd $ORIGIN_DIR; pwd)

export GIT_WORK_TREE="$ORIGIN_DIR"
export GIT_DIR="$ORIGIN_DIR/.git"

if [ ! -d "$ORIGIN_DIR" ];
then
    git clone "$ORIGIN_GALAXY_REPO" "$ORIGIN_DIR"
fi

for remote in `git branch -r | grep -v /HEAD`;
do
    git checkout --track "$remote" | true
done

git pull --all

echo "$GALAXY_DIR"
unset GIT_WORK_TREE
unset GIT_DIR
git clone "$ORIGIN_DIR" "$GALAXY_DIR"
export GIT_WORK_TREE="$GALAXY_DIR"
export GIT_DIR="$GALAXY_DIR/.git"

echo "Clone over.."
git remote add target "$TARGET_GALAXY_REPO"
git checkout "origin/$VERSION"
git checkout -b "$MERGE_BRANCH"

cd $GALAXY_DIR
git merge -m "$MESSAGE" "origin/$PREVIOUS_VERSION"
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
