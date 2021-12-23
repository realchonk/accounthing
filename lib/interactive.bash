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
      open_dialog choice ret_val                                           \
         --title "Accounthing" --menu "Accounthing Main Menu" 15 60 5      \
         "Customers"    "Manage the customer database."                    \
         "Transactions" "Manage the transactions database."                \
         "Git"          "Control the Git repository."                      \
         "Config"       "Edit configuration parameters."                   \
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
      Git)
         int_git
         ;;
      Config)
         int_config
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
      csv_customers="$(sort <<< "${csv_customers}")"

      if [[ ${csv_customers} ]]; then
         dialog_args=("---" "--------------")
         IFS="="
         for e in $(echo "${csv_customers}" | tr '\n' '='); do
            csv_get "$e" "$CUSTOMER_ID" CID
            csv_get "$e" "$CUSTOMER_NAME" name
            dialog_args+=("${CID}" "${name}")
         done
      fi

      open_dialog choice ret_val --cancel-label "Back"   \
         --menu "Customer Management" 40 40 10           \
         "Add" "Create a new customer."                  \
         "${dialog_args[@]}"                             \
         "---" "--------------"                          \
         "Back" "Go back to the main menu."              \
         "Exit" "Close this program."                    \

      case "${ret_val}" in
      "$DIALOG_CANCEL")
         return 0
         ;;
      "$DIALOG_ESC")
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

int_select_customer() {
   local IFS e dialog_args csv_customers
   local CID name choice ret_val

   dialog_args=()
   csv_read "customers" csv_customers
   csv_customers="$(sort <<< "${csv_customers}")"

   IFS="="
   for e in $(echo "${csv_customers}" | tr '\n' '='); do
      csv_get "$e" "$CUSTOMER_ID" CID
      csv_get "$e" "$CUSTOMER_NAME" name
      dialog_args+=("${CID}" "${name}")
   done

   open_dialog choice ret_val             \
      --menu "Select Customer" 40 40 10   \
      "${dialog_args[@]}"

   case "${ret_val}" in
   "$DIALOG_OK")
      eval "${1}='${choice}'"
      return 0
      ;;
   "$DIALOG_CANCEL")
      return 2
      ;;
   "$DIALOG_ESC")
      return 1
      ;;
   esac
}

int_manage_customer() {
   local choice ret_val name tmp

   cdb_search_by_ID "$1" "" tmp
   csv_get "${tmp}" "$CUSTOMER_NAME" name

   while true; do
      open_dialog choice ret_val                            \
         --title "Manage Customers"                         \
         --cancel-label "Back"                              \
         --menu "${name} ($1)" 10 60 10                     \
         "Show" "Display infomation about the customer."    \
         "Edit" "Change customer details."                  \
         "Remove" "Delete the customer from the database." 
      
      case "${ret_val}" in
      "$DIALOG_CANCEL")
         return 0
         ;;
      "$DIALOG_ESC")
         return 1
         ;;
      esac

      case "${choice}" in
      Show)
         int_show_customer "$1" || return 1
         ;;
      Edit)
         int_edit_customer "$1" || return 1
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

   csv_get "${csv_entry}" "$CUSTOMER_NAME" name
   csv_get "${csv_entry}" "$CUSTOMER_ADDRESS" address
   csv_get "${csv_entry}" "$CUSTOMER_ZIP" zip
   csv_get "${csv_entry}" "$CUSTOMER_HOURLY" rate

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
   local name address zip rate csv_entry choice ret_val title CID

   if [ "$1" ]; then
      CID="$1"
      cdb_search_by_ID "${CID}" "" csv_entry
   else
      CID="$(csv_next_ID "customers")"
      title="New Customer"
   fi

   while true; do
      csv_get "${csv_entry}" "$CUSTOMER_NAME" name
      csv_get "${csv_entry}" "$CUSTOMER_ADDRESS" address
      csv_get "${csv_entry}" "$CUSTOMER_ZIP" zip
      csv_get "${csv_entry}" "$CUSTOMER_HOURLY" rate

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
      "$DIALOG_CANCEL")
         return 0
         ;;
      "$DIALOG_ESC")
         return 1
         ;;
      esac
      
      if echo "${choice}" | grep -qF ','; then
         title="Commas are not allowed!"
         continue
      fi

      csv_entry="$(echo "${CID},$(echo "${choice}" | tr '\n' ',' | sed 's/\,$//')")"


      is_zip "$(csv_get "${csv_entry}" "$CUSTOMER_ZIP")"  || { title="Invalid ZIP"; continue; }
      is_cost "$(csv_get "${csv_entry}" "$CUSTOMER_HOURLY")"  || { title="Invalid Hourly Rate"; continue; }

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
   csv_get "${csv_entry}" "$CUSTOMER_NAME" name

   dialog --title "Remove Customer" \
      --yesno "Are you sure to remove customer '${name}'?" \
      6 60

   case "$?" in
   "$DIALOG_OK")
      cdb_remove "$1"
      git_append_msg "Removed Customer $1"
      return 0
      ;;
   "$DIALOG_CANCEL")
      return 2
      ;;
   "$DIALOG_ESC")
      return 1
      ;;
   esac
}

