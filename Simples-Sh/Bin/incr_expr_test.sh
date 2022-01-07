#!/bin/sh
# incr_expr_test.sh
# Copyright (c) 2008 J. Greg Davidson.  All rights reserved.
# Test of incr_expr shell package

. ${simples_sh:-$HOME/Lib/Sh}/simples.sh ||
  ( >&2 echo $0: "Can't source simples package!" ; exit 1 )

simple_require test_expect
simple_require incr_expr

var_expr x 1 + 1 && test_ok || test_failed var_expr x 1 + 1
test_var x 2 var_expr x 1 + 1

var_incr x
test_var x 3 var_incr x

test_output 3 post_incr x       # side-effect lost in subshell
post_incr x >/dev/null          # value sent to null, side-effect left
test_var x 4 post_incr x

test_output 5 pre_incr x        # side-effect lost in subshell
pre_incr x >/dev/null           # value sent to null, side-effect left
test_var x 5 pre_incr x

test_report
