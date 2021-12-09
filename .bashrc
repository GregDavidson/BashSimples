#!/bin/bash
# where: $HOME/.bashrc
#  what: Bourne Again SHell customization script
#   who: J. Greg Davidson
#  when: February 1995
#  revised to use my simples package: April 2008

[ -n "$simples_provided" ] || {
    . ~/.bash_profile
    # which will also source this script, so we're done!
    return
}

# That's enough if we're in a non-interactive shell which is just going to run a
# script and then terminate.

# return if we're in a non-interactive shell
[[ -t 0 ]] &&  [[ "$-" == *i* ]] || return

# bring in way too many things!
simple_require interactive

# maybe nicer to bring in selected bundles of nice features
if_src_dir ~/.bashrc.d
