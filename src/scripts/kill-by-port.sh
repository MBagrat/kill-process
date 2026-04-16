#!/usr/bin/env zsh
set -eo pipefail
export PATH="/usr/bin:/bin:/usr/sbin:/sbin:$PATH"

force=0
if [[ "$1" == --force ]]; then
	force=1
	shift
fi

PORT="$1"

if [[ -z "$PORT" || ! "$PORT" =~ ^[0-9]+$ ]] || (( PORT < 1 || PORT > 65535 )); then
	echo "Invalid port: '$PORT' (must be 1-65535)"
	exit 1
fi

signal=15
verb="Terminated"
if (( force )); then
	signal=9
	verb="Force killed"
fi

PID=$(lsof -t -i :"$PORT" -sTCP:LISTEN 2>/dev/null || true)

if [[ -z "$PID" ]]; then
	echo "No process found on port $PORT"
	exit 0
fi

if echo "$PID" | xargs kill "-$signal"; then
	echo "$verb port $PORT (PID: $PID)"
else
	echo "Could not ${verb:l} port $PORT"
fi
