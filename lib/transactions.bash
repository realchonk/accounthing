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

# Format:
# - Transaction ID   (eg. 001)
# - Customer ID      (eg. 001)
# - Date             (eg. 2021-10-29)
# - Num              (eg. 4.5)
# - Price            (eg. 12.40)
# - Description      (eg. Haushaltshilfe)

TRANS_ID=1
TRANS_CID=2
TRANS_DATE=3
TRANS_NUM=4
TRANS_PRICE=5
TRANS_DESC=6

# Construct a CSV entry for a new transaction.
# Arguments:
#   $1 - TID
#   $2 - CID
#   $3 - Date
#   $4 - Count
#   $5 - Price
#   $6 - Description
create_transaction() {
   local TID="$1"
   local CID="$2"
   local date="$3"
   local count="$4"
   local price="$5"
   local desc="$6"
   echo "${TID},${CID},${date},${count},${price},${desc}"
}

tdb_year="$(date +%Y)"

tdb_file() {
   echo "transactions_${tdb_year}"
}

# Search for one or more transactions.
# Arguments:
#   $1 - search term
#   $2 - See: csv_search()
#   $3 - See: csv_search():$4
tdb_search() {
   local year TID CID
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
      file="$(tdb_file)"
   else
      file="transactions_${year}"
   fi
   csv_search "${file}" "${pattern}" "$2" "$3"
}

# Add a transaction directly.
# Arguments:
#   $1 - CID
#   $2 - date
#   $3 - num
#   $4 - price (optional)
#   $5 - description
tdb_add_direct() {
   local price customer TID

   is_date "$2" || error "Invalid Date: $2"
   is_number "$3" || error "Invalid Count: $3"
   cdb_search_by_ID "$1" "" customer
   [ -z "${customer}" ] && error "No such customer: $1"

   if [ "$4" ]; then
      is_cost "$4" || error "Invalid Cost: $4"
      price="$4"
   else
      csv_get "${customer}" "$CUSTOMER_HOURLY" price
   fi

   echo "$5" | grep -qF ',' && error "Description contains a comma"

   TID="$(csv_next_ID "$(tdb_file)")"

   csv_append "$(tdb_file)" "$(create_transaction "${TID}" "$1" "$2" "$3" "${price}" "$5")"

   git_append_msg "Added new transaction with ID ${TID}"
}

# Interactively add a new transacton to the current database.
# Exit Code:
#   0 - OK
#   1 - Failed
tdb_add_i() {
   local TID CID customer date num price tmp old oldname desc

   # Read the transaction ID.
   while true; do
      csv_next_ID "$(tdb_file)" TID
      TID="$(prompt "Transaction ID" "${TID}")"
      csv_is_ID "${TID}" && break
      echo "Invalid Transaction ID" >&2
   done
   
   # Find an old transaction if any
   tdb_search "${TID}" "" old
   cdb_search_by_ID "$(csv_get "${old}" "$TRANS_CID")" "" customer
   csv_get "${customer}" "$CUSTOMER_NAME" oldname

   # Read the customer ID/name.
   while true; do
      cdb_search "$(prompt "Customer" "${oldname}")" "" customer
      if [ -z "${customer}" ]; then
         echo "Invalid Customer" >&2
      else
         csv_get "${customer}" "$CUSTOMER_ID" CID
         break
      fi
   done

   # Read the date.
   while true; do
      if [ -n "${old}" ]; then
         csv_get "${old}" "$TRANS_DATE" tmp
      else
         tmp="$(date +%F)"
      fi
      date="$(prompt "Date" "${tmp}")"
      is_date "${date}" && break
      echo "Invalid Date" >&2
   done

   # Read the description
   [ -n "${old}" ] && csv_get "${old}" "$TRANS_DESC" tmp
   [ -z "${desc}" ] && tmp="${tdb_default_desc}"
   while true; do
      desc="$(prompt "Description" "${tmp}")"
      echo "${desc}" | grep -qF ',' || break
      echo "Commas are not allowed." >&2
   done

   # Read the number of hours.
   while true; do
      num="$(prompt "Number of hours/units" "$(csv_get "${old}" "$TRANS_NUM")")"
      is_number "${num}" && break
      echo "Invalid Number" >&2
   done

   # Get the default price.
   csv_get "${customer}" "$CUSTOMER_HOURLY" price
   # Read the price per unit.
   while true; do
      price="$(prompt "Price" "${price}")"
      is_cost "${price}" && break
      echo "Invalid Price" >&2
   done


   # Remove transactions with the same ID
   tdb_remove "${TID}"

   # Update the transaction database
   csv_append "$(tdb_file)" "$(create_transaction "${TID}" "${CID}" "${date}" "${num}" "${price}" "${desc}")"


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
   tdb_search "$1" "" entries
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
   local entries
   tdb_search "$1" "" entry
   tdb_do_print "${entry}"
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
   local TID CID tmp count price total
   [ -z "$1" ] && return 1

   csv_get "$1" "$TRANS_ID" TID
   csv_get "$1" "$TRANS_CID" CID
   csv_get "$1" "$TRANS_NUM" count
   csv_get "$1" "$TRANS_PRICE" price
   total="$(calc_total "${count}" "${price}")"

   printf '\033[36m============== %s\033[0m\n' "${TID}-$(date +%Y)"
   cdb_search "${CID}" "" tmp
   printf '| Customer:    %s (%s)\n' "$(csv_get "${tmp}" "$CUSTOMER_NAME")" "${CID}"
   printf '| Date:        %s\n' "$(csv_get "$1" "$TRANS_DATE")"
   printf '| Count:       %s\n' "${count}"
   printf '| Price:       %s\n' "${price}"
   printf '| Total:       %s\n' "${total}"
   printf '| Description: %s\n' "$(csv_get "$1" "$TRANS_DESC")"
   echo
}

# List all transactions.
tdb_list() {
   local line IFS tdb
   csv_read "$(tdb_file)" tdb
   tdb="$(echo "${tdb}" | tr '\n' '=')"

   IFS="="
   for line in ${tdb}; do
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
   local tmp
   csv_is_ID "$1" || return 1
   tdb_search "$1" >/dev/null || return 1
   tdb_search "$1" "-v" tmp
   csv_write "$(tdb_file)" "${tmp}"
}
