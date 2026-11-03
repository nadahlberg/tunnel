#!/bin/sh
# Mirror the GitHub keys of every allowed user into sish's authorized-keys
# directory. sish reloads the directory on its own. The user list comes from
# the first of these that is set (see README):
#   ALLOWED_USERS      comma-separated GitHub usernames
#   ALLOWED_USERS_URL  URL or local path of a text file, one username per line
#   (default)          the `users` file on this repo's main branch
# Any fetch failure aborts before rsync, so a GitHub blip never wipes keys.
set -eu
[ -f /opt/tunnel/.env ] && . /opt/tunnel/.env
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

if [ -n "${ALLOWED_USERS:-}" ]; then
	printf '%s\n' "$ALLOWED_USERS" | tr ',' '\n' >"$tmp/users"
else
	src=${ALLOWED_USERS_URL:-https://raw.githubusercontent.com/nadahlberg/tunnel/main/users}
	case "$src" in
	http://* | https://*) curl -fsS "$src" >"$tmp/users" ;;
	*) cat "$src" >"$tmp/users" ;;
	esac
fi

sed 's/#.*//' "$tmp/users" | tr -d ' \t\r' | grep -v '^$' | sort -u | while read -r user; do
	curl -fsS "https://github.com/$user.keys" >"$tmp/$user.pub" </dev/null
done
mkdir -p /opt/tunnel/pubkeys
rsync -a --delete --exclude users "$tmp/" /opt/tunnel/pubkeys/
