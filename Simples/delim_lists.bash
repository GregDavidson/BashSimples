# delim_lists.bash
# simple lists, sets, maps as delimited lists

# Copyright (c) 2008 J. Greg Davidson. This work is licensed under a
# Creative Commons Attribution 4.0 International License
# http://creativecommons.org/licenses/by/4.0.

# Simple lists and sets as strings for shells lacking
# arrays and/or hashes.

# builds on simple_delim_lists

delim_var() {	# DELIMITER VAR [ITEM]
    simple_set "${2}__delim" "$1"
    simple_set "$2" "${3-}"
}

_delim_list_cmd() {	# COMMAND LISTVAR ARGS...
    local -r v="{$2}__delim"
    case "${!v}" in
      	'') simple_exitor 1 delim_list_cmd -- "No delimiter for $2."
    esac
    "$1" "${!v}" "${!2}" "${@:3}"
}

_var_delim_list_cmd() {        # COMMAND LISTVAR ARGS...
    simple_set "$2" "`_delim_list_cmd \"$@\"`"
}

in_delim_listvar() { _delim_list_cmd in_simple_delim_list "$@"; }
ni_delim_listvar() { _delim_list_cmd ni_simple_delim_list "$@"; }
delim_listvar_prepend() { _var_delim_list_cmd simple_delim_list_prepend "$@"; }
delim_listvar_append() { _var_delim_list_cmd simple_delim_list_append "$@"; }
delim_setvar_prepend() { _var_delim_list_cmd simple_delim_set_prepend "$@"; }
delim_setvar_append() { _var_delim_list_cmd simple_delim_set_append "$@"; }
