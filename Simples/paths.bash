#!/bin/bash

# J. Greg Davidson
# Support for environment path variables

# Copyright (c) 1992, 2021 J. Greg Davidson. This work is licensed under a
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

# pathvar_dedup_array input output
# warning: modifies output!
pathvar_dedup_array() {
    local -n input="$1"
    local -n output
    local -A count
    local x
    for x in "${input[@]}"; do (( count["$x"]++ )) || output+=("$x"); done
}
export -f pathvar_dedup_array

# pathvar_dedup path-variable
# deduplicate : separated path
# warning: modifies variable!
pathvar_dedup() {
    local -n path="$1"
    local -a input
    local -a output
    split_array_delim_str input : path
    pathvar_dedup_array input output
    path=$(join_delim_args : "${output[@]}")
}
export -f pathvar_dedup

# help test | grep '^ *-. *FILE'
# echo [$(help test | sed -n 's/^ *-\(.\) FILE .*/\1/p' | tr -d '\n')]
# [abcdefghLkprsSuwxOGN]
# test_to hash arg
test_to() {
    local -n a="$1"; shift
    [[ "$1" == [abcdefghLkprsSuwxOGN] ]] || {
        >&2 echo "test_to error: Unrecognized test $*"
        return 1
    }
    a[test]="test -$1"
}
export -f test_to

# test_from hash arg
# evaluate [test] expression with arg
test_from() {
    local -n a="$1"
    eval "${a[test]} $2"
}
export -f test_from

pathvar_add_usage='pathvar_add VAR-NAME [ -{OPTIONS}... item... ]...'
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
  -v		-- write result back to shell var
  -V		-- write result to environment var
  --dedup=[no|silent|warn|fail]	-- deduplication policy
  --test=expr	-- eval "$expr $item" || skip item
  --skip=[silent|warn|fail]	-- skip policy
  --sep=X	-- use character X instead of default :
  --dots=[no|ok|end] policy on . items in path
'
pathvar_add_purpose='add new components to a PATH-like variable'
pathvar_add_version='$Id$'

enum_set error-array array key given-value allowed_value...
enum_set() {
    local -n e="$1"
    local -n a="$2"
    local k="$3" v="$4"; shift 4
    for x; do
        [[ "$v" == $x ]] && {
            a[$k]="$v" ; return 0
        }
    done
    e+=("no $k option of $v")
    return 1 
}

# Update associative array of current options
# pathvar_add_opt associative-array-name arguments
# at least the first argument should start with 
# returns number of arguments to skip
# pathvar_add_opt error_array settings_array
pathvar_add_opt(
    local -n e="$1"; shift
    local -n a="$1"; shift
    case "$1" in
        (--version) echo "Version: $pathvar_add_version"; return 0 ;;
        (--usage) echo "Usage: $pathvar_add_usage"; return 0 ;;
        (--help) echo -n "$pathvar_add_usage$pathvar_add_options"; return 0 ;;
        (--sep=?) a[sep]="${1#*=}"; return 0 ;;
        (--dots) enum_set e a dots "${1#*=}" no ok end; return 0 ;;
        (--test=) unset a[test]; return 0 ;;
        (--test=*) set a[test]="${1#*=}"; return 0 ;;
        (--dedup=) enum_set e a dedup "${1#*=}" no silent warn fail;;
        (--skip=) enum_set e a skip "${1#*=}" silent warn fail;;
        (-*) OPTIND=0
             while getopts ":az.efdWD:E" myopt;  do
                 case "$myopt" in
                     (a) a[a]=1 ;;
                     (z) a[a]=0 ;;
                     (e) test_to a e ;;
                     (E) test_to a e ; a[warn]=1 ;;
                     (f) test_to a f ;;
                     (F) test_to a f ; a[warn]=1 ;;
                     (d) test_to a d ;;
                     (D) test_to a d ; a[warn]=1 ;;
                     (s) a[strict]=1 ;;
                     (S) a[strict]=0 ;;
                     (w) a[warn]=1 ;;
                     (W) a[warn]=0 ;;
                     (v) a[var]=0 ;;
                     (V) a[env]=0 ;;
                     ('?') e+("Bad option $myopt; usage: $pathvar_add_usage")
                           return 1 ;;
                 esac
             done ; return 0 ;;
        *)	e+=("no option(s) $1"); return 1 ;;
    esac
)

# initialize pathvar_add options
pathvar_add_option_init() {
    local -a e
    local -n a="$1"
    for o in -zw; do 
        pathvar_add_opt e a "$o"
    done
}

pathvar_error() {
    local -n c="1"
    local -n e="$2"
    shift 2
    let ++c
    e+=("error: $*")
}

pathvar_warn() {
    local -n e="$2"; shift
    e+=("warning: $*")
}

function pathvar_add {
    local fn_name='pathvar_add'
    local path_var_name="$1"
    local -n path_var="$1" ; shift
    local -a e                  # error messages
    local -A a;                 # current options
    local -a before             # items to add in front
    local -a after              # items to add at end
    local -a input              # items before deduping
    local -a output             # items after deduping
    local x result err_cnt=0 dot_cnt=0
    pathvar_add_option_init a
    for item; do
        case "$item" in
            (-*) path_add_opt e a "$item" ;;
            (*) if ! test_from a "$item"; then
                    x="${a[test]} $item is false"
                    if (( ${a[strict]} )); then
                        pathvar_error err_cnt e "$x"
                    elif (( ${a[warn] })); then
                        pathvar_warn e "$x"
                    fi
                else
                    if [[ "{a[dots]}" != ok ]] && [[ "$item]" == . ]]; then
                        let ++dot_cnt
                    elif (( a{[a]} )); then
                        before+=("$item")
                    else
                        after+=("$item")
                    fi
                fi
        esac
    done
    local -a middle
    split_array_delim_str middle "${a[sep]}" "$path_var"
    [[ "{a[dots]}" != ok ]] && (( ${#middle[@]} )) && [[ "${middle[-1]}" == . ]] {
        let ++dot_cnt
        unset middle[-1]
    }
    input=( "${before[@]}" "${middle[@]}"   "${after[@]}"  )
    [[ "{a[dots]}" == end ]] && (( dot_cnt )) &&
        input+=('.')
    if [[ ${a[dedup]} == no ]]
    then output=( "${input[@]}" )
    else pathvar_dedup_array input output
    fi
    (( ${#input[@]} !=  ${#output[@]} )) && {
        x="found duplicates"
        [[ ${a[dedup]} == fail ]] && pathvar_error err_cnt e "x"
        [[ ${a[dedup]} == warn ]] && pathvar_warn e "x"
    }
    # Output any errors or warnings
    for x in "${e[@]}"; do
        >&2 printf "%s %s\n" "$fn_name" "$x"
    done
    (( err_cnt )) && {
        >&2 printf "Exiting with %d errors!\n" "$err_cnt"
        exit 2
    }
    result=$( join_delim_args "${a[sep]}" "${output[@]}" )
    (( a{[var]} )) && path_var="$result"
    (( a{[env]} )) && export path_var="$result"
    ! (( a{[var]} )) && ! (( a{[env]} )) && printf "%s\n" "$result"
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
