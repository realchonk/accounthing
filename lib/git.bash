#  Copyright (C) 2021 Benjamin Stürz
#
#  This file is part of the accounthing project.
#  
#  This program is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#  
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#  
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <https://www.gnu.org/licenses/>.

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
