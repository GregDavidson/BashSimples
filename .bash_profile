# * where: ~/.bash_profile
#    what: bash login profile - sourced by login Bourne Again Shell
#    who: J. Greg Davidson
#   when: April 1996 - December 2021

# Note: This file should be linked to by ~/.xprofile
# because some X Display Managers source that at login time.

# ** a few essential functions

# These could be moved into Simples, but this script deserves some kudos too

# Source a file if it exists and has not already been sourced.
if_src() {
    declare -gA if_src_count
    local f g
    for f; do
        if [ ! -f "$f" ]; then
            >&2 echo "if_src warning: No file $f!"
        else
            g=$(realpath "$f") 
            (( if_src_count["$g"] )) || {
                . "$g"
                let ++if_src_count["$g"] 
            }
        fi
    done
}
export -f if_src

if_src_dir() {
    for d; do
        [ -d "$d" ] && if_src "$d"*
    done
}
export -f if_src

# Tests if argument is a command
is_cmd() { type "$1" > /dev/null; }
export -f is_cmd

# ** Load "Simples" system and path management

# Be sure to install the awesome Simples extensions for Bash!

if_src "${simples_bash-$HOME/Lib/Bash/Simples/simples.bash}"
[ -n "${simples_provided-}" ] || {
  >&2 echo ".bash_profile failed to load Simples; exiting"
  return 1
}

simple_require paths

# ** Source System and User Specific Content

# To add your favorite paths, consider this command:
# path_add -aW ~/SW/*/[Bb]in{,`arch`} /usr/bin/mh ~/.cargo/bin /usr/local/SW/*/[Bb]in

# Setup any subsystems which need environment variable support
# e.g. GUIX, mmh, etc.

# To keep this file generic, we'll do our things here:

if_src $LOGIN_INITS $HOME/.bash_profile_local"

# ** Interactive Shell Features

# return if we're in a non-interactive shell
[[ -t 0 ]] &&  [[ "$-" == *i* ]] || return

# is this ancient s**t still meaningful?
stty erase '^?' kill '^u' intr '^c' quit '^\' susp '^z'

# Source your favorite login-time scripts
if_src_dir ~/.bash_profile.d

# Source your favorite interactive session features
if_src "${BASH_ENV:-$HOME/.bashrc}"
