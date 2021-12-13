#!/bin/bash

# * Simples paths.bash

# J. Greg Davidson
# Support for environment path variables

# Copyright (c) 1992, 2021 J. Greg Davidson. This work is licensed under a
# Creative Commons Attribution 4.0 International License
# http://creativecommons.org/licenses/by/4.0.

# See IMPLEMENTATION NOTES at bottom
# See WISHLIST at bottom

# Requires simples package.

# New Bash scripting technique (borrowed from TCL):
# Unite related functions via aliased variables, especially arrays!

# ** Somewhat General Purpose Functions

# Move some of the utility functions here to simples.bash??

# error_accum error_count message_array message...
# Increment count and append message to array
error_accum() {
    local -n error_accum_count="$1"
    local -n error_accum_msgs="$2"
    shift 2
    let ++error_accum_count
    error_accum_msgs+=("error: $*")
}

# warn_accum message_array message...
# Append message to array
warn_accum() {
    local -n warn_accum_msgs="$1"; shift
    warn_accum_msgs+=("warning: $*")
}

# enum_set count message_array hash key given-value allowed_value...
enum_set() {
    local -n enum_set_count="$1"
    local -n enum_set_msgs="$2"
    local -n enum_set_array="$3"
    local k="$4" v="$5" ; shift 5
    local x ; for x; do
        [[ "$v" == $x ]] && {
            enum_set_array[$k]="$v" ; return 0
        }
    done
    let ++enum_set_count
    enum_set_msgs+=("no $k option of $v")
    return 1 
}

# Bash requires * here instead of @!
join_delim_args() {
    local IFS="$1"; shift; echo "$*"
}
export -f join_delim_args

# split_array_delim_str array_name 1-char-delim string
# Split string into array elements by given delimiter
split_array_delim_str() {
    local -n split_array_delim_str_array="$1"   
    IFS="$2" read -a split_array_delim_str_array <<< "$3"
#    IFS="$2" read -a $!1 <<< "$3"
}
export -f split_array_delim_str 

# dedup_array input_array output_array
# warning: replaces output_array!
dedup_array() {
    local -n dedup_array_input="$1"
    local -n dedup_array_output="$2"
    local -A counts
    local x
    dedup_array_output=( )
    for x in "${dedup_array_input[@]}"; do
        (( counts["$x"]++ )) || dedup_array_output+=("$x")
    done
}
export -f dedup_array

# pathvar_dedup path-variable
# deduplicate : separated path
# warning: modifies variable!
pathvar_dedup() {
    local -n pathvar_dedup="$1"
    local -a input
    local -a output
    split_array_delim_str input : pathvar_dedup
    dedup_array input output
    pathvar_dedup=$(join_delim_args : "${output[@]}")
}
export -f pathvar_dedup

# test_to error_cnt msg_array hash arg
# hash[test]=arg
# where arg is a single letter valid flag for Bash test
# $ help test | grep '^ *-. *FILE'
# $ echo [$(help test | sed -n 's/^ *-\(.\) FILE .*/\1/p' | tr -d '\n')]
test_to() {
    local -n test_to_cnt="$1"
    local -n test_to_msgs="$2"
    local -n test_to_opts="$3"; shift 3
    [[ "$1" == [abcdefghLkprsSuwxOGN] ]] || {
        error_accum test_to_cnt test_to_msgs "invalid test_to $*"
        return 2
    }
    test_to_opts[test]="test -$1"
}
export -f test_to

# test_from hash arg
# evaluate hash[test] with arg
test_from() {
    local -n test_from="$1"
    eval "${test_from[test]} $2"
}
export -f test_from

# ** pathvar_add helper functions

pathvar_add_usage='VAR-NAME [OPTIONS|ITEM]...'
pathvar_add_purpose='add new components to a PATH-like variable'
pathvar_add_options='
	-a # add at beginning
	-z # add at end (the default)
	-e # following items exist or item skipped
	-E # same with warning
	-f # following items exist as regular files or item skipped
	-F # same with warning
	-d # following items exist as directory or item skipped
	-D # same with warning
	-s # strict: any skip becomes transaction failure
	-S # unstrict: back to silent or warning
	-w # warn and unstrict: any skip generates a warning
	-W # unwarn and unstrict: back to silent skipping
	-v # write result back to shell var
	-V # write result to environment var
	--sep=X  # use character X instead of default :
	--test=expr  # eval "$expr $item" || skip item
	--dots=[no|ok|end]  # policy on '.' items
	--skip=[silent|warn|fail]  # skip policy
	--dedup=[no|silent|warn|fail]  # deduplication policy
