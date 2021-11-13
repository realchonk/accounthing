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

# Invoice Generation
# Dependencies:
# - customers
# - transactions
# - error

invoice_template_file="${invoicedir}/template.tex"
invoice_latex_file="${invoicedir}/invoice.tex"
next_invoice_file="${invoicedir}/next_invoice"
hourrows_temp_file="${invoicedir}/hourrows.tmp"

[ ! -d "${invoicedir}" ] && error "${invoicedir}: No such directory"

# Stdin:
#   TDB entries
# Returns:
#   \hourrow{date}{num}
invoice_hourrows() {
   local line date num desc last_desc
   while read -r line; do
      desc="$(echo "${line}" | cut -d',' -f6)"
      [ "${desc}" != "${last_desc}" ] && printf '\\feetype{%s}\n' "${desc}"
      date="$(date --date="$(echo "${line}" | cut -d',' -f3)" +"%x")"
      num="$(echo "${line}" | cut -d',' -f4)"
      printf '\\hourrow{%s}{%s}\n' "${date}" "${num}"
      last_desc="${desc}"
   done
}

# Replace all variables in the template
# Arguments:
#   $1 - CDB entry
# Stdin:
#   template
# Stdout:
#   pre-generated latex
invoice_pass1() {
   local IID CID name address zip taxID

   IID="$(next_invoice)"
   CID="$(echo "$1" | cut -d',' -f1)"
   name="$(echo "$1" | cut -d',' -f2)"
   address="$(echo "$1" | cut -d',' -f3)"
   zip="$(echo "$1" | cut -d',' -f4)"
   rate="$(echo "$1" | cut -d',' -f5)"
   
   taxID="$(echo "${vendor_taxID}" | sed 's,/,\\\\slash{},g')"

   sed                                             \
      -e "s/%CUSTOMER_ID%/${CID}/"                 \
      -e "s/%CUSTOMER_NAME%/${name}/"              \
      -e "s/%CUSTOMER_ADDRESS%/${address}/"        \
      -e "s/%CUSTOMER_ZIP%/${zip}/"                \
      -e "s/%CUSTOMER_HOURLY%/${rate}/"            \
      -e "s/%VENDOR_NAME%/${vendor_name}/"         \
      -e "s/%VENDOR_OWNER%/${vendor_owner}/"       \
      -e "s/%VENDOR_ADDRESS%/${vendor_address}/"   \
      -e "s/%VENDOR_ZIP%/${vendor_zip}/"           \
      -e "s/%VENDOR_EMAIL%/${vendor_email}/"       \
      -e "s/%VENDOR_IBAN%/${vendor_iban}/"         \
      -e "s/%VENDOR_BIC%/${vendor_bic}/"           \
      -e "s/%VENDOR_BANK%/${vendor_bank}/"         \
      -e "s,%VENDOR_TAXID%,${taxID},"              \
      -e "s/%INVOICE_ID%/${IID}/"
}

# Replace %WORK%
# Arguments:
#   $1 - transactions
invoice_pass2() {
   echo "$1" | invoice_hourrows >"${hourrows_temp_file}"
   sed -e "/%WORK%/r${hourrows_temp_file}" -e '/%WORK%/d'

   rm "${hourrows_temp_file}"
}

# Print the ID of the next invoice.
next_invoice() {
   local file num year
   file="${next_invoice_file}"
   if [ -e "${file}" ] && grep -q '^[0-9]\{3\}-[0-9]\{4\}' "${file}"; then
      num="$(cut -d'-' -f1 "${file}")"
      year="$(cut -d'-' -f2 "${file}")"
      if [ "${year}" -ne "$(date +%Y)" ]; then
         num=001
         year="$(date +%Y)"
      fi
   else
      num=001
      year="$(date +%Y)"
   fi
   echo "${num}-${year}"

   # Increment num
   num="$(increment_ID "${num}" 3)"

   # Update ${file}
   echo "${num}-${year}" > "${file}"
}

# Generates an invoice written in LaTeX.
# Arguments:
#   $1 - CID
#   $2 - month
# Return:
#   LaTeX invoice
generate_invoice() {
   local customer transactions
   customer="$(cdb_search "$1")"
   transactions="$(tdb_search "$2:$1")"

   [ -z "${customer}" ] && echo "$1: No such customer" >&2 && exit 1
   [ -z "${transactions}" ] && echo "$2: Couldn't find any transactions" >&2 && exit 1

   invoice_pass1 "${customer}" <"${invoice_template_file}" \
   | invoice_pass2 "${transactions}" \
   >"${invoice_latex_file}"

   pushd "${invoicedir}" >/dev/null
   log="$(pdflatex "$(basename "${invoice_latex_file}")" </dev/null)"
   if [ $? -ne 0 ]; then
      echo "${log}" >&2
      return 1
   fi
   popd >/dev/null

   rm -f "${invoicedir}/invoice.aux"
   rm -f "${invoicedir}/invoice.log"
   rm -f "${invoicedir}/invoice.tex"
   mv "${invoicedir}/invoice.pdf" "./invoice.pdf"
}

# Arguments:
#   $1 - month
generate_all_invoices() {
   local c outfile
   mkdir -p "${invoice_output_dir}" || exit 1
   for c in $(tdb_search "$1" | cut -d',' -f2 | sort | uniq); do
      outfile="${invoice_output_dir}/invoice_${c}_$(date +"%Y-%m").pdf"
      generate_invoice "$c"
      [ $? -ne 0 ] && echo "${outfile}: Failed" >&2 && return 1
      mv "invoice.pdf" "${outfile}"
      echo "${outfile}: Done" >&2
   done
}

