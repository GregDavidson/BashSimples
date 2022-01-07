### add a few more features from misc.sh

# J. Greg Davidson
# Copyright (c) 1992, 1993 Virtual Infinity Systems.  All rights reserved.
# rewritten in January 2008 to make use of simple_delim_lists

# Requires simples package.

# dir_add DIR_PATH [-a|-z|DIR]...
# adds DIR to colon-delimited DIR_PATH list
# -a means prepend, -z means append (the default)
dir_add() {
  dir_add_append=true
  dir_add_path="$1"; shift
  for dir_add_dir; do
    case "$dir" in
    -a) dir_add_append=true ;;
    -z) dir_add_append=false ;;
    *:*) simple_msg "dir_add error: Colons forbidden ($dir_add_dir)" ;;
    *) if [ ! -d "$dir" ] ; then
	 simple_msg "dir_add error: No directory $dir"
       elif $dir_add_append
	 simple_delim_list_append : "$dir_add_path" "$dir_add_dir"
       else
	 simple_delim_list_prepend : "$dir_add_path" "$dir_add_dir"
       fi
    esac
  done
  eval "export \"$dir_add_path\""
}

path_add() { dir_add PATH "$@"; }
man_path_add() { dir_add MANPATH "$@"; }
lib_path_add() { dir_add LD_LIBRARY_PATH "$@"; }
