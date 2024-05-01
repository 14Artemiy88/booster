#!/bin/bash

declare -r NORMAL_COLOR="\e[0;39m"
declare -r GREEN_COLOR="\e[0;32m"
declare -r YELLOW_COLOR="\e[0;33m"
declare -r BLUE_COLOR="\e[1;36m"
declare -r RED_COLOR="\e[1;31m"
declare -r GRAY_COLOR="\e[38;5;254m"
declare -r IMG_PATH="/tmp/booster"

bar_size=$(( $(tput cols) - 25 ))

if [ ! -d $IMG_PATH ]; then
	mkdir $IMG_PATH
fi

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

load() {
	if [ ! -f "$IMG_PATH/$vid" ]; then
	
		cha=" "
		(( len=$bar_size - ${#title} ))
    	local v=$(printf "%-${len}s" "$cha")
    
		echo -e '\e[2F\n'
    	echo -en "Loading image...\t${GREEN_COLOR}$2${NORMAL_COLOR}${v// /$cha}"
	
		wget -O "$IMG_PATH/$vid" $1 &> /dev/null
	fi
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
	if [[ $title == null ]]; then
		break;
	fi
	vid=$(jq ".[$i].media" <<< $json | jq '.[0].vid' | tr -d '"')
	if [[ $vid -ne null ]]; then
		hasAccess=$(jq ".[$i].post.hasAccess" <<< $json)
		access="${RED_COLOR} 󰅖${NORMAL_COLOR}"
		if [[ "$hasAccess" == true ]]; then
			access="${GREEN_COLOR} 󰄬${NORMAL_COLOR}"
			preview=$(jq ".[$i].media" <<< $json | jq '.[0].preview' | tr -d '"')
		else
			preview=$(jq ".[$i].post.teaser" <<< $json | jq '.[0].url' | tr -d '"')
		fi
		load $preview "$title"

		str="$str\n $access|${BLUE_COLOR}$title${NORMAL_COLOR}|${GRAY_COLOR}$vid${NORMAL_COLOR}"
	fi
	((i++))
done

if [[ $str == "" ]]; then
	echo "Nothing to show"
	exit 0
fi

str="  ${YELLOW_COLOR}Free| Title| Id${NORMAL_COLOR}\n$str"
echo -e "$str" | column --table --separator "|" | fzf --ansi --header '  CTRL-V Only 󰄬 / CTRL-X Only 󰅖 / CTRL-A All' --header-lines=1 --bind 'enter:become(mpv https://ok.ru/videoembed/{-1})+abort' --bind "ctrl-v:+transform-query(echo '󰄬 ')" --bind "ctrl-x:+transform-query(echo '󰅖 ')" --bind "ctrl-a:+transform-query(echo )" --preview "chafa --size=60% $IMG_PATH/{-1}" --preview-window 'nohidden,right,40%,border-left'
