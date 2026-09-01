#!/usr/bin/env bash

# Copyright AppsCode Inc. and Contributors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Verifies that a *.dev/apimachinery-style repo's ./apis and ./client are up
# to date with update-codegen.sh. Run it the same way, with the same env
# vars (see update-codegen.sh for the full list): working directory set to
# the repo root and `docker run ... $(CODE_GENERATOR_IMAGE) verify-codegen.sh`.

set -o errexit
set -o nounset
set -o pipefail

SCRIPT_ROOT="$(pwd)"
TMP_DIFFROOT="$(mktemp -d -t "$(basename "$0").XXXXXX")"

cleanup() {
    rm -rf "${TMP_DIFFROOT}"
}
trap "cleanup" EXIT SIGINT

mkdir -p "${TMP_DIFFROOT}/apis" "${TMP_DIFFROOT}/client"
cp -a "${SCRIPT_ROOT}/apis/." "${TMP_DIFFROOT}/apis"
cp -a "${SCRIPT_ROOT}/client/." "${TMP_DIFFROOT}/client"

update-codegen.sh

echo "diffing ${SCRIPT_ROOT}/apis and ${SCRIPT_ROOT}/client against freshly generated codegen"
ret=0
diff -Naupr "${TMP_DIFFROOT}/apis" "${SCRIPT_ROOT}/apis" || ret=$?
diff -Naupr "${TMP_DIFFROOT}/client" "${SCRIPT_ROOT}/client" || ret=$?

# Put the tree back the way we found it, regardless of outcome, so this can
# be run against a working tree without leaving it dirty.
rm -rf "${SCRIPT_ROOT}/apis" "${SCRIPT_ROOT}/client"
cp -a "${TMP_DIFFROOT}/apis" "${SCRIPT_ROOT}/apis"
cp -a "${TMP_DIFFROOT}/client" "${SCRIPT_ROOT}/client"

if [[ $ret -eq 0 ]]; then
    echo "${SCRIPT_ROOT}/apis and ${SCRIPT_ROOT}/client up to date."
else
    echo "${SCRIPT_ROOT}/apis or ${SCRIPT_ROOT}/client is out of date. Please run update-codegen.sh (or 'make update-codegen')."
fi
exit ${ret}
