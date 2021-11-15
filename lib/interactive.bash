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
      open_dialog choice ret_val --menu "Accounthing Main Menu" 10 60 4  \
         "Customers" "Manage the customer database."           \
         "Transactions" "Manage the transactions database."    \
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
      Exit)
         return
         ;;
      esac
      [ "$?" != 0 ] && break
   done
}

int_customers() {
   local choice ret_val csv_customers IFS
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
         "Add" "a new customer"                          \
         "---" "--------------"                          \
         "${dialog_args[@]}"                             \
         "---" "--------------"                          \
         "Exit" "Close this program."                    \

      case "${ret_val}" in
      $DIALOG_CANCEL)
         return
         ;;
      $DIALOG_ESC)
         return
         ;;
      esac

      case "${choice}" in
      Add)
         int_add_customer
         ;;
      ---)
         continue
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
         return
         ;;
      $DIALOG_ESC)
         return
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
         return
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