##################################
####### TRANSACTION STUFF ########
##################################

int_transactions() {
   local transactions e CID TID date desc customer name
   local choice ret_val IFS
   local -a dialog_args

   while true; do
      dialog_args=()
      csv_read "$(tdb_file)" transactions
      transactions="$(sort <<< "${transactions}")"

      if [[ ${transactions} ]]; then
         dialog_args=("---" "------------------------")
         IFS="="
         for e in $(echo "${transactions}" | tr '\n' '='); do
            csv_get "$e" "$TRANS_ID" TID
            csv_get "$e" "$TRANS_CID" CID
            csv_get "$e" "$TRANS_DATE" date
            csv_get "$e" "$TRANS_DESC" desc
            cdb_search_by_ID "${CID}" "" customer
            if [ "${customer}" ]; then
               csv_get "${customer}" "$CUSTOMER_NAME" name
            else
               name="${CID}"
            fi
            dialog_args+=("${TID}" "${name} ${date}: ${desc}")
         done
      fi

      open_dialog choice ret_val --cancel-label "Back"   \
         --menu "Transaction Management" 40 60 10        \
         "Add"    "Create a new transacion."             \
         "Year"   "Select a different year."             \
         "${dialog_args[@]}"                             \
         "---"    "------------------------"             \
         "Back"   "Go back to the main menu."            \
         "Exit"   "Close this program."

      case "${ret_val}" in
      "$DIALOG_CANCEL")
         return 0
         ;;
      "$DIALOG_ESC")
         return 1
         ;;
      esac

      case "${choice}" in
      Add)
         int_add_transaction
         ;;
      Year)
         int_select_year
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

int_select_year() {
   local years choice ret_val y IFS
   local -a dialog_args

   while true; do
      years="$(ls "${datadir}" | grep '^transactions_\([0-9]\{4\}\)\.csv\(\.gpg\)\?$' | sed 's/^[^0-9]\+\([0-9]\+\).*$/\1/' | sort -nr)"


      dialog_args=()
      unset IFS
      for y in ${years}; do
         dialog_args+=("${y}" "Select year ${y}.")
      done

      open_dialog choice ret_val          \
         --title "Select Year"            \
         --menu "Select Year" 20 60 20    \
         "${dialog_args[@]}"

      case "${ret_val}" in
      "$DIALOG_CANCEL")
         return 0
         ;;
      "$DIALOG_ESC")
         return 1
         ;;
      esac

      tdb_year="${choice}"
      return 0
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
      "$DIALOG_CANCEL")
         return 0
         ;;
      "$DIALOG_ESC")
         return 1
         ;;
      esac

      case "${choice}" in
      Show)
         int_show_transaction "$1" || return 1
         ;;
      Edit)
         int_edit_transaction "$1" || return 1
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
   local trans CID date num price total desc text customer cname
   tdb_search "$1" "" trans

   csv_get "${trans}" "$TRANS_CID" CID
   csv_get "${trans}" "$TRANS_DATE" date
   csv_get "${trans}" "$TRANS_NUM" num
   csv_get "${trans}" "$TRANS_PRICE" price
   csv_get "${trans}" "$TRANS_DESC" desc

   total="$(calc_total "${num}" "${price}")"

   cdb_search_by_ID "${CID}" "" customer
   csv_get "${customer}" "$CUSTOMER_NAME" cname

   [ -z "${cname}" ] && cname="(Deleted)"

   text=""
   text+="ID:           $1\n"
   text+="Customer:     ${cname} (${CID})\n"
   text+="Description:  ${desc}\n"
   text+="Date:         ${date}\n"
   text+="Count:        ${num}\n"
   text+="Price:        ${price}\n"
   text+="Total:        ${total}\n"

   dialog --title "Transaction Information" \
      --msgbox "${text}" 12 40
}

