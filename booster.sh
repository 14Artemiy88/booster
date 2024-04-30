#!/bin/bash

declare -r NORMAL_COLOR="\e[0;39m"
declare -r GREEN_COLOR="\e[0;32m"
declare -r YELLOW_COLOR="\e[0;33m"

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
		access="󰅖"
		if [[ "$hasAccess" == true ]]; then
			# access="󰄬"
			access=" "
		fi
		str="$str\n https://ok.ru/videoembed/$vid;$access;$title"
	fi
	((i++))
done

if [[ $str == "" ]]; then
	echo "Nothing to show"
	exit 0
fi

str="  URL;Free; Title\n$str"
echo -e "$str" | column --table --separator ";" | fzf --header '' --header-lines=1 --bind 'enter:become(mpv {1})+abort'
