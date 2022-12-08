#!/bin/sh Bin/simples_test.sh
# * simples.sh - simple mechanisms for better Bourne-Shell scripts

# ** Header

simples_header='$Header: simples.sh,v 1.3 2008/03/08 03:44:33 greg Exp greg $'

# Copyright (c) 2008 J. Greg Davidson. This work is licensed under a
# Creative Commons Attribution 4.0 International License
# http://creativecommons.org/licenses/by/4.0.

# ** Introduction, Assumptions, Dependencies

# This version is for the Bourne Shell!

# Please consult:
#	simples-man.txt		- steps towards a man page
#	simples-impl-notes.txt	- implementation notes

# Dependencies:

# Assumptions about shell packages (change and uncomment if needed):
#	simples_sh_suffix='.sh'
#	simples_sh_path="$HOME/Lib/Bash-Sh/Simples-Sh"

# Requires the following shell builtins:
#	echo
#	echo -n
#	expr
#	[ ] aka test

# For anything else, test for it and prepare a fallback!

# Test if argument is a command
simple_is_cmd() { type "$1" > /dev/null; }

# ** Simple Output

simple_out() { echo "$@"; }
simple_out_inline() { echo -n "$@"; }
simple_msg() { echo "$@" >&2; }
simple_msg_inline() { echo -n "$@" >&2; }

# ** join, pad, preargs

# simple_join1 DELIMTER [WORD...]
# DELIMITER must be a single character or an empty string
simple_join1() {
    local IFS="$1" ; shift
    simple_out "$*"
}

# simple_join DELIMITER [WORD...]
simple_join() {
  case $# in
		0) return ;;
		1) return ;;
		2) echo -n "$2";;
		3) echo -n "$2$1$3";;
		4) echo -n "$2$1$3$1$4";;
		*) simple_delim_="$1" ; shift
			 simple_delim__="${1}" ; shift
			 for simple_delim___; do
				 simple_delim__="${simple_delim__}${simple_delim_}${simple_delim___}"
			 done
			 echo -n "$simple_delim__" ;;
	esac
}

# simple_pad left-padding value right-padding...
simple_pad() {
    case "$2" in
        ?*) simple_join '' "$@" ;;
    esac
}

# simple_preargs [ [ arg... ] -- ] arg... ---> BOOLEAN
# Tests for existence of any arguments before a '--' argument.
# When true, sets simple_preargs_cnt and simple_preargs_args.
simple_preargs() {
    case "$#" in
        0) return 1 ;;
    esac
    case "$1" in
        --) return 1 ;;
    esac
    simple_preargs_cnt_="$#"
    simple_preargs_args_="$1" ; shift
    while [ $# -gt 0 ]; do
        case "$1" in
            --) simple_preargs_cnt=`expr $simple_preargs_cnt_ - $#`
                simple_preargs_args="$simple_preargs_args_"
                return 0 ;;
        esac
        simple_preargs_args_="$simple_preargs_args_ $1" ; shift
    done
    return 1
}

# ** Error Reporting and Exiting

simple_error_msg() {
    echo -n "${pgm_name:-$0} error"
    if simple_preargs "$@"; then
        echo -n " in $simple_preargs_args"
        shift $simple_preargs_cnt
    fi
    case "$1" in
      --) shift ;;
    esac
    case "$#" in
      0) return ;;
    esac
    echo ": $*"
}

simple_error() { simple_error_msg "$@" >&2; }
simple_exit() { code=$1; shift; simple_msg "$*"; exit $code; }
simple_exitor() { code=$1; shift; simple_error "$@"; exit $code; }

