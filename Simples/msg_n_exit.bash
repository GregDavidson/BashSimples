# msg_n_exit.bash
# A declarative framework for printing messages and exiting

# Copyright (c) 2007 J. Greg Davidson. This work is licensed under a
# Creative Commons Attribution 4.0 International License
# http://creativecommons.org/licenses/by/4.0.

# Script requirements:
#	simples
	simple_require hash_maps
# Program or built-ins required:
#	printf

# declarative program exit codes and exit message formats

msg_format() {		# name exit_message_format ...
  local -r name="$1"; shift
  hash_set "$*" msg_format "$name"
}

msg_exit_format() {	# name exit_code message_format ...
  local -r name="$1"; hash_set "$2" exit_code "$1" ; shift 2
  msg_format "$name" "${*-}"
}

# msg_out msg_name [arg...]
#   write the formatted arguments to standard output
msg_out() {
  local -r name="${1}"; shift
  if hash_exists msg_format "$name"; then
      printf "`hash_get msg_format $name`" "$@"
  else
      simple_msg "msg_out: No format named $name"
      simple_out "$*"
  fi
}

# msg_err msg_name [arg...]
#   write the formatted arguments to standard error
msg_err() { >&2 msg_out "$@"; }

# msg_exit name [arg...] -- exit using name's message format and code
msg_exit() {
  local -r name="${1}"; shift ; msg_err "$name" "$@"
  var_hash_get code exit_code "$name"
  if [ -z "${code}" ]; then
    simple_msg "${pgm_name} error: No exit_code named '${name}'."
    local -r code=1
  fi
  exit "$code"
}

die() { msg_exit "$@"; }
