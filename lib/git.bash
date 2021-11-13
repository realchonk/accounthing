# shellcheck shell=bash
# Git versioning support
# Dependencies:
# - error.bash

# This is an optional module
ENABLE_GIT=1

git_commit_msg="Automatic Update"
git_need_commit=0

if [ "${ENABLE_GIT}" = 1 ]; then

   # Commits to the git repo.
   git_commit() {
      [ "${git_need_commit}" = 0 ] && return
      [ -z "${commit_msg}" ] && commit_msg="Update"

      pushd "${datadir}" >/dev/null

      # If there is no git repo
      if [ ! -d .git ]; then
         git init -q || return 1
      fi

      git add . || return 1
      echo "${git_commit_msg}" | git commit -qF - || return 1
      popd >/dev/null
   }

else

   git_commit() {
      :
   }

fi


# Append a string to the commit message.
# Arguments:
#   $1 - string
git_append_msg() {
   git_commit_msg="$(printf "%s\n%s" "${git_commit_msg}" "$1")"
   git_need_commit=1
}
