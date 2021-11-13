# shellcheck shell=bash
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

# Properly increment an ID.
# Arguments:
#   $1 - ID
#   $2 - length
increment_ID() {
   local ID
   ID="$(echo "$1" | sed 's/0*//')"
   printf "%0*d" "$2" "$((ID + 1))"
}
