# Simple login profile for Bourne-Shell compatible shells

# ifsrc will source a file if it exists
ifsrc() { [ -f "$1" -a -r "$1" ] && . "$1"; }

# unless PROFILEREAD is defined, source the system profile
test -n "$PROFILEREAD" || ifsrc /etc/profile

# Unless we're a child of a super account,
# define this account as the super account.
[ -n "$super" ] || export super="$HOME"

ifsrc "$super/.env.sh"		# Set up the environment

# Perform routine login-time updates
for doit in "$HOME/This/update-this"; do
	[ -x "$doit" ] && "$doit"
done

# If login is sharing an X screen with an already logged-in
# account which has given us DISPLAY credentials, unpack
# them.  This only works if used in conjuction with, e.g.
# configuration of the su or sudo commands to set and
# propagate XAUTH_ADD appropriately in subshells.
[ -n "$XAUTH_ADD" ] && { xauth add "$DISPLAY" "${XAUTH_ADD#* }"; export XAUTH_ADD= ; }
