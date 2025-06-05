CONFIG_FILE=$(realpath ".config")

get_config_value() {
  local var_name=$1

  local line
  line=$(grep -E "^\s*${var_name}=" "$CONFIG_FILE" | tail -n1)

  if [[ -z "$line" ]]; then
    echo "Error: Variable '$var_name' not found in config." >&2
    exit 1
  fi

  local value="${line#*=}"
  value="${value%%#*}"
  value="${value//\"/}"
  value=$(echo "$value" | xargs)

  if [[ -z "$value" ]]; then
    echo "Error: Variable '$var_name' is empty in config." >&2
    exit 1
  fi

  echo "$value"
}

get_config_bool() {
  local var_name=$1
  local value
  value=$(get_config_value "$var_name") || exit 1

  case "$value" in
    y|Y)
      return 0 ;;
    n|N)
      return 1 ;;
    *)
      echo "Error: Variable '$var_name' must be 'y' or 'n', but got '$value'." >&2
      exit 1
      ;;
  esac
}
