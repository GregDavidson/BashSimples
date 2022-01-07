# include.sh
# Copyright (c) 2007 J. Greg Davidson.  All rights reserved
# A declarative framework for writing Bourne-shell scripts.

##	external dependencies

# ensure the programs we run are the ones we think we're running:

PATH=/bin:/usr/bin
export PATH

# ensure all required scripting packages are loaded

case "${simples_provided-}" in
    'simples *') : ;;           # simples package already loaded
    *) . "${simples_sh-$HOME/Lib/Sh/simples.sh}" ||
        (echo "$0 error: Can't load simples.sh, goodbye!" >&2; exit 1) ;;
esac

simple_require hash_maps
simple_require msg_n_exit
simple_require incr_expr

# standard external programs

#	printf -- used by msg_n_exit
#	cat -- a fallback if formatting functions aren't found
#	tr -- to translate '~' characters into tabs ('\t')

# two external scripts for formatting help messages

: "${pgm_helper_bin:=$HOME/Lib/Sh/Bin}"

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
  flag_="${1}" ; name_="${2}"; dfalt_="${3}"; value_="${4}" ; shift 4
  simple_set "${name_}" "${dfalt_}"
  program_flag_set "${flag_}" flag type
  program_flag_set "${flag_}" "${name_}" name
  program_flag_set "${flag_}" "${value_}" value
  var_simple_update simple_list_append pgm_flags "${flag_}"
  pgm_option "-${flag_}" '' "${dfalt_}" "$*"
}

# program_flag_get flag key ...
program_flag_get() {
# simple_err program_flag_get "$@"
  program_flag_="$1" ; shift
  hash_get program_flag "${program_flag_}" "$@"
}
var_program_flag_get() { var_simple_cmd program_flag_get "$@"; }

# program_flag_set flag value key ...
# watch out for argument order!
program_flag_set() {
# simple_err program_flag_set "$@"
  program_flag_="$1" ; program_flag_value_="$2" ; shift 2
  hash_set "${program_flag_value_}" program_flag "${program_flag_}" "$@"
}

# program_flag_var_set flag value ...
# sets variable associated with flag to value ...
program_flag_var_set() {
#  simple_err program_flag_var_set "$@"
    var_program_flag_get pgm_flag_param_ "$1" name ; shift
    assert_simple_re "$simple_name_re" "${pgm_flag_param_}" \
        1 program_flag_var_set -- "$@"
    simple_set "${pgm_flag_param_}" "$@"
}

# program_option letter name default description
# defines a single-letter option which takes an extra argument as its value
# the name should be a good mnemonic which is also a legal hash key
program_option() {
  ok_pgm_option "$1" program_option "$@"
  assert_simple_re "$simple_name_re" "$2" 1 "program_option $@" -- \
      "illegal name $2"
  option_="${1}" ; name_="${2}"; dfalt_="${3}"; shift 3
  simple_set "${name_}" "${dfalt_}"
  program_flag_set "${option_}" option type
  program_flag_set "${option_}" "${name_}" name
  var_simple_update simple_list_append pgm_opts  " [-${option_} ${name_}]"
  var_simple_update simple_list_append pgm_opt_str  "${option_}:"
  pgm_option "-${option_}" "${name_}" "${dfalt_}" "$*"
}

# program_arg name description
# the name should be a good mnemonic which is also a legal hash key
program_arg() {
  name_="$1" ; shift
  var_simple_update simple_list_append pgm_args "${name_}"
  pgm_option '' "${name_}" '' "$*"
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
  var_expr program_option_count $OPTIND - 1
}

# Answers help and version queries and exits cleanly.
# Called automatically by program_process_options
# or call it after all your program_* declarations.
program_help() {
  pgm_describe
  count_=0
  for arg; do
    case "${arg}" in
    --usage) var_incr count_; msg_out pgm_usage ;;
    --version) var_incr count_; simple_out "${pgm_version}" ;;
    --help) var_incr count_
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
  [ "$count_" -gt 0 ] && exit 0
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
      pgm_flags_="`simple_pad ' [-' \"${pgm_flags}\" ']' \"${pgm_opts}\"`"
      padded_args_="`simple_pad ' ' \"$pgm_args\"`"
      : "${pgm_syntax:=${pgm_flags_}$padded_args_}"
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
#    simple_show pgm_options_out pgm_options
    ( simple_out_inline "%-${#pgm_options_width1}s~"
      simple_out_inline "%-${#pgm_options_width2}s~"
      simple_out        "%-${#pgm_options_width3}s"
      simple_out_inline "${pgm_options}"
    ) | tr '~' '\t' | $program_format_table
}

# pgm_option name default description
pgm_option() {
  opt_="$1"; name_="$2"; dfalt_="`simple_pad '[ ' \"${3}\" ' ]'`"; shift 3
  desc_="`simple_pad ' -- ' \"$*\"`"
  var_simple_update _pgm_max_width pgm_options_width1 " $dfalt_"
  var_simple_update _pgm_max_width pgm_options_width2 " ${opt_} $name_"
  var_simple_update _pgm_max_width pgm_options_width3 " $desc_"
  pgm_options="${pgm_options}${dfalt_}~${opt_} ${name_}~${desc_}
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
