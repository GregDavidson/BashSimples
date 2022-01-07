#!/bin/sh
program_test_header='$Header$'
# program_test.sh - testing the simples program package
# Copyright (c) 2007 J. Greg Davidson.  All rights reserved
# 

. "${simples_sh:-$HOME/Lib/Sh/simples.sh}" ||
  ( >&2 echo "$0: Can't source simples package!" ; exit 1 )

simple_require test_expect
simple_require program

##	external dependencies

test_var PATH '/bin:/usr/bin'

for v in pgm_helper_bin program_format_notes program_format_table; do
    test_success simple_var_exists $v
    test_success test -x "`simple_get $v`"
done

test_output 0 hash_get exit_code pgm_complete
test_output '' hash_get msg_format pgm_complete

##	declarative program self-description

program_name program_test
program_purpose test the simples package named program
program_version 1
program_author J. Greg Davidson
program_rights

program_note The program package provides for a declarative script-writing style.
program_note This test program is using my new testing framework.

num_lines() {
    simple_out_inline "$1" | wc -l
}

test_output 2 num_lines "$pgm_notes" program_notes

program_flag	n	nullity	true	false	establish nullity

test_success in_simple_list "$pgm_flags" n program_flag n
test_output flag program_flag_get n type
test_output nullity program_flag_get n name
test_output false program_flag_get n value
test_var nullity true
test_output 1 num_lines "$pgm_options" program_options after flag n
# simple_show pgm_flags

program_option	f	friendliness	low	set level of friendliness

test_success in_simple_list "$pgm_opt_str" 'f:' program_option f in pgm_opt_str
test_success in_simple_list "$pgm_opts" '[-f' program_option f flag in pgm_opts
test_success in_simple_list "$pgm_opts" 'friendliness]' program_option f name in pgm_opts
test_output option program_flag_get f type
test_output friendliness program_flag_get f name
test_failure hash_exists program_flag_get f value
test_var friendliness low
test_output 2 num_lines "$pgm_options" program_options after option f
# simple_show pgm_options

program_arg		target			the poor sucker
test_success in_simple_list "$pgm_args" target program_arg
test_output 3 num_lines "$pgm_options" program_options after target arg
# simple_show pgm_args

test_msg Status before we call program help:

test_report

program_help "$@"
test_var pgm_described yes

test_msg Status before we die pgm_complete
test_report

die pgm_complete
