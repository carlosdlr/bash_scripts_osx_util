#!/usr/bin/env bash
function parse_yaml() {
    local prefix=$2
    local s='[[:space:]]*' w='[a-zA-Z0-9_]*' fs=$(echo @|tr @ '\034')
    sed -ne "s|^\($s\):|\1|" \
        -e  "s|^\($s\)\(-\)|\1|" \
         -e "s|^\($s\)\($w\)$s:$s[\"']\(.*\)[\"']$s\$|\1$fs\2$fs\3|p" \
         -e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3|p" $1 |   
    awk -F$fs '{
        indent = length($1)/2;
        vname[indent] = $2;
        for (i in vname) {if (i > indent) {delete vname[i]}}
        if (length($3) > 0){
            vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
            line_value=sprintf("%s%s%s=\"%s\"\n", "'$prefix'",vn, $2, $3);
            if(index(line_value, "key1") != 0 || index(line_value, "key2") != 0){
                printf(line_value);
            }
        }
    }'
}

function load_data() {
    local map_var_name=$1
    declare -A | grep -q "declare -A ${map_var_name}" || fail "no ${map_var_name} associative array declared"
    local current_path=$(dirname $0)
    local feature_path=$(echo ${current_path} | sed -e "s/\/[^\/]*$//")
    eval $(parse_yaml ${feature_path}/fileToParse.yaml)
    local descriptors_data=$(parse_yaml ${feature_path}/fileToParse.yaml)
    
    while IFS=' ' read -ra ADDR; do
     ((++id))
        for i in "${ADDR[@]}"; do
            if [[ $i == *"key1"* ]]; then
                IFS='=' read -ra name <<< "$i"
                clean_name=$(echo ${name[1]} | sed "s/\"//g" | sed "s/-helm//")
                clean_helm_name=$(echo ${name[1]} | sed "s/\"//g")
                eval "${map_var_name}[$id]='${clean_name} ${clean_helm_name}'"
            elif [[ $i == *"key2"* ]]; then
                IFS='=' read -ra version <<< "$i"
                ((--id))
                eval current_data=\( \${${map_var_name}[$id]} \)
                clean_version=$(echo ${version[1]} | sed "s/\"//g")
                eval "${map_var_name}[$id]='${current_data[0]} ${current_data[1]} ${clean_version}'"
            fi
        done
    done <<< $descriptors_data
}
