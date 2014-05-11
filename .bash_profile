# where: ~/.bash_profile
#  what: bash login profile - sourced by login Bourne Again Shell
#   who: J. Greg Davidson
#  when: April 1996

ifsrc() { [ -f "$1" ] && . "$1"; }
is_cmd() { type "$1" > /dev/null; }

# Let's live peacefully with sh and ksh
ifsrc ~/.profile

# Set up my "Simples" modular library system
ifsrc "$HOME/Lib/Bash/Simples/simples.bash"
# if that worked, let's add some program directories
is_cmd simple_require && {
	simple_require paths
	path_add -a ~/SW/*/[Bb]in{,.`arch`} ~/Shared/Bin
}

# If we're interactive, bring in interactive features
[[ -t "$fd" || -p /dev/stdin ]] && {
	ifsrc "${BASH_ENV:-~/.bashrc}"
	stty erase '^h' kill '^u' intr '^c' quit '^\' susp '^z'
	is_cmd fortune && { echo; fortune -a; echo; }
}
