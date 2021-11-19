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
# External Dependencies:
# - git

# git_commit_msg is now defined in the config
git_need_commit=0


if [ "${enable_git}" = true ]; then

   if [ -z "${GIT}" ]; then
      GIT="$(which git)"
      [ -z "${GIT}" ] && error "git is not installed."
   fi

   # Commits to the git repo.
   git_commit() {
      [ "${git_need_commit}" = 0 ] && return

      pushd "${datadir}" >/dev/null

      # If there is no git repo
      if [ ! -d .git ]; then
         "${GIT}" init -q || return 1
      fi

      "${GIT}" add . || return 1
      echo "${git_commit_msg}" | "${GIT}" commit -qF - || return 1
      popd >/dev/null

      git_reset_msg
      git_need_commit=0
   }

   # Prints the ID of the last commit
   git_get_commit() {
      pushd "${datadir}" >/dev/null
      git describe --always 2>/dev/null
      popd >/dev/null
   }

   # Reads commits into an array
   # Arguments:
   #   $1 - out_array
   git_read_commits() {
      local log
      [[ -d ${datadir}/.git ]] || return 1
      pushd "${datadir}" >/dev/null
      log="$(git log --format="format:%h,%s")"
      mapfile -t "$1" <<<"${log}"
      popd >/dev/null
   }

   # Get the commit message from a commit.
   # Arguments:
   #   $1 - commit hash
   #   $2 - format string (See: man git-show)
   git_show_message() {
      pushd "${datadir}" >/dev/null
      git show --no-patch --format="format:$2" "$1"
      popd "${datadir}" >/dev/null
   }

else

   git_commit() {
      :
   }

   git_get_commit() {
      return 1
   }

   git_read_commits() {
      return 1
   }  

fi


# Append a string to the commit message.
# Arguments:
#   $1 - string
git_append_msg() {
   git_commit_msg="$(printf "%s\n%s" "${git_commit_msg}" "$1")"
   git_need_commit=1
}

git_reset_msg() {
   git_commit_msg=""
   [[ ${git_commit_header} ]] && git_commit_msg="${git_commit_header}\n"
}


git_reset_msg
