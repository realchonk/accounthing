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

# Encryption/Decryption module
# External Dependencies:
# - gpg

if [ "${enable_gpg}" = true ]; then
   
   # Sometimes gpg-agent is broken.
   export GPG_TTY="$(tty)"

   if [ -z "${GPG}" ]; then
      GPG="$(which gpg || which gpg2)"
      [ -z "${GPG}" ] && error "GNU Privacy Guard (gpg) is not installed."
   fi
   
   # Encrypt standard input.
   # Arguments:
   #   $1 - file without the .gpg extension
   encrypt() {
      debug "Encrypting ${1}.gpg..."
      # cat; return
      rm -f "${1}.gpg.tmp"
      "${GPG}" --yes -o "${1}.gpg.tmp" -e --default-recipient-self #2>/dev/null
      mv "${1}.gpg.tmp" "${1}.gpg"
   }
   
   # Decrypt a file.
   # Arguments:
   #   $1 - file to decrypt without the .gpg extension.
   #   $2 - out
   decrypt() {
      local gpg_data

      [ ${#2} -eq 0 ] && error "\$2 is undefined"

      gpg_data="$("${GPG}" -d "${1}.gpg" 2>/dev/null)"

      eval "${2}='${gpg_data}'"
   }

else
   encrypt() {
      cat - > "$1"
   }

   decrypt() {
      [ ${#2} -eq 0 ] && error "\$2 is undefined"
      eval "${2}='$(cat "$1")'"
   }
fi
