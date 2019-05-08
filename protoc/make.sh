#!/bin/bash
set -xeuo pipefail

docker build --pull -t appscode/protoc:release-1.14 .
docker push appscode/protoc:release-1.14
