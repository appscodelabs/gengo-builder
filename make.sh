#!/bin/bash
set -xeuo pipefail

REGISTRY=${REGISTRY:-appscode}

docker build --pull -t $REGISTRY/gengo:release-1.21 .
docker push $REGISTRY/gengo:release-1.21
