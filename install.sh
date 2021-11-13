#!/bin/sh

if [ $# -eq 1 ]; then
   DESTDIR=""
   prefix="$(realpath "$1")"
elif [ $# -eq 2 ]; then
   DESTDIR="$(realpath "$1")"
   prefix="$2"
else
   echo "Usage: $0 [DESTDIR] prefix" >&2
   exit 1
fi

# The program name.
prog_name="accounthing"

# Check if this script is run from the directory, where the program is in.
if [ ! -f "./${prog_name}.sh" ]; then
   echo "Please ensure that you are running this script from the correct directory." >&2
   exit 1
fi

# Check for the existence of the logo file.
if [ ! -f "./invoice/Logo.png" ]; then
   echo "Please create a 'invoice/Logo.png' file." >&2
   echo "You can use 'invoice/Logo.xcf' as an example." >&2
   exit 1
fi

# Set the default directories paths.
[ -z "${bindir}" ]      && bindir="${prefix}/bin"
[ -z "${libdir}" ]      && libdir="${prefix}/lib"
[ -z "${invoicedir}" ]  && invoicedir="${prefix}/invoice"
[ -z "${datadir}" ]     && datadir="${prefix}/db"
[ -z "${conffile}" ]    && conffile="${prefix}/etc/${prog_name}.conf"

# Install all necessary directories.
install -vdm755               \
   "${DESTDIR}${bindir}"     \
   "${DESTDIR}${libdir}"     \
   "${DESTDIR}${invoicedir}" \
   "${DESTDIR}${datadir}"    || exit 1

# Install the program.
install -vDm755 "${prog_name}.sh" \
   "${DESTDIR}${bindir}/${prog_name}" || exit 1

# Patch the paths of the program.
echo "Patching ${prog_name}..." >&2
sed -i                                                      \
   -e "s,prefix=.*,prefix=${prefix},"                       \
   -e "s,libdir=.*,libdir=${libdir},"                       \
   -e "s,invoicedir=.*,invoicedir=${invoicedir},"           \
   -e "s,datadir=.*,datadir=${datadir},"                    \
   -e "s,conffile=.*,conffile=${conffile},"                 \
   "${DESTDIR}${bindir}/${prog_name}"                      || exit 1


install -vDm644 ./lib/* "${DESTDIR}${libdir}" || exit 1

# Install the template invoice.
install -vDm644               \
   "invoice/template.tex"     \
   "invoice/invoice.cls"      \
   "invoice/Logo.png"         \
   "${DESTDIR}${invoicedir}" || exit 1

# Install the config file.
install -vDm644 "config.sh" "${DESTDIR}${conffile}" || exit 1
