# simples-codepool.sh
# Copyright (c) 2008 J. Greg Davidson.  All rights reserved.
# Simple mechanisms for better shell scripts - code variations

##	Table of Contents

#	Table of Contents
#	introduction
#	simple joining and padding
#	error reporting and exiting
#	managing global resource dependencies
#	shell and environment variable management
#	simple lists and sets
#	safely sourcing scripts

##	introduction

# This file contains multiple implementations of the mechanisms of the
# simples package.  It is intended as a working reference and resource
# for shell programmers.

# Some of these functions and mechanisms are no longer part of the
# simples package, yet they may still be useful as reference.

# See also:
#	simples-man.txt		- steps towards a man page
#	simples-impl-notes.txt	- implementation notes

# Dependencies:  No external programs; builtins:
#	echo
#	echo -n
#	expr
#	[ ]

##	simple joining and padding

simple_char_join() {        # DELIMITER must be 1 character only
    simple_delim_="$1" ; shift
    da1_save_ifs_="${IFS}"
    echo -n "$*"
    IFS="${da1_save_ifs}"
}

_simple_join_1() {
    simple_delim_="$1" ; simple_delim_out_="$2" ; shift 2
    for simple_delim__; do
      simple_delim_out_="${simple_delim_out_}${simple_delim_}${simple_delim__}"
    done
    echo -n "$simple_delim_out_"
}

_simple_join_2() {
    simple_delim_="$1" ; simple_delim_out_="$2" ; shift 2
    while [ $# -gt 0 ]; do
      simple_delim_out_="${simple_delim_out_}${simple_delim_}${1}" ; shift
    done
    echo -n "$simple_delim_out_"
}

_simple_join_3() {
    simple_delim_="$1" ; echo -n "$2" ; shift 2
    while [ $# -gt 0 ]; do
      echo -n "${simple_delim_}$1" ; shift
    done
}

# simple_pad left-padding value right-padding...
simple_pad() { [ -n "$2" ] && simple_join '' "$@"; }

##	error reporting and exiting

simple_ctxt() {
  echo -n "${pgm_name:-$0}`simple_pad ' ' ${FUNCNAME:-} '()'`"
}

simple_out() { echo "$@"; }
simple_out_inline() { echo -n "$@"; }
simple_err() { echo "$@" >&2; }
simple_err_inline() { echo -n "$@" >&2; }
simple_error() { echo "`simple_ctxt` error: $@" >&2; }
simple_exit() { code=$1; shift; simple_err "$*"; exit $code; }
simple_exitor() { code=$1; shift; simple_error "$*"; exit $code; }

##	shell and environment variable management

is_simple_name() { # would $1 be an OK identifier?
    [ `expr "X${1}" : 'X[A-Za-z_][A-Za-z0-9_]*$'` -ne 0 ]
}

simple_name() { # simple_name name? calling_function context
    is_simple_name "$1" && return
    simple_name_="$1"; shift
    FUNCNAME="$*"
    simple_exitor 1 "illegal name ($simple_name_)"
}

# simple_var_exists VARIABLE_NAME -- returns true or false
simple_var_exists() {
#   simple_name "$1" simple_var_exists
    eval [ -n \"\${${1}+yes}\" ]
}

# simple_get_var VARIABLE_NAME - prints the value of the named variable
simple_get_var() {
 simple_var_exists "$1" && eval "echo \"\$${1}}\""
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
  simple_set_name_="${1}" ; shift
  simple_var_trace "$simple_set_name_" &&
    simple_err "`simple_ctxt` trace: ${simple_set_name_}='${*}'"
  eval "${simple_set_name_}='${*}'"
}

# var_simple_cmd COMMAND VARIABLE_NAME ARGS...
# sets the value of the named variable to the
# result of evaluating the specified command
var_simple_cmd() {
  simple_cmd_="$1" ; simple_var_="$2" ; shift 2
  simple_set "$simple_var_" "`$simple_cmd_ \"$@\"`"
}

# simple_set_default VARIABLE_NAME VALUE...
# sets the value of the named variable to the specified value/list
simple_set_default() {
    simple_name "$1" simple_set_default
    simple_var_exists "$1" || simple_set "$@"
}

# simple_env_default VARIABLE_NAME DEFAULT_VALUE...
simple_env_default() {
    simple_name "$1" simple_env_default
    simple_set_default "$@"
    export "${1}"
}

##	simple lists, sets, maps

# Simple lists and sets as strings for shells lacking
# arrays and/or hashes.

# WARNING: Metacharacters in the delimiter or values are
# problematic for some algorithms here.  This check for
# basic regexp metacharacters may be insufficient!
is_simple_meta_free() {
    case "$1" in
        *[]\\\^.*\$[]*) return 1 ;;
        *) return 0 ;;
    esac
}

##	managing global resource dependencies

# Resource management can either use list sets or hash sets

# simple_provided_list required, even if using hash sets
simple_delim_var '/' simple_provided_list 'simples'

# simple_provide NAME
# - register the global availability of resource NAME
simple_provide() { var_simple_setvar_append simple_provided_list "$1"; }
simple_provided() { in_simple_listvar simple_provided_list "$1"; }

##	safely sourcing scripts

simple_source_suffix='.sh'
simple_delim_var ' ' simple_load_extensions 'sh'
simple_delim_var ':' simple_source_path "$HOME/Lib/Sh"

# simple_source SIMPLE_FILENAME...
# sources (i.e. includes, consults, performs the commands of)
# the script file with indicated simple name
# (the extension $simple_source_suffix will be added)
# provided that it exists in one of the allowed directories
# listed in simple_source_path.
simple_source() {
    simple_source_return_=0     # any error will change this!
    for simple_source_file in "$@"; do
        if ! is_simple_name "$1"; then
            simple_error "improper filename $simple_source_file_!"
            simple_source_return_=1
        elif simple_load "$simple_source_file_"; then
            simple_provide "$simple_source_file_"
        else
            simple_error "loading $simple_source_file_ failed!"
            simple_source_return_=1
        fi
    done
    return $simple_source_return_
}

simple_load() { _simple_load_1 "$@"; }

_simple_load_1() {
  simple_load_save_path_=$PATH
  PATH="$simple_source_path"
  . "${1}$simple_source_suffix"
  simple_load_return_=$?
  PATH="$simple_load_save_path_"
  return $simple_load_return_
}

_simple_load_2() {
  simple_load_save_ifs_=$IFS
  IFS=":$IFS"
  for simple_load_dir_ in "$simple_source_path"; do
      for simple_load_ext_ in "$simple_load_extensions"; do
          if [ -r "$simple_load_dir_/$1.$simple_load_ext_" ]; then
              . "$simple_load_dir_/$1.$simple_load_ext_" && break 2
          fi
      done
  done
  IFS="$simple_load_save_ifs_"
}

# simple_require SIMPLE_FILENAME..
# sources one or more files in the manner of simple_source above
# but only if they have not yet been sourced by this process.
simple_require() {
  for item; do
    in_simple_delim_list / "$simple_source_list" "$item" ||
      simple_source "$item"
  done
}
