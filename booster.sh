#!/bin/bash

declare -r NORMAL_COLOR="\e[0;39m"
declare -r GREEN_COLOR="\e[0;32m"
declare -r YELLOW_COLOR="\e[0;33m"
declare -r BLUE_COLOR="\e[1;36m"
declare -r RED_COLOR="\e[1;31m"
declare -r GRAY_COLOR="\e[38;5;254m"
declare -r IMG_PATH="$HOME/.cache/booster"

if [ ! -d "$IMG_PATH" ]; then
	mkdir "$IMG_PATH"
fi

Help() {
    # Display Help
    echo "Get video from Boosty by channel name."
    echo
    echo -e "${YELLOW_COLOR}USAGE${NORMAL_COLOR}
    booster CHANNEL [OPTIONS]"
    echo
    echo -e "${YELLOW_COLOR}ARGS${NORMAL_COLOR}
    ${GREEN_COLOR}<CHANNEL>${NORMAL_COLOR}    Channel name"
    echo
    echo -e "${YELLOW_COLOR}OPTIONS${NORMAL_COLOR}
    ${GREEN_COLOR}-v <string> ${NORMAL_COLOR}        Preview image viewer [default: chafa --size=60%]
    ${GREEN_COLOR}--no-image ${NORMAL_COLOR}         Disable image preview"
    echo
}

params() {
    if [[ -z $1 ]]; then
        show_help_and_exit
    fi
    if [ "$#" -gt 1 ]; then
        if [[ "$2" == "--no-image" ]]; then
            str=" ${YELLOW_COLOR}Free| Title\n"
            SHOW_IMAGE=false
        elif [[ "$2" == "-v" && -n "$3" ]]; then
            IMAGE_VIEWER="$3"
        else
            show_help_and_exit
        fi
    fi
}

show_help_and_exit() {
    Help
    exit 0
}

load() {
	if [[ ! -f "$IMG_PATH/$vid" ]]; then
		local len=$((bar_size - ${#title}))
    	local v=$(printf "%-${len}s" " ")
    	echo -e '\e[2F\n'
    	echo -en "Loading image...\t${GREEN_COLOR}$2${NORMAL_COLOR}${v// / }"
		curl -s -o "$IMG_PATH/$vid" "$1" >/dev/null
	fi
}

function get_channels() {
    readonly json=$(curl https://api.boosty.to/v1/blog/$1/media_album/\?type\=all\&limit_by\=media | jq -r '.data.mediaPosts')
    local -i i=0
    local title vid hasAccess access preview
    while true; do
    	title=$(jq -r ".[$i].post.title" <<< "$json")
    	if [[ $title == null ]]; then
    		break
    	fi
    	vid=$(jq -r ".[$i].media[0].vid" <<< "$json")
    	if [[ $vid != "null" ]]; then
    		hasAccess=$(jq -r ".[$i].post.hasAccess" <<< "$json")
    		access="${RED_COLOR}󰅖${NORMAL_COLOR}"
    		if [[ $hasAccess == true ]]; then
    			access="${GREEN_COLOR}󰄬${NORMAL_COLOR}"
    			preview=$(jq -r ".[$i].media[0].preview" <<< "$json")
    		else
    			preview=$(jq -r ".[$i].post.teaser[0].url" <<< "$json")
    		fi
    		str="$str\n $access|${BLUE_COLOR}$title${NORMAL_COLOR}"
            if [ $SHOW_IMAGE = true ]; then
    		    load "$preview" "$title"
                fzf_params+=(--preview-window 'nohidden,right,40%,border-left')
                fzf_params+=(--preview "$IMAGE_VIEWER $IMG_PATH/{-1}")
    		    str="$str|${GRAY_COLOR}$vid${NORMAL_COLOR}"
            else
                fzf_params+=(--preview-window hidden)
            fi
            empty=false
    	fi
    	((i++))
    done
}

SHOW_IMAGE=true
str=" ${YELLOW_COLOR}Free| Title| Id${NORMAL_COLOR}\n"
IMAGE_VIEWER="chafa --size=60%"
params "${@}"

bar_size=$(( $(tput cols) - 25 ))
fzf_params=(
    "--ansi"
    --header ' CTRL-V Only 󰄬 / CTRL-X Only 󰅖 / CTRL-A All'
    "--header-lines=1"
    --bind 'enter:become(mpv https://ok.ru/videoembed/{-1})+abort'
    --bind "ctrl-v:+transform-query(echo '󰄬 ')"
    --bind "ctrl-x:+transform-query(echo '󰅖 ')"
    --bind "ctrl-a:+transform-query(echo )"
    --bind "esc:+abort"
)
empty=true
get_channels "$1"

if [ $empty = true ]; then
	echo -e "${YELLOW_COLOR}Nothing to show${NORMAL_COLOR}"
	exit 0
fi

echo -e "$str" | column --table --separator "|" | fzf "${fzf_params[@]}"








