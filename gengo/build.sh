#!/bin/bash
set -x
set -euo pipefail

docker build -t appscode/gengo:release-1.8 .
docker push appscode/gengo:release-1.8
