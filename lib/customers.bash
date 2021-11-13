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

# Customer Database module
# Dependencies:
# - csv
# - util

# Format:
# - Customer ID   (eg. 001)
# - Name
# - Address
# - ZIP + City
# - Hourly Cost   (eg. 15.00)

# Search for a customer by name.
# Arguments:
#   $1 - name
#   $2 - See: csv_search()
# Returns & Exit Code:
#   See: csv_search()
cdb_search_by_name() {
   csv_search "customers" "^[0-9]\\+\\,$1\\,.*\$" "$2"
}

# Search for a customer by customer ID.
# Arguments:
#   $1 - customer ID
#   $2 - See: csv_search()
# Returns & Exit Code:
#   See: csv_search()
cdb_search_by_ID() {
   csv_search "customers" "^$1\\,.*\$" "$2"
}

# Search for a customer either by ID or name.
# Arguments:
#   $1 - name/customer ID
#   $2 - See: csv_search()
# Returns & Exit Code:
#   See: csv_search()
cdb_search() {
   if csv_is_ID "$1"; then
      cdb_search_by_ID "$1" "$2"
   else
      cdb_search_by_name "$1" "$2"
   fi
}

# Print information about a customer.
# Arguments:
#   $1 - name/customer ID
# Returns:
#   See: cdb_do_print()
# Exit Code:
#   0 - OK
#   1 - No such customer
cdb_print() {
   cdb_do_print "$(cdb_search "$1")"
}

# Print information about a customer.
# Arguments:
#   $1 - CSV entry
# Returns:
#   String to be printed to standard output.
cdb_do_print() {
   [ -z "$1" ] && return 1
   ID="$(echo "$1" | cut -d',' -f1)"
   printf '\033[33m============== %s\033[0m\n' "$(echo "$1" | cut -d',' -f2)"
   printf "| ID:          %s\n" "$(echo "$1" | cut -d',' -f1)"
   printf "| Address:     %s\n" "$(echo "$1" | cut -d',' -f3)"
   printf "|              %s\n" "$(echo "$1" | cut -d',' -f4)"
   printf "| Hourly:      %s\n" "$(echo "$1" | cut -d',' -f5)"
   echo
}

# List all customers.
cdb_list() {
   local line
   csv_read "customers" | while read -r line; do
      [ -n "${line}" ] && cdb_do_print "${line}"
   done
}

# Remove a customer.
# Arguments:
#   $1 - name/customer ID
# Exit Code:
#   0 - Successfully removed.
#   1 - No such entry
cdb_remove() {
   cdb_search "$1" >/dev/null || return 1
   cdb_search "$1" "-v" | csv_write "customers"
}

# Calculate the total cost.
# Arguments:
#   $1 - customer ID/name
#   $2 - num
# Returns:
#   (customer hourly cost) * $2
# Exit Code:
#   0 - OK
#   1 - No such customer
cdb_calc_total() {
   local cost="$(cdb_search "$1" | cut -d',' -f5)"
   [ -z "${cost}" ] && return 1
   echo "scale=2; ${cost} * $2" | bc
}

# Interactively add a new customer to the database.
# Exit Code:
#   0 - OK
#   1 - Failed
cdb_add_i() {
   local CID name address zip cost old
   echo "Adding a new customer." >&2


   # Read the ID for the new customer.
   while true; do
      CID="$(prompt "ID" "$(csv_next_ID "customers")")"
      csv_is_ID "${CID}" && break
      echo "Invalid Customer ID" >&2
   done

   # Search for an old entry.
   old="$(cdb_search_by_ID "${CID}")"

   # Read the name for the new customer.
   name="$(prompt "Name" "$(echo "${old}" | cut -d',' -f2)")"

   # If no old entry is found yet, find any entry with the same name.
   [ -z "${old}" ] && old="$(cdb_search_by_name "${name}")"

   # Read the address for the new customer.
   address="$(prompt "Address" "$(echo "${old}" | cut -d',' -f3)")"

   # Read the ZIP & city for the new customer.
   while true; do
      zip="$(prompt "ZIP+City" "$(echo "${old}" | cut -d',' -f4)")"
      echo "${zip}" | grep -q '^[0-9]\{5\}\s\+[a-zA-Z]\+$' && break
      echo "Invalid ZIP or City" >&2
   done

   # Read the hourly cost for the new customer.
   while true; do
      cost="$(prompt "Hourly Cost" "$(echo "${old}" | cut -d',' -f5)")"
      echo "${cost}" | grep -q '^[0-9]\+\(\.[0-9]\+\)\?$' && break
      echo "Invalid Cost" >&2
   done

   # Remove customers that have the same ID as the new one, if any.
   cdb_remove "${CID}"

   # Remove customers that have the same name as the new one, if any.
   cdb_remove "${name}"

   # Update the customer database
   csv_append "customers" "${CID},${name},${address},${zip},${cost}"

   git_append_msg "Added new customer '${name}' (${CID})"
}

# Remove a customer. (interactive version)
# Arguments:
#   $1 - name/customer ID
# Exit Code:
#   0 - Successfully removed.
#   1 - No such entry
cdb_remove_i() {
   local entry CID name resp
   entry="$(cdb_search "$1")"
   CID="$(echo "${entry}" | cut -d',' -f1)"
   name="$(echo "${entry}" | cut -d',' -f2)"

   if [ -n "${name}" ]; then
      printf 'Are your sure to remove '%s' (%s)? ' "${name}" "${CID}" >&2
      read -r resp
      [ "${resp}" = "y" ] || return
      cdb_remove "${CID}"
      git_append_msg "Removed customer '${name}' (${CID})"
   else
      echo "No such customer: $1" >&2
      return 1
   fi
}
