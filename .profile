# Simple login profile for Bourne-Shell compatible shells

# ifsrc will source a file if it exists
ifsrc() { [ -f "$1" -a -r "$1" ] && . "$1"; }

# unless PROFILEREAD is defined, source the system profile
test -n "$PROFILEREAD" || ifsrc /etc/profile

# If login is sharing an X screen with an already logged-in
# account which has given us DISPLAY credentials, unpack
# them.  This only works if used in conjuction with, e.g.
# configuration of the su or sudo commands to set and
# propagate XAUTH_ADD appropriately in subshells.
[ -n "$XAUTH_ADD" ] && { xauth add "$DISPLAY" "${XAUTH_ADD#* }"; export XAUTH_ADD= ; }

for f in $HOME/.profile.d/*
do
		ifsrc "$f"
done
