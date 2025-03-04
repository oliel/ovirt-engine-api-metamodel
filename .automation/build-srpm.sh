#!/bin/bash -xe

# When building on GitHub we should use GITHUB_SHA environment variable, otherwise parse has from git
if [ "${GITHUB_SHA}" == "" ]; then
  GIT_HASH=$(git rev-list HEAD | wc -l)
else
  GIT_HASH=$(git rev-parse --short $GITHUB_SHA)
fi

# Directory, where build artifacts will be stored, should be passed as the 1st parameter
ARTIFACTS_DIR=${1:-exported-artifacts}

# Disabling tests can be passed as the 2nd parameter
SKIP_TESTS=${2:-0}

# Prepare the version string (with support for SNAPSHOT versioning)
VERSION=$(mvn help:evaluate  -q -DforceStdout -Dexpression=project.version)
VERSION=${VERSION/-SNAPSHOT/-0.${GIT_HASH}.$(date +%04Y%02m%02d%02H%02M)}
IFS='-' read -ra VERSION <<< "$VERSION"
RELEASE=${VERSION[1]-1}

# Prepare source archive
[[ -d rpmbuild/SOURCES ]] || mkdir -p rpmbuild/SOURCES
git archive --format=tar HEAD | gzip -9 > rpmbuild/SOURCES/ovirt-engine-api-metamodel-$VERSION.tar.gz


# Set version and release
sed \
    -e "s|@VERSION@|${VERSION}|g" \
    -e "s|@RELEASE@|${RELEASE}|g" \
    -e "s|@SKIP_TESTS@|${SKIP_TESTS}|g" \
    < ovirt-engine-api-metamodel.spec.in \
    > ovirt-engine-api-metamodel.spec

# Build source package
rpmbuild \
    -D "_topdir rpmbuild" \
    -bs ovirt-engine-api-metamodel.spec
