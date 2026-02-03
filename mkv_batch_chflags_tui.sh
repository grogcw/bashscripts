#!/usr/bin/env bash
set -u
export LC_ALL=C

# ---------- deps ----------
require_cmd() { command -v "$1" >/dev/null 2>&1 || { echo "Missing dependency: $1" >&2; exit 1; }; }
require_cmd mkvinfo
require_cmd mkvpropedit

if command -v dialog >/dev/null 2>&1; then
  tui="dialog"
elif command -v whiptail >/dev/null 2>&1; then
  tui="whiptail"
else
  echo "Error: need 'dialog' or 'whiptail' installed." >&2
  exit 1
fi

cleanup() {
  if [[ "$tui" == "dialog" ]]; then dialog --clear 2>/dev/null || true; fi
}
trap cleanup EXIT

# ---------- args ----------
dir="${1:-}"
[[ -n "$dir" ]] || { echo "Usage: $0 <directory>" >&2; exit 1; }
[[ -d "$dir" ]] || { echo "Not a directory: $dir" >&2; exit 1; }
[[ "$dir" != */ ]] && dir="${dir}/"

# ---------- gather MKVs safely (handles spaces, apostrophes, etc.) ----------
mkv_files=()
while IFS= read -r -d '' f; do
  mkv_files+=("$f")
done < <(find "$dir" -maxdepth 1 -type f -name '*.mkv' -print0 2>/dev/null | sort -z)

