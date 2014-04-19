#!/bin/bash
# where: $HOME/.bashrc
#  what: Bourne Again SHell customization script
#   who: J. Greg Davidson
#  when: February 1995
#  revised to use my simples package: April 2008

[ -n "$simples_provided" ] || {
  for f in $simples_bash {$HOME,/Shared}/Lib/Bash/Simples/simples.bash; do
    [ -r "$f" ] && { . "$f"; break; }
  done
}

if [ -z "$simples_provided" ]; then
	>&2 echo "Error: .bashrc punting without simples!"
else
	if [ -n "$PS1" ]; then
		:
		# interactive shell

		# require env
		# require interactive

		# alias whence='type -p'
		# ifsrc() { [ -f $1 ] && . $1; }
		#ifsrc /etc/bashrc
		#ifsrc $HOME/.kbashrc
		PS1='$ '
	fi
fi