int_remove_transaction() {
   local name csv_entry

   dialog --title "Erase Transaction" \
      --yesno "Are you sure to erase transaction $1?" \
      6 60

   case "$?" in
   "$DIALOG_OK")
      tdb_remove "$1"
      git_append_msg "Removed Transaction $1"
      return 0
      ;;
   "$DIALOG_CANCEL")
      return 2
      ;;
   "$DIALOG_ESC")
      return 1
      ;;
   esac
}


int_add_transaction() {
   local customer_ID
   int_select_customer customer_ID
   case "$?" in
   0)
      int_edit_transaction ":${customer_ID}"
      ;;
   1)
      return 1
      ;;
   2)
      return 0
      ;;
   esac
}
int_edit_transaction() {
   local TID CID date num desc customer price
   local csv_entry choice ret_val cname tmp saved_year


   if echo "$1" | grep -q '^:'; then
      #CID="${1//^:/}"
      CID="$(echo "$1" | sed 's/^://')"
      TID="$(csv_next_ID "$(tdb_file)")"
      cdb_search_by_ID "${CID}" "" customer
      csv_get "${customer}" "$CUSTOMER_HOURLY" price
      if [[ ${tdb_year} = $(date +%Y) ]]; then
         date="$(date +%F)"
      fi
      csv_entry="${TID},${CID},${date},,${price},${tdb_default_desc}"
      title="New Transaction"
   else
      TID="$1"
      tdb_search "${TID}" "" csv_entry
   fi

   while true; do
      csv_get "${csv_entry}" "$TRANS_CID" CID
      csv_get "${csv_entry}" "$TRANS_DATE" date
      csv_get "${csv_entry}" "$TRANS_NUM" num
      csv_get "${csv_entry}" "$TRANS_PRICE" price
      csv_get "${csv_entry}" "$TRANS_DESC" desc


      cdb_search_by_ID "${CID}" "" customer
      if [ "${customer}" ]; then
         csv_get "${customer}}" "$CUSTOMER_NAME" cname
         [ -z "${price}" ] && \
            csv_get "${customer}" "$CUSTOMER_HOURLY" price
      else
         cname="${CID}"
      fi

      [ -z "${title}" ] && title="Transaction ${TID}"

      open_dialog choice ret_val                         \
         --title "Edit Transaction"                      \
         --form "${title}" 20 60 7                       \
         "ID"           0 0 "${TID}"         0 15 0  0   \
         "Customer"     2 0 "${cname}"       2 15 30 30  \
         "Description"  3 0 "${desc}"        3 15 30 30  \
         "Date"         4 0 "${date}"        4 15 30 30  \
         "Count"        5 0 "${num}"         5 15 30 30  \
         "Price"        6 0 "${price}"       6 15 30 30

      case "${ret_val}" in
      "$DIALOG_CANCEL")
         return 0
         ;;
      "$DIALOG_ESC")
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

      csv_entry="$(create_transaction "${TID}" "${CID}" "${date}" "${num}" "${price}" "${desc}")"

      is_number "${num}" || { title="Invalid count"; continue; }
      is_cost "${price}" || { title="Invalid price"; continue; }
      is_date "${date}"  || { title="Invalid Date"; continue; }

      cdb_search "${cname}" "" tmp
      if [ "${tmp}" ]; then
         csv_get "${tmp}" "$CUSTOMER_ID" CID
      else
         title="No such customer: ${cname}"
         csv_entry="$(create_transaction "${TID}" "${cname}" "${date}" "${num}" "${price}" "${desc}")"
         continue
      fi

      csv_entry="$(create_transaction "${TID}" "${CID}" "${date}" "${num}" "${price}" "${desc}")"
      break
   done

   tdb_remove "${TID}"

   saved_year="${tdb_year}"
   tdb_year="$(cut -d'-' -f1 <<<"${date}")"
   csv_append "$(tdb_file)" "${csv_entry}"
   tdb_year="${saved_year}"

   if echo "$1" | grep -q '^:'; then
      git_append_msg "Added Transaction ${TID}"
   else
      git_append_msg "Changed Transaction Details for ${TID}"
   fi
}

