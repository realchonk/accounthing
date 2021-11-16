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

# Interactive mode
# External Dependencies:
# - dialog

# References:
# https://linuxcommand.org/lc3_adv_dialog.php

DIALOG_OK=0
DIALOG_CANCEL=1
DIALOG_HELP=2
DIALOG_EXTRA=3
DIALOG_ITEM_HELP=4
DIALOG_ESC=255

# Arguments:
#   $1   - dialog output
#   $2   - dialog return value
#   $... - args to dialog
open_dialog() {
   local dout dval tmp1 tmp2

   # Duplicate file descriptor 1
   exec 3>&1

   tmp1="$1"
   tmp2="$2"
   shift 2

   dout="$(dialog "$@" 2>&1 1>&3)"
   dval="$?"

   exec 3>&-

   eval "${tmp1}='${dout}'"
   eval "${tmp2}='${dval}'"
}

int_main() {
   local choice ret_val

   while true; do
      open_dialog choice ret_val --menu "Accounthing Main Menu" 12 60 5    \
         "Customers"    "Manage the customer database."                    \
         "Transactions" "Manage the transactions database."                \
         "Version"      "Show version information."                        \
         "Exit" "Close this program."

      case "${ret_val}" in
      $DIALOG_CANCEL)
         return
         ;;
      $DIALOG_ESC)
         return 1
         ;;
      esac

      case "${choice}" in
      Customers)
         int_customers
         ;;
      Transactions)
         int_transactions
         ;;
      Version)
         int_version
         ;;
      Exit)
         return
         ;;
      esac
      [ "$?" != 0 ] && break
   done
}

int_version() {
   local text=""

   text+="Program DB Version: ${DB_VERSION}\n"
   text+="Local DB Version: $(db_version)\n"

   dialog --title "Customer Information"  \
      --msgbox "${text}" 8 40
}

##################################
######### CUSTOMER STUFF #########
##################################

int_customers() {
   local e choice ret_val csv_customers IFS
   local CID cname
   local -a dialog_args

   while true; do
      dialog_args=()
      csv_read "customers" csv_customers

      IFS="="
      for e in $(echo "${csv_customers}" | tr '\n' '='); do
         csv_get "$e" $CUSTOMER_ID CID
         csv_get "$e" $CUSTOMER_NAME name
         dialog_args+=("${CID}" "${name}")
      done

      open_dialog choice ret_val --cancel-label "Back"   \
         --menu "Customer Management" 40 40 10           \
         "Add" "Create a new customer."                  \
         "---" "--------------"                          \
         "${dialog_args[@]}"                             \
         "---" "--------------"                          \
         "Back" "Go back to the main menu."              \
         "Exit" "Close this program."                    \

      case "${ret_val}" in
      $DIALOG_CANCEL)
         return 0
         ;;
      $DIALOG_ESC)
         return 1
         ;;
      esac

      case "${choice}" in
      Add)
         int_add_customer
         ;;
      ---)
         continue
         ;;
      Back)
         return 0
         ;;
      Exit)
         return 1
         ;;
      *)
         int_manage_customer "${choice}"
         ;;
      esac
      [ $? != 0 ] && return 1
   done
}

int_manage_customer() {
   local choice ret_val name tmp

   cdb_search_by_ID "$1" "" tmp
   csv_get "${tmp}" $CUSTOMER_NAME name

   while true; do
      open_dialog choice ret_val                            \
         --title "Manage Customers"                         \
         --cancel-label "Back"                              \
         --menu "${name} ($1)" 10 60 10                     \
         "Show" "Display infomation about the customer."    \
         "Edit" "Change customer details."                  \
         "Remove" "Delete the customer from the database." 
      
      case "${ret_val}" in
      $DIALOG_CANCEL)
         return 0
         ;;
      $DIALOG_ESC)
         return 1
         ;;
      esac

      case "${choice}" in
      Show)
         int_show_customer "$1"
         [ $? -ne 0 ] && return 1
         ;;
      Edit)
         int_edit_customer "$1"
         [ $? -ne 0 ] && return 1
         ;;
      Remove)
         int_remove_customer "$1"
         case $? in
         0)
            return
            ;;
         1)
            return 1
            ;;
         2)
            continue
            ;;
         esac
         ;;
      esac
   done
}

int_show_customer() {
   local name address zip rate csv_entry text
   cdb_search_by_ID "$1" "" csv_entry

   csv_get "${csv_entry}" $CUSTOMER_NAME name
   csv_get "${csv_entry}" $CUSTOMER_ADDRESS address
   csv_get "${csv_entry}" $CUSTOMER_ZIP zip
   csv_get "${csv_entry}" $CUSTOMER_HOURLY rate

   text=""
   text+="ID:         $1\n"
   text+="Name:       ${name}\n"
   text+="Address:    ${address}\n"
   text+="ZIP+City:   ${zip}\n"
   text+="Houry Rate: ${rate}\n"

   dialog --title "Customer Information"  \
      --msgbox "${text}" 10 40
}

int_add_customer() {
   int_edit_customer
}

