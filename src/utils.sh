# Function to read from YAML configuration or use default values
ore_wizard_get_config() {
  local path=$1
  local default_value=$2
  local value=$(yq e "$path" $config_file)
  if [[ "$value" == "null" || -z "$value" ]]; then
    echo "$default_value"
  else
    echo "$value"
  fi
}
