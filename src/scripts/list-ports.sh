#!/usr/bin/env zsh
set -eo pipefail
export PATH="/usr/bin:/bin:/usr/sbin:/sbin:$PATH"
query="$1"
query="${query#"${query%%[![:space:]]*}"}"
query="${query%"${query##*[![:space:]]}"}"

json_escape() { local s="${1//\\/\\\\}"; printf '%s' "${s//\"/\\\"}"; }

# Get all TCP LISTEN ports with PID, command name, and address
list=$(lsof -iTCP -sTCP:LISTEN -P -n -Fpcn)

if [[ -z "$list" ]]; then
	echo '{"items": [{"title": "No active ports found", "subtitle": "Check your server status", "valid": false}]}'
	exit 0
fi

echo '{"items": ['
echo "$list" | while read -r line; do
	case $line in
		p*) pid=${line#p}
		    cpu=$(ps -p "$pid" -o %cpu= 2>/dev/null | xargs) ;;
		c*) raw_name=${line#c} ;;
		n*)
			port=$(echo "$line" | awk -F':' '{print $NF}')
			if [[ -z "$query" ]] || [[ "$port" == *"$query"* ]]; then
				full_path=$(ps -p "$pid" -o comm= 2>/dev/null | xargs)
				display_name="$raw_name"
				icon_path="$full_path"
				icon_type="fileicon"

				if [[ "$full_path" == *".app/"* ]]; then
					app_bundle="${full_path%%.app/*}.app"
					display_name="${app_bundle##*/}"
					display_name="${display_name%.app}"
					icon_path="$app_bundle"
				fi

				if [[ ! -e "$icon_path" ]]; then
					icon_path="/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/Everyone.icns"
					icon_type=""
				fi

				display_name=$(json_escape "$display_name")
				escaped_path=$(json_escape "$full_path")
				escaped_icon_path=$(json_escape "$icon_path")

				if [[ -n "$icon_type" ]]; then
					icon_json="{ \"type\": \"$icon_type\", \"path\": \"$escaped_icon_path\" }"
				else
					icon_json="{ \"path\": \"$escaped_icon_path\" }"
				fi

				echo "{"
				echo "  \"title\": \"$display_name (Port $port)\", "
				echo "  \"subtitle\": \"CPU: ${cpu:-0.0}%  •  PID: $pid  •  $escaped_path\", "
				echo "  \"arg\": \"$port\", "
				echo "  \"variables\": { \"process_name\": \"$display_name\" },"
				echo "  \"icon\": $icon_json"
				echo "},"
			fi
			;;
	esac
done | awk 'NR>1{print prev} {prev=$0} END{sub(/,$/,"",prev); print prev}'
echo ']}'
