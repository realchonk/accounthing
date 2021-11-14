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

# Read/Write encrypted CSV databases
# Dependencies:
# - error
# - gpg


# Check if $datadir is set.
[ -z "${datadir}" ] && error "\${datadir} is not defined"

# Checks if $1 is a valid CSV ID.
# Exit Code:
#   0 - Valid
#   1 - Invalid
csv_is_ID() {
   echo "$1" | grep -q '^[0-9]\{3\}$'
}

# Read an encrypted CSV database.
# Arguments:
#   $1 - name of the database
csv_read() {
   decrypt "${datadir}/${1}.csv"
}

# Write an encrypted CSV database.
# Arguments:
#   See: csv_read()
csv_write() {
   mkdir -p "${datadir}" || error "failed to create ${datadir}"
   encrypt "${datadir}/${1}.csv" || error "failed to update '$1'"
}

# Append to an encrypted CSV database.
# Arguments:
#   $1 - See: csv_read()
#   $2 - text to be appended
csv_append() {
   csv_read "$1" | { cat -; echo "$2"; } | csv_write "$1"
}

# Search for an entry in a CSV database.
# Arguments:
#   $1 - See: csv_read()
#   $2 - search regex
#   $3 - '-v' (optional)
# Returns:
#   The corresponding entry in the database in CSV format.
# Exit Code:
#   0 - Entry found
#   1 - No such entry
csv_search() {
   local arg

   if [ -n "$3" ]; then
      arg="$3"
   else
      arg="--"
   fi

   csv_read "$1" | grep "${arg}" "$2"
}

# Search for the next available ID.
# IDs are always 3 digits long.
csv_next_ID() {
   local ID="$(csv_read "$1" | cut -d',' -f1 | sort | tail -n1)"
   [ -z "${ID}" ] && echo "001" && return
   increment_ID "${ID}" 3
}
