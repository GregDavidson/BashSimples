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

. ~/.profile

# ** Load the Simples System

. "${simples_bash-$HOME/Lib/Shell/Simples-Bash/simples-export.bash}" || {
  >&2 echo ".bash_profile failed to load Simples; exiting"
  return 1 2> /dev/null || exit 1
}

simple_require --export paths

# ** Source System and User-Specific Content

if_src $LOGIN_INITS ".local.bash"

# ** Interactive Shell Features

# unless we're in a non-interactive shell, we're done
x="$?" # preserve any existing error code
[[ -t 0 ]] ||  [[ "$-" == *i* ]] ||
    { return "$x" 2> /dev/null || exit "$x"; }

# is this ancient s**t still meaningful?
stty erase '^?' kill '^u' intr '^c' quit '^\' susp '^z'

# Source your favorite login-time scripts
simple_src_dir ~/.local.bash.d

simple_src --set ~/.bash_profile

# Source your favorite interactive session features
simple_src "${BASH_ENV:-$HOME/.bashrc}"
