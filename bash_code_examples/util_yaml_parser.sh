#!/usr/bin/env bash
function parse_yaml() {
    local prefix=$2
    local s='[[:space:]]*' w='[a-zA-Z0-9_]*' fs=$(echo @|tr @ '\034')
    #regex expressions to execute per each stream line of the file to parse the yaml structure
    sed -ne "s|^\($s\):|\1|" \
        -e  "s|^\($s\)\(-\)|\1|" \
         -e "s|^\($s\)\($w\)$s:$s[\"']\(.*\)[\"']$s\$|\1$fs\2$fs\3|p" \
         -e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3|p" $1 |
    #program that executes the logic to get the deployment descriptors information after the line is parsed     
    awk -F$fs '{
        indent = length($1)/2;
        vname[indent] = $2;
        for (i in vname) {if (i > indent) {delete vname[i]}}
        if (length($3) > 0){
            vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
            line_value=sprintf("%s%s%s=\"%s\"\n", "'$prefix'",vn, $2, $3);
            if(index(line_value, "deploymentDescriptors__version") != 0 || index(line_value, "deploymentDescriptors__name") != 0){
                printf(line_value);
            }
        }
    }'
}

function load_data() {
    local map_var_name=$1
    #defines a map data structure to store the services installation data
    declare -A | grep -q "declare -A ${map_var_name}" || fail "no ${map_var_name} associative array declared"
    local current_path=$(dirname $0)
    local feature_path=$(echo ${current_path} | sed -e "s/\/[^\/]*$//")
    #parsing the yaml manifest file
    eval $(parse_yaml ${feature_path}/pManifest.yaml)
    #getting filtered descriptor data
    local descriptors_data=$(parse_yaml ${feature_path}/pManifest.yaml)
    
    while IFS=' ' read -ra ADDR; do
     ((++id))
        for i in "${ADDR[@]}"; do
            if [[ $i == *"deploymentDescriptors__name"* ]]; then
                IFS='=' read -ra name <<< "$i"
                #removes the helm word from the descriptor artifact name
                clean_name=$(echo ${name[1]} | sed "s/\"//g" | sed "s/-helm//")
                #removes double quotes from the descriptor artifact name
                clean_helm_name=$(echo ${name[1]} | sed "s/\"//g")
                #stores the service name and the heml chart artifact name in the installation map
                eval "${map_var_name}[$id]='${clean_name} ${clean_helm_name}'"
            elif [[ $i == *"deploymentDescriptors__version"* ]]; then
                IFS='=' read -ra version <<< "$i"
                ((--id))
                #gets the current value of the service installation data in the map 
                eval current_data=\( \${${map_var_name}[$id]} \)
                #removes double quotes from the version
                clean_version=$(echo ${version[1]} | sed "s/\"//g")
                #updates the service installation data with (service name, helm chart name and version)
                eval "${map_var_name}[$id]='${current_data[0]} ${current_data[1]} ${clean_version}'"
            fi
        done
    done <<< $descriptors_data
}