((${#mkv_files[@]} > 0)) || { echo "No .mkv files found in: $dir" >&2; exit 1; }
sample_file="${mkv_files[0]}"

# ---------- parse mkvinfo (best-effort) ----------
# Output TSV per track:
# track_number \t track_type \t language \t name \t default_flag \t forced_flag \t enabled_flag
parse_tracks_tsv() {
  mkvinfo "$sample_file" | awk '
    function trim(s) { gsub(/^[[:space:]]+/, "", s); gsub(/[[:space:]]+$/, "", s); return s }
    function print_track() {
      if (tnum == "") return
      if (ttype == "") ttype = "unknown"
      if (lang  == "") lang  = "und"
      if (def  == "") def  = "?"
      if (forc == "") forc = "?"
      if (en   == "") en   = "?"
      gsub(/\t/, " ", name)
      gsub(/\r/, "", name)
      gsub(/\n/, " ", name)
      print tnum "\t" ttype "\t" lang "\t" name "\t" def "\t" forc "\t" en
    }

    BEGIN { tnum=""; ttype=""; lang=""; name=""; def=""; forc=""; en="" }

    /Track number:/ {
      print_track()
      tnum=""; ttype=""; lang=""; name=""; def=""; forc=""; en=""
      line=$0
      sub(/^.*Track number:[[:space:]]*/, "", line)
      tnum = int(line)
      next
    }

    (tnum != "") && /Track type:/ { line=$0; sub(/^.*Track type:[[:space:]]*/, "", line); ttype=trim(line); next }
    (tnum != "") && /Language:/   { line=$0; sub(/^.*Language:[[:space:]]*/, "", line);   lang=trim(line);  next }
    (tnum != "") && /Name:/       { line=$0; sub(/^.*Name:[[:space:]]*/, "", line);       name=trim(line);  next }

    (tnum != "") && /Default track flag:/ { line=$0; sub(/^.*Default track flag:[[:space:]]*/, "", line); def=int(line);  next }
    (tnum != "") && /Forced track flag:/  { line=$0; sub(/^.*Forced track flag:[[:space:]]*/, "", line);  forc=int(line); next }
    (tnum != "") && /Enabled track flag:/ { line=$0; sub(/^.*Enabled track flag:[[:space:]]*/, "", line); en=int(line);   next }

    END { print_track() }
  '
}

tracks_tsv="$(parse_tracks_tsv)"

# ---------- load into arrays ----------
track_count=0
track_num=()
track_type=()
track_lang=()
track_name=()
cur_default=()
cur_forced=()
cur_enabled=()
track_mode=()   # NONE / DEFAULT / FORCED

while IFS=$'\t' read -r n t l nm d f e; do
  [[ -n "${n:-}" ]] || continue
  track_num+=("$n")
  track_type+=("${t:-unknown}")
  track_lang+=("${l:-und}")
  track_name+=("${nm:-}")
  cur_default+=("${d:-?}")
  cur_forced+=("${f:-?}")
  cur_enabled+=("${e:-?}")

  if [[ "${f:-?}" == "1" ]]; then
    track_mode+=("FORCED")
  elif [[ "${d:-?}" == "1" ]]; then
    track_mode+=("DEFAULT")
  else
    track_mode+=("NONE")
  fi

  track_count=$((track_count + 1))
done <<<"$tracks_tsv"

(( track_count > 0 )) || {
  echo "Could not parse any tracks from mkvinfo output for: $sample_file" >&2
  exit 1
}

# ---------- TUI helpers ----------
tui_menu() {
  local title="$1"; shift
  local prompt="$1"; shift
  local h="$1"; shift
  local w="$1"; shift
  local mh="$1"; shift
  if [[ "$tui" == "dialog" ]]; then
    dialog --clear --stdout --title "$title" --menu "$prompt" "$h" "$w" "$mh" "$@"
  else
    whiptail --title "$title" --menu "$prompt" "$h" "$w" "$mh" "$@" 3>&1 1>&2 2>&3
  fi
}

tui_radiolist() {
  local title="$1"; shift
  local prompt="$1"; shift
  local h="$1"; shift
  local w="$1"; shift
  local lh="$1"; shift
  if [[ "$tui" == "dialog" ]]; then
    dialog --clear --stdout --title "$title" --radiolist "$prompt" "$h" "$w" "$lh" "$@"
  else
    whiptail --title "$title" --radiolist "$prompt" "$h" "$w" "$lh" "$@" 3>&1 1>&2 2>&3
  fi
}

tui_yesno() {
  local title="$1"
  local prompt="$2"
  if [[ "$tui" == "dialog" ]]; then
    dialog --clear --title "$title" --yesno "$prompt" 0 0
  else
    whiptail --title "$title" --yesno "$prompt" 0 0
  fi
}

tui_msgbox() {
  local title="$1"
  local msg="$2"
  if [[ "$tui" == "dialog" ]]; then
    dialog --clear --title "$title" --msgbox "$msg" 0 0
  else
    whiptail --title "$title" --msgbox "$msg" 0 0
  fi
}

tui_infobox() {
  local msg="$1"
  if [[ "$tui" == "dialog" ]]; then
    dialog --infobox "$msg" 0 0
  else
    whiptail --infobox "$msg" 0 0
  fi
}

tui_textbox_from_cmd() {
  local title="$1"; shift
  local tmp
  tmp="$(mktemp)"
  "$@" >"$tmp" 2>&1 || true
  if [[ "$tui" == "dialog" ]]; then
    dialog --clear --title "$title" --textbox "$tmp" 0 0
  else
    whiptail --title "$title" --msgbox "$(sed -n '1,200p' "$tmp")" 0 0
  fi
  rm -f "$tmp"
}

tui_textbox_from_string() {
  local title="$1"
  local content="$2"
  local tmp
  tmp="$(mktemp)"
  printf "%s\n" "$content" >"$tmp"
  if [[ "$tui" == "dialog" ]]; then
    dialog --clear --title "$title" --textbox "$tmp" 0 0
  else
    whiptail --title "$title" --msgbox "$(sed -n '1,200p' "$tmp")" 0 0
  fi
  rm -f "$tmp"
}

# ---------- per-track editor ----------
edit_track_mode() {
  local idx="$1"
  local n="${track_num[$idx]}"
  local t="${track_type[$idx]}"
  local l="${track_lang[$idx]}"
  local nm="${track_name[$idx]}"
  local current="${track_mode[$idx]}"

  local on_none="off" on_default="off" on_forced="off"
  case "$current" in
    NONE)    on_none="on" ;;
    DEFAULT) on_default="on" ;;
    FORCED)  on_forced="on" ;;
  esac

  local selection=""
  selection="$(
    tui_radiolist \
      "Track $n" \
      "Mode for track $n ($t, $l, ${nm:-<no name>})" \
      12 75 5 \
      "NONE"    "No default/forced" "$on_none" \
      "DEFAULT" "Default track"     "$on_default" \
      "FORCED"  "Forced track"      "$on_forced"
  )" || true

  [[ -n "$selection" ]] || return 0
  track_mode[$idx]="$selection"
}

# ---------- build real argv for mkvpropedit (NO %q) ----------
args=()

