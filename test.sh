#!/bin/sh

PATH=./bin:$PATH

set -e 

KOOK_TEST_CONFIG="$(pwd)/test.config.yml"
KOOK_OPTS="--verbose --config $KOOK_TEST_CONFIG"
TEST_TITLE=""

fail() {
	echo "ERROR: $TEST_TITLE"
	exit 1
}

test_cleanup() {
	rm -f $KOOK_TEST_CONFIG
	rm -f Kookfile
}

test_start() {
	test_cleanup
	TEST_TITLE="$*"
	echo ""
	echo ""
	echo "## TEST : $TEST_TITLE"
	echo ""
}

test_start "Simple project listing"
kook project list $KOOK_OPTS || fail

test_start "Add project (explicit pah)"
kook project add kook-project $KOOK_OPTS --path . || fail
kook project list $KOOK_OPTS || fail

test_start "Add project (auto path)"
kook project add kook-project $KOOK_OPTS || fail
kook project list $KOOK_OPTS || fail

test_start "Add and remove project"
kook project add kook-project $KOOK_OPTS || fail
kook project list $KOOK_OPTS || fail
kook project rm kook-project $KOOK_OPTS || fail 
kook project list $KOOK_OPTS || fail 

test_start "Detect current project"
kook project add kook-project $KOOK_OPTS || fail
kook project list $KOOK_OPTS || fail 
kook project detect $KOOK_OPTS || fail 

test_start "Simple view listing (explicit project)"
kook project add kook-project $KOOK_OPTS || fail 
kook view list $KOOK_OPTS --project kook-project || fail 

#test_start "Simple view listing (implicit project)"
#kook project add kook-project $KOOK_OPTS || fail 
#kook view list $KOOK_OPTS || fail 

test_start "Fire a project with no view"
kook project add kook-project $KOOK_OPTS || fail 
kook view list $KOOK_OPTS || fail 
kook fire kook-project $KOOK_OPTS || fail 

test_start "Add a project with a view (explicit project)"
kook project add kook-project $KOOK_OPTS || fail 
kook view add root $KOOK_OPTS --project kook-project || fail
kook view list $KOOK_OPTS --project kook-project || fail

#test_cleanup