# Arguments
#   $1 - old CID
int_edit_customer() {
   local name address zip rate csv_entry choice ret_val title new_entry CID

   if [ "$1" ]; then
      CID="$1"
      cdb_search_by_ID "${CID}" "" csv_entry
   else
      CID="$(csv_next_ID "customer")"
      title="New Customer"
   fi

   while true; do
      csv_get "${csv_entry}" $CUSTOMER_NAME name
      csv_get "${csv_entry}" $CUSTOMER_ADDRESS address
      csv_get "${csv_entry}" $CUSTOMER_ZIP zip
      csv_get "${csv_entry}" $CUSTOMER_HOURLY rate

      [ -z "${title}" ] && title="${name}"

      open_dialog choice ret_val                      \
         --title "Edit Customer"                      \
         --form "${title}" 20 60 5                    \
         "ID"           0 0 "${CID}"      0 15 0  0   \
         "Name"         2 0 "${name}"     2 15 30 30  \
         "Address"      3 0 "${address}"  3 15 30 30  \
         "ZIP+City"     4 0 "${zip}"      4 15 30 30  \
         "Hourly Rate"  5 0 "${rate}"     5 15 30 30

      case "${ret_val}" in
      $DIALOG_CANCEL)
         return 0
         ;;
      $DIALOG_ESC)
         return 1
         ;;
      esac
      
      if echo "${choice}" | grep -qF ','; then
         title="Commas are not allowed!"
         continue
      fi

      csv_entry="$(echo "${CID},$(echo "${choice}" | tr '\n' ',' | sed 's/\,$//')")"


      is_zip "$(csv_get "${csv_entry}" $CUSTOMER_ZIP)"  || { title="Invalid ZIP"; continue; }
      is_cost "$(csv_get "${csv_entry}" $CUSTOMER_HOURLY)"  || { title="Invalid Hourly Rate"; continue; }

      break
   done

   cdb_remove "${CID}"
   cdb_remove "${name}"
   
   csv_append "customers" "${csv_entry}"

   if [ "$1" ]; then
      git_append_msg "Changed Customer Details for ${CID}"
   else
      git_append_msg "Added Customer ${CID}"
   fi
}

int_remove_customer() {
   local name csv_entry

   cdb_search_by_ID "$1" "" csv_entry
   csv_get "${csv_entry}" $CUSTOMER_NAME name

   dialog --title "Remove Customer" \
      --yesno "Are you sure to remove customer '${name}'?" \
      6 60

   case "$?" in
   $DIALOG_OK)
      cdb_remove "$1"
      git_append_msg "Removed Customer $1"
      return 0
      ;;
   $DIALOG_CANCEL)
      return 2
      ;;
   $DIALOG_ESC)
      return 1
      ;;
   esac
}

##################################
####### TRANSACTION STUFF ########
##################################

int_transactions() {
   local transactions e CID TID date desc customer name
   local choice ret_val
   local -a dialog_args

   while true; do
      dialog_args=()
      csv_read "${tdb_file}" transactions

      IFS="="
      for e in $(echo "${transactions}" | tr '\n' '='); do
         csv_get "$e" $TRANS_ID TID
         csv_get "$e" $TRANS_CID CID
         csv_get "$e" $TRANS_DATE date
         csv_get "$e" $TRANS_DESC desc
         cdb_search_by_ID "${CID}" "" customer
         if [ "${customer}" ]; then
            csv_get "${customer}" $CUSTOMER_NAME name
         else
            name="${CID}"
         fi
         dialog_args+=("${TID}" "${name} ${date}: ${desc}")
      done

      open_dialog choice ret_val --cancel-label "Back"   \
         --menu "Transaction Management" 40 60 10        \
         "Add" "Create a new transacion."                \
         "---" "------------------------"                \
         "${dialog_args[@]}"                             \
         "---" "------------------------"                \
         "Back" "Go back to the main menu."              \
         "Exit" "Close this program."

      case "${ret_val}" in
      $DIALOG_CANCEL)
         return 0
         ;;
      $DIALOG_ESC)
         return 1
         ;;
      esac

      case "${choice}" in
      Add)
         int_add_transaction
         ;;
      ---)
         continue
         ;;
      Back)
         return 0
         ;;
      Exit)
         return 1
         ;;
      *)
         int_manage_transaction "${choice}"
         ;;
      esac
      [ $? != 0 ] && return 1
   done
}

int_manage_transaction() {
   local choice ret_val

   while true; do
      open_dialog choice ret_val                            \
         --title "Manage Transaction"                       \
         --cancel-label "Back"                              \
         --menu "Transaction $1" 10 60 10                   \
         "Show" "Display infomation about the transaction." \
         "Edit" "Change transaction details."               \
         "Remove" "Delete the transaction from the database." 
      
      case "${ret_val}" in
      $DIALOG_CANCEL)
         return 0
         ;;
      $DIALOG_ESC)
         return 1
         ;;
      esac

      case "${choice}" in
      Show)
         int_show_transaction "$1"
         [ $? -ne 0 ] && return 1
         ;;
      Edit)
         int_edit_transaction "$1"
         [ $? -ne 0 ] && return 1
         ;;
      Remove)
         int_remove_transaction "$1"
         case $? in
         0)
            return
            ;;
         1)
            return 1
            ;;
         2)
            continue
            ;;
         esac
         ;;
      esac
   done
}

