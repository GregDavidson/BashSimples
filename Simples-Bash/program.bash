#!/bin/bash
# A declarative framework for writing Bourne-shell scripts.

# Copyright (c) 2007 J. Greg Davidson. This work is licensed under a
# Creative Commons Attribution 4.0 International License
# http://creativecommons.org/licenses/by/4.0.

##	external dependencies

# ensure the programs we run are the ones we think we're running:

PATH=/bin:/usr/bin
export PATH

# ensure all required scripting packages are loaded

case "${simples_provided-}" in
    simples) : ;;           # simples package already loaded
    simples\ *) : ;;           # simples package already loaded
    *) . "${simples_bash-$HOME/Lib/Shell/Simples-Bash/simples.bash}" ||
        (echo "$0 error: Cannot load simples.bash, goodbye!" >&2; exit 1) ;;
esac

simple_require hash_maps
simple_require msg_n_exit

# standard external programs

#	printf -- used by msg_n_exit
#	cat -- a fallback if formatting functions aren't found
#	tr -- to translate '~' characters into tabs ('\t')

# two external scripts for formatting help messages

: "${pgm_helper_bin:=$HOME/Lib/Shell/Simples-Bash/Bin}"

for pgm_helper in notes table; do
    x_="program_format_$pgm_helper"
    simple_set $x_ "$pgm_helper_bin/$x_"
    [ -x "`simple_get $x_`" ] || simple_set $x_ "cat" # graceless degradation
done

##	declarative program self-description

program_name() { pgm_name="$*" ; }
program_purpose() { pgm_purpose="$*" ; }
program_version() { pgm_version="$*" ; }
program_author() { pgm_author="$*" ; }
program_rights() { pgm_rights="${*:-All rights reserved.}" ; }
program_note() { pgm_notes="${pgm_notes}${*}
" ; }                           # newline added to each note!

# program_flag letter variable default value_if_set description
# defines a single-letter flag for controlling the program's behavior
# the variable name should be a good mnemonic
program_flag() {
  ok_pgm_option "$1" program_flag "$@"
  assert_simple_re "$simple_name_re" "$2" 1 "program_flag $@" -- \
      "illegal name $2"
  local -r flag="${1}" name="${2}" dfalt="${3}" value="${4}" ; shift 4
  simple_set "${name}" "${dfalt}"
  program_flag_set flag "${flag}" type
  program_flag_set "${name}" "${flag}" name
  program_flag_set "${value}" "${flag}" value
  _pgm_list_append pgm_flags "${flag}"
  pgm_option "-${flag}" '' "${dfalt}" "$*"
}

# program_flag_get flag key ...
program_flag_get() {
# simple_err program_flag_get "$@"
  local -r flag="$1" ; shift
  hash_get program_flag "${flag}" "$@"
}

var_program_flag_get() { simple_cmd_setvar_args program_flag_get "$@"; }


_pgm_list_append() { 		# listvar newitem [delim]
  simple_cmd_arg_var_args simple_delim_list_append "${3-}" "$1" "$2"
}

# program_flag_set value flag key ...
# same argument order as hash_set!
program_flag_set() { hash_set "$1" program_flag "${@:2}"; }

# program_flag_var_set flag value ...
# sets variable associated with flag to value ...
program_flag_var_set() {
#  simple_err program_flag_var_set "$@"
    local param ;  var_program_flag_get param "$1" name ; shift
    assert_simple_re "$simple_name_re" "${param}" \
        1 program_flag_var_set -- "$@"
    simple_set "${param}" "$@"
}

# program_option letter name default description
# defines a single-letter option which takes an extra argument as its value
# the name should be a good mnemonic which is also a legal hash key
program_option() {
  ok_pgm_option "$1" program_option "$@"
  assert_simple_re "$simple_name_re" "$2" 1 "program_option $@" -- \
      "illegal name $2"
  local -r option="${1}" name="${2}" dfalt="${3}" ; shift 3
  simple_set "${name}" "${dfalt}"
  program_flag_set option "${option}" type
  program_flag_set "${name}" "${option}" name
  _pgm_list_append pgm_opts " [-${option} ${name}]"
  _pgm_list_append pgm_opt_str "${option}:"
  pgm_option "-${option}" "${name}" "${dfalt}" "$*"
}

# program_arg name description
# the name should be a good mnemonic which is also a legal hash key
program_arg() {
  local -r name="$1" ; shift
  _pgm_list_append pgm_args "${name}" ' '
  pgm_option '' "${name}" '' "$*"
}

# Answer help and version queries
# Call after all program_ declarations are complete
# Will exit program cleanly if any help requests are present
# The number of options is placed in a varible and you call it like this:
#	program_process_options "$@"
#	shift $program_option_count
program_process_options() {
  program_help "$@"
  while getopts "${program_options}" option "$@"; do
      case "`program_flag_get "$option" type`" in
        flag) program_flag_var_set "$option" "`program_flag_get "$option" value`" ;;
        option) program_flag_var_set "$option" "${OPTARG}" ;;
        *) die pgm_usage ;;
      esac
  done
  (( program_option_count=$OPTIND-1 ))
}

