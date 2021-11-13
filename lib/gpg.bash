# shellcheck shell=bash
# Encryption/Decryption module
# Dependencies:
# - error.sh

export GPG_TTY="$(tty)"

if [ -z "${GPG}" ]; then
   GPG="$(which gpg || which gpg2)"
   [ -z "${GPG}" ] && error "GNU Privacy Guard (gpg) is not installed."
fi

# Encrypt standard input.
# Arguments:
#   $1 - file
encrypt() {
   "${GPG}" --yes -o "$1" -e --default-recipient-self 2>/dev/null
}

decrypt() {
   "${GPG}" -d 2>/dev/null
}

