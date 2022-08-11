#!/bin/sh
# ~/.profile - login preferences for sh compatible shells

# Now that so many login systems are using dash instead of bash or zsh
# we need to get back to the basics for these essentials.
# Everything here should work with any of these shells.

# We define some generic functions in this script
# then source some local scripts to actually set things up

# Our configuration could "inherit" from a "super" one
# Local scripts could be under $super or under $HOME
sh_local=".profile.sh"
sh_local_dir=".sh.d"

# Intended for use by if_src_super
# Try sourcing "$1"
# If it exists and we succeed, add it to $if_src_list
if_src_one() {
  [ -f "$1" -a -r "$1" ] || return 1
  . "$1"
  if_src_list="${if_src_list:+$if_src_list:}$1"
  return 0
}

# Intended for use by if_src
# Using if_src_one
#		Try sourcing $1 if it's an absolute path
#		otherwise try $super/$1 and $HOME/$1
# Succeed iff we source at least one
if_src_super() {
  case "$1" in
    /*) if_src_one "$1" ; return $? ;;
  esac
	[ -d "$super" ] && if_src_one "$super/$1"
  if_src_super_status="$?"
  if_src_one "$HOME/$1" || return $if_src_super_status
}

# if_src SCRIPT...
# Try sourcing the specified scripts under $super and/or $HOME.
# Return 0 iff at least one file is successfully sourced.
# Report if no files are successfully sourced.
if_src() {
  if_src_list=''
  for f; do if_src_super "$f"; done
	[ -n "$if_src_list" ] && return 0
  >&2 echo "if_src: no file(s) $*" 
  return 1
}

# Determine our machine architecture, if possible
# because some things in Bin directories are
# binaries compiled for specific architectures!
if type -p arch >/dev/null      # do we have the arch program?
then arch=`arch`
elif type -p uname >/dev/null   # or do we have the uname program?
then arch=`uname -m`            # hope it has the -m option!
else arch='any'                 # really the default when no suffix anyway
fi

# path_list [-TEST] EXISTING_PATH MAYBE_NEW_ITEM...
# Return a colon-separated list of items
# if they pass [ -TEST ] and are not already present.
# man test | grep '^ *-. ' | grep FILE | sort
path_list() {
# >&2 echo "path_list $@"
# set -xv
    path_list_test='-n'        # any non-empty value will do
    path_list_append='false'
    path_list_delim=':'
    while case "$1" in
	-[bcdefgGhkLOprsSuwx]) path_list_test="$1" ;;
	-a) path_list_append='true' ;;
	-?) >&2 echo "path_list warning: unknown option $1" ;;
	*) break ;;
    esac; do
# >&2 echo "path_list: got option $1"
shift; done
    path_list_items="$1"; shift
# >&2 echo "path_list: Initial path_list_items=$path_list_items"
    for path_list_item; do
        [ "$path_list_test" "$path_list_item" ] &&
            case ":$path_list_items:" in
                *":$path_list_item:"*) ;; 
                *)
if $path_list_append
then path_list_items="$path_list_items:$path_list_item"
     # >&2 echo "path_list: appending $path_list_item"
else path_list_items="$path_list_item:$path_list_items"
     # >&2 echo "path_list: prepending $path_list_item"
fi ;;
            esac
    done
    echo "$path_list_items"
# set +xv
}

path_add () { PATH=$(path_list -d "$PATH" "$@"); export PATH ; }

# We store some of our collections of legacy software and some of the fancy
# software packages which we've built from source in their own directories which
# have subdirectories which need to be added to appropriate path variables
# before we can use them.
collection_add() {
    for ddd; do
        [ -d "$ddd" ] && for dd in "$ddd"/*; do
            [ -d "$dd" ] && for d in "$dd"/*; do
                [ -d "$d" ] && case "$d" in
                    */[Bb]in|*/[Bb]in-"$arch") PATH=$(path_list "$PATH" "$d") ;;
                    */[Ii]nfo) INFOPATH=$(path_list "$INFOPATH" "$d") ;;
                    */site-lisp) EMACSLOADPATH=$(path_list "$EMACSLOADPATH" "$d") ;;
                    */Tcl) TCLLIBPATH=$(path_list "$TCLLIBPATH" "$d") ;;
                    */JVM) CLASSPATH=$(path_list -f "$CLASSPATH" $(find "$d/JVM" -name '*.jar' -print))
                    # Do you need to manage other kinds of paths?

                    # Run: env | cut -d= -f1 | grep PATH
                esac
            done
        done
    done
}

# OK, now let's do what is desired locally
if [ -n "$super" ]; then
    if_src "$sh_local" $super/$sh_local_dir/* $HOME/$sh_local_dir/*
else
    if_src "$sh_local" $HOME/$sh_local_dir/*
fi

