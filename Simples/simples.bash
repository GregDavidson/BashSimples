#!/bin/bash simples_test.bash
# simples.bash - simple mechanisms for better Bash scripts
simples_header='$Id: simples.bash,v 1.1 2008/03/18 20:42:55 greg Exp greg $'

# Copyright (c) 2008 J. Greg Davidson. This work is licensed under a
# Creative Commons Attribution 4.0 International License
# http://creativecommons.org/licenses/by/4.0.

# See WISHLIST at bottom

# Note these:
#    O=$IFS IFS=$'\n' arr=($(< myfile)) IFS=$O
# shopt -s nullglobshopt -s nullglob
# shopt -u nullglobshopt -u nullglob

##	Table of Contents

#	Table of Contents
#	Introduction
#	simple output
#	join, pad, preargs
#	error reporting and exiting
#	regexp matching and cutting
#	shell and environment variable management
#	lists and sets
#	managing global resource dependencies
#	safely sourcing scripts

##	Introduction

# This is a Bash port of the simples package developed for the Bourne Shell,
# Any places where code here will not run under (pd)ksh should be documented!

# The purpose of this port is to improve efficiency of this fundamental
# package while keeping its interface and behavior compatible.  Any
# changes should be internal, i.e. not affect client code following the
# documentation.

# Please consult:
#	simples-man.txt		- steps towards a man page
#	simples-impl-notes.txt	- implementation notes

# Dependencies:

# Assumptions about shell packages (change below, not here!):
#	simples_bash_suffixes: .bash .kbash .sh
#	simples_bash_path: $HOME/Lib/Bash/Simples $HOME/Lib/Sh/Simples

# Requires the following shell builtins and/or features:
#	echo -E -e -n
#	$(( )) and (( )) aka let
#	[[ ]] - similar to [ ] aka test
#	set -A array_variable [value...] --- ksh only!!!
#	array_variable=( value...) --- bash only!!!
#	${array_name[index]} and ${array_name[*]}
#	typeset -r -i -- aka declare in bash
#	local -r -i -- aka typeset in ksh

# Customized for Bash using:
#	${!var}	instead of `simple_get "$var"`

# Which are faster in a modern Bash?
# - aliases or functions
# - echo or printf

# Sometimes defining a function with postfix ()
# gets a syntax error and using the function keyword
# fixes it!

##	simple output

simple_out() { printf "%s\n" "$@"; } # { echo -E "$@"; }
simple_out_inline() { printf "%s" "$@"; } # { echo -En "$@"; }
simple_msg() { >&2 printf "%s\n" "$@"; } # { >&2 echo -E "$@"; }
simple_msg_inline() { >&2 printf "%s" "$@"; } # { >&2 echo -En "$@"; }

##	join, pad, preargs

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
			*) local -r d="$1" ; shift
				 local accum="$1" ; shift
				 local word
				 for word; do
					 accum="${accum}${d}${word}"
				 done
				 simple_out_inline "$accum" ;;
		esac
}

# simple_pad left-padding value right-padding...
simple_pad() {
    case "$2" in
        (?*) simple_join1 '' "$@" ;;
    esac
}

