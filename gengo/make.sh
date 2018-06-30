#!/bin/bash
set -xeuo pipefail

docker build -t appscode/gengo:release-1.11 .
docker push appscode/gengo:release-1.11
