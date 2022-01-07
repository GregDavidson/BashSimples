# include.sh
# Copyright (c) 2007 J. Greg Davidson.  All rights reserved
# A declarative framework for writing Bourne-shell scripts.

# Script requirements:
#	simples
	simple_require hash_sets
# Program or built-ins required:
#	printf(1), fmt(1) with -s option, cat(1) with -n option
# Note:
#	The framework could be rewritten using awk as the sole
#	external program required.  Using awk would also allow
#	for a more optimal output format for the --help option.

# Ensure the programs we run are the ones we think we're running:
PATH=/bin:/usr/bin
export PATH

[ -z "$sh_lib" ] && sh_lib=$HOME/Lib/Sh export sh_lib
. "$sh_lib/simples.sh"

# declarative program exit codes and exit message formats

# program_exit exit_name exit_code exit_message_format ...
program_exit() {
  exit_name_="${1}"; exit_code_="${2}"; shift 2
  hash_set "$exit_code_" pgm_exit code "${exit_name_}"
  hash_set  "$*" pgm_exit format "${exit_name_}"
}

# die name [arg...]	-- exit using name's message format and code
die() {
  exit_name_="${1}"; shift
  var_hash_get exit_code_ pgm_exit code "${exit_name_}"
  if [ -z "${exit_code_}" ]; then
    >&2 echo "${pgm_name} error: No program_exit named '${exit_name_}'."
    exit_code_=1
  fi
  var_hash_get exit_format_ pgm_exit format "${exit_name_}"
  if [ -n "${exit_format_}" ]; then
    if [ "$#" -gt 0 ]; then
	>&2 printf "${exit_format_}\n" "$@"
    else
	>&2 echo "${exit_format_}"
    fi
  fi
  [ 1 = "${exit_code_}" ] && >&2 echo "${pgm_name}: Exiting with exit code 1."
  exit "${exit_code_}"
}

# declarative program self-description

program_name() { pgm_name="$1" ; }
program_purpose() { pgm_purpose="$*" ; }
program_version() { pgm_version="$*" ; }
program_author() { pgm_author="$*" ; }
program_copyright() { pgm_copyright="$*" ; }
program_note() { var_delim_append pgm_notes '\n' "$*" ; }

# program_var_set variable value ...	-- sets variable name to value(s)
# little more than var_set, but we could exercise more control later
program_var_set() {
#  >&2 echo program_var_set "$@"
  pgm_param_="$1" ; shift
  var_set "${pgm_param_}" "$*"
}

# program_flag_get flag key ...
program_flag_get() {
#  >&2 echo program_flag_get "$@"
  program_flag_="$1" ; shift
  hash_get program_flag "${program_flag_}" "$@"
}
 
# var_program_flag_get output_var flag key ...
var_program_flag_get() {
#  >&2 echo var_program_flag_get "$@"
  program_flag_var_="$1" ; program_flag_="$2" ; shift 2
  var_hash_get "${program_flag_var_}" program_flag "${program_flag_}" "$@"
}

# program_flag_set flag value key ...
# watch out for argument order!
program_flag_set() {
#  >&2 echo program_flag_set "$@"
  program_flag_="$1" ; program_flag_value_="$2" ; shift 2
  hash_set "${program_flag_value_}" program_flag "${program_flag_}" "$@"
}

# program_flag_var_set flag value ...
# sets variable associated with flag to value ...
program_flag_var_set() {
#  >&2 echo program_flag_var_set "$@"
    var_program_flag_get pgm_flag_param_ "$1" name ; shift
    program_var_set "${pgm_flag_param_}" "$@"
}
 
# program_flag letter variable default value_if_set description
# defines a single-letter flag for controlling the program's behavior
# the variable name should be a good mnemonic
program_flag() {
  flag_="${1}" ; name_="${2}"; dfalt_="${3}"; value_="${4}" ; shift 4
  program_var_set "${name_}" "${dfalt_}"
  program_flag_set "${flag_}" flag type
  program_flag_set "${flag_}" "${name_}" name
  program_flag_set "${flag_}" "${value_}" value
  var_append pgm_flags "${flag_}"
  pgm_option "-${flag_}" "" "${dfalt_}" "$*"
}

