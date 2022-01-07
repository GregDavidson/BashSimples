# simples.sh
# Copyright (c) 2008 J. Greg Davidson.  All rights reserved.
# Simple things to source in all Bourne Shell scripts.

# Provides simple functions for:
#	error reporting and exiting
#	traceable variable management
#	shell and environment variable defaults
#	safely sourcing scripts
#	simple list sets

# External or built-in dependencies:
#	echo

simple_msg() { echo "$@" >&2; }
simple_msg_inline() { echo -n "$@" >&2; }
simple_exit() { code=$1; shift; simple_msg "$*"; exit $code; }

# general variable and value manipulation functions

# simple_var_exists VARIABLE_NAME
# returns true or false
simple_var_exists() {
  eval "[ '_|_' = \"\${${1}:-_|_}\" ]" && return 1 || return 0;
}

# simple_get_var VARIABLE_NAME
# prints the value of the named variable
simple_get_var() {
 simple_var_exists "$1" || return 1
 eval "echo \"\${${1}}\""
}

# simple_var_trace VARIABLE_NAME
# returns whether or not updates to VARIABLE_NAME should be traced
# to get fine control of variable tracing:
#	simple_require simple_hash_var_trace
#simple_var_trace() { return 1 ; }
simple_var_trace() {
    case $1 in
	foo_*) return 0;;
    esac
    return 1
}

# simple_set_var VARIABLE_NAME VALUE...
# sets the value of the named variable to the specified value/list
simple_set_var() {
  simple_set_var_name="${1}" ; shift
  simple_var_trace "$simple_set_var_name" &&
    simple_msg "${simple_set_var_name}='${*}'"
  eval "${simple_set_var_name}='${*}'"
}

# simple_set_default VARIABLE_NAME VALUE...
# sets the value of the named variable to the specified value/list
simple_set_default() {
  [ "_no_value_" = "${1:-_no_value_}" ] && simple_set_var "$@"
}

# simple_export_default VARIABLE_NAME DEFAULT_VALUE...
simple_export_default() {
  simple_set_default "$@"
  eval "export \"${1}\""
}

# Simple lists and sets as strings with separator delimiters.

# Limitations:
#   	The delimiter may not contain any regular expression
#	metacharacters, e.g. none of the characters \.^$*?()[]

# in_simple_delim_list DELIMITER LIST ITEM
in_simple_delim_list() {
  delim_list="`simple_get_var $2`"
  [ `expr "${1}${delim_list}${1}" : ".*${1}${3}${1}"` -ne 0 ]
}

# not_in_simple_delim_list DELIMITER LIST ITEM
not_in_simple_delim_list() {
 in_simple_delim_list "$@" && return 1 || return 0
}

#simple_delim_list_prepend DELIMITER LIST ITEM
simple_delim_list_prepend() {
  delim_list="`simple_get_var $2`"
  if [ -z "$delim_list" ]; then
      simple_set_var "$2" "$3"
  else
      simple_set_var "$2" "$3$1$delim_list"
  fi
}

#simple_delim_list_append DELIMITER LIST ITEM
simple_delim_list_append() {
  delim_list="`simple_get_var $2`"
  if [ -z "$delim_list" ]; then
      simple_set_var "$2" "$3"
  else
      simple_set_var "$2" "$delim_list$1$3"
  fi
}

simple_delim_set_prepend() {
  in_simple_delim_list "$@" || simple_delim_list_prepend "$@"
}

simple_delim_set_append() {
  in_simple_delim_list "$@" || simple_delim_list_append "$@"
}

simple_source_suffix='.sh'
simple_set_default simple_source_path "$HOME/Lib/Sh"
simple_source_list=''

# simple_source SIMPLE_FILENAME...
# sources (i.e. includes, consults, performs the commands of)
# the file with indicated name and extension $simple_source_suffix
# provided that it is in one of the allowed directories.
simple_source() {
#  set -xv
  simple_source_return_code=0
  simple_source_save_path=$PATH
  for simple_source_file in "$@"; do
    case "$1" in
      */*) simple_exit 1 "$0: illegal simple_source file $simple_source_file!";;
    esac
    PATH="$simple_source_path"
    if . ${1}${simple_source_suffix}; then
      PATH="$simple_source_save_path"
      simple_delim_set_append / simple_source_list "$simple_source_file"
    else
      PATH="$simple_source_save_path"
      simple_source_return_code=1
    fi
  done
  return $simple_source_return_code
}

# simple_require SIMPLE_FILENAME..
# sources one or more files in the manner of simple_source above
# but only if they have not yet been sourced by this process.
# Should this fail, the whole script fails.
simple_require() {
  for item; do
    in_simple_delim_list / simple_source_list "$item" ||
      simple_source "$item" ||
        err_exit 1 "simple_require error: failed to source $item!"
  done
}
