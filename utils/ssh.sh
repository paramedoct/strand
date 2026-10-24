ssh_download() {
  local alias
  local path
  local destination
  local timestamp
  local sequence
  local staging
  local status
  alias=$1
  path=$2
  shift 2
  while [ "${path%/}" != "$path" ]; do
    path=${path%/}
  done
  case "$alias" in
    ""|.|..|-*|*[!a-zA-Z0-9._-]*)
      return 1
      ;;
  esac
  case "$path" in
    ""|*\**|*\?*|*\[*|*\]*)
      return 1
      ;;
  esac
  case "/$path/" in
    */../*|*/./*)
      return 1
      ;;
  esac
  mkdir -p "/tmp/$alias" || return 1
  timestamp=$(date +%Y%m%d-%H%M%S)
  destination="/tmp/$alias/$timestamp"
  sequence=0
  while ! mkdir "$destination" 2>/dev/null; do
    if [ ! -e "$destination" ] && [ ! -L "$destination" ]; then
      printf 'Could not create download directory: %s\n' "$destination" >&2
      return 1
    fi
    sequence=$((sequence + 1))
    destination="/tmp/$alias/$timestamp-$sequence"
  done
  staging=$(mktemp -d "$destination/.download.XXXXXX") || return 1
  if scp -F "$STRAND_GENERATED_CONFIG_FILE" "$@" "$alias:$path" "$staging/"; then
    ssh_download_place "$staging" "$destination" || return 1
    printf '%s\n' "$destination"
  else
    status=$?
    printf 'Download failed; partial files may remain in: %s\n' "$staging" >&2
    return "$status"
  fi
}

ssh_download_place() (
  local staging
  local destination
  local directory
  staging=$1
  destination=$2
  shopt -s dotglob nullglob
  set -- "$staging"/*
  if [ "$#" -eq 1 ] && [ -d "$1" ]; then
    directory=$1
    set -- "$directory"/*
    if [ "$#" -gt 0 ]; then
      mv -- "$@" "$destination/" || return 1
    fi
    rmdir -- "$directory" || return 1
  elif [ "$#" -gt 0 ]; then
    mv -- "$@" "$destination/" || return 1
  else
    printf 'Download returned no files: %s\n' "$staging" >&2
    return 1
  fi
  rmdir -- "$staging"
)

ssh_fingerprint_from_key() {
  local key
  local output
  local type
  local hash
  key=$1
  output=$(printf '%s\n' "$key" | ssh-keygen -lf - -E sha256 2>/dev/null) || return 1
  type=${output##* }
  type=${type#(}
  type=${type%)}
  type=$(printf '%s' "$type" | tr '[:upper:]' '[:lower:]')
  hash=$(printf '%s\n' "$output" | awk 'NR == 1 { print $2 }')
  printf '%s:%s\n' "$type" "$hash"
}

ssh_capture_key() {
  local hostname
  local output
  hostname=$1
  output="$(ssh-keyscan -T 2 "$hostname" 2>/dev/null)" || return 1
  grep -m 1 -E '^[^#[:space:]]+[[:space:]]+ssh-ed25519[[:space:]]' <<<"$output" \
    || grep -m 1 -E '^[^#[:space:]]+[[:space:]]+ecdsa-sha2-' <<<"$output" \
    || grep -m 1 -E '^[^#[:space:]]+[[:space:]]+ssh-rsa[[:space:]]' <<<"$output" \
    || awk 'NF >= 3 && $1 !~ /^#/ { print; found = 1; exit }
      END { exit !found }' <<<"$output"
}