##################################
###### CONFIGURATION STUFF #######
##################################

int_config() {
   local choice ret_val title name value line lines i file
   local -a config forms

   title=""

   mapfile -t lines <"${conffile}"

   while true; do
      forms=()
      i=0
      for line in "${lines[@]}"; do
         if grep -q '^## ' <<<"${line}"; then
            #name="${line//^## /}"
            name="$(sed 's/^## //' <<<"${line}")"
            #[[ $i != 0 ]] && forms[$i]="\"\" $i 0 \"\" $i 33 0 0" && i=$((i + 1))
            forms+=("${name}" "$i" 0 "" "$i" 33 0 0)
         elif grep -q '^# ' <<<"${line}"; then
            #name="${line//^# /}"
            name="$(sed 's/^# //' <<<"${line}")"
            forms+=("${name}" "$i" 0 "" "$i" 33 0 0)
         elif grep -q '^[a-zA-Z_]\+=.*$' <<<"${line}"; then
            name="$(cut -d'=' -f1 <<<"${line}")"
            value="$(cut -d'=' -f2 <<<"${line}" | sed -e "s/^[\"']//" -e "s/[\"']$//")"
            forms+=("${name}" "$i" 0 "${value}" "$i" 33 45 45)
            config+=("${name}=${value}")
         fi
         

         i=$((i + 1))
      done

      open_dialog choice ret_val             \
         --title "Edit accounthing.conf"     \
         --form "${title}" 28 80 30          \
         "${forms[@]}"

      case "${ret_val}" in
      "$DIALOG_CANCEL")
         return 0
         ;;
      "$DIALOG_ESC")
         return 1
         ;;
      esac

      i=0
      while read -r line; do
         name="$(cut -d'=' -f1 <<<"${config[$i]}")"
         config[$i]="${name}=\"${line}\""
         i=$((i + 1))
      done <<<"${choice}"


      for (( i = 0; i < "${#lines[@]}"; i++ )); do
         line="${lines[$i]}"
         grep -q '^[a-zA-Z_]\+=.*$' <<<"${line}" || continue
         name="$(cut -d'=' -f1 <<<"${line}")"
         for opt in "${config[@]}"; do
            grep -q "^${name}=" <<<"${opt}" && break
         done
         lines[$i]="${opt}"
      done

      for opt in "${config[@]}"; do
         name="$(cut -d'=' -f1 <<<"${opt}")"
         value="$(cut -d'=' -f2 <<<"${opt}" | sed -e "s/^['\"]//" -e "s/['\"]$//")"
         grep -q '^enable_' <<<"${name}" && ! is_bool "${value}" && { failed=1; title="${name} expects a boolean value"; break; }
      done
      [[ ${failed} = 1 ]] && continue

      mv "${conffile}" "${conffile}.bak"
      for line in "${lines[@]}"; do
         echo "${line}" >>"${conffile}"
      done
      break
   done

   dialog --title "Config" --colors --msgbox "Config saved as \Z4\Zb$(realpath "${conffile}")\Zn" 6 80

}