build_mkvpropedit_args_array() {
  args=()
  local i=0
  while (( i < track_count )); do
    local n="${track_num[$i]}"
    local mode="${track_mode[$i]}"
    local def="0" forc="0"

    case "$mode" in
      NONE)    def="0"; forc="0" ;;
      DEFAULT) def="1"; forc="0" ;;
      FORCED)  def="0"; forc="1" ;;
    esac

    # track:@N matches mkvinfo's "Track number:" element
    args+=( --edit "track:@${n}" --set "flag-default=${def}" --set "flag-forced=${forc}" )
    i=$((i + 1))
  done
}

build_preview_command_string() {
  build_mkvpropedit_args_array
  local out=""
  out+="Folder: $dir"$'\n'
  out+="Sample file: $sample_file"$'\n'
  out+="Files to edit: ${#mkv_files[@]}"$'\n\n'
  out+='mkvpropedit "FILE.mkv"'
  local a
  for a in "${args[@]}"; do
    out+=" $(printf '%q' "$a")"
  done
  out+=$'\n'
  printf "%s" "$out"
}

# ---------- apply ----------
apply_changes() {
  tui_textbox_from_string "Preview" "$(build_preview_command_string)"

  if ! tui_yesno "Apply changes" "This WILL modify all ${#mkv_files[@]} MKV files in:\n$dir\n\nProceed?"; then
    return 0
  fi

  build_mkvpropedit_args_array

  local log_file
  log_file="$(mktemp)"
  : >"$log_file"

  local healthy=1
  local failed=0

  # Log the argv we will run
  {
    echo "=== Planned argv (excluding FILE.mkv) ==="
    printf '%q ' "${args[@]}"
    echo
    echo
  } >>"$log_file"

  for file in "${mkv_files[@]}"; do
    tui_infobox "Editing:\n$(basename "$file")"

    {
      echo "=== FILE: $file ==="
      printf '%q ' mkvpropedit "$file" "${args[@]}"
      echo
    } >>"$log_file"

    if ! mkvpropedit "$file" "${args[@]}" >>"$log_file" 2>&1; then
      healthy=0
      failed=$((failed + 1))
      echo "!! FAILED (exit $?)" >>"$log_file"
    fi
    echo >>"$log_file"
  done

  if (( healthy == 1 )); then
    rm -f "$log_file"
    tui_msgbox "Done" "All files updated successfully."
  else
    if [[ "$tui" == "dialog" ]]; then
      dialog --clear --title "mkvpropedit errors (log)" --textbox "$log_file" 0 0
    else
      tui_msgbox "Done (errors)" "$failed file(s) failed.\nInstall 'dialog' to view the full log, or check:\n$log_file"
      # keep log_file around in whiptail mode so user can open it
      return 0
    fi
    rm -f "$log_file"
  fi
}

# ---------- main loop ----------
while true; do
  menu_args=()
  i=0
  while (( i < track_count )); do
    n="${track_num[$i]}"
    t="${track_type[$i]}"
    l="${track_lang[$i]}"
    nm="${track_name[$i]}"
    mode="${track_mode[$i]}"

    short_name="$nm"
    if (( ${#short_name} > 30 )); then short_name="${short_name:0:27}..."; fi

    label="$(printf "%-9s %-6s %-30s [%s]" "$t/$l" "trk:$n" "${short_name:-<no name>}" "$mode")"
    menu_args+=("$n" "$label")
    i=$((i + 1))
  done

  menu_args+=("P" "Preview planned mkvpropedit command (no apply)")
  menu_args+=("A" "Apply changes to all MKV files (MODIFIES FILES)")
  menu_args+=("I" "Show mkvinfo for sample file")
  menu_args+=("X" "Exit")

  choice="$(
    tui_menu \
      "MKV Flags TUI" \
      "Select a track to edit. Selection is reflected in the menu." \
      0 0 0 \
      "${menu_args[@]}"
  )" || true

  [[ -n "${choice:-}" ]] || break

  case "$choice" in
    X) break ;;
    P) tui_textbox_from_string "Planned changes" "$(build_preview_command_string)" ;;
    A) apply_changes ;;
    I) tui_textbox_from_cmd "mkvinfo (sample file)" mkvinfo "$sample_file" ;;
    *)
      idx=-1
      i=0
      while (( i < track_count )); do
        if [[ "${track_num[$i]}" == "$choice" ]]; then idx=$i; break; fi
        i=$((i + 1))
      done
      (( idx >= 0 )) && edit_track_mode "$idx"
      ;;
  esac
done
