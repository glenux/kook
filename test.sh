#!/bin/sh

PATH=./bin:$PATH

set -e 

fail() {
	set +x
	echo "ERROR: $*"
	exit 1
}

set -x

kook project add kook1 . || fail "test1"
kook project add kook2 || fail "test2"
kook project list || fail "test3"

