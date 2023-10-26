
#!/bin/bash
BASEDIR=$(dirname "$0")

# Function to parse and read the configuration yaml file
function parse_yaml {
   local prefix=$2
   local s='[[:space:]]*' w='[a-zA-Z0-9_]*' fs=$(echo @|tr @ '\034')
   sed -ne "s|^\($s\):|\1|" \
        -e "s|^\($s\)\($w\)$s:$s[\"']\(.*\)[\"']$s\$|\1$fs\2$fs\3|p" \
        -e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3|p"  $1 |
   awk -F$fs '{
      indent = length($1)/2;
      vname[indent] = $2;
      for (i in vname) {if (i > indent) {delete vname[i]}}
      if (length($3) > 0) {
         vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
         printf("%s%s%s=\"%s\"\n", "'$prefix'",vn, $2, $3);
      }
   }'
}

eval $(parse_yaml "$BASEDIR/notebooks/$1/configuration.yaml")

local_version=$version
local_description=$description

wget -q https://raw.githubusercontent.com/IvanHCenalmor/playground/main/notebooks/CARE_2D_DL4Mic/configuration.yaml
# wget -q https://raw.githubusercontent.com/HenriquesLab/DL4MicEverywhere/tree/main/notebooks/$1/configuration.yaml
eval $(parse_yaml "./configuration.yaml")
rm ./configuration.yaml

if [ $version == $local_version ]; then
   echo 1
else
   echo 0
fi

echo $local_description