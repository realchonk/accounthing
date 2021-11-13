#!/bin/bash

# These will be changed by `./install.sh`
prefix="$(dirname "$0")"
libdir="${prefix}/lib"
invoicedir="${prefix}/invoice"
datadir="${prefix}/db"
conffile="${prefix}/config.sh"

prog="$(basename "$0")"

# Load libdir

# shellcheck source=config.sh
. "${conffile}"

# shellcheck source=lib/git.bash
. "${libdir}/git.bash"

# shellcheck source=lib/customers.bash
. "${libdir}/customers.bash"

# shellcheck source=lib/error.bash
. "${libdir}/error.bash"

# shellcheck source=lib/gpg.bash
. "${libdir}/gpg.bash"

# shellcheck source=lib/util.bash
. "${libdir}/util.bash"

# shellcheck source=lib/csv.bash
. "${libdir}/csv.bash"

# shellcheck source=lib/transactions.bash
. "${libdir}/transactions.bash"

# shellcheck source=lib/invoice.bash
. "${libdir}/invoice.bash"


[ $# -lt 1 ] && echo "Usage: ${prog} -h" >&2 && exit 1

case "$1" in
-h)
   echo "Usage: ${prog} [options]"
   echo
   echo "Options:"
   echo "  -h                 Show this help page."
   echo "  -sc name/ID        Search for a customer."
   echo "  -ac                Add a new customer."
   echo "  -lc                List all customers."
   echo "  -pc                Dump the customer database."
   echo "  -rc name/ID        Remove a customer."
   echo "  -st term           Search for a transaction."
   echo "  -at                Add a new transaction."
   echo "  -lt [year]         List all transactions during the current year or a specified year."
   echo "  -pt                Dump the transaction database."
   echo "  -rt ID             Remove a transaction."
   echo "  -i customer month  Generate an invoice for a particular customer."
   echo "  -ia month          Generate invoices for all transactions during a month."
   exit
   ;;
-sc)
   [ -z "$2" ] && echo "Usage: ${prog} $1 name/ID" >&2 && exit 1
   cdb_print "$2"
   ret="$?"
   ;;
-st)
   [ -z "$2" ] && echo "Usage: ${prog} $1 name/ID" >&2 && exit 1
   tdb_print "$2"
   ret="$?"
   ;;
-lc)
   cdb_list
   ret="$?"
   ;;
-lt)
   if [ -z "$2" ]; then
      tdb_list
      ret="$?"
   else
      tdb_list "$2"
      ret="$?"
   fi
   ;;
-pc)
   csv_read "customers"
   ret="$?"
   ;;
-pt)
   csv_read "${tdb_file}"
   ret="$?"
   ;;
-ac)
   cdb_add_i
   ret="$?"
   ;;
-at)
   tdb_add_i
   ret="$?"
   ;;
-rc)
   [ -z "$2" ] && echo "Usage: ${prog} $1 name/ID" >&2 && exit 1
   cdb_remove_i "$2"
   ret="$?"
   ;;
-rt)
   [ -z "$2" ] && echo "Usage: ${prog} $1 ID" >&2 && exit 1
   tdb_remove_i "$2"
   ret="$?"
   ;;
-i)
   ([ -z "$2" ] || [ -z "$3" ]) && echo "Usage: ${prog} $1 customer month" >&2 && exit 1
   generate_invoice "$2" "$3"
   ret="$?"
   ;;
-ia)
   if [ -z "$2" ]; then
      generate_all_invoices "$(date +"%Y-%m")"
      ret="$?"
   else
      generate_all_invoices "$2"
      ret="$?"
   fi
   ;;
*)
   echo "${prog}: invalid option '$1'" >&2
   exit 1
   ;;
esac

git_commit || echo "Failed to commit"

exit "${ret}"
