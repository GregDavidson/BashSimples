#!/bin/bash

# Copyright (c) 2008 J. Greg Davidson. This work is licensed under a
# Creative Commons Attribution 4.0 International License
# http://creativecommons.org/licenses/by/4.0.

[ -n "${simples_provided-}" ] || # is simples package already loaded?
  . "${simples_bash-$HOME/Lib/Bash/Simples/simples.bash}" || # try loading it
  (echo "$0 error: Can't load simples, goodbye!" >&2; exit 1)

simple_require program msg_n_exit

program_author	J. Greg Davidson
program_rights 'Copyright (c) 2007 J. Greg Davidson.  All rights reserved.'
program_version	'$Id: program_demo.bash,v 1.1 2008/03/18 20:44:16 greg Exp greg $'		# RCS or equiv will expand this
program_purpose	'demonstrate some simples packages for shell scripting'

msg_exit_format done	0
msg_exit_format goodbye	0 'Goodbye %s!\n'
msg_exit_format fire	3 'User %s is on fire!\n'

msg_format extra_args	'%14s\t%s\n'
msg_format extra_arg	'%14d\t%s\n'

program_flag	f	friendly	true	false	establish friendly
program_option	h	heat	low	set level of heat
program_arg		user			the poor sucker

program_note I hope you understand and appreciate the nice things \
	which these simples packages are taking care of for you.

program_note I explicitly loaded the simples package and then used it \
	to require three other packages along with anything they \
        might require.

program_note  None of these things are really hard to do, \
	but they are tedious enough to do well that too often \
	we just will not bother, or worse, we will do them in a slapdash fashion.

program_note This is also an example of a declarative interface.

program_process_options "$@" ; shift $program_option_count

# Do we have the minimum number of required arguments?
[ $# -ge 1 ] || die pgm_usage

user=$1 ; shift

# simple_bashow 'Options:' friendly heat
# simple_bashow 'Required arguments:' user

if [ $# -gt 0 ]; then
    msg_out extra_args 'NUMBER' 'EXTRA ARGUMENT'
    i=0; for arg; do
        msg_out extra_arg $(( ++i )) "$arg"
    done
fi

if [ high = "$heat" ]; then
    msg_exit fire "$user"
elif $friendly; then
    msg_exit goodbye "$user"
else
    msg_exit done
fi
