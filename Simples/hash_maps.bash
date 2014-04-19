# hash_maps.bash
# Simple associative arrays for a simple shell.
# Note: Bash now has associative arrays built in!

# Copyright (c) 2008 J. Greg Davidson. This work is licensed under a
# Creative Commons Attribution 4.0 International License
# http://creativecommons.org/licenses/by/4.0.

# We can create a very simple hash aka associative array using global
# variables as long as the hash keys are legal identifiers.

# Here's a start; what other functions would we like?
# Let's let application pressure drive this!

_hash_join() { simple_join '_' "$@"; }
alias _hash_join="simple_join '_'"

hash_exists() { simple_var_exists `_hash_join "$@"`; }

# I don't think this is needed - jgd
hash_define() {
  case $# in
      0) simple_exitor 1 hash_define -- no arguments ;;
      1) return 0 ;;
  esac
  hash_set "$@"
}

# hash_get name key...
hash_get() { simple_get "`_hash_join $*`"; }
var_hash_get() { simple_cmd_setvar_args hash_get "$@"; }
alias var_hash_get='simple_cmd_setvar_args hash_get'

# hash_set value name key...
# warning: argument order inconsistent with simple_set!
hash_set() {
 local -r value="$1" ; shift
 simple_set "`_hash_join $*`" "$value"
}
