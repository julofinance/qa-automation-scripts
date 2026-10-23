#!/bin/bash
# Manage the encrypted secrets file for tools_script (GPG symmetric, AES256).
#
#   ./secrets.sh encrypt   # .env      -> .env.gpg  (commit .env.gpg)
#   ./secrets.sh decrypt   # .env.gpg  -> .env      (never commit .env)
#   source ./secrets.sh load   # decrypt into memory and export vars to current shell
#
# Passphrase is taken from $TOOLS_SCRIPT_GPG_PASSPHRASE if set, otherwise gpg prompts for it.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLAIN="$SCRIPT_DIR/.env"
ENCRYPTED="$SCRIPT_DIR/.env.gpg"

gpg_args=(--batch --yes --quiet --pinentry-mode loopback)
if [ -n "$TOOLS_SCRIPT_GPG_PASSPHRASE" ]; then
    gpg_args+=(--passphrase-fd 3)
    exec 3<<<"$TOOLS_SCRIPT_GPG_PASSPHRASE"
else
    gpg_args=(--yes --quiet)
fi

case "$1" in
    encrypt)
        [ -f "$PLAIN" ] || { echo "$PLAIN not found (copy .env.example to .env and fill it)."; exit 1; }
        gpg "${gpg_args[@]}" --symmetric --cipher-algo AES256 --output "$ENCRYPTED" "$PLAIN" \
            && echo "Encrypted -> $ENCRYPTED"
        ;;
    decrypt)
        [ -f "$ENCRYPTED" ] || { echo "$ENCRYPTED not found."; exit 1; }
        (umask 077; gpg "${gpg_args[@]}" --decrypt --output "$PLAIN" "$ENCRYPTED") \
            && echo "Decrypted -> $PLAIN"
        ;;
    load)
        [ -f "$ENCRYPTED" ] || { echo "$ENCRYPTED not found."; return 1 2>/dev/null || exit 1; }
        set -a
        source <(gpg "${gpg_args[@]}" --decrypt "$ENCRYPTED")
        set +a
        echo "Secrets exported to current shell."
        ;;
    *)
        echo "Usage: $0 {encrypt|decrypt|load}"
        exit 1
        ;;
esac
exec 3<&-
