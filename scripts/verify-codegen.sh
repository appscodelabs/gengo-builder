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

# client/ doesn't exist for repos that only generate deepcopy/defaulter code
# and no typed client at all (see update-codegen.sh's GENERATORS env var).
gen_dirs=(apis)
if [[ -d "${SCRIPT_ROOT}/client" ]]; then
    gen_dirs+=(client)
fi

for d in "${gen_dirs[@]}"; do
    mkdir -p "${TMP_DIFFROOT}/${d}"
    cp -a "${SCRIPT_ROOT}/${d}/." "${TMP_DIFFROOT}/${d}"
done

update-codegen.sh

echo "diffing ${gen_dirs[*]/#/${SCRIPT_ROOT}/} against freshly generated codegen"
ret=0
for d in "${gen_dirs[@]}"; do
    diff -Naupr "${TMP_DIFFROOT}/${d}" "${SCRIPT_ROOT}/${d}" || ret=$?
done

# Put the tree back the way we found it, regardless of outcome, so this can
# be run against a working tree without leaving it dirty.
for d in "${gen_dirs[@]}"; do
    rm -rf "${SCRIPT_ROOT:?}/${d}"
    cp -a "${TMP_DIFFROOT}/${d}" "${SCRIPT_ROOT}/${d}"
done

if [[ $ret -eq 0 ]]; then
    echo "${gen_dirs[*]/#/${SCRIPT_ROOT}/} up to date."
else
    echo "${gen_dirs[*]/#/${SCRIPT_ROOT}/} out of date. Please run update-codegen.sh (or 'make update-codegen')."
fi
exit ${ret}
