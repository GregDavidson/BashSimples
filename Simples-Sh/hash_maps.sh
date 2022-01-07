# hash_maps.sh
# Copyright (c) 2008 J. Greg Davidson.  All rights reserved.
# Simple associative arrays for a simple shell.

# We can create a very simple hash aka associative array using global
# variables as long as the hash keys are legal identifiers.

# Here's a start; what other functions would we like?
# Let's let application pressure drive this!

_hash_join() { simple_join '_' "$@"; }

hash_exists() { simple_var_exists `_hash_join "$@"`; }

hash_define() {
  # typedef -A "$1"
  case $# in
      0) simple_exitor 1 hash_define -- no arguments ;;
      1) return 0 ;;
  esac
  hash_set "$@"
}

# hash_get name key...
hash_get() { simple_get "`_hash_join $*`"; }
var_hash_get() { var_simple_cmd hash_get "$@"; }

# hash_set value name key...
# warning: argument order inconsistent with simple_set!
hash_set() {
 hash_value_="$1" ; shift
 simple_set "`_hash_join $*`" "$hash_value_"
}
