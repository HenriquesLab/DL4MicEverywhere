#!/bin/bash

# Parse the small YAML subset used by DL4MicEverywhere into variable-name/value
# records. Values are data only: callers load them with printf -v and never
# execute parser output as shell code.
_yaml_records_from_file() {
   local file="$1"
   local prefix="${2:-}"
   local s='[[:space:]]*' w='[a-zA-Z0-9_]*' fs
   fs=$(printf '\034')

   tr -d '\r' < "$file" |
   sed -ne "s|^\($s\):|\1|" \
        -e "s|^\($s\)\($w\)$s:$s[\"']\(.*\)[\"']$s\$|\1$fs\2$fs\3|p" \
        -e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3|p" |
   awk -F"$fs" -v prefix="$prefix" -v separator="$fs" '{
      indent = length($1)/2;
      vname[indent] = $2;
      value = $3;

      # Remove inline comments only if they are at the beginning of a line or after whitespace.
      gsub(/[[:space:]]#.*/, "", value);

      for (i in vname) {if (i > indent) {delete vname[i]}}
      if (length($3) > 0) {
         vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
         printf("%s%s%s%s%s\n", prefix, vn, $2, separator, value);
      }
   }'
}

# Load parsed values directly into the current Bash process without eval.
# YAML keys are already restricted by the parser to [A-Za-z0-9_], and the
# optional prefixes used by DL4MicEverywhere follow the same rule.
load_yaml_args_from_file() {
   local file="$1"
   local prefix="${2:-}"
   local variable_name variable_value

   if [ ! -r "$file" ]; then
      echo "Could not read YAML file: $file" >&2
      return 1
   fi

   case "$prefix" in
      *[!a-zA-Z0-9_]* )
         echo "Invalid YAML variable prefix: $prefix" >&2
         return 1
         ;;
   esac

   while IFS=$'\034' read -r variable_name variable_value; do
      [ -z "$variable_name" ] && continue
      case "$variable_name" in
         [a-zA-Z_]* ) ;;
         * )
            echo "Invalid variable name produced while parsing YAML: $variable_name" >&2
            return 1
            ;;
      esac
      case "$variable_name" in
         *[!a-zA-Z0-9_]* )
            echo "Invalid variable name produced while parsing YAML: $variable_name" >&2
            return 1
            ;;
      esac
      printf -v "$variable_name" '%s' "$variable_value"
   done < <(_yaml_records_from_file "$file" "$prefix")
}

# Remote YAML support follows the same no-eval loading path. Download to a
# temporary file so curl failures are observable before parsing begins.
load_yaml_args_from_url() {
   local url="$1"
   local prefix="${2:-}"
   local tmp_file
   tmp_file=$(mktemp) || return 1

   if ! curl -fsSL "$url" -o "$tmp_file"; then
      rm -f "$tmp_file"
      return 1
   fi

   load_yaml_args_from_file "$tmp_file" "$prefix"
   local result=$?
   rm -f "$tmp_file"
   return "$result"
}