int_show_transaction() {
   local trans CID date num total desc text customer cname
   tdb_search "$1" "" trans

   csv_get "${trans}" $TRANS_CID CID
   csv_get "${trans}" $TRANS_DATE date
   csv_get "${trans}" $TRANS_NUM num
   csv_get "${trans}" $TRANS_TOTAL total
   csv_get "${trans}" $TRANS_DESC desc

   cdb_search_by_ID "${CID}" "" customer
   csv_get "${customer}" $CUSTOMER_NAME cname

   [ -z "${cname}" ] && cname="(Deleted)"

   text=""
   text+="ID:           $1\n"
   text+="Customer:     ${cname} (${CID})\n"
   text+="Description:  ${desc}\n"
   text+="Date:         ${date}\n"
   text+="Count:        ${num}\n"
   text+="Total:        ${total}\n"

   dialog --title "Transaction Information" \
      --msgbox "${text}" 10 40
}

int_remove_transaction() {
   local name csv_entry

   dialog --title "Erase Transaction" \
      --yesno "Are you sure to erase transaction $1?" \
      6 60

   case "$?" in
   $DIALOG_OK)
      tdb_remove "$1"
      git_append_msg "Removed Transaction $1"
      return 0
      ;;
   $DIALOG_CANCEL)
      return 2
      ;;
   $DIALOG_ESC)
      return 1
      ;;
   esac
}


int_add_transaction() {
   int_edit_transaction
}
int_edit_transaction() {
   local TID CID date num total desc customer price
   local csv_entry choice ret_val new_entry cname tmp
   if [ "$1" ]; then
      TID="$1"
      tdb_search "${TID}" "" csv_entry
   else
      TID="$(csv_next_ID "${tdb_file}")"
      title="New Transaction"
   fi

   while true; do
      csv_get "${csv_entry}" $TRANS_CID CID
      csv_get "${csv_entry}" $TRANS_DATE date
      csv_get "${csv_entry}" $TRANS_NUM num
      csv_get "${csv_entry}" $TRANS_TOTAL total
      csv_get "${csv_entry}" $TRANS_DESC desc

      cdb_search_by_ID "${CID}" "" customer
      if [ "${customer}" ]; then
         csv_get "${customer}}" $CUSTOMER_NAME cname
      else
         cname="${CID}"
      fi

      price="$(echo "scale=2; ${total} / ${num}" | bc)"

      [ -z "${title}" ] && title="Transaction ${TID}"

      open_dialog choice ret_val                         \
         --title "Edit Transaction"                      \
         --form "${title}" 20 60 7                       \
         "ID"           0 0 "${TID}"         0 15 0  0   \
         "Customer"     2 0 "${cname}"       2 15 30 30  \
         "Description"  3 0 "${desc}"        3 15 30 30  \
         "Date"         4 0 "${date}"        4 15 30 30  \
         "Count"        5 0 "${num}"         5 15 30 30  \
         "Price"        6 0 "${price}"       6 15 30 30  \
         "Total"        7 0 "${total}"       7 15 0  0

      case "${ret_val}" in
      $DIALOG_CANCEL)
         return 0
         ;;
      $DIALOG_ESC)
         return 1
         ;;
      esac

      if echo "${choice}" | grep -qF ','; then
         title="Commas are not allowed!"
         continue
      fi

      tmp="$(echo "${choice}" | tr '\n' ',' | sed 's/\,$//')"

      cname="$(echo "${tmp}" | cut -d',' -f1)"
      desc="$(echo "${tmp}" | cut -d',' -f2)"
      date="$(echo "${tmp}" | cut -d',' -f3)"
      num="$(echo "${tmp}" | cut -d',' -f4)"
      price="$(echo "${tmp}" | cut -d',' -f5)"


      if is_cost "${price}" && is_number "${num}"; then
         total="$(echo "scale=2; ${price} * ${num}" | bc)"
      else
         title="Invalid price or count"
         csv_get "${csv_entry}" $TRANS_TOTAL total
         csv_entry="${TID},${CID},${date},${num},${total},${desc}"
         continue
      fi

      cdb_search "${cname}" "" tmp
      if [ "${tmp}" ]; then
         csv_get "${tmp}" $CUSTOMER_ID CID
      else
         title="No such customer: ${cname}"
         csv_entry="${TID},${cname},${date},${num},${total},${desc}"
         continue
      fi

      csv_entry="${TID},${CID},${date},${num},${total},${desc}"

      is_date "${date}" || { title="Invalid Date"; continue; }

      break
   done

   tdb_remove "${TID}"

   csv_append "${tdb_file}" "${csv_entry}"

   if [ "$1" ]; then
      git_append_msg "Changed Transaction Details for ${TID}"
   else
      git_append_msg "Added Transaction ${TID}"
   fi
}
