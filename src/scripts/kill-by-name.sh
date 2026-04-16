#!/usr/bin/env zsh
set -eo pipefail
export PATH="/usr/bin:/bin:/usr/sbin:/sbin:$PATH"

force=0
all=0
while [[ "$1" == --* ]]; do
	case "$1" in
		--force) force=1 ;;
		--all) all=1 ;;
	esac
	shift
done

target="$1"
signal=15
verb="Terminated"
if (( force )); then
	signal=9
	verb="Force killed"
fi

# "all:<query>" prefix from list-processes.sh opts this row into mass kill
if [[ "$target" == all:* ]]; then
	all=1
	target="${target#all:}"
fi

if (( all )); then
	if pkill "-$signal" -i -- "$target"; then
		echo "$verb all: $target"
	else
		echo "No processes found: $target"
	fi
	exit 0
fi

if kill "-$signal" "$target" 2>/dev/null; then
	echo "$verb PID $target"
else
	echo "Could not ${verb:l} PID $target"
fi
