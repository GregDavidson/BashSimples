#!/usr/bin/sh
# Note: there are a variety of fortune database collections
# as well as switches to select from those collections
type fortune >/dev/null && { echo; fortune; echo; }
