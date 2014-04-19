#!/bin/bash
# test_expect.bash
# A (very) simple testing framework.  Still in Bourne Shell form.

# Copyright (c) 2008 J. Greg Davidson. This work is licensed under a
# Creative Commons Attribution 4.0 International License
# http://creativecommons.org/licenses/by/4.0.

# This test framework is so crude!  Why don't we rewrite
# it using some of the simples packages?  Oh yes, it is
# used to test those packages!  OK, so maybe we rename this
# to crude_test_expect package and use it to bootstrap the
# packages which we use to create a better test frame.  OK,
# you go first....

test_msg() { >&2 echo "$*"; }

test_error() { test_msg "Error: $*"; return 1; }

test_exit() {                   # [ EXIT_CODE ] MESSAGE...
    code='1'
    case "$1" in
        [0-9]) code="$1"; shift ;;
        [0-9][0-9]) code="$1"; shift ;;
        [0-9][0-9][0-9]) code="$1"; shift ;;
    esac
    case "$code" in
        0) test_msg "${*:-${0}: Goodbye!}" ;;
        *) test_error "${*:-${0} error: Better luck next time!}" ;;
    esac
    exit "$code"
}

case "${test_expect_debug-}" in
    ('')	test_expect_debug=false ;;
    (true|false) : ;;
    (*)	test_msg "Soft error: test_expect_debug='${test_expect_debug}'"
	test_expect_debug=false
	test_msg "Corrected: test_expect_debug='${test_expect_debug}'" ;;
esac

num_tests_passed='0'
incr_tests_passed() {
    ((++num_tests_passed))
    return 0
}
num_tests_failed='0'
incr_tests_failed() {
    ((++num_tests_failed))
    return 1
}
num_tests_missing='0'
incr_tests_missing() {
    ((++num_tests_missing))
    return 1
}
test_missing() { test_msg "Missing test for $*"; incr_tests_missing ; }

test_status() {
    case "$num_tests_failed" in
        0) return 0;;
        *) return 1;;
    esac
}

test_report() {
    test_msg "tests_passed: $num_tests_passed"
    test_msg "tests_failed: $num_tests_failed"
    test_msg "tests_missing: $num_tests_missing"
    test_status
}

test_source() {                 # test_source PATH_TO_SCRIPT
    . "$1" || test_exit 3 "$0 error in test_source: can't source $1"
}

test_main() {                   # test_main script script_dir
    case $# in
        0) echo -n "Run $0 on: " ; read script_to_test junk ;;
        1) test_source "$1" ;;
        2) if [ -r "$1" ] && . "$1"; then :; else
            PATH="$2:$PATH" ; export PATH ; test_source "$1"
            fi ;;
        *) >&2 echo Usage: $0 script_to_test ; exit 2 ;;
    esac
}

test_note() { cmd="$1" ; shift; test_msg "$cmd: ${*}" ; }

test_ok() { [ -n "${*-}" ] && test_msg "$*" ; incr_tests_passed ; }

test_failed() {
    cmd="$1" ; shift ; test_error "$cmd failed ${*}" ; incr_tests_failed
}

test_get_var() { eval "echo -n \"\${${1}-}\"" ; } # same as simple_get

test_var() {                  # test_var VAR VALUE MESSAGE
  $test_expect_debug && set -xv
  test_var_="$1" ; test_var__=`test_get_var "$1"` ; shift
  test_var___="$1" ; shift
  if [ X"$test_var__" = X"$test_var___" ]; then
    incr_tests_passed
  else
    test_var_msg_="$test_var_ == '$test_var__', not '${test_var___}'"
    [ $# -gt 0 ] && test_var_msg_="$test_var_msg_: $*"
    test_error  $test_var_msg_
    incr_tests_failed
  fi
}

# test_output EXPECTED_OUTPUT COMMAND [ARGS..]
test_output() {
    $test_expect_debug && set -xv
    answer_="$1" ; shift
    output_="`\"$@\"`"
    test_cmd_status="$?"
    if [ X"$output_" = X"$answer_" ]; then
        incr_tests_passed
    else
        test_error "'$@' failed!"
        test_msg "	expected: '$answer_'"
        test_msg "	output: '$output_'"
        incr_tests_failed
    fi
}

# test_success COMMAND [ARGS..]
test_success() {
    $test_expect_debug && set -xv
    output_="`\"$@\"`"
    test_cmd_status=$?
    if [ "$test_cmd_status" -eq 0 ]; then
        incr_tests_passed
    else
        test_error "Failed: '$@'"
        test_msg "	exit code: $test_cmd_status"
        [ -n "$output_" ] &&  test_msg "	output: '$output_'"
        incr_tests_failed
        return "$test_cmd_status"   # extra feature
    fi
}

# test_failure COMMAND [ARGS..]
test_failure() {
    $test_expect_debug && set -xv
    output_="`\"$@\"`"
    test_cmd_status=$?
    if [ "$test_cmd_status" -ne 0 ]; then
        incr_tests_passed
    else
        test_error "'$@' succeeded!"
        [ -n "$output_" ] &&  test_msg "	output: '$output_'"
        incr_tests_failed
    fi
}
