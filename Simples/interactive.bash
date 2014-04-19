# where: $HOME/.kbashrc
#  what: Korn or Bourne Again SHell customization script
#   who: J. Greg Davidson
#  when: April 1996

# Copyright (c) 1996 J. Greg Davidson. This work is licensed under a
# Creative Commons Attribution 4.0 International License
# http://creativecommons.org/licenses/by/4.0.

ifsrc() { [ -f $1 ] && . $1; }		# source a file if it exists
get_env() {  eval "echo \$$1" ; }	# get_env var - get value of var
set_env() { eval "export $1=$2" ; }	# set_env var value - set var to value
function stderr { echo "$*" >&2;  }	# send a message to the standard output
function error { stderr "Error: $*"; }
function usage { stderr "Usage: $*"; }

function lsd { ps ax | awk '$2=="?"{print $5}' | tr -d '[]' | sort -u | fmt; }

[[ -n "$(type -p less)" ]] && alias more='less'

for program in gvim vim v; do
    [[ -n "$(type -p "$program")" ]] && alias v="$program" && break
done

function l {
    case $# in
	(0) ls ;;
	(1) case $(file "$1") in
	    ('*text*') less "$1" ;;
	    (*) ls "$1" ;;
	    esac ;;
        (*) ls "$@" ;;
    esac
}

case "$OSTYPE" in
    (*[Ll]inux*|*[Gg][Nn][Uu]*)
    export LS_OPTIONS='-bBCF'
    case "$TERM" in
	(emacs|dumb) ;;
	(*) export LS_OPTIONS="$LS_OPTIONS --color=auto" ;;
    esac ;;
esac
    
case "$TERM" in
    (emacs|dumb) export PAGER="ul -i" MANPAGER="ul -i" ;;
esac

function ll { l -bCF "$@" ; }
function lll { l -blF --color=never "$@" | ${PAGER:-less}; }

# here are some useful functions for pathnames

path_head() {   # / -> "",  /x -> /,  x/y/z -> x/y,  x -> .
  if [ "/" = "$1" ] ; then
	echo ""
  else
	expr  "$1" : '\(/\)[^/]*$'  '|'  "$1" : '\(.*\)/.*'  '|'  .
  fi
}

path_tail() {   # / -> "",  x/ -> "",  /x -> x,  x/y/z -> z,  x -> x
  if expr  x"$1" : x'[^/]*/$'  >/dev/null ; then
	echo ""
  else
	expr  "$1" : '.*/\(.*\)'  '|'  "$1"
  fi
}

# Have cd update visible hostnames and current directories
HOSTNAME=${HOSTNAME:-`hostname`}
PS1_base=${PS1_base:-'\! $ '}
PS1="$PS1_base"

# Note: the echo features used in show_dir are in the builtin
# ksh echo but not the builtin bash echo.  Check that /bin/echo
# has these features (octal escapes and \c) or rewrite this code!
show_parent=$(path_head $HOME)
show_shell=$(path_tail $SHELL)
show_dir() {	# put wd in title, status line or prompt
show_wd=$(expr "$PWD" : "$show_parent/\(.*\)" "|" "$PWD")
case "$TERM" in
# Ideally, show updates window titles or status lines:
  dtterm|xterm|nxterm|xterm-color)
	/bin/echo -en '\033]0;'"$HOSTNAME: $show_wd "'\07' ;;
# But in a pinch, it can put things in my prompt:
  *)	PS1="$show_wd $PS1_base "	;;
esac
}
alias cd=show_cd
show_cd() { 'cd' "$@" ; show_dir ; }

# Make viewing paths easier

path_list() { get_env "$1" | tr : '\012' | sed "s:^$HOME:\~:"; }
if [ -f /usr/5bin/pr ]; then
  pr=/usr/5bin/pr
else
  pr=pr
fi
path1() {
  case $# in
    1) path_list $1 | fmt ;;
    2) path_list $1 | $pr -$2 -t ;;
    *) usage "path1 path_var [ columns ]" ;;
  esac
}
path() {
  case $# in
    0) path1 PATH ;;
    1) path1 PATH "$1" ;;
    *) usage "path [ columns ]" ;;
  esac
}

# sh or ksh: rsh otherhost -n "command 1>&- 2>&- &"
#       csh: rsh otherhost -n "sh -c \"command 1>&- 2>&- &\""

xsh() {
  host=$1 ; pgm=$2 ; shift 2
  rsh $host -n "sh -c \"PATH=$PATH $pgm -display $DISPLAY $@ 1>&- 2>&- &\""
}

zero() {
  for f ; do
    if [ -f $f ] ; then
      cp /dev/null $f
    else
      error "zero: Can't zero $f, it's not a file!"
    fi
  done
}

# Handy abbreviations:
alias h=history

# Help those in recovery
try() { echo Try: "$@"; }
alias cls='try clear'
alias del='try rm'
alias delete=del
alias erase=del
#alias rename='try mv'
alias ren=rename
copy() { if [ $# = 1 ] ; then try cp $1 . ; else try cp "$@" ; fi ; }
function cp_ { if [ $# = 1 ] ; then try cp $1 . ; else /bin/cp $mv_cp_opt "$@" ; fi ; }
alias md='try mkdir'
alias rd='try rmdir'
alias dir='try ls'
alias print='try lp'
alias cd..='try cd .. \(with a space\)'

alias bye='try exit or EOF'
alias logout=bye
alias logoff=bye
alias quit=bye

# Miscellaneous good things

if [ yes = "$UsingLinux" ]; then
  alias ln="ln $mv_cp_opt"
fi
alias mv="mv $mv_cp_opt"
alias cp="cp $mv_cp_opt"

orig() { for f ; do mv $f ${f}.orig && cp ${f}.orig $f ; done ; }