simple_show() {                 # for debugging
    while [ $# -gt 0 ]; do
        match_simple_re "$simple_name_re" "$1" &&
        simple_var_exists "$1" &&
        simple_msg_inline "$1='`simple_get $1`' " ||
        simple_msg_inline "$1 "
        shift
    done
    simple_msg ''
}

# ** Regexp Matching and Cutting

simple_name_re='[A-Za-z_][A-Za-z0-9_]*'
simple_name_err='is not a simple name'

simple_part_re='[A-Za-z0-9_]*'
simple_part_err='cannot be part of a simple name'

# match_simple_re REGEXP-PATTERN STRING ---> BOOLEAN
# Note: REGEXP will be anchored
match_simple_re() { [ `expr "X$2" : "X$1\$"` -ne 0 ]; }
no_match_simple_re() { [ `expr "X$2" : "X$1\$"` -eq 0 ]; }

# assert_simple_re REGEXP-PATTERN STRING EXITOR_ARGS...
# asserts match_simple_re
assert_simple_re() {
 if [ `expr "X${2}" : "X$1"` -eq 0 ]; then shift 2; simple_exitor "$@"; fi
}
assert_simple_re_not() {
 if [ `expr "X${2}" : "X$1"` -ne 0 ]; then shift 2; simple_exitor "$@"; fi
}

# simple_re_cut REGULAR_EXPRESSION VALUE
# RE must one tagged subexpression, e.g. the \(.*\) in $simple_trim_re.
# The tagged part of the subexpression will be returned.
simple_re_cut() {	# regular expression extract
    expr "$2" : "${1}\$"
}

simple_trim_re='[[:space:]]*\(.*[^[:space:]]\)[[:space:]]*'
simple_trim() { simple_re_cut "$simple_trim_re" "$*"; }

# ** Shell and Environment Variable Management

# simple_var_exists VARIABLE_NAME -- returns true or false
simple_var_exists() {
#   assert_simple_re "$simple_name_re" "$1" 1 simple_var_exists -- "$@"
    eval [ -n \"\${${1}+yes}\" ]
}

# simple_get VARIABLE_NAME - prints the value of the named variable
simple_get() {
    eval "echo -n \"\${${1}-}\""
}

# simple_var_trace VARIABLE_NAME -- should this variable be traced
# Redefine this function as needed
simple_var_trace() {
    case $1 in
        foo_*) return 0;;
        *) return 1;;
    esac
}

# simple_set VARIABLE_NAME VALUE...
# sets the value of the named variable to the specified value/list
simple_set() {
#    assert_simple_re "$simple_name_re" "$1" 1 simple_set -- "$@"
    simple_set_name_="${1}" ; shift
    simple_var_trace "$simple_set_name_" &&
    simple_msg "${pgm_name:-$0} trace: ${simple_set_name_}='${*}'"
    eval "${simple_set_name_}='${*}'"
}

# deviations from simples.bash in next few functions!!!

# var_simple_cmd COMMAND VARIABLE_NAME ARGS...
# sets the value of the named variable to the
# result of evaluating the specified command
var_simple_cmd() {
  simple_cmd_="$1" ; simple_var_="$2" ; shift 2
  simple_set "$simple_var_" "`$simple_cmd_ \"$@\"`"
}

# var_simple_update COMMAND VARIABLE_NAME ARGS...
# Updates sets the value of the named variable
# setting it to result of evaluating the specified
# command on the variable's old value and other args.
var_simple_update() {
  simple_cmd_="$1"; simple_var_="$2"; simple_var__="`simple_get $2`"; shift 2
  simple_set "$simple_var_" "`$simple_cmd_ \"$simple_var__\" \"$@\"`"
}

# simple_set_default VARIABLE_NAME VALUE...
# sets the value of the named variable to the specified value/list
simple_set_default() {
    assert_simple_re "$simple_name_re" "$1" \
        1 simple_set_default -- "$1" "$simple_name_err"
    simple_var_exists "$1" || simple_set "$@"
}

# simple_env_default VARIABLE_NAME DEFAULT_VALUE...
simple_env_default() {
    assert_simple_re "$simple_name_re" "$1" \
        1 simple_env_default -- "$1" "$simple_name_err"
    simple_set_default "$@"
    export "${1}"
}

# ** Lists and Sets

# Simple lists and sets as strings for shells lacking
# arrays and/or hashes.  List items may not contain whitespace
# and maybe some other metacharacters should be forbidden???

