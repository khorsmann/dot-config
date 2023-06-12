#!/bin/bash
TAG=$1
if [ -z $TAG ]; then
    echo "use $(basename) tag"
    git tag
    exit
fi
git tag --delete $TAG
git push --delete origin $TAG
