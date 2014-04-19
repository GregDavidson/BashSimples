#!/bin/bash
# hash_maps_test.bash
# Test of hash_maps shell package

# Copyright (c) 2007 J. Greg Davidson. This work is licensed under a
# Creative Commons Attribution 4.0 International License
# http://creativecommons.org/licenses/by/4.0.

. ${simples_bash:-$HOME/Lib/Bash/Simples}/simples.bash ||
  ( >&2 echo $0: "Can't source simples package!" ; exit 1 )

simple_require test_expect
simple_require pathvar

#set -xv

unset test_path

listset_add test_path red
test_var test_path red
test_success in_simple_delim_list test_path red

listset_add test_path 'pale yellow'
test_var test_path 'red:pale yellow'

test_success in_simple_delim_list test_path red
test_success in_simple_delim_list test_path 'pale yellow'

listset_add -a test_path 'royal blue'
test_var test_path 'royal blue:red:pale yellow'