'
pathvar_add_version='$Id$'

# pathvar_add_opt err_cnt msg_array option_hash option_arg
# Update associative array of current options.
# The option_arg should either be
#    -- followed by a long option
#    - followed by (possibly multiple) single letter option(s)
# Returns 1 if processing should stop, 0 if processing should continue
pathvar_add_opt() {
    local -n c="$1"; shift
    local -n m="$1"; shift
    local -n o="$1"; shift
    >&2 echo "path_add_opt: $1"
    case "$1" in
        (--version) echo "Version: $pathvar_add_version"
                    return 1 ;;
        (--usage) printf 'Usage: %s %s\n' "${o[fn_name]}" "$pathvar_add_usage" 
                  return 1 ;;
        (--help)
            printf 'Usage: %s %s\n' "${o[fn_name]}" "$pathvar_add_usage" 
            printf 'Purpose: %s\n' "$pathvar_add_purpose" 
            printf 'Options:%s' "$pathvar_add_options"
            return 1 ;;
        (--sep=?) o[sep]="${1#*=}"
         return 0 ;;
        (--dots=*) enum_set c m o dots "${1#*=}" no ok end
                   return 0 ;;
        (--test=*) unset o[test]
                   return 0 ;;
        (--test=*) set o[test]="${1#*=}"
                   return 0 ;;
        (--dedup=*) enum_set c m o dedup "${1#*=}" no silent warn fail
                    return 1 ;;
        (--skip=*) enum_set c m o skip "${1#*=}" silent warn fail
                   return 1 ;;
        (--*) error_accum c m No long option "$1"
              return 1 ;;
        (-*) OPTIND=0  OPTERR=0
             while getopts "azeEfFdDsSwWvV" myopt "$1";  do
                 case "$myopt" in
                     (a) o[a]=1 ;;
                     (z) o[a]=0 ;;
                     (e) test_to c m o e ;;
                     (E) test_to c m o e ; o[warn]=1 ;;
                     (f) test_to c m o f ;;
                     (F) test_to c m o f ; o[warn]=1 ;;
                     (d) test_to c m o d ;;
                     (D) test_to c m o d ; o[warn]=1 ;;
                     (s) o[strict]=1 ;;
                     (S) o[strict]=0 ;;
                     (w) o[warn]=1 ;;
                     (W) o[warn]=0 ;;
                     (v) o[var]=1 ;;
                     (V) o[env]=1 ;;
                     ('?') error_accum c m "No option -$OPTARG";;
                 esac
             done ;;
        *) error_accum c m "no option(s) $1" ;;
    esac
    return 0
}

# ** pathvar_add

# pathvar_add is not really supposed to be called directly.
# Instead create wrapper functions as in Porcelain below.

