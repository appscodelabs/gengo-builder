#!/bin/bash
set -xeuo pipefail

docker build --pull -t appscode/gengo:release-1.16 .
docker push appscode/gengo:release-1.16
