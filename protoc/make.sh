#!/bin/bash
set -xeuo pipefail

docker build --pull -t appscode/protoc:release-1.13 .
docker push appscode/protoc:release-1.13
