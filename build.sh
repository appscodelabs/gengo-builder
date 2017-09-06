#!/bin/sh
set -x

docker build -t appscode/gengo:canary .
docker push appscode/gengo:canary
