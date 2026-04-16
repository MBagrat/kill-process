set quiet := true

# REQUIRED local workflow uses same folder name

workflow_uid := `basename "$PWD"`
prefs_location := `defaults read com.runningwithcrayons.Alfred-Preferences syncfolder | sed "s|^~|$HOME|"`
local_workflow := prefs_location / "Alfred.alfredpreferences/workflows" / workflow_uid

#───────────────────────────────────────────────────────────────────────────────

transfer-changes-FROM-local:
    #!/usr/bin/env zsh
    rsync --archive --delete "{{ local_workflow }}/scripts/" "$PWD/src/scripts/"
    rsync --archive "{{ local_workflow }}/icon.png" "$PWD/src/assets/"
    rsync --archive --exclude="scripts/" --exclude="icon.png" --exclude-from="$PWD/.rsync-exclude" "{{ local_workflow }}/" "$PWD/"
    git status --short

sync-readme:
    #!/usr/bin/env zsh
    readme="$(cat "$PWD/src/WORKFLOW_README.md")"
    plutil -replace readme -string "$readme" "$PWD/info.plist"
    local_info_plist="{{ local_workflow }}/info.plist"
    if [[ -f "$local_info_plist" ]]; then
        plutil -replace readme -string "$readme" "$local_info_plist"
    fi

transfer-changes-TO-local:
    #!/usr/bin/env zsh
    just sync-readme
    rsync --archive --delete "$PWD/src/scripts/" "{{ local_workflow }}/scripts/"
    rsync --archive "$PWD/src/assets/" "{{ local_workflow }}/"
    rsync --archive --exclude-from="$PWD/.rsync-exclude" --exclude="/src/" "$PWD/" "{{ local_workflow }}"
    print "\e[1;34mChanges at the local workflow:\e[0m"
#    git status --short .

[macos]
open-local-workflow-in-alfred:
    #!/usr/bin/env zsh
    # using JXA and URI for redundancy, as both are not 100 % reliable https://www.alfredforum.com/topic/18390-get-currently-edited-workflow-uri/
    open "alfredpreferences://navigateto/workflows>workflow>{{ workflow_uid }}"
    osascript -e 'tell application id "com.runningwithcrayons.Alfred" to reveal workflow "{{ workflow_uid }}"'

release:
    ./.build-and-release.sh
