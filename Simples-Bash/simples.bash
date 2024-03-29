#!/bin/bash simples_test.bash
# * simples.bash - simple mechanisms for better Bash scripts

# ** Header

simples_header='$Id: simples.bash,v 1.1 2008/03/18 20:42:55 greg Exp greg $'

# Copyright (c) 2008 J. Greg Davidson. This work is licensed under a
# Creative Commons Attribution 4.0 International License
# http://creativecommons.org/licenses/by/4.0.

# See WISHLIST at bottom

# Note these:
#    O=$IFS IFS=$'\n' arr=($(< myfile)) IFS=$O
# shopt -s nullglobshopt -s nullglob
# shopt -u nullglobshopt -u nullglob

# ** Introduction

# This is a Bash port of the simples package developed for the Bourne Shell,
# Any places where code here will not run under (pd)ksh should be documented!

# The purpose of this port is to improve efficiency of this fundamental
# package while keeping its interface and behavior compatible.  Any
# changes should be internal, i.e. not affect client code following the
# documentation.

# Please consult:
#	simples-man.txt		- steps towards a man page
#	simples-impl-notes.txt	- implementation notes

# ** Feature Assumptions

# Assumptions about shell packages (change below, not here!):
#	simples_bash_suffixes: .bash .kbash .sh
#	simples_bash_path: $HOME/Lib/Shell/Simples-Bash $HOME/Lib/Shell/Simples-Sh

# Assumes the following shell builtins and/or features:
#	printf
#	$(( )) and (( )) aka let
#	[[ ]] - similar to [ ] aka test
#	set -A array_variable [value...] --- for ksh version
#	array_variable=( value...) --- for bash version
#	${array_name[index]} and ${array_name[*]}
#	typeset -r -i --- for bash version
#	local -r -i --- for ksh version
#	${!var}	--- for bash version

# For anything else, test for it and prepare a fallback!

# Test if argument is a command
simple_is_cmd() { type "$1" > /dev/null; }

# ** Simple Output

simple_out() { printf '%s\n' "$*"; }
simple_out_inline() { printf '%s' "$*"; }
simple_msg() { >&2 printf '%s\n' "$*"; }
simple_msg_inline() { >&2 printf '%s' "$*"; }

# ** join, pad, preargs

# simple_join1 DELIMTER [WORD...]
# DELIMITER must be a single character or an empty string
simple_join1() {
    local IFS="$1" ; shift
    printf '%s' "$*"
}

# simple_join DELIMITER [WORD...]
simple_join() {
    case $# in
			0) return ;;
			1) return ;;
			2) printf '%s' "$2";;
			3) printf '%s%s%s' "$2" "$1" "$3";;
			4) printf '%s%s%s%s%s' "$2" "$1" "$3" "$1" "$4";;
			*) local -r d="$1" ; shift
				 local accum="$1" ; shift
				 local word
				 for word; do
					 accum="${accum}${d}${word}"
				 done
				 printf '%s' "$accum" ;;
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

# ** Error Reporting and Exiting

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

# ** Regexp Matching and Cutting

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

# ** Shell and Environment Variable Management

# simple_var_exists VARIABLE_NAME -- returns true or false
simple_var_exists() { [[ -v "$1" ]]; } # bash >= 4.2

# simple_get VARIABLE_NAME - prints the value of the named variable
simple_get() {
    simple_out "${!1-}"
}

# simple_var_trace VARIABLE_NAME | {--on | --off} VARIABLE_NAME...
# should this variable be traced
simple_var_trace() {
    declare -gA simple_var_trace
    local v
    case $1 in
        (--on) for v in "${@:2}"; do let simple_var_trace["$v"]=0; done ;;
        (--off) for v in "${@:2}"; do unset ${simple_var_trace["$v"]}; done ;;
        (*) return $(( ${simple_var_trace["$1"]-1}  )) ;;
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

# deviations from simples.sh in next few functions!!!

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

# ** Lists and Sets

# These are arguably obsoleted by modern Bash arrays

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
    ('') printf '%s' "$3" ;;
    (*) printf '%s%s%s' "$3" "$1" "$2" ;;
  esac
}

#simple_delim_list_append DELIMITER LIST ITEM
simple_delim_list_append() {
  case "$2" in
    ('') printf '%s' "$3" ;;
    (*) printf '%s%s%s' "$2" "$1" "$3" ;;
  esac
}

#simple_delim_set_prepend DELIMITER LIST ITEM
simple_delim_set_prepend() {
  case "$1$2$1" in
		(*"$1$3$1"*) printf '%s' "$2" ;;
    ("$1$1") printf '%s' "$3" ;;
    (*) printf '%s%s%s' "$3" "$1" "$2" ;;
  esac
}

#simple_delim_set_append DELIMITER LIST ITEM
simple_delim_set_append() {
  case "$1$2$1" in
		(*"$1$3$1"*) printf '%d' "$2" ;;
    ("$1$1") printf '%d' "$3" ;;
    (*) printf '%d%d%d' "$2" "$1" "$3" ;;
  esac
}

# Is this still needed??
#simple_array ARRAY_NAME [ value... ]
#simple_array() { set -A "$@"; }	# ksh-specific code!!!
simple_array() {		# ARRAY_NAME [ value... ]
	  local -n var="$1"
    var=("${@:2}")
}

# ** Sourcing Scripts

