#!/bin/bash

declare -r NORMAL_COLOR="\e[0;39m"
declare -r GREEN_COLOR="\e[0;32m"
declare -r YELLOW_COLOR="\e[0;33m"
declare -r BLUE_COLOR="\e[1;36m"
declare -r RED_COLOR="\e[1;31m"
declare -r GRAY_COLOR="\e[38;5;254m"

Help() {
    # Display Help
    echo "Get video from Boosty by channel name."
    echo
    echo -e "${YELLOW_COLOR}USAGE${NORMAL_COLOR}
    booster CHANNEL"
    echo
    echo -e "${YELLOW_COLOR}ARGS${NORMAL_COLOR}
    ${GREEN_COLOR}<CHANNEL>${NORMAL_COLOR}    Channel name"
    echo
}

if [[ -z $1 ]]; then
	Help
	exit 0
fi
channel=$1

json=$(curl https://api.boosty.to/v1/blog/$channel/media_album/\?type\=all\&limit_by\=media | jq -r '.data.mediaPosts')

i=0
str=""
while true; do
	title=$(jq ".[$i].post.title" <<< $json | tr -d '"')
	vid=$(jq ".[$i].media" <<< $json | jq '.[0].vid' | tr -d '"')
	if [[ $title == null ]]; then
		break;
	fi
	if [[ $vid -ne null ]]; then
		hasAccess=$(jq ".[$i].post.hasAccess" <<< $json)
		access="${RED_COLOR} 󰅖${NORMAL_COLOR}"
		if [[ "$hasAccess" == true ]]; then
			access="${GREEN_COLOR} 󰄬${NORMAL_COLOR}"
		fi
		str="$str\n ${GRAY_COLOR}https://ok.ru/videoembed/$vid${NORMAL_COLOR}|$access|${BLUE_COLOR}$title${NORMAL_COLOR}"
	fi
	((i++))
done

if [[ $str == "" ]]; then
	echo "Nothing to show"
	exit 0
fi

str="  ${YELLOW_COLOR}URL|Free| Title${NORMAL_COLOR}\n$str"
echo -e "$str" | column --table --separator "|" | fzf --ansi  --header '  CTRL-V Only 󰄬 / CTRL-X Only 󰅖 / CTRL-A All' --header-lines=1 --bind 'enter:become(mpv {1})+abort' --bind "ctrl-v:+transform-query(echo '󰄬 ')" --bind "ctrl-x:+transform-query(echo '󰅖 ')" --bind "ctrl-a:+transform-query(echo )"
