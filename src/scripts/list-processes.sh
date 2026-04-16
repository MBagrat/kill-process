#!/usr/bin/env zsh
set -eo pipefail
export PATH="/usr/bin:/bin:/usr/sbin:/sbin:$PATH"
query="$1"
query="${query#"${query%%[![:space:]]*}"}"
query="${query%"${query##*[![:space:]]}"}"

json_escape() { local s="${1//\\/\\\\}"; printf '%s' "${s//\"/\\\"}"; }

# Fetch processes: PID, %CPU, and Command (Path)
# -A: all processes, -ww: wide output (prevents truncation)
all_procs=$(ps -Aww -o pid= -o %cpu= -o comm=)

if [[ -z "$query" ]]; then
	# No search query: show top 50 by CPU (|| true: head closes the pipe early, causing SIGPIPE on sort)
	processes=$(echo "$all_procs" | sort -nrk 2 | head -n 50 || true)
else
	# Filter by query, case-insensitive (grep exits 1 on no match — || true prevents -e from triggering)
	processes=$(echo "$all_procs" | grep -iF "$query" || true)
fi

if [[ -z "$processes" ]]; then
	escaped_query=$(json_escape "$query")
	echo '{"items": [{"title": "No processes found for \"'"$escaped_query"'\"", "subtitle": "Try a different name...", "valid": false}]}'
	exit 0
fi

echo '{"items": ['

# Show "Kill All" option only if there is a query and more than one match
count=$(echo "$processes" | wc -l | xargs)

if [[ -n "$query" && ${#query} -ge 3 && $count -gt 1 ]]; then
	escaped_query=$(json_escape "$query")
	echo "{"
	echo "  \"title\": \"Kill ALL processes matching '$escaped_query'\", "
	echo "  \"subtitle\": \"Found $count matches. Runs: pkill -9 -i '$escaped_query'\", "
	echo "  \"arg\": \"all:$escaped_query\", "
	echo "  \"variables\": { \"process_name\": \"$escaped_query\" },"
	echo "  \"icon\": { \"path\": \"/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/AlertStopIcon.icns\" }"
	echo "},"
fi

while IFS= read -r line; do
	[[ -z "$line" ]] && continue

	read -r pid cpu path <<< "$line"

	display_name="${path##*/}"
	icon_path="$path"
	icon_type="fileicon"

	if [[ "$path" == *".app/"* ]]; then
		app_bundle="${path%%.app/*}.app"
		display_name="${app_bundle##*/}"
		display_name="${display_name%.app}"
		icon_path="$app_bundle"
	fi

	# Fall back to generic icon for kernel threads and unresolvable paths
	if [[ ! -e "$icon_path" ]]; then
		icon_path="/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/Everyone.icns"
		icon_type=""
	fi

	display_name=$(json_escape "$display_name")
	escaped_path=$(json_escape "$path")
	escaped_icon_path=$(json_escape "$icon_path")

	if [[ -n "$icon_type" ]]; then
		icon_json="{ \"type\": \"$icon_type\", \"path\": \"$escaped_icon_path\" }"
	else
		icon_json="{ \"path\": \"$escaped_icon_path\" }"
	fi

	echo "{"
	echo "  \"title\": \"$display_name\", "
	echo "  \"subtitle\": \"CPU: $cpu%  •  PID: $pid  •  $escaped_path\", "
	echo "  \"arg\": \"$pid\", "
	echo "  \"variables\": { \"process_name\": \"$display_name\" },"
	echo "  \"icon\": $icon_json"
	echo "},"
done <<< "$processes" | awk 'NR>1{print prev} {prev=$0} END{sub(/,$/,"",prev); print prev}'

echo ']}'
