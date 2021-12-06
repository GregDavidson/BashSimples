#!/bin/bash

# J. Greg Davidson
# Support for environment path variables

# Copyright (c) 1992, 1993 J. Greg Davidson. This work is licensed under a
# Creative Commons Attribution 4.0 International License
# http://creativecommons.org/licenses/by/4.0.

# See WISHLIST at bottom

# Requires simples package.

pathvar_add_usage='pathvar_add VAR [-az] [-efdW] [-D delim] [-E] item...'
pathvar_add_options='
	-a		-- add at the beginning
	-z		-- add at the end (the default)
	-.		-- let there be at most 1 . at the end
	-e		-- require that item exists on this file system
	-f		-- require that item exists as an ordinary file
	-d		-- require that item exists as a directory
	-W		-- warn if existence check fails
        -D delim	-- use delim instead of default : delimiter
        -E		-- do NOT export variable to the environment
'
pathvar_add_purpose='add new components to a PATH-like variable'
pathvar_add_version='$Id$'
# BUG: if something doesn't exist, it will trigger warnings
# and elisions on subsequent valid items!!!
# 10:02 p.m., Sunday, 5 December 2021 -jgd
function pathvar_add {
    # process any help options
    local arg
    for arg; do
        case "$arg" in
            --version) echo "Version: $pathvar_add_version"; return 0 ;;
            --usage) echo "Usage: $pathvar_add_usage"; return 0 ;;
            --help) echo -n "$pathvar_add_usage$pathvar_add_options"; return 0 ;;
        esac
    done
    # fetch the path variable and its current value (if any)
    if ! match_simple_re "$simple_name_re" "$1"; then
        >&2 echo "Usage: $pathvar_add_usage" ; return 1
    fi
    local -r var="$1" ; val="${!1-}" ; shift
    # process any options
    local delim=':' append=1 fix_dot=0 tests='' warn=0 export=1
    OPTIND=0 ; while getopts ":az.efdWD:E" myopt;  do 
                   case "$myopt" in
                       [def])	tests+=" $myopt" ;;
                       a)	append=0	;;		z)	append=1	;;
                       E)	export=0	;;		W)	warn=1		;;
                       .)	fix_dot=1	;;		D)	delim=OPTARG	;;
                       '?')	>&2 echo "Usage: $pathvar_add_usage" ; return 1 ;;
                   esac    
               done ; shift $(( $OPTIND - 1 ))
    # process the items to add
    local item item_test item_ok=1
    for item; do
        for item_test in $tests; do
            [ -$item_test "$item" ] || item_ok=0
        done
        if (( ! $item_ok )); then
            (( $warn )) && simple_msg "pathvar_add: $item not found"
        elif [ -z "$val" ]; then
            val="$item"
        elif in_simple_delim_list "$delim" "$val" "$item"; then
            :
        elif (( $append )); then
            val="$val$delim$item"
        else
            val="$item$delim$val"
        fi
    done
    if (( $fix_dot )) && in_simple_delim_list "$delim" "$val"X '.'; then
        val="${val/#$delim.$delim/}" # delete any initial .
        val="${val//$delim.$delim/$delim}" # delete any intermediate .'s
        in_simple_delim_list "$delim" "$val" '.' ||
            val="$val$delim."
    fi
    simple_set "$var" "$val"
    (( $export )) && export "$var"
}

path_add() { pathvar_add PATH -d. "$@" ; }
manpath_add() { pathvar_add MANPATH -d. "$@" ; }
libpath_add() { pathvar_add LD_LIBRARY_PATH -d. "$@" ; }

export -f pathvar_add path_add manpath_add libpath_add

# make viewing paths easier

pathvar_show_() { echo "${!1}" | tr : '\012' | sed "s:^$HOME:\~:"; }

pathvar_show() {
  case $# in
    1) pathvar_show_ $1 | fmt ;;
    2) pathvar_show_ $1 | pr -$2 -t ;;
    *) usage "pathvar_show path_var [ columns ]" ;;
  esac
}

path_show() { pathvar_show PATH; }
manpath_show() { pathvar_show MANPATH; }
libpath_show() { pathvar_show LD_LIBRARY_PATH; }

export -f pathvar_show_ pathvar_show path_show manpath_show libpath_show

# WISHLIST

# deleting items
## a function to delete a given path component if it exists
## a function to delete all path components patching a pattern
# item order
## order of multiple items in argument list same in path
# an option to add a new dir before/after a given component/pattern
# an option to add a new dir just after my own dirs
# master paths
## can contain tags and comments
## can have hierarchical structures
## derived paths are constructed from master paths
# super master paths
## multiple paths, e.g. bin, man, lib, etc. generated from one master
# bash 4.0
## make any simplifications possible