##################################
######## GIT INTEGRATION #########
##################################

int_git() {
   local ret_val choice commit ref msg
   local -a commits dialog_args

   while true; do
      dialog_args=()
      if git_read_commits commits; then
         for commit in "${commits[@]}"; do
            ref="$(cut -d',' -f1 <<<"${commit}")"
            msg="$(cut -d',' -f2 <<<"${commit}")"
            dialog_args+=("${ref}" "${msg}")
         done
      fi

      dialog_args+=("---" "--------------")
      dialog_args+=("Commit"  "Commit all outstanding changes.")
      dialog_args+=("Push"    "Push all changes to the remotes.")
      dialog_args+=("Options" "Configure the Git repo.")
      dialog_args+=("Back"    "Go back to the main menu.")
      dialog_args+=("Exit"    "Close this program.")
 
      open_dialog choice ret_val       \
         --title "Git Integration"     \
         --menu "Git Commit" 28 80 25  \
         "${dialog_args[@]}"

      case "${ret_val}" in
      "$DIALOG_CANCEL")
         return 0
         ;;
      "$DIALOG_ESC")
         return 1
         ;;
      esac

      case "${choice}" in
      ---)
         continue
         ;;
      Commit)
         git_commit
         ;;
      Push)
         int_git_push
         ;;
      Options)
         int_git_options
         ;;
      Back)
         return 0
         ;;
      Exit)
         return 1
         ;;
      *)
         int_manage_commit "${choice}"
         ;;
      esac
      [[ $? -ne 0 ]] && return 1
   done

}

# Arguments:
#   $1 - commit hash
int_manage_commit() {
   local choice ret_val name tmp

   while true; do
      open_dialog choice ret_val                            \
         --title "Manage Commit"                            \
         --cancel-label "Back"                              \
         --menu "Commit $1" 10 60 10                        \
         "Show"   "Display the commit."                     \
         "Reset"  "Reset the database to this commit."
      
      case "${ret_val}" in
      "$DIALOG_CANCEL")
         return 0
         ;;
      "$DIALOG_ESC")
         return 1
         ;;
      esac

      case "${choice}" in
      Show)
         int_show_commit "$1"
         ;;
      Reset)
         int_reset_commit "$1"
         ;;
      esac
      case "$?" in
      0)
         continue
         ;;
      1)
         return 1
         ;;
      2)
         return 0
         ;;
      esac
   done
}

# Arguments:
#   $1 - commit hash
int_show_commit() {
   local text

   text="$(git_show_message "$1" "Hash: %H%nFrom: %cn <%ce>%nDate: %cr%nMessage: %s%n%b")"

   dialog --title "Commit Information" \
      --msgbox "${text}" 10 60
}

# Arguments:
#   $1 - commit hash
int_reset_commit() {
   local text ret_val
   text+="Do you really want to reset the databases to commit $1?\n"
   text+="This will irreversibly delete all commits made after it."
   dialog --title "Reset to commit $1" --yesno "${text}" 7 70
   ret_val="$?"

   echo "${ret_val}"

   case "${ret_val}" in
   "$DIALOG_OK")
      git_reset "$1"
      dialog --title "Reset to commit $1" --msgbox "Databases were reset to commit $1." 5 60
      return 2
      ;;
   "$DIALOG_CANCEL")
      return 0
      ;;
   "$DIALOG_ESC")
      return 1
      ;;
   esac
}

int_git_options() {
   local choice ret_val
   while true; do
      open_dialog choice ret_val                   \
         --title "Git Integration"                 \
         --menu "Git Options" 28 80 25             \
         "Remote" "Add/Remove external repos."     \
         "Back"   "Go back to the previous menu."  \
         "Exit"   "Close this program."

      case "${ret_val}" in
      "$DIALOG_CANCEL")
         return 0
         ;;
      "$DIALOG_ESC")
         return 1
         ;;
      esac

      case "${choice}" in
      Remote)
         int_git_remote || return 1
         ;;
      Back)
         return 0
         ;;
      Exit)
         return 1
         ;;
      esac
   done
}

