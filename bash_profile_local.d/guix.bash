# login time guix setup
# Sourced by ~/.bash_profile_local

if [ -e ~/.guix-profile ]; then

export GUIX_PROFILE="$HOME/.guix-profile"
. "$GUIX_PROFILE/etc/profile"

# Alas, GUIX has likely prepended its directories onto paths
# which already contained them.  Let's dedupe any of these

guix_env_path_vars() {
  local g="${GUIX_PROFILE//\//\\/}"
  local h="${g//\./\\.}"
  env | sed -e '/^[A-Z_]*PATH=/!d' -e "/[=:]$h\\//"'!d' -e 's/=.*//'
}

dedup_env_paths XDG_DATA_DIRS $(guix_env_path_vars)

fi
