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

# Regenerates a *.dev/apimachinery-style repo's deepcopy/defaulter/conversion
# helpers under ./apis and clientset/listers/informers under ./client, using
# the generator binaries from k8s.io/code-generator's kube_codegen.sh
# toolchain (https://github.com/kubernetes/code-generator/blob/master/kube_codegen.sh).
#
# Bundled into this image so downstream repos don't each need their own copy
# -- run it via `docker run ... $(CODE_GENERATOR_IMAGE) update-codegen.sh`
# with the working directory set to the repo root (`-w $(DOCKER_REPO_ROOT)`)
# and generation scope configured through env vars:
#
#   API_GROUPS (required)
#       "group:v1,v2 group2:v3 ..." -- the same format generate-groups.sh
#       took. Every listed group/version gets whichever of deepcopy, a typed
#       client, a lister and an informer are enabled via $GENERATORS.
#
#   GENERATORS (optional)
#       Comma-separated subset of "deepcopy,defaulter,client,lister,informer"
#       -- which generators to run against $API_GROUPS. Defaults to
#       "deepcopy,client,lister,informer" (i.e. no defaulter-gen), matching
#       what every repo migrated onto this script before GENERATORS existed
#       already generated.
#
#   DEFAULTER_GROUPS (optional)
#       Same format as API_GROUPS, scoped to just the group/versions that
#       need defaulter-gen run against them. Only takes effect if
#       "defaulter" is in $GENERATORS. Left unset/empty, no defaulter code
#       is generated even if GENERATORS includes "defaulter".
#
#   CONVERSION_GROUPS (optional)
#       Same format as API_GROUPS, scoped to just the group/versions that
#       need conversion-gen run against them. Each one's peer/hub package is
#       auto-discovered from its own +k8s:conversion-gen doc.go marker, so
#       only the source side needs listing here. Left unset/empty, no
#       conversion code is generated.
#
#   CONVERSION_EXTRA_PEER_DIRS (optional)
#       Comma-separated extra --extra-peer-dirs for conversion-gen, e.g. for
#       types referenced from another module that conversion-gen wouldn't
#       otherwise scan. Applied to every entry in CONVERSION_GROUPS.
#
#   EXTRA_DEEPCOPY_PKGS (optional)
#       Space-separated list of additional full package import paths (not
#       expressed via API_GROUPS, e.g. a shared/common apis package with no
#       client of its own) to also run deepcopy-gen against. Only takes
#       effect if "deepcopy" is in $GENERATORS.
#
#   GO_HEADER_FILE (optional)
#       Defaults to ./hack/license/go.txt (relative to the repo root).
#
# This deliberately does NOT call kube_codegen.sh's gen_helpers/gen_client
# wrapper functions: those auto-discover their scope by grepping the whole
# apis/ tree for +k8s:deepcopy-gen / +k8s:defaulter-gen / +k8s:conversion-gen
# / +genclient markers. In practice that over-matches what these repos
# actually generate -- e.g. some carry +k8s:conversion-gen or
# +k8s:defaulter-gen markers on packages that were never wired up to real
# generated code. So scope is explicit (API_GROUPS/DEFAULTER_GROUPS/
# CONVERSION_GROUPS/EXTRA_DEEPCOPY_PKGS) rather than auto-discovered,
# matching what each repo's Makefile passes through.

set -o errexit
set -o nounset
set -o pipefail

SCRIPT_ROOT="$(pwd)"
CODEGEN_PKG="${CODEGEN_PKG:-/go/src/k8s.io/code-generator}"
BOILERPLATE="${GO_HEADER_FILE:-${SCRIPT_ROOT}/hack/license/go.txt}"

# The calling repo's own module path, e.g. kubedb.dev/apimachinery -- read
# from its go.mod rather than passed in, since it's always derivable and
# never varies within a repo.
THIS_PKG="$(go list -m)"

API_GROUPS="${API_GROUPS:?API_GROUPS must be set, e.g. from the Makefile \$(API_GROUPS) variable}"
GENERATORS="${GENERATORS:-deepcopy,client,lister,informer}"
DEFAULTER_GROUPS="${DEFAULTER_GROUPS:-}"
CONVERSION_GROUPS="${CONVERSION_GROUPS:-}"
CONVERSION_EXTRA_PEER_DIRS="${CONVERSION_EXTRA_PEER_DIRS:-}"
EXTRA_DEEPCOPY_PKGS="${EXTRA_DEEPCOPY_PKGS:-}"

