# login time guix setup
# Sourced by ~/.bash_profile_local

export GUIX_PROFILE=~/.guix-profile
if [ -e "$GUIX_PROFILE" ]; then

# GUIX's profile puts its path elements in front of 
# other elements and it doesn't check if they  are
# already there, creating duplicates if they are.

# GUiX also puts more programs in its bin directory
# than I asked for and some of them are NOT my
# preferred version of such!

# There's also something in the current
#   January 2022
# guix profile which is causing trouble!!
#   A broken PATH
#   Shell errors before each prompt
#   Login problems

# And guix put a system profile in
# /etc/profile.d which caused trouble!!
#   I've removed it!!

# Let's clone and tame the guix profile
#   ~/.guix-profile/etc/profile
# and assume the maintenance burden for it!!

# I've put links to the guix programs I like in my directory
#   ~/Bin.guix

path_add "$GUIX_PROFILE/bin" -a ~/Bin.guix

emacs_load_path_add () { 
    declare -gA emacs_load_path_add_options=([fn_name]="emacs_load_path_add");
    pathvar_add EMACSLOADPATH emacs_load_path_add_options --dots=no -zDV "$@"
}

info_load_path_add () { 
    declare -gA info_load_path_add_options=([fn_name]="emacs_load_path_add");
    pathvar_add INFOLOADPATH info_load_path_add_options --dots=no -zDV "$@"
}


guix_emacs_version=$(emacs --batch --eval '(prog1 (eval-expression emacs-version) (kill-emacs))')
emacs_load_path_add "$GUIX_PROFILE/share/emacs/site-lisp" "$GUIX_PROFILE/share/emacs/$guix_emacs_version/lisp"
info_load_path_add "$GUIX_PROFILE/share/info"

fi
