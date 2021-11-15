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

# Format:
# - Customer ID   (eg. 001)
# - Name
# - Address
# - ZIP + City
# - Hourly Cost   (eg. 15.00)

CUSTOMER_ID=1
CUSTOMER_NAME=2
CUSTOMER_ADDRESS=3
CUSTOMER_ZIP=4
CUSTOMER_HOURLY=5

# Search for a customer by name.
# Arguments:
#   $1 - name
#   $2 - See: csv_search()
#   $3 - See: csv_search():$4
# Returns & Exit Code:
#   See: csv_search()
cdb_search_by_name() {
   csv_search "customers" "^[0-9]\\+\\,$1\\,.*\$" "$2" "$3"
}

# Search for a customer by customer ID.
# Arguments:
#   $1 - customer ID
#   $2 - See: csv_search()
#   $3 - See: csv_search():$4
# Returns & Exit Code:
#   See: csv_search()
cdb_search_by_ID() {
   csv_search "customers" "^$1\\,.*\$" "$2" "$3"
}

# Search for a customer either by ID or name.
# rguments:
#   $1 - name/customer ID
#   $2 - See: csv_search()
#   $3 - See: csv_search():$4
# Returns & Exit Code:
#   See: csv_search()
cdb_search() {
   if csv_is_ID "$1"; then
      cdb_search_by_ID "$1" "$2" "$3"
   else
      cdb_search_by_name "$1" "$2" "$3"
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
   local entry
   cdb_search "$1" "" entry
   cdb_do_print "${entry}"
}

# Print information about a customer.
# Arguments:
#   $1 - CSV entry
# Returns:
#   String to be printed to standard output.
cdb_do_print() {
   [ -z "$1" ] && return 1
   printf '\033[33m============== %s\033[0m\n' "$(csv_get "$1" $CUSTOMER_NAME)"
   printf "| ID:          %s\n" "$(csv_get "$1" $CUSTOMER_ID)"
   printf "| Address:     %s\n" "$(csv_get "$1" $CUSTOMER_ADDRESS)"
   printf "|              %s\n" "$(csv_get "$1" $CUSTOMER_ZIP)"
   printf "| Hourly:      %s\n" "$(csv_get "$1" $CUSTOMER_HOURLY)"
   echo
}

# List all customers.
cdb_list() {
   local line cdb IFS
   csv_read "customers" cdb
   cdb="$(echo "${cdb}" | tr '\n' '=')"
   IFS='='
   for line in ${cdb}; do
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
   local new_data
   cdb_search "$1" "" _ >/dev/null || return 1
   cdb_search "$1" "-v" new_data
   csv_write "customers" "${new_data}"
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
   local entry cost
   cdb_search "$1" "" entry
   csv_get "${entry}" $CUSTOMER_HOURLY cost
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
   cdb_search_by_ID "${CID}" "" old

   # Read the name for the new customer.
   name="$(prompt "Name" "$(csv_get "${old}" $CUSTOMER_NAME)")"

   # If no old entry is found yet, find any entry with the same name.
   [ -z "${old}" ] && cdb_search_by_name "${name}" "" old

   # Read the address for the new customer.
   address="$(prompt "Address" "$(csv_get "${old}" $CUSTOMER_ADDRESS)")"

   # Read the ZIP & city for the new customer.
   while true; do
      zip="$(prompt "ZIP+City" "$(csv_get "${old}" $CUSTOMER_ZIP)")"
      is_zip "${zip}" && break
      echo "Invalid ZIP or City" >&2
   done

   # Read the hourly cost for the new customer.
   while true; do
      cost="$(prompt "Hourly Cost" "$(csv_get "${old}" $CUSTOMER_HOURLY)")"
      is_cost "${cost}" && break
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
   cdb_search "$1" "" entry
   csv_get "${entry}" $CUSTOMER_ID CID
   csv_get "${entry}" $CUSTOMER_NAME name

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
