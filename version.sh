#!/bin/bash -e

# Prints a version string of the form:
#
#     VERSION-devel-HASH[-dirty]
#
# or just
#
#     VERSION
#
# if '--release' is specified.
#
# This is used to generate "verstr.h".

VERSION=$(cat VERSION)

if [[ "$1" != "--release" ]]; then
    VERSION=${VERSION}-devel-$(git rev-parse --short HEAD)

    # Check if there are uncommitted changes
    if [[ -n "$(git status --porcelain -uno)" ]]; then
        VERSION=${VERSION}-dirty
    fi
fi

echo -n ${VERSION}