# Answers help and version queries and exits cleanly.
# Called automatically by program_process_options
# or call it after all your program_* declarations.
program_help() {
  pgm_describe
  local count=0
  local arg ; for arg; do
    case "${arg}" in
    --usage) (( ++count )) ; msg_out pgm_usage ;;
    --version) (( ++count )) ; simple_out "${pgm_version}" ;;
    --help) (( ++count ))
      simple_out "${pgm_name}`simple_pad ' -- ' \"${pgm_purpose:-}\"`"
      msg_out pgm_usage
      pgm_options_out
      simple_out "Version: ${pgm_version}"
      if [ -n "{pgm_notes}" ]; then
        simple_out "Notes:"
        simple_out_inline "${pgm_notes}" | $program_format_notes
      fi
      [ -n "${pgm_author}" ] && simple_out "Author: ${pgm_author}"
      [ -n "${pgm_rights}" ] && simple_out "${pgm_rights}"
      ;;
      esac
  done
  [ "$count" -gt 0 ] && exit 0
}

##	program variable initialization

: "${pgm_flags:=}"	# flag letters
: "${pgm_opts:=}"	# list of option descriptions
: "${pgm_opt_str:=}"	# list of option letters
: "${pgm_args:=}"	# list of mnemonic names for arguments
: "${pgm_notes:=}"	# '\n' terminated notes lines
: "${pgm_options:=}"	# '\n' terminated option description lines

hash_define program_flag # flag -> type, name, value -> data

pgm_described=no
pgm_describe() {
  case "${pgm_described}" in
   no)
      : "${pgm_name:=${0##*/}}"
      : "${pgm_version:=UNKNOWN}"
      local -r flags="`simple_pad ' [-' \"${pgm_flags}\" ']' \"${pgm_opts}\"`"
      local -r args="`simple_pad ' ' \"$pgm_args\"`"
      : "${pgm_syntax:=${flags}$args}"
      : "${pgm_usage:=$pgm_name$pgm_syntax}"
      msg_exit_format pgm_usage 2 "Usage: ${pgm_usage}\n"
      pgm_option '--usage' '' '' print usage message
      pgm_option '--version' '' '' print program version
      pgm_option '--help' '' '' print help message
      : "${program_options:=$pgm_flags$pgm_opt_str}"
      pgm_described='yes' ;;
  esac
}

##	option and flag management

pgm_options_width1="12345678"
pgm_options_width2="12345678"
pgm_options_width3="12345678012345678"

_pgm_max_width() { # string1 string2
    if [ ${#1} -ge ${#2} ]; then
        simple_out_inline "$1"
    else
        simple_out_inline "$2"
    fi
}

pgm_options_out() {
#    simple_bashow pgm_options_out pgm_options
    ( simple_out_inline "%-${#pgm_options_width1}s~"
      simple_out_inline "%-${#pgm_options_width2}s~"
      simple_out        "%-${#pgm_options_width3}s"
      simple_out_inline "${pgm_options}"
    ) | tr '~' '\t' | $program_format_table
}

# pgm_option name default description
pgm_option() {
  local -r opt="$1" name="$2" dfalt="`simple_pad '[ ' \"${3}\" ' ]'`"; shift 3
  local -r desc="`simple_pad ' -- ' \"$*\"`"
  simple_cmd_var_args _pgm_max_width pgm_options_width1 " $dfalt"
  simple_cmd_var_args _pgm_max_width pgm_options_width2 " ${opt} $name"
  simple_cmd_var_args _pgm_max_width pgm_options_width3 " $desc"
  pgm_options="${pgm_options}${dfalt}~${opt} ${name}~${desc}
"                               # newline added at the end!
}

is_ok_pgm_option() {
    case "$1" in
        [A-Za-z]) return 0 ;;
        *) return 1 ;;
    esac
}

ok_pgm_option() {
    is_ok_pgm_option "$1" && return
    simple_exitor 1 ok_pgm_option "$*" -- "illegal option letter $1"
}