int_git_remote() {
   local choice ret_val remote IFS
   local -A remotes
   local -a dialog_args

   while true; do
      dialog_args=()
      git_get_remotes dialog_args

      dialog_args+=("---" "--------------")
      dialog_args+=("Add"  "Add an external Git repository.")
      dialog_args+=("Help" "Help on setting up your own Git server.")
      dialog_args+=("Back" "Go back to the main menu.")
      dialog_args+=("Exit" "Close this program.")
      
      open_dialog choice ret_val                   \
         --title "Git Integration"                 \
         --menu "Git Remotes" 28 80 25             \
         "${dialog_args[@]}"

      case "${ret_val}" in
      "$DIALOG_CANCEL")
         return 0
         ;;
      "$DIALOG_ESC")
         return 1
         ;;
      esac

      case "${choice}" in
      ---)
         continue
         ;;
      Add)
         int_git_add_repo
         ;;
      Help)
         int_git_help_server || return 1
         ;;
      Back)
         return 0
         ;;
      Exit)
         return 1
         ;;
      *)
         int_git_manage_remote "${choice}" || return 1
         ;;
      esac
   done
}

int_git_add_repo() {
   local ret_val name URI msg

   open_dialog name ret_val         \
      --title     "Add Git Remote"  \
      --inputbox  "Name" 10 60

   case "${ret_val}" in
   "$DIALOG_CANCEL")
      return 0
      ;;
   "$DIALOG_ESC")
      return 1
      ;;
   esac

   open_dialog URI ret_val          \
      --title "Add Git Remote"      \
      --inputbox "URI" 10 60

   case "${ret_val}" in
   "$DIALOG_CANCEL")
      return 0
      ;;
   "$DIALOG_ESC")
      return 1
      ;;
   esac

   msg="Failed to add Git Repo:\n$(git_do remote add "${name}" "${URI}" 2>&1)" && msg="Added git remote '${name}'"

   dialog --title "Add Git Remote"  \
      --msgbox "${msg}" 8 60

   return 0
}

# Arguments:
#   $1 - remote
int_git_show_remote() {
   local text

   text="$(git_do remote show -n "$1")"

   dialog --title "Git Remote Info" \
      --msgbox "${text}" 15 80
}

# Arguments:
#   $1 - remote
int_git_manage_remote() {
   local choice ret_val

   while true; do
      open_dialog choice ret_val                            \
         --title "Manage Git Remote"                        \
         --cancel-label "Back"                              \
         --menu "$1" 10 60 10                               \
         "Show"   "Display infomation about the customer."  \
         "Push"   "Send data to the remote."                \
         "Remove" "Delete the customer from the database." 
      
      case "${ret_val}" in
      "$DIALOG_CANCEL")
         return 0
         ;;
      "$DIALOG_ESC")
         return 1
         ;;
      esac

      case "${choice}" in
      Show)
         int_git_show_remote "$1" || return 1
         ;;
      Push)
         int_git_push "$1"
         ;;
      Remove)
         int_git_remove_remote "$1"
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

# Arguments:
#   $1 - remote
int_git_remove_remote() {
   dialog --title "Remove Git Remote" \
      --yesno "Are you sure to remove Git remote '$1'?" \
      6 60

   case "$?" in
   "$DIALOG_OK")
      git_do remote remove "$1"
      return 0
      ;;
   "$DIALOG_CANCEL")
      return 2
      ;;
   "$DIALOG_ESC")
      return 1
      ;;
   esac
}

int_git_help_server() {
   xdg-open "https://git-scm.com/book/en/v2/Git-on-the-Server-Setting-Up-the-Server" 2>/dev/null >&2
}

# Arguments:
#   $1 - remote
int_git_push() {
   local msg

   if [[ $1 ]]; then
      msg="$(git_push "$1" 2>&1)" && return 0
   else
      msg="$(git_push_all 2>&1)" && return 0
   fi

   dialog --title "Git Push Failed"    \
      --msgbox "${msg}" 20 60
}
