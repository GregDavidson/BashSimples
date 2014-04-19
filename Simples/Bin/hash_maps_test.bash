#!/bin/bash
# hash_maps_test.bash
# Test of hash_maps shell package

# Copyright (c) 2007 J. Greg Davidson. This work is licensed under a
# Creative Commons Attribution 4.0 International License
# http://creativecommons.org/licenses/by/4.0.

. ${simples_bash:-$HOME/Lib/Bash/Simples}/simples.bash ||
  ( >&2 echo $0: "Can't source simples package!" ; exit 1 )

simple_require test_expect
simple_require hash_maps

test_failure hash_exists greg age

hash_set young greg age

test_success hash_exists greg age

test_output 'young' hash_get greg age

var_hash_get answer greg age

test_var answer 'young' var_hash_get

test_report
