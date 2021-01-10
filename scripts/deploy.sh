#!/bin/bash

set -e

./scripts/build.sh
aws s3 sync ./_site/ s3://dalton-blog --delete
