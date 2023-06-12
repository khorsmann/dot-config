#!/bin/bash
HASH=$(git log --pretty=oneline | head -n1 | cut -c1-7)
TAG=$1
git tag -a $TAG $HASH -m "$TAG $HASH"
git push origin $TAG
