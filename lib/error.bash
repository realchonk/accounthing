# shellcheck shell=bash
# Error handling module


error() {
   echo "Error: $1" >&2
   exit 1
}
