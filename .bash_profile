# * where: ~/.bash_profile
#    what: bash login profile - sourced by login Bourne Again Shell
#    who: J. Greg Davidson
#   when: April 1996 - December 2021

# Note: Modern Display Managers and Session Managers won't run BASH so you can't
# source this. Instead, they use sh or dash which sources ~/.profile or
# ~/.xprofile and you don't get to export functions to the environment.
# We're using the bash version of Simples for this file.  You can instead
# use the sh version for ~/.profile and ~/.xprofile (which can be linked
# together).  You can put scalar variables into the environment.


# ** Load the Simples System

. "${simples_bash-$HOME/Lib/Bash/Simples-Bash/simples-export.bash}" || {
  >&2 echo ".bash_profile failed to load Simples; exiting"
  return 1 > /dev/null || exit 1
}

simple_require --export paths

# ** Source System and User-Specific Content

# To add your favorite paths, consider this 3-step command:
# shopt -s nullglob
# path_add -aDV ~/SW/*/[Bb]in{,`arch`} /usr/bin/mh ~/.cargo/bin /usr/local/SW/*/[Bb]in
# shopt -u nullglob

# Setup any subsystems which need environment variable support
# e.g. GUIX, mmh, etc.

# To keep this file generic, we'll do our things here:

simple_src $LOGIN_INITS "$HOME/.bash_profile_local"

# ** Interactive Shell Features

# return if we're in a non-interactive shell
[[ -t 0 ]] &&  [[ "$-" == *i* ]] || return

# is this ancient s**t still meaningful?
stty erase '^?' kill '^u' intr '^c' quit '^\' susp '^z'

# Source your favorite login-time scripts
simple_src_dir ~/.bash_profile.d

# Source your favorite interactive session features
simple_src "${BASH_ENV:-$HOME/.bashrc}"
