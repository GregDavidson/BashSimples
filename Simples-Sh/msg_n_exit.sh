# msg_n_exit.sh
# Copyright (c) 2007 J. Greg Davidson.  All rights reserved
# A declarative framework for printing messages and exiting

# Script requirements:
#	simples
	simple_require hash_maps
# Program or built-ins required:
#	printf

# declarative program exit codes and exit message formats

msg_format() {		# name exit_message_format ...
  format_name_="$1"; shift
  hash_set "$*" msg_format "$format_name_"
}

msg_exit_format() {	# name exit_code message_format ...
  format_name_="$1"; hash_set "$2" exit_code "$1" ; shift 2
  msg_format "$format_name_" "${*-}"
}

# msg_out msg_name [arg...]
#   write the formatted arguments to standard output
msg_out() {
  format_name_="${1}"; shift
  if hash_exists msg_format "$format_name_"; then
      printf "`hash_get msg_format $format_name_`" "$@"
  else
      simple_msg "msg_out: No format named $format_name_"
      simple_out "$*"
  fi
}

# msg_err msg_name [arg...]
#   write the formatted arguments to standard error
msg_err() { >&2 msg_out "$@"; }

# msg_exit name [arg...] -- exit using name's message format and code
msg_exit() {
  format_name_="${1}"; shift ; msg_err "$format_name_" "$@"
  var_hash_get exit_code_ exit_code "$format_name_"
  if [ -z "${exit_code_}" ]; then
    simple_msg "${pgm_name} error: No exit_code named '${format_name_}'."
    exit_code_=1
  fi
  exit "$exit_code_"
}

die() { msg_exit "$@"; }
