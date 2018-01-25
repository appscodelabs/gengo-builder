#!/bin/bash
set -xeuo pipefail

docker build -t appscode/gengo:release-1.9 .
docker push appscode/gengo:release-1.9
