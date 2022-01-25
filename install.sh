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

failed=0

# Arguments:
#   $1 - program
#   $2 - optional?
check_dep() {
   if ! which $1 >/dev/null 2>&1; then
      echo "Warning: '$1' is not installed" >&2
      [ "$2" = 1 ] || failed=1
   fi
}

# Args:
#   $1 - src
#   $2 - dest
install_norep() {
   [ -f "$2" ] || install -vDm644 "$1" "$2"
}

# Check if which is installed
which which >/dev/null 2>&1
if [ $? -eq 127 ]; then
   echo "'which' is not installed" >&2
   exit 1
fi

# Check for other dependencies
check_dep "bash"
check_dep "pdflatex"
check_dep "gpg" 1
check_dep "git" 1
check_dep "dialog" 1
check_dep "zenity" 1

[ "${failed}" = 1 ] && exit 1

# Set the default directories paths.
[ -z "${bindir}" ]      && bindir="${prefix}/bin"
[ -z "${libdir}" ]      && libdir="${prefix}/lib"
[ -z "${invoicedir}" ]  && invoicedir="${prefix}/invoice"
[ -z "${datadir}" ]     && datadir="${prefix}/db"
[ -z "${conffile}" ]    && conffile="${prefix}/etc/${prog_name}.conf"
[ -z "${mandir}" ]      && mandir="${prefix}/share/man"

# Install all necessary directories.
install -vdm755               \
   "${DESTDIR}${bindir}"      \
   "${DESTDIR}${libdir}"      \
   "${DESTDIR}${invoicedir}"  \
   "${DESTDIR}${mandir}"      \
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
install_norep "invoice/template.tex"   "${DESTDIR}${invoicedir}/template.tex"
install_norep "invoice/invoice.cls"    "${DESTDIR}${invoicedir}/invoice.cls"
install_norep "invoice/Logo.png"       "${DESTDIR}${invoicedir}/Logo.png"

# Install the config file.
install_norep "config.sh"              "${DESTDIR}${conffile}"

# Install the man page.
install -vDm644 "${prog_name}.1" "${DESTDIR}${mandir}/man1/${prog_name}.1" || exit 1
