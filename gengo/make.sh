#!/bin/bash
set -xeuo pipefail

docker build --pull -t appscode/gengo:release-1.12 .
docker push appscode/gengo:release-1.12
