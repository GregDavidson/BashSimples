# hash_maps_test.sh
# Copyright (c) 2007 J. Greg Davidson.  All rights reserved
# Test of hash_maps shell package

. ${simples_sh:-$HOME/Lib/Sh}/simples.sh ||
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