# pathvar_add path_string_var option-hash options-and-items...
function pathvar_add {
    # pva_* variables passed by name and received with -n!
    local path_var_name="$1"
    local -n pva_path_str="$1"  # path as delimited string
    local -n pva_options="$2";  # options as we go along
    shift 2
    local fn_name="${pva_options[fn_name]:-pathvar_add}"
    declare -g pva_nerrs=0      # error count
    declare -ga pva_msgs=( )    # error and warning messages
    local -a before             # items to add in front
    declare -ga pva_middle      # for original items
    local -a after              # items to add at end
    declare -ga pva_input       # all items before deduping
    declare -ga pva_output      # remaining items after deduping
    local item option_arg x result dot_cnt=0
    for item; do
        case "$item" in
            (-*) pathvar_add_opt pva_nerrs pva_msgs pva_options "$item" ||
                       return 2
                 # uncomment for debug tracing:
                 >&2 declare -p "${!pva_options}"
                 ;;
            (*) if ! test_from pva_options "$item"; then
                    x="${pva_options[test]} $item is false"
                    if (( ${pva_options[strict]} )); then
                        error_accum pva_nerrs pva_msgs "$x"
                    elif (( ${pva_options[warn] })); then
                        warn_accum pva_msgs "$x"
                    fi
                else
                    if [[ $"{pva_options[dots]}" != ok ]] && [[ "$item" == . ]]; then
                        let ++dot_cnt
                    elif (( ${pva_options[a]} )); then
                        before+=("$item")
                    else
                        after+=("$item")
                    fi
                fi
        esac
        # uncomment for debug tracing:
        >&2 declare -p pva_msgs
    done
    split_array_delim_str pva_middle "${pva_options[sep]:-:}" "$pva_path_str"
    >&2 declare -p before
    >&2 declare -p pva_middle
    >&2 declare -p after
    [[ "${pva_options[dots]}" != ok ]]&&(( ${#pva_middle[@]} ))&&[[ "${pva_middle[-1]}" == . ]]&&{
        let ++dot_cnt
        unset pva_middle[-1]
    }
    pva_input=( "${before[@]}" "${pva_middle[@]}"   "${after[@]}"  )
    [[ "${pva_options[dots]}" == end ]] && (( dot_cnt )) &&
        input+=('.')
    if [[ "${pva_options[dedup]}" == no ]]
    then pva_output=( "${pva_input[@]}" )
    else dedup_array pva_input pva_output
    fi
    (( ${#pva_input[@]} !=  ${#pva_output[@]} )) && {
        x="found duplicates"
        [[ ${pva_options[dedup]} == fail ]] && error_accum pva_nerrs pva_msgs "x"
        [[ ${pva_options[dedup]} == warn ]] && warn_accum pva_msgs "x"
    }
    # Pva_Output any error or warning messages
    for x in "${pva_msgs[@]}"; do
        >&2 printf "%s %s\n" "$fn_name" "$x"
    done
    (( pva_nerrs )) && {
        >&2 printf "Aborting with %d errors!\n" "$pva_nerrs"
        return 1
    }
    result=$( join_delim_args "${pva_options[sep]:-:}" "${pva_output[@]}" )
    (( ${pva_options[var]} )) && pva_path_str="$result"
    (( ${pva_options[env]} )) && export pva_path_str="$result"
    ! (( ${pva_options[var]} )) && ! (( ${pva_options[env]} )) && printf "%s\n" "$result"
    (( $export )) && export "$var"
}

# ** Porcelain for pathvar_add

path_add() {
    declare -gA path_add_options=( [fn_name]="path_add")
    pathvar_add PATH path_add_options --dots=end -zDV "$@"
}
manpath_add() {
    declare -gA path_add_options=( [fn_name]="manpath_add")
    pathvar_add MANPATH manpath_add_options --dots=no -zDV "$@"
}
infopath_add() {
    declare -gA path_add_options=( [fn_name]="infopath_add")
    pathvar_add INFOPATH manpath_add_options --dots=no -zDV "$@"
}
libpath_add() {
    declare -gA path_add_options=( [fn_name]="libpath_add")
    pathvar_add LD_LIBRARY_PATH libpath_add_options --dots=no -zDV "$@"
}

export -f pathvar_add path_add manpath_add libpath_add

# make viewing paths easier

pathvar_show_() { echo "${!1}" | tr : '\012' | sed "s:^$HOME:\~:"; }

pathvar_show() {
  case $# in
    1) pathvar_show_ $1 | fmt ;;
    2) pathvar_show_ $1 | pr -$2 -t ;;
    *) usage "pathvar_show pva_path_str [ columns ]" ;;
  esac
}

path_show() { pathvar_show PATH; }
manpath_show() { pathvar_show MANPATH; }
libpath_show() { pathvar_show LD_LIBRARY_PATH; }

export -f pathvar_show_ pathvar_show path_show manpath_show libpath_show

# ** END NOTES

# *** IMPLEMENTATION NOTES

# This was to be my first Bash Script to make good use of the relatively new
# =local -n=...= feature which was inspired by ksh's =nameref=. Alas, the Bash
# =-n= feature is horribly broken. The variable name passed by the caller will
# conflict with any variable of the same name in the receiver!!! Still, given
# Bash, =-n= is really the only reasonable way to pass arrays, so we're just
# going to have to make all of the variable names which are being passed unique.
# The best way to do that is to prefix them with the name of their functions.
# The receiving names can be short.

# *** WISHLIST

# Adapting to Wrapper Functions
## Wrapper function could pass its name to pathvar_add
## As part of the initial option hash!
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
