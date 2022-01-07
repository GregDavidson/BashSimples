# delim_lists.sh
# Copyright (c) 2008 J. Greg Davidson.  All rights reserved.
# simple lists, sets, maps as delimited lists

# Simple lists and sets as strings for shells lacking
# arrays and/or hashes.

# WARNING: Metacharacters in the delimiter or values are
# problematic for some algorithms here.  This check for
# basic regexp metacharacters may be insufficient!
_is_meta_free() {
    case "$1" in
        *[]\\\^.*\$[]*) return 1 ;;
        *) return 0 ;;
    esac
}

# in_delim_list DELIMITER LIST ITEM
in_delim_list() {
  if _is_meta_free "$3"; then
      _in_str_delim_list "$@"
  else
      case "$1" in
          ?) _in_char_delim_list "$@" ;;
          FUNCNAME='' simple_exitor 1 "No algorithm for 'in_delim_list $@'"
      esac
  fi
}

# ni_delim_list DELIMITER LIST ITEM
ni_delim_list() {
#  ! in_delim_list "$@"
   in_delim_list "$@" && return 1 || return 0
}

in_char_delim_list() {
    in_char_delim_list_return_=1
    in_char_delim_list_ifs_=$IFS
    IFS="$1"
    for in_char_delim_list_item_ in $2; do
        if [ X"$3" = X"$in_char_delim_list_item_" ]; then
            in_char_delim_list_return_=0
            break
        fi
    done
    IFS="$in_char_delim_list_ifs_"
    return "$in_char_delim_list_return_"
}

_in_str_delim_list() {
    [ `expr "${1}{$2}${1}" : ".*${1}{$3}${1}"` -ne 0 ]
}

# Limitations:
# no metacharacters allowed in $1 or $3!
# $1 must not occur in $3
in_str_delim_list() {
    _is_meta_free "$3" ||
    simple_exit 1 "in_str_delim_list: metacharacter in ($3)"
    _in_str_delim_list "$@"
}

#delim_list_prepend DELIMITER LIST ITEM
delim_list_prepend() {
    [ -z "$2" ] && echo -n "$3" || echo -n "$3$1$2"
}

#delim_list_append DELIMITER LIST ITEM
delim_list_append() {
    [ -z "$2" ] && echo -n "$3" || echo -n "$2$1$3"
}

#delim_set_prepend DELIMITER LIST ITEM
delim_set_prepend() {
  in_delim_list "$@" || delim_list_prepend "$@"
}

#delim_set_append DELIMITER LIST ITEM
delim_set_append() {
  in_delim_list "$@" || delim_list_append "$@"
}

# Now a second, side-effecting API

_get_list_delim() { simple_get "${1}__delim"; }
_set_list_delim() { simple_set "${1}__delim" "$2"; }

delim_var() {	# DELIMITER VAR [ITEM]
    _set_list_delim "$2" "$1"
    simple_set "$2" "${3-}"
}

_delim_list_cmd() {	# COMMAND LISTVAR ARGS...
    cmd_="$1" ; var_="$2" ; shift 2
    delim_=`_get_list_delim "$var_"`
    [ -n "$delim_" ] ||
    simple_exitor 1 delim_list_cmd -- "No delimiter for $var_."
    list_=`simple_get "$var_"`
    $cmd_ "$delim_" "$list_" "$@"
}

_var_delim_list_cmd() {        # COMMAND LISTVAR ARGS...
    simple_set "$2" "`_delim_list_cmd \"$@\"`"
}

in_listvar() { _delim_list_cmd in_delim_list "$@"; }
ni_listvar() { _delim_list_cmd ni_delim_list "$@"; }

var_listvar_prepend() { _var_delim_list_cmd delim_list_prepend "$@"; }
var_listvar_append() { _var_delim_list_cmd delim_list_append "$@"; }

var_setvar_prepend() { _var_delim_list_cmd delim_set_prepend "$@"; }
var_setvar_append() { _var_delim_list_cmd delim_set_append "$@"; }
