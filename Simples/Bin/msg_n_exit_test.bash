#!/bin/bash
# msg_n_exit_test.bash
# Test of msg_n_exit shell package

# Copyright (c) 2007 J. Greg Davidson. This work is licensed under a
# Creative Commons Attribution 4.0 International License
# http://creativecommons.org/licenses/by/4.0.

. ${simples_bash:-$HOME/Lib/Bash/Simples}/simples.bash ||
  ( >&2 echo $0: "Can't source simples package!" ; exit 1 )

simple_require test_expect
simple_require msg_n_exit

# declarative program exit codes and exit message formats

h='hey_howdy'
hf='Hey %s, how do you do?'
msg_format $h "$hf"
test_output "$hf" hash_get msg_format $h

test_output 'Hey Greg, how do you do?' msg_out $h Greg

g='goodbye'
gf='Goodbye %s, run me again sometime?'
gc=0
msg_exit_format $g $gc "$gf"
test_output "$gf" hash_get msg_format $g
test_output $gc hash_get exit_code $g

test_msg Just before the last test exits us with code 0:

test_report

die $g Greg