# program_option letter name default description
# defines a single-letter option which takes an extra argument as its value
# the name should be a good mnemonic which is also a legal hash key
program_option() {
  option_="${1}" ; name_="${2}"; dfalt_="${3}"; shift 3
  program_var_set "${name_}" "${dfalt_}"
  program_flag_set "${option_}" option type
  program_flag_set "${option_}" "${name_}" name
  var_append pgm_opts  " [-${option_} ${name_}]"
  var_append pgm_opt_str  "${option_}:"
  pgm_option "-${option_}" "${name_}" "${dfalt_}" "$*"
}

# program_arg name description
# the name should be a good mnemonic which is also a legal hash key
program_arg() {
  name_="$1" ; shift
  var_append pgm_args " ${name_}"
  pgm_option "" "${name}" "" "$*"
}

# Answer help and version queries
# Call after all program_ declarations are complete
# Will exit program cleanly if any help requests are present
# Originally returned number of arguments which have been processed,
# and was called like this:
#	shift `program_process_options "$@"`
# but under my sh (bash version 3.1.17 masquerading as sh)
# this made variable modifications isolated to the function (subshell).
# Now the count is placed in a variable and you call it like this:
#	program_process_options "$@"
#	shift $program_option_count
program_process_options() {
  program_help "$@"
  while getopts "${program_options}" option "$@"; do
      case "`program_flag_get "$option" type`" in
        flag) program_flag_var_set "$option"  "`program_flag_get "$option" value`" ;;
        option) program_flag_var_set "$option" "${OPTARG}" ;;
      *) die usage ;;
      esac
  done
  program_option_count=`expr $OPTIND - 1`
}

# Answer help and version queries
# Call after all program_ declarations are complete
# Will exit program cleanly if any help requests are present
# Do not call directly if you're planning on using program_process_options
program_help() {
  pgm_describe
  count_=0
  for arg; do
    case "${arg}" in
    --usage) var_incr count_; echo "${pgm_usage_msg}" ;;
    --version) var_incr count_; echo "${pgm_version}" ;;
    --help) var_incr count_
      echo "${pgm_name}`may_wrap ' -- ' "${pgm_purpose:-}"`"
      echo "${pgm_usage_msg}" 
      echo -e "${pgm_options}"
      echo "Version: ${pgm_version}"
      if [ -n "{pgm_notes}" ]; then
       echo "Notes:"
       echo -e ${pgm_notes} | cat -n | fmt -s
      fi
      [ -n "${pgm_author}" ] && echo "Author: ${pgm_author}"
      [ -n "${pgm_copyright}" ] && echo "${pgm_copyright}"
      ;;
      esac
  done
  [ "$count_" -gt 0 ] && die quietly
}

# variable initialization and help functions

: "${pgm_options:=}"	# list of '\n' prefixed option descriptions
: "${pgm_flags:=}"		# flag letters
: "${pgm_opts:=}"		# list of option descriptions
: "${pgm_opt_str:=}"	# list of option letters
: "${pgm_args:=}"		# list of mnemonic names for arguments

pgm_described=no
pgm_describe() {
  case "${pgm_described}" in no)
      : "${pgm_name:=${0##*/}}"
      : "${pgm_version:=UNKNOWN}"
      var_may_wrap pgm_flags_ ' [-' "${pgm_flags}" ']'"${pgm_opts}"
      : "${pgm_syntax:="${pgm_flags_}${pgm_args}"}"
      : "${pgm_usage:=${pgm_name}`sp_wrap "${pgm_syntax}"`}"
      : "${pgm_usage_msg:=Usage: ${pgm_usage}}"
      pgm_option "--usage" "" "" print usage message
      pgm_option "--version" "" "" print program version
      pgm_option "--help" "" "" print help message
      : "${program_options:="${pgm_flags}${pgm_opt_str}"}"
      program_exit quietly	0		# all is well, nothing to say
      program_exit usage	2 "${pgm_usage}"	# traditional exit code for mis-usage
      pgm_described=yes
  esac
}

pgm_option_format='\n  %-16s%-8s %s'

# pgm_option name default description
pgm_option() {
  option_="${1}" ; name_="${2}"; dfalt_="${3}"; shift 3
  var_may_wrap desc_ ' -- ' "$*"
  var_may_wrap dfalt_ '[ ' "${dfalt_}" ' ]'
  full_desc_="`printf "${pgm_option_format}" "${option_} ${name_}" "${dfalt_}" "${desc_}"`"
  var_append pgm_options "${full_desc_}"
}
