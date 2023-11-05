is_storage() {
	if [ -d "$HOME/storage/" ]
	then
		return 0
	else
		return 1
	fi
}

path_parse() {
	path=$1
	
	if [[ $path == "~"* ]]
	then
		path="${HOME}${path:1}"
	fi
	
	echo $path
}

get_content() {
	line=$1
	filename=$2
	
	printf $(sed -n "${line}p" $filename)
}

edit_content() {
	content_replace="$1"
	content_replacement="$2"
	line=$3
	filename=$4
	
	sed -i "${line}s|$content_replace|$content_replacement|" $filename
}

add_content() {
	content=$(printf "$1")
	line=$2
	filename=$3
	
	sed -i "${line}i\\$content\\" $filename
}