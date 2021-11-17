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

# Utilities module

# Print a prompt
# Arguments:
#   $1 - prompt
#   $2 - default value (optional)
# Exit Code:
#   0 - OK
#   1 - read failed
prompt() {
   local input
   if [ -n "$2" ]; then
      printf "%s [%s]: " "$1" "$2" >&2
      read -r input || return 1
      [ -z "${input}" ] && input="$2"
   else
      while [ -z "${input}" ]; do
         printf "%s: " "$1" >&2
         read -r input || return 1
      done
   fi
   echo "${input}"
}

# Checks if $1 is a valid number.
is_number() {
   echo "$1" | grep -q '^[0-9]\+\(\.[0-9]\+\)\?$'
}

# Checks if $1 is a valid date.
is_date() {
   local year month day
   echo "$1" | grep -q '^[0-9]\+-[0-9]\+-[0-9]\+$' || return 1
   year="$(echo "$1" | cut -d'-' -f1)"
   month="$(echo "$1" | cut -d'-' -f2)"
   day="$(echo "$1" | cut -d'-' -f3)"

   # Check if year is in the range [1970-9999]
   { [ "${year}" -ge 1970 ] && [ "${year}" -le 9999 ]; } || return 1

   # Check if month is in the range [1-12]
   { [ "${month}" -ge 1 ] && [ "${month}" -le 12 ]; } || return 1

   # Check if day is in the range [1-31]
   { [ "${day}" -ge 1 ] && [ "${day}" -le 31 ]; } || return 1

   return 0
}

# Checks if $1 is a valid ZIP+City
is_zip() {
   echo "$1" | grep -q '^[0-9]\{5\}\s\+[a-zA-Z]\+$'
}

# Checks if $1 is a valid cost
is_cost() {
   echo "$1" | grep -q '^[0-9]\+\(\.[0-9]\+\)\?$'
}

# Checks if $1 is either true or false.
is_bool() {
   grep -q '^\(true\|false\)$' <<< "$1"
}

# Properly increment an ID.
# Arguments:
#   $1 - ID
#   $2 - length
increment_ID() {
   local ID
   ID="$(echo "$1" | sed 's/0*//')"
   printf "%0*d" "$2" "$((ID + 1))"
}

if [ "${enable_debug}" = true ]; then
   # Print a message to standard error
   debug() {
      echo "$@" >&2
   }
else
   debug() {
      :
   }
fi

# Calculate the total from a count and a price.
# Arguments:
#   $1 - count
#   $2 - price
calc_total() {
   echo "scale=2; $1 * $2" | bc
}