# simple_preargs [ [ arg... ] -- ] arg... ---> BOOLEAN
# Tests for existence of any arguments before a '--' argument.
# When true, sets simple_preargs_cnt and simple_preargs_args.
simple_preargs() {
    (( $# )) || return 1
    case "$1" in (--) return 1 ;; esac
    local -r cnt="$#"
    local args="$1" ; shift
    while (( $# )); do
        case "$1" in
            (--) (( simple_preargs_cnt=$cnt-$# ))
            simple_preargs_args="$args"
            return 0 ;;
        esac
        args="$args $1" ; shift
    done
    return 1
}

##	error reporting and exiting

simple_error_msg() {
    simple_out_inline "${pgm_name:-$0} error"
    if simple_preargs "$@"; then
        simple_out_inline " in $simple_preargs_args"
        shift $simple_preargs_cnt
    fi
    case "${1-}" in (--) shift ;; esac
    (( $# )) && simple_out ": $*"
    return 1
}

simple_error() { >&2 simple_error_msg "$@"; }

simple_exit() { simple_msg "${@:2}"; exit $1; }
simple_exitor() { simple_error "${@:2}"; exit $1; }

simple_show() {                 # for debugging
    while (( $# )); do
        match_simple_re "$simple_name_re" "$1" &&
        simple_var_exists "$1" &&
        simple_msg_inline "$1='${!1}' " ||
        simple_msg_inline "$1 "
        shift
    done
    simple_msg ''
}

##	regexp matching and cutting

simple_name_re='[A-Za-z_][A-Za-z0-9_]*'
simple_name_err='is not a simple name'

simple_part_re='[A-Za-z0-9_]*'
simple_part_err='cannot be part of a simple name'

# match_simple_re REGEXP-PATTERN STRING ---> BOOLEAN
# Note: REGEXP will be anchored
match_simple_re() { (( `expr "X$2" : "X$1\$"` )) ; }
no_match_simple_re() { (( ! `expr "X$2" : "X$1\$"` )) ; }

# assert_simple_re REGEXP-PATTERN STRING EXITOR_ARGS...
# asserts match_simple_re
assert_simple_re() {  (( ! `expr "X${2}" : "X$1"` )) && simple_exitor "${@:3}"; }
assert_simple_re_not() { (( `expr "X${2}" : "X$1"` )) && simple_exitor "${@:3}"; }

# simple_re_cut REGULAR_EXPRESSION VALUE
# RE must have one tagged subexpression, e.g. the \(.*\) in $simple_trim_re.
# The tagged part of the subexpression will be returned.
simple_re_cut() { expr "$2" : "${1}\$" ; }

simple_trim_re='[[:space:]]*\(.*[^[:space:]]\)[[:space:]]*'
simple_trim() { simple_re_cut "$simple_trim_re" "$@" ; }

##	shell and environment variable management

# simple_var_exists VARIABLE_NAME -- returns true or false
simple_var_exists() { [[ -v "$1" ]]; } # bash >= 4.2

# simple_get VARIABLE_NAME - prints the value of the named variable
simple_get() {
    simple_out "${!1-}"
}

# simple_var_trace VARIABLE_NAME -- should this variable be traced
# Redefine this function as needed
# This is clumsy!!!
# How about using an associative array instead???
simple_var_trace() {
    case $1 in
        (foo_*) return 0;;
        (*) return 1;;
    esac
}

# simple_set VARIABLE_NAME VALUE...
# sets the value of the named variable to the specified value/list
simple_set() {
	local -n var="$1"
  local -r name="$1" ; shift
  simple_var_trace "$name" &&
    simple_msg "${pgm_name:-$0} trace: ${name}='${*}'"
  var="$*"
}

# simple_cmd_setvar_args: setvar  =  cmd args...
simple_cmd_setvar_args() { simple_set "$2" "`$1 "${@:3}"`"; }

# simple_cmd_var_args: var  =  cmd $var args...
simple_cmd_var_args() { simple_set "$2" "`$1 "${!2}" "${@:3}"`"; }

# simple_cmd_arg_var_args: var  =  cmd arg $var args...
simple_cmd_arg_var_args() { simple_set "$3" "`$1 "$2" "${!3}" "${@:4}"`"; }

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

##	lists and sets

# Simple lists and sets as strings for shells lacking
# arrays and/or hashes.

# in_simple_delim_list DELIMITER LIST ITEM
in_simple_delim_list() {
  case "$1$2$1" in
		(*"$1$3$1"*) return 0;;
		(*) return 1;;
  esac
}

# ni_simple_delim_list DELIMITER LIST ITEM
ni_simple_delim_list() {
  case "$1$2$1" in
		(*"$1$3$1"*) return 1;;
		(*) return 0;;
  esac
}

#simple_delim_list_prepend DELIMITER LIST ITEM
simple_delim_list_prepend() {
  case "$2" in
    ('') simple_out "$3" ;;
    (*) simple_out "$3$1$2" ;;
  esac
}

#simple_delim_list_append DELIMITER LIST ITEM
simple_delim_list_append() {
  case "$2" in
    ('') echo -n "$3" ;;
    (*) echo -n "$2$1$3" ;;
  esac
}

#simple_delim_set_prepend DELIMITER LIST ITEM
simple_delim_set_prepend() {
  case "$1$2$1" in
		(*"$1$3$1"*) echo -n "$2" ;;
    ("$1$1") echo -n "$3" ;;
    (*) echo -n "$3$1$2" ;;
  esac
}

#simple_delim_set_append DELIMITER LIST ITEM
simple_delim_set_append() {
  case "$1$2$1" in
		(*"$1$3$1"*) echo -n "$2" ;;
    ("$1$1") echo -n "$3" ;;
    (*) echo -n "$2$1$3" ;;
  esac
}

##	managing global resource dependencies

simples_provided='simples'

simples() {
  echo "$simples_provided" | tr ' ' '\n'
}

# simple_provide NAME
# - register the global availability of resource NAME
simple_provide() {
 in_simple_delim_list ' ' "$simples_provided" "$1" ||
   simples_provided="$simples_provided $1"
}
simple_provided() { in_simple_delim_list ' ' "$simples_provided" "$1"; }

##	safely sourcing scripts

#simple_array ARRAY_NAME [ value... ]
#simple_array() { set -A "$@"; }	# ksh-specific code!!!
simple_array() {		# ARRAY_NAME [ value... ]
	local -n var="$1"
  var=("${@:2}")
}

# Anyone who wants to extend theses lists should
#	simple_require pathvar
# and use the facilities defined therein.
simples_bash_suffixes='.bash .kbash .sh'
simples_bash_path="$HOME/Lib/Bash/Simples $HOME/Lib/Sh/Simples"

# simple_source_file SIMPLE_FILENAME
# returns the filename, if any, which corresponds to the argument
# with an allowed suffix in one of the allowed directories.
simple_source_file() {
  match_simple_re "$simple_name_re" "$1" || {
    simple_error simple_source_file -- "improper source $1"
		return 1
  }
  local d s
  for d in $simples_bash_path; do
		for s in $simples_bash_suffixes; do
	    [[ -r "$d/$1$s" ]] && echo "$d/$1$s" && return 0
		done
  done
  simple_error simple_source_file -- "no source $1"
  return 1
}

# simple_source SIMPLE_FILENAME...
# sources (i.e. includes, consults, performs the commands of)
# the script file corresponding to each SIMPLE_FILENAME
simple_source() {
  local return=0     # any error will change this!
  local f file
	for f in "$@"; do
		file=`simple_source_file "$f"` || return=1
	done
  (( $return )) && return $return
  for f in "$@"; do
		. `simple_source_file "$f"`
		[[ $? -eq 0 ]] || {
	    return=$?
	    simple_error simple_source -- "sourcing $f failed; aborting"
	    return $return
		}
		simple_provide "$f"
  done
}

# simple_require SIMPLE_FILENAME..
# sources one or more files in the manner of simple_source above
# but only if they have not yet been sourced by this process.
simple_require() {
  local return item
	for item; do
		in_simple_delim_list ' ' "$simples_provided" "$item" && continue
		simple_source "$item"
		[[ $? -eq 0 ]] || {
	    return=$?
	    simple_error simple_require -- "requirement $item not met; aborting"
	    return $return
		}
  done
}

# WISHLIST

# # bash 4.2
## make any simplifications possible