# simple_src [--set | get] path-to-script...
# Source scripts if they exist and have not already been sourced.
# --set --- just boost the count(s), it was sourced another way
# --get --- just return the count -- one path only
simple_src() {
    declare -gA simple_src_count
    local set_only=''
    case "$1" in
        (--set) set_only="$1"; shift ;;
        (--get) (( $# == 2 )) ||
                     { >&2 echo simple_src arity warning: "$*"; return 127; }
                  g=$(realpath "$2") || return 126
                  return ${simple_src_count[$g]:-0} ;;
        (--) shift ;;
        (-*) >&2 echo simple_src warning: bad option "$1" ; shift ;;
    esac
    local f g
    for f; do
        if [ ! -f "$f" ]; then
            >&2 echo "simple_src warning: No file $f!"
        else
            g=$(realpath "$f") || return 125
            [ -n "$set_only" ] ||
              (( simple_src_count["$g"] )) ||
              . "$g" ||
              >&2 echo simple_src warning: error after sourcing "$g"
            let ++simple_src_count["$g"]
        fi
    done
}

simple_src_dir() {
    for d; do
        [ -d "$d" ] && simple_src "$d"/*
    done
}

# ** Querying Simples

# simples_exported will
#   be exported
#   contain list of exported simples
# simples_provided will
#   NOT be exported
#   contain a list of all simples sourced by current shell
#   be a superset of simples_exported
simples_exported='' simples_provided='simples'

the_simples_provided() {
  [ -z "$simples_provided" ] && [ -n "$imples_exported" ] &&
    simples_provided="$simples_exported"
  printf "%s" "$simples_provided"
}

simples() {
  for s in $(the_simples_provided); do
    if in_simple_delim_list ' ' "$simples_exported" "$s"
    then printf '%s exported\n' "$s"
    else printf '%s local\n' "$s"
    fi
  done
}

# simple_provide [--export] NAME
# - register the global availability of resource NAME
simple_provide() {
  local maybe_export=''
  [ X--export == X"$1" ] && {
    maybe_export="$1"; shift
  }
  in_simple_delim_list ' ' "$(the_simples_provided)" "$1" ||
    simples_provided="$simples_provided $1"
  [ -z "$maybe_export" ] || in_simple_delim_list ' ' "$simples_exported" "$1" || {
    simples_exported="$simples_exported $1"
  }
}
simple_provided() { in_simple_delim_list ' ' "$(the_simples_provided)" "$1"; }
simple_exported() { in_simple_delim_list ' ' "$simples_exported" "$1"; }

# ** Sourcing Simples Scripts

# Anyone who wants to extend theses lists should
#	simple_require pathvar
# and use the facilities defined therein.
simples_bash_suffixes='.bash .kbash .sh'
simples_bash_path="$HOME/Lib/Shell/Simples-Bash $HOME/Lib/Shell/Simples-Sh"

# simple_source_file [--export] SIMPLE_FILENAME
# returns the filename, if any, which corresponds to the argument
# with an allowed suffix in one of the allowed directories.
simple_source_file() {
  local maybe_export=''
  [ X--export == X"$1" ] && {
    maybe_export="$1"; shift
  }
  match_simple_re "$simple_name_re" "$1" || {
    simple_error simple_source_file -- "improper source $1"
		return 1
  }
local d s x dx y dy
  for d in $simples_bash_path; do
		for s in $simples_bash_suffixes; do
        x="$1$s" 
        dx="$d/$x" 
        [[ -r "$dx" ]] &&
            if [ -z "$maybe_export" ]; then
                printf '%s\n' "$dx" && return 0
            else
                y="$1-export$s" 
                dy="$d/$y" 
                ! [[ -r "$dy" ]] && make -C "$d" "$y"
                if [[ -r "$dy" ]]; then
                    printf '%s\n' "$dy"
                    return 0
                else
                    simple_error simple_source_file -- "cannot make source $dy"
                    return 1
                fi
            fi
    done
  done
  simple_error simple_source_file -- "no source $1"
  return 1
}

# simple_source [--export] SIMPLE_FILENAME...
# sources (i.e. includes, consults, performs the commands of)
# the script file corresponding to each SIMPLE_FILENAME
simple_source() {
  local maybe_export=''
  [ X--export == X"$1" ] && {
    maybe_export="$1"; shift
  }
  local return=0     # any error will change this!
  local f file
	for f in "$@"; do
		file=`simple_source_file $maybe_export "$f"` || return=1
	done
  (( $return )) && return $return
  for f in "$@"; do
		. `simple_source_file $maybe_export "$f"`
		[[ $? -eq 0 ]] || {
	    return=$?
	    simple_error simple_source -- "sourcing $f failed; aborting"
	    return $return
		}
		simple_provide $maybe_export "$f"
  done
}

# simple_require [--export] SIMPLE_FILENAME..
# sources one or more files in the manner of simple_source above
# but only if they have not yet been sourced by this process.
simple_require() {
  local maybe_export=''
  [ X--export == X"$1" ] && {
    maybe_export="$1"; shift
  }
  local simples=$(the_simples_provided)
  local return item
	for item; do
		in_simple_delim_list ' ' "$simples" "$item" && continue
		[ -n "$maybe_export" ] && in_simple_delim_list ' ' "$simples_exported" "$item" && continue
		simple_source $maybe_export "$item"
		[[ $? -eq 0 ]] || {
	    return=$?
	    simple_error simple_require -- "requirement $item not met; aborting"
	    return $return
		}
  done
}

# ** WISHLIST

# Update for Bash Version >= 5
# Modularize the remainders into separate simples
# make things more elgant: +Simplicity, +Generality, +Power
# Bring it back into compatibility with sh version
# Share some code with sh version??
# Move sh Simples into same git repository
