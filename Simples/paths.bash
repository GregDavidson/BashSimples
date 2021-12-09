#!/bin/bash

# J. Greg Davidson
# Support for environment path variables

# Copyright (c) 1992, 1993 J. Greg Davidson. This work is licensed under a
# Creative Commons Attribution 4.0 International License
# http://creativecommons.org/licenses/by/4.0.

# See WISHLIST at bottom

# Requires simples package.

# New Bash scripting technique (borrowed from TCL):
# Unite related functions via aliased variables, especially arrays!

# Move some of the utility functions here to simples.bash??

# It really requires * instead of @ - sigh!
join_delim_args() {
    local IFS="$1"; shift; echo "$*"
}
export -f join_delim_args

# split_array_delim_str array_name 1-char-delim delimited-string
# split a string into array elements by a 1-character delimiter
split_array_delim_str() {
    local -n array="$1"   
    IFS="$2" read -a array <<< "$$3"
}
export -f split_array_delim_str 

# pathvar_dedup path-variable
# deduplicate : separated path
# warning: modifies variable!
pathvar_dedup() {
    local -n path="$1"
    local -a input
    local -a output
    local -A count
    split_array_delim_str input : path
    for x in "${input[@]}"; do (( count["$x"]++ )) || output+=("$x"); done
    path=$(join_delim_args : "${output[@]}")
}
export -f pathvar_dedup

# help test | grep '^ *-. *FILE'
# echo [$(help test | sed -n 's/^ *-\(.\) FILE .*/\1/p' | tr -d '\n')]
# [abcdefghLkprsSuwxOGN]
# pathvar_add_test hash arg
pathvar_add_test() {
    local -An a="$1"; shift
    [[ $# == 1 ]] && [[ "$1" == [abcdefghLkprsSuwxOGN] ]] || {
        >&2 echo "pathvar_add_test error: Unrecognized test $*"
        return 1
    }
    a[test]='test -'"$1"
}
export -f pathvar_add_test

# pathvar_add_testit hash arg
# evaluate [test] expression with arg
pathvar_add_testit() {
    local -An a="$1"
    eval "${a[test]} $2"
}
export -f pathvar_add_testit

pathvar_add_usage='pathvar_add VAR [-az] [-efdW] [-D delim] [-E] item...'
pathvar_add_options='
	-a		-- add at beginning
	-z		-- add at end (the default)
	-e		-- following items exist or item skipped
	-E		-- same with warning
	-f		-- following items exist as regular files or item skipped
	-F		-- same with warning
	-d		-- following items exist as directory or item skipped
	-D		-- same with warning
	-s		-- strict: any skip becomes transaction failure
	-S		-- unstrict: back to silent or warning
	-w		-- warn and unstrict: any skip generates a warning
	-W		-- unwarn and unstrict: back to silent skipping
  -V		-- do NOT export variable to the environment
  --dedup=[no|silent|warn|fail]	-- deduplication policy
  --test=expr	-- eval "$expr $item" || skip item
  --skip=[silent|warn|fail]	-- skip policy
  --sep=X	-- use character X instead of default :
  --dots -- . not special, default: . only allowed at end
'
pathvar_add_purpose='add new components to a PATH-like variable'
pathvar_add_version='$Id$'

# Update associative array of current options
# pathvar_add_opt associative-array-name arguments
# at least the first argument should start with 
# returns number of arguments to skip
pathvar_add_opt(
    local -An a="$1"; shift
    case "$1" in
        --version) echo "Version: $pathvar_add_version"; return 0 ;;
        --usage) echo "Usage: $pathvar_add_usage"; return 0 ;;
        --help) echo -n "$pathvar_add_usage$pathvar_add_options"; return 0 ;;
        --sep=?) a[:]="${1##--sep=}"; return 1 ;;
        --dots) a[.]=0; return 1 ;;
        --notest) unset a[e]; return 1 ;;
        --nodedup) a[nodedup]=1 ;;
        -*) OPTIND=0
            while getopts ":az.efdWD:E" myopt;  do
                case "$myopt" in
                    a) a[a]=1 ;;
                    z) a[a]=0 ;;
                    e) pathvar_add_test a e ;;
                    E) pathvar_add_test a e ; a[warn]=1 ;;
                    f) pathvar_add_test a f ;;
                    F) pathvar_add_test a f ; a[warn]=1 ;;
                    d) pathvar_add_test a d ;;
                    D) pathvar_add_test a d ; a[warn]=1 ;;
                    s) a[strict]=1 ;;
                    S) a[strict]=0 ;;
                    w) a[warn]=1 ;;
                    W) a[warn]=0 ;;
                    V) a[export]=variable ;;
                    '?')	>&2 echo "Bad option $myopt; usage: $pathvar_add_usage" ; return 1 ;;
                esac
            done ; return 0 ;;
        *)	>&2 echo "Error: pathvar_add_opt $1" ; return 1 ;;
    esac
)

# initialize pathvar_add options
pathvar_add_opt_init() {
    local -An a="$1"
    for o; do 
        pathvar_add_opt a "$o"
    done
}
pathvar_add_opt_init -adw

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
