#!/bin/sh
# ttyd target. $1 is the Cloudflare-authenticated email (or "anonymous").
#
# - "anonymous" or empty: anon dgamelaunch menu.
# - Email matches a dgl row: greet, then auto-login via -l.
# - Email is real but unknown: prompt for a new username, create the
#   account with an empty (but properly salted+hashed) password, then
#   auto-login via -l. The user is told to change their password.
set -eu

DB=/var/dgl-chroot/dgldir/dgamelaunch.db
email="${1:-anonymous}"

case "$email" in
    ""|anonymous)
        exec /usr/local/bin/dgamelaunch
        ;;
esac

sql_email=$(printf '%s' "$email" | sed "s/'/''/g")
match=$(sqlite3 -readonly "$DB" \
    "SELECT username FROM dglusers WHERE lower(email) = lower('$sql_email') LIMIT 1;")

if [ -n "$match" ]; then
    printf '\033[2J\033[H'
    printf '\nWelcome back, %s! Press enter to continue..' "$match"
    read -r _ || true
    exec /usr/local/bin/dgamelaunch -l "$match"
fi

# --- New-account flow ------------------------------------------------------
printf '\033[2J\033[H\n'
printf 'No account found for %s.\n\n' "$email"
printf 'Let'\''s create one.\n\n'

while :; do
    printf 'Choose a username (alphanumeric or _, max 20 chars): '
    read -r choice || exit 0

    case "$choice" in
        "")
            printf 'Username cannot be empty.\n\n'
            continue
            ;;
        *[!a-zA-Z0-9_]*)
            printf 'Username must be alphanumeric or underscore.\n\n'
            continue
            ;;
    esac
    if [ "${#choice}" -gt 20 ]; then
        printf 'Username too long (max 20 chars).\n\n'
        continue
    fi

    sql_choice=$(printf '%s' "$choice" | sed "s/'/''/g")
    if [ -n "$(sqlite3 -readonly "$DB" \
        "SELECT 1 FROM dglusers WHERE username = '$sql_choice' LIMIT 1;")" ]; then
        printf 'Username "%s" is already taken. Try another.\n\n' "$choice"
        continue
    fi

    break
done

hash='dgW3V3VCexLpc'

sqlite3 "$DB" "INSERT INTO dglusers (username, email, env, password, flags)
               VALUES ('$sql_choice', lower('$sql_email'), '', '$hash', 0);"

# Filesystem setup matching existing dgl users (games:games = 5:60).
# `install -d` only applies -m/-o/-g to the leaf, so create both explicitly.
user_dir="/var/dgl-chroot/dgldir/userdata/$choice"
install -d -m 0755 -o 5 -g 60 "$user_dir"
install -d -m 0755 -o 5 -g 60 "$user_dir/ttyrec"
install -m 0664 -o 5 -g 60 \
    /var/dgl-chroot/dgl-default.nethackrc \
    "$user_dir/$choice.nethackrc"

printf '\nAccount "%s" created.\n\n' "$choice"
printf 'If you want to login via ssh, change your password first.\n\n'
printf 'Press enter to continue..'
read -r _ || true
exec /usr/local/bin/dgamelaunch -l "$choice"