has_generator() {
    [[ ",${GENERATORS}," == *",${1},"* ]]
}

# Expand "group:v1,v2 group2:v3 ..." into a "group/version" array, e.g.
# "kubedb:v1alpha1,v1alpha2" -> kubedb/v1alpha1 kubedb/v1alpha2.
expand_group_versions() {
    local groups="$1"
    local group_and_versions group version
    for group_and_versions in ${groups}; do
        group="${group_and_versions%%:*}"
        IFS=',' read -r -a versions <<<"${group_and_versions#*:}"
        for version in "${versions[@]}"; do
            echo "${group}/${version}"
        done
    done
}

group_versions=()
while IFS= read -r gv; do
    group_versions+=("${gv}")
done < <(expand_group_versions "${API_GROUPS}")

input_pkgs=()
for gv in "${group_versions[@]}"; do
    input_pkgs+=("${THIS_PKG}/apis/${gv}")
done

# Install the generator binaries into a scratch dir rather than the
# default $GOBIN/$GOPATH/bin: this runs as an arbitrary non-root uid (via
# `docker run -u $(id -u):$(id -g)`), and unlike the binaries this image
# pre-installs at build time (as root), these are (re-)installed fresh at
# generation time, which needs a directory that uid can actually write into
# -- not guaranteed for $GOPATH/bin depending on how the image was built.
GOBIN="${GOBIN:-$(mktemp -d)}"
export GOBIN

# cd into the code-generator module and `go install` fully-qualified package
# names, the same way kube_codegen.sh does, so they resolve against the
# module already on disk instead of as an out-of-module dependency.
(
    cd "${CODEGEN_PKG}"
    GO111MODULE=on go install \
        k8s.io/code-generator/cmd/deepcopy-gen \
        k8s.io/code-generator/cmd/defaulter-gen \
        k8s.io/code-generator/cmd/conversion-gen \
        k8s.io/code-generator/cmd/client-gen \
        k8s.io/code-generator/cmd/lister-gen \
        k8s.io/code-generator/cmd/informer-gen
)

# Deepcopy helpers for every group/version in $API_GROUPS, plus any
# additional packages listed in $EXTRA_DEEPCOPY_PKGS.
if has_generator deepcopy; then
    deepcopy_pkgs=("${input_pkgs[@]}")
    if [[ -n "${EXTRA_DEEPCOPY_PKGS}" ]]; then
        # shellcheck disable=SC2206 # word-splitting is the point here
        deepcopy_pkgs+=(${EXTRA_DEEPCOPY_PKGS})
    fi
    echo "Generating deepcopy code for ${#deepcopy_pkgs[@]} targets"
    find "${SCRIPT_ROOT}/apis" -name zz_generated.deepcopy.go -delete
    "${GOBIN}/deepcopy-gen" \
        --output-file zz_generated.deepcopy.go \
        --go-header-file "${BOILERPLATE}" \
        "${deepcopy_pkgs[@]}"
fi

# Defaulter helpers, scoped to $DEFAULTER_GROUPS only (empty by default).
if has_generator defaulter && [[ -n "${DEFAULTER_GROUPS}" ]]; then
    defaulter_pkgs=()
    while IFS= read -r gv; do
        defaulter_pkgs+=("${THIS_PKG}/apis/${gv}")
    done < <(expand_group_versions "${DEFAULTER_GROUPS}")

    echo "Generating defaulter code for ${#defaulter_pkgs[@]} targets"
    find "${SCRIPT_ROOT}/apis" -name zz_generated.defaults.go -delete
    "${GOBIN}/defaulter-gen" \
        --output-file zz_generated.defaults.go \
        --go-header-file "${BOILERPLATE}" \
        "${defaulter_pkgs[@]}"
fi

# Conversion helpers, scoped to $CONVERSION_GROUPS only (empty by default).
if [[ -n "${CONVERSION_GROUPS}" ]]; then
    conversion_args=(--go-header-file "${BOILERPLATE}" --output-file zz_generated.conversion.go)
    if [[ -n "${CONVERSION_EXTRA_PEER_DIRS}" ]]; then
        conversion_args+=(--extra-peer-dirs "${CONVERSION_EXTRA_PEER_DIRS}")
    fi

    while IFS= read -r gv; do
        echo "Generating conversion code for apis/${gv}"
        "${GOBIN}/conversion-gen" "${conversion_args[@]}" "${THIS_PKG}/apis/${gv}"
    done < <(expand_group_versions "${CONVERSION_GROUPS}")
