#!/bin/bash
# simples_test.bash
# Test of simple mechanisms which make shell scripting easier.

# Copyright (c) 2008 J. Greg Davidson. This work is licensed under a
# Creative Commons Attribution 4.0 International License
# http://creativecommons.org/licenses/by/4.0.

loaded_test_expect=false
for d in ${simples_bash_path:-$HOME/Lib/Bash/Simples}; do
    . $d/test_expect.bash && loaded_test_expect=true && break
done
$loaded_test_expect || (
  >&2 echo $0: "Can't source test_expect package!"
  exit 1
)

case $# in
    0) script_to_test="simples.bash" ;;
    1) script_to_test="$1"; shift ;;
esac

test_main "$script_to_test" "${simples_bash:-$HOME/Lib/Bash/Simples}" "${@}"

##	join, pad, trim, preargs

test_output 'a beta *' simple_join ' ' a beta '*'
test_output 'a:beta:*' simple_join ':' a beta '*'
test_output 'abeta*' simple_join '' a beta '*'
test_output 'this and that' simple_join ' and ' this that
test_output 'hello' simple_join 'xxx' hello
test_output '' simple_join 'xxx'

test_output 'Dear John, ' simple_pad 'Dear ' 'John' ', '
test_output '' simple_pad 'Dear ' '' ', '
test_output 'Function foo error: ' simple_pad 'Function ' 'foo' ' error' ': '

test_missing simple_trim

test_failure simple_preargs --
test_failure simple_preargs -- hello
test_failure simple_preargs -- hello world

if simple_preargs hello --; then
    test_ok
    test_var simple_preargs_cnt 1 'hello'
    test_var simple_preargs_args 'hello'
else
    test_failed simple_preargs hello --
fi

if simple_preargs hello world --; then
    test_ok
    test_var simple_preargs_cnt 2 'hello world'
    test_var simple_preargs_args 'hello world'
else
    test_failed simple_preargs hello world --
fi

##	error reporting and exiting

test_output 'foo bar' simple_out_inline foo bar
[ `simple_out foo bar | wc -c` -eq 8 ] && test_ok ||
	test_failed simple_out
[ -n `'simple_msg' foo bar 2>/dev/null` ] && test_ok ||
	test_failed simple_msg
[ -n `'simple_msg_inline' foo bar 2>/dev/null` ] && test_ok ||
	test_failed simple_msg
[ `'simple_msg' foo bar 2>&1 | wc -c` -eq 8 ] && test_ok ||
	test_failed simple_msg
[ `'simple_msg_inline' foo bar 2>&1 | wc -c` -eq 7 ] && test_ok ||
	test_failed simple_msg_inline

# test_expect_debug=true
test_output "$0 error" simple_error_msg
test_output "$0 error: foo" simple_error_msg foo
test_output "$0 error in foo" simple_error_msg foo --
test_output "$0 error in foo bar" simple_error_msg foo bar --
test_output "$0 error in foo bar: baz" simple_error_msg foo bar -- baz
pgm_name=simples_test
test_output "$pgm_name error" simple_error_msg

test_missing simple_error
test_missing simple_exitor
# simple_exit tested at bottom of script!

##	regexp pattern matching

test_success match_simple_re "$simple_name_re" hello
test_failure match_simple_re "$simple_name_re" 123
test_success match_simple_re "$simple_part_re" 123
test_failure match_simple_re "$simple_part_re" '***'

test_missing no_match_simple_re
test_missing assert_simple_re
test_missing assert_simple_re_not

##	shell and environment variable management

foo1='bar'
if simple_var_exists non_existent_variable; then
    test_failed simple_var_exists with non_existent_variable
else
    test_ok
fi
simple_var_exists foo1 && test_ok || test_failed simple_var_exists with foo1

empty_variable=""
simple_var_exists empty_variable ||
  test_note simple_var_exists reports empty variables as not existing

foo2='bar'
test_output bar simple_get foo2

simple_set foo3 bar
test_var foo3 'bar' simple_set foo3 bar

simple_set foo4 foo bar
test_var foo4 'foo bar' simple_set multiple values

[ -n "`simple_set foo_bar foobar 2>&1`" ] && test_ok ||
  test_failed simple_var_trace to trace simple_set foo_bar

simple_cmd_setvar_args echo foo5 hello world
test_var foo5 'hello world' simple_cmd_setvar_args

foo6='bar'
simple_set_default foo6 fubar
test_var foo6 bar simple_set_default to let well enough alone
simple_set_default foo7 bar
test_var foo7 'bar' simple_set_default

foo8='bar' ; export foo8
simple_env_default foo8 fubar
env | grep '^foo8=bar$' >/dev/null && test_ok ||
  test_failed simple_env_default to let well enough alone
foo9='bar'
simple_env_default foo9 fubar
env | grep '^foo9=bar$' >/dev/null && test_ok ||
  test_failed simple_env_default to export its setting
simple_env_default foo10 bar
test_var foo10 'bar' simple_env_default

##	simple lists, sets and maps

# Simple lists and sets as strings with whitespace delimiters.

colors='red green blue'

for item in $colors; do
  test_success in_simple_delim_list ' ' "$colors" "$item"
done

test_failure in_simple_delim_list ' ' "$colors" 'reen'
test_success ni_simple_delim_list ' ' "$colors" 'reen'

test_output "purple $colors" simple_delim_list_prepend ' ' "$colors" purple
test_output "$colors teal" simple_delim_list_append ' ' "$colors" teal

##	managing global resource dependencies

test_var simples_provided simples

test_failure simple_provided non_existent_resource

simple_provide je_ne_sais_quoi

test_success simple_provided je_ne_sais_quoi

test_output 'Hello world!' simple_source hello_world

tmp_file="/tmp/hello_world.$$"

if simple_source hello_world > /tmp/simple_test.$$; then
    test_ok
    simple_provided hello_world && test_ok ||
    test_failed simple_source "to record the resource, simples_provided=($simples_provided)"
else
    test_failed simple_source hello_world
fi
rm /tmp/simple_test.$$  

test_output '' simple_require hello_world && test_ok ||
  test_failed simple_require hello_world

## and finally:

test_msg With one more test to go:

test_report

simple_exit 0 "That's all folks."

test_failed simple_exit
