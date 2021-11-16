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

# Version information

# !!! IMPORTANT !!!
# Increment this version number if you change the layout of the databases.
DB_VERSION=1

versionfile="${datadir}/version"

# Get the version of the databases.
# If the version file does not exist,
# create it and set it to the current version.
db_version() {
   if [ -e "${versionfile}" ]; then
      cat "${versionfile}"
   else
      echo "${DB_VERSION}" | tee "${versionfile}"
   fi
}

# Checks the version of this program with the version the databases were created with.
check_version() {
   local ver="$(db_version)"
   
   if [ "${ver}" -lt "${DB_VERSION}" ]; then
      error "The databases were created with an older version of this program. Automatic upgrading is not yet implemented, therefore please look up instructions on how to upgrade your databases."
   elif [ "${ver}" -gt "${DB_VERSION}" ]; then
      error "The databases were created with a newer version of this program, please update to the latest versio."
   fi
}