fi

# Typed clientset for every group/version in $API_GROUPS -- including any
# with no +genclient resource types of their own, which still get a
# (near-empty) typed client.
if has_generator client; then
    echo "Generating client code for ${#group_versions[@]} targets"
    inputs=()
    for gv in "${group_versions[@]}"; do
        inputs+=(--input "${gv}")
    done
    find "${SCRIPT_ROOT}/client/clientset" -name '*.go' -exec grep -l '^// Code generated by client-gen. DO NOT EDIT.$' {} + 2>/dev/null | xargs -r rm -f
    "${GOBIN}/client-gen" \
        --go-header-file "${BOILERPLATE}" \
        --output-dir "${SCRIPT_ROOT}/client/clientset" \
        --output-pkg "${THIS_PKG}/client/clientset" \
        --clientset-name versioned \
        --input-base "${SCRIPT_ROOT}/apis" \
        "${inputs[@]}"
fi

if has_generator lister; then
    echo "Generating lister code for ${#input_pkgs[@]} targets"
    find "${SCRIPT_ROOT}/client/listers" -name '*.go' -exec grep -l '^// Code generated by lister-gen. DO NOT EDIT.$' {} + 2>/dev/null | xargs -r rm -f
    "${GOBIN}/lister-gen" \
        --go-header-file "${BOILERPLATE}" \
        --output-dir "${SCRIPT_ROOT}/client/listers" \
        --output-pkg "${THIS_PKG}/client/listers" \
        "${input_pkgs[@]}"
fi

if has_generator informer; then
    echo "Generating informer code for ${#input_pkgs[@]} targets"
    find "${SCRIPT_ROOT}/client/informers" -name '*.go' -exec grep -l '^// Code generated by informer-gen. DO NOT EDIT.$' {} + 2>/dev/null | xargs -r rm -f
    "${GOBIN}/informer-gen" \
        --go-header-file "${BOILERPLATE}" \
        --output-dir "${SCRIPT_ROOT}/client/informers" \
        --output-pkg "${THIS_PKG}/client/informers" \
        --versioned-clientset-package "${THIS_PKG}/client/clientset/versioned" \
        --listers-package "${THIS_PKG}/client/listers" \
        "${input_pkgs[@]}"
fi

# apis/ always exists; client/ doesn't for repos that only generate
# deepcopy/defaulter code and no typed client at all (e.g. GENERATORS is
# just "deepcopy,defaulter").
gen_dirs=("${SCRIPT_ROOT}/apis")
if [[ -d "${SCRIPT_ROOT}/client" ]]; then
    gen_dirs+=("${SCRIPT_ROOT}/client")
fi

# The generator binaries above emit each file's imports as a single
# unsorted block. Downstream repos' own `make fmt` (reimport3.py) regroups
# a file's imports into stdlib / this-project / everything-else (in that
# order, blank-line separated) before goimports/gofmt sorts each group --
# reimport3.py isn't available in this (generator-only) image, so reproduce
# its grouping here. Without this, a freshly generated tree wouldn't match
# what's checked in, and verify-codegen.sh (which diffs raw generator
# output, not `make fmt`'s output) would flag the mismatch as codegen drift
# on every run.
while IFS= read -r -d '' f; do
    awk -v prj="${THIS_PKG}" '
        /^import \($/ { in_import=1; print; next }
        in_import && /^\)$/ {
            in_import=0
            for (i=0;i<nstd;i++) print std[i]
            if (nstd>0 && (nprj>0 || next_i>0)) print ""
            for (i=0;i<nprj;i++) print prj_l[i]
            if (nprj>0 && next_i>0) print ""
            for (i=0;i<next_i;i++) print ext[i]
            print
            next
        }
        in_import && /^$/ { next }
        in_import {
            if ($0 !~ /\./) { std[nstd++]=$0 }
            else if (index($0, prj) > 0) { prj_l[nprj++]=$0 }
            else { ext[next_i++]=$0 }
            next
        }
        { print }
    ' "${f}" >"${f}.tmp" && mv "${f}.tmp" "${f}"
done < <(grep -rlZ -e '^// Code generated by .*-gen\. DO NOT EDIT\.$' "${gen_dirs[@]}")
goimports -w "${gen_dirs[@]}"