# deviations from simples.bash in these functions!!!
# can we just use the simples.bash versions???

# Unless given explicitly, arguments are: LIST ITEM

# Warning: sensitive to metacharacters in LIST
in_simple_list() {
    for in_simple_list_ in $1; do
        [ X"$2" = X"$in_simple_list_" ] && return 0
    done
    return 1
}
ni_simple_list() { in_simple_list "$@" && return 1 || return 0; }

simple_list_prepend() {
    case "$1" in
      '') echo -n "$2" ;;
      *) echo -n "$2 $1" ;;
      esac
}
simple_list_append() {
    case "$1" in
      '') echo -n "$2" ;;
      *) echo -n "$1 $2" ;;
      esac
}

# Now a slightly more abstract list API which might conceal an array

simple_listvar_set() {	# LISTVAR [ ITEM... ]
  simple_list_="$1"; shift
  simple_set "$simple_list_" "$*"
}
simple_listvar_get() { simple_get "$1"; }

simple_listvar_prepend() { var_simple_update simple_list_prepend "$@"; }
simple_listvar_append() { var_simple_update simple_list_append "$@"; }

# ** Sourcing Scripts

# simple_src [--count-only] path-to-script
# Source a file if it exists and has not already been sourced.
# --count-only --- just list it, it was sourced another way
simple_src() {
    local count_only=''
    [ X--count-only == X"$1" ] && {
        count_only="$1"; shift
    }
    local f g
    for f; do
        if [ ! -f "$f" ]; then
            >&2 echo "simple_src warning: No file $f!"
        else
            g=$(realpath "$f") 
            ni_simple_list simple_src_list "$g" || {
                { [ -n "$count_only" ] || . "$g"; }
            } && simple_src_list="$g $simple_src_list"
        fi
    done
}

simple_src_dir() {
    for d; do
        [ -d "$d" ] && simple_src "$d"/*
    done
}

# ** Querying Simples

simples_provided='simples'

simples() {
    for s in $(the_simples_provided); do
        echo "$s"
    done
}

# simple_provide NAME
# - register the global availability of resource NAME
simple_provide() {
    in_simple_list "$simples_provided" "$1" ||
        simple_listvar_append simples_provided "$1"
}
simple_provided() { in_simple_list "$simples_provided" "$1"; }

# ** Sourcing Simples Scripts

simple_set_default simples_sh_suffix '.sh'
simple_set_default simples_sh_path "$HOME/Lib/Bash/Simples-Sh"

# simple_source SIMPLE_FILENAME...
# sources (i.e. includes, consults, performs the commands of)
# the script file with indicated simple name
# (the extension $simples_sh_suffix will be added)
# provided that it exists in one of the allowed directories
# listed in simples_sh_path.
simple_source() {
  simple_source_return_=0     # any error will change this!
  for simple_source_file_ in "$@"; do
    if no_match_simple_re "$simple_name_re" "$simple_source_file_"; then
      simple_error simple_source -- "$simple_source_file_" "$simple_name_err"
      simple_source_return_=1
    elif simple_load "$simple_source_file_"; then
      simple_provide "$simple_source_file_"
    else
      simple_error simple_source -- "loading $simple_source_file_ failed!"
      simple_source_return_=1
    fi
  done
  return $simple_source_return_
}

simple_load() {
    for simple_load_dir_ in $simples_sh_path; do
        if [ -r "$simple_load_dir_/$1$simples_sh_suffix" ]; then
            . "$simple_load_dir_/$1$simples_sh_suffix" && return 0
        fi
    done
    return 1
}

# simple_require SIMPLE_FILENAME..
# sources one or more files in the manner of simple_source above
# but only if they have not yet been sourced by this process.
simple_require() {
  for item; do
    in_simple_list "$simples_provided" "$item" ||
    simple_source "$item" || simple_exitor 1 "simple_require of $item not met"
  done
}

# ** WISHLIST

# Bring it back into compatibility with bash version
# Share some code with bash version??
# Move sh Simples into same git repository as bash Simples
