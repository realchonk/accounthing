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

# Transactions Database module
# Dependencies:
# - csv
# - util

# Format:
# - Transaction ID   (eg. 001)
# - Customer ID      (eg. 001)
# - Date             (eg. 2021-10-29)
# - Num              (eg. 4.5)
# - Total            (eg. 67.50)
# - Description      (eg. Haushaltshilfe)

# tdb_default_desc is now defined in the config
tdb_file="transactions_$(date +%Y)"

# Search for one or more transactions.
# Arguments:
#   $1 - search term
#   $2 - See: csv_search()
tdb_search() {
   local year month TID CID
   local p file pattern
   
   if echo "$1" | grep -Fq ':'; then
      p="$(echo "$1" | cut -d':' -f1)"
      CID="$(cdb_search "$(echo "$1" | cut -d':' -f2)" | cut -d',' -f1)"
      [ -z "${CID}" ] && return 1
   else
      p="$1"
      CID='[0-9]\+'
   fi

   if echo "$p" | grep -q '^[0-9]\{3\}$'; then
      # Search by partial transaction ID
      pattern="^$p\\,${CID}\\,.*$"
   elif echo "$p" | grep -q '^[0-9]\{3\}-[0-9]\{4\}$'; then
      # Search by full transaction ID
      TID="$(echo "$p" | cut -d'-' -f1)"
      year="$(echo "$p" | cut -d'-' -f2)"
      pattern="^${TID}\\,${CID}\\,.*\$"
   elif echo "$p" | grep -q '^[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}$'; then
      # Search by full date
      year="$(echo "$p" | cut -d'-' -f1)"
      pattern="^[0-9]\\+\\,${CID}\\,$p\\,.*\$"
   elif echo "$p" | grep -q '^[0-9]\{4\}-[0-9]\{2\}$'; then
      # Search by month
      year="$(echo "$p" | cut -d'-' -f1)"
      pattern="^[0-9]\\+\\,${CID}\\,${p}-[0-9]\\+\\,.*$"
   elif echo "$p" | grep -q '^[0-9]\{4\}$'; then
      # Search by year
      year="$p"
      pattern="^[0-9]\\+\\,${CID}\\,.*$"
   elif [ -z "${p}" ]; then
      # Just list all entries
      pattern="^[0-9]\\+\\,${CID}\\,.*$"
   else
      error "tdb_search(): Invalid search format"
   fi

   if [ -z "${year}" ]; then
      file="${tdb_file}"
   else
      file="transactions_${year}"
   fi
   csv_search "${file}" "${pattern}" "$2"
}

# Interactively add a new transacton to the current database.
# Exit Code:
#   0 - OK
#   1 - Failed
tdb_add_i() {
   local TID CID date num total tmp old oldname desc

   # Read the transaction ID.
   while true; do
      TID="$(prompt "Transaction ID" "$(csv_next_ID "${tdb_file}")")"
      csv_is_ID "${TID}" && break
      echo "Invalid Transaction ID" >&2
   done
   
   # Find an old transaction if any
   old="$(tdb_search "${TID}")"
   oldname="$(cdb_search_by_ID "$(echo "${old}" | cut -d',' -f2)" | cut -d',' -f2)"

   # Read the customer ID/name.
   while true; do
      tmp="$(cdb_search "$(prompt "Customer" "${oldname}")")"
      if [ -z "${tmp}" ]; then
         echo "Invalid Customer" >&2
      else
         CID="$(echo "${tmp}" | cut -d',' -f1)"
         break
      fi
   done

   # Read the date.
   while true; do
      if [ -n "${old}" ]; then
         tmp="$(echo "${old}" | cut -d',' -f3)"
      else
         tmp="$(date +%F)"
      fi
      date="$(prompt "Date" "${tmp}")"
      is_date "${date}" && break
      echo "Invalid Date" >&2
   done

   # Read the description
   [ -n "${old}" ] && tmp="$(echo "${old}" | cut -d',' -f6)"
   [ -z "${desc}" ] && tmp="${tdb_default_desc}"
   while true; do
      desc="$(prompt "Description" "${tmp}")"
      echo "${desc}" | grep -qF ',' || break
      echo "Commas are not allowed." >&2
   done

   # Read the number of hours.
   while true; do
      num="$(prompt "Number of hours" "$(echo "${old}" | cut -d',' -f4)")"
      is_number "${num}" && break
      echo "Invalid Number" >&2
   done

   # Pre-calculate the default total.
   tmp="$(cdb_calc_total "${CID}" "${num}")"
   # Read the total cost.
   while true; do
      total="$(prompt "Total" "${tmp}")"
      is_number "${total}" && break
      echo "Invalid Number" >&2
   done


   # Remove transactions with the same ID
   tdb_remove "${TID}"

   # Update the transaction database
   csv_append "${tdb_file}" "${TID},${CID},${date},${num},${total},${desc}"

   git_append_msg "Added new transaction with ID ${TID}"
}

# Remove a transaction. (interactive version)
# Arguments:
#   $1 - transaction ID
# Exit Code:
#   0 - Successfully removed.
#   1 - No such entry
tdb_remove_i() {
   local entry TID resp
   entries="$(tdb_search "$1")"
   TID="$(echo "${entries}" | cut -d',' -f1)"
   
   if [ -n "${TID}" ]; then
      echo "${TID}" >&2
      printf "Are you willing to remove these transactions? " >&2
      read -r resp
      [ "${resp}" = "y" ] || return
      tdb_remove "$1"
      git_append_msg "Removed transactions: ${TID}"
   else
      echo "No such transactions: $1" >&2
      return 1
   fi
}

# Print information about a transaction.
# Arguments:
#   $1 - See: tdb_search()
# Returns & Exit Code:
#   See tdb_do_print()
tdb_print() {
   tdb_do_print $(tdb_search "$1")
}

# Print information about a transaction.
# Arguments:
#   $1 - CSV entry
# Returns:
#   String to be printed to standard output
# Exit Code:
#   0 - OK
#   1 - Invalid entry
tdb_do_print() {
   local TID CID
   [ -z "$1" ] && return 1
   for e in $@; do
      TID="$(echo "$e" | cut -d',' -f1)"
      CID="$(echo $e | cut -d',' -f2)"
      printf '\033[36m============== %s\033[0m\n' "${TID}-$(date +%Y)"
      printf '| Customer:    %s (%s)\n' "$(cdb_search "${CID}" | cut -d',' -f2)" "${CID}"
      printf '| Date:        %s\n' "$(echo "$e" | cut -d',' -f3)"
      printf '| Num Hours:   %s\n' "$(echo "$e" | cut -d',' -f4)"
      printf '| Total:       %s\n' "$(echo "$e" | cut -d',' -f5)"
      printf '| Description: %s\n' "$(echo "$e" | cut -d',' -f6)"
      echo
   done
}

# List all transactions.
tdb_list() {
   local file line
   if [ -z "$1" ]; then
      file="${tdb_file}"
   else
      file="transactions_$1"
   fi
   csv_read "${file}" | while read -r line; do
      [ -n "${line}" ] && tdb_do_print "${line}"
   done
}

# Remove a transaction.
# Arguments:
#   $1 - transaction ID
# Exit Code:
#   0 - Successfully removed.
#   1 - No such entry
tdb_remove() {
   csv_is_ID "$1" || return 1
   tdb_search "$1" >/dev/null || return 1
   tdb_search "$1" "-v" | csv_write "${tdb_file}"
}
