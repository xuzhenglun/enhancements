#!/usr/bin/env bash

# Copyright 2019 The Kubernetes Authors.
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

set -o errexit
set -o nounset
set -o pipefail

# keep in sync with hack/verify-toc.sh
TOOL_VERSION=v1.1.0

# cd to the root path
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
cd "${ROOT}"

# create a temporary directory
TMP_DIR=$(mktemp -d)

# cleanup
exitHandler() (
  echo "Cleaning up..."
  rm -rf "${TMP_DIR}"
)
trap exitHandler EXIT

# Perform go install in a temp dir as we are not tracking this version in a go
# module.
# If we do the go install in the repo, it will create/update go.mod and go.sum.
cd "${TMP_DIR}"
GO111MODULE=on GOBIN="${TMP_DIR}" go install "sigs.k8s.io/mdtoc@${TOOL_VERSION}"
export PATH="${TMP_DIR}:${PATH}"
cd "${ROOT}"

# Update tables of contents if necessary.
find keps -name '*.md' \
    | grep -Fxvf hack/.notableofcontents \
    | xargs mdtoc --inplace --max-depth=5  || (
      echo "Failed generating TOC. If this failed silently and you are on mac, try 'brew install grep'"
      exit 1
    )
