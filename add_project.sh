#!/usr/bin/env bash
set -euo pipefail

# --- Helpers ---------------------------------------------------------------

die() { echo "Error: $*" >&2; exit 1; }

prompt() {
  local var_name="$1"
  local label="$2"
  local hint="${3:-}"
  local value=""

  if [[ -n "$hint" ]]; then
    read -r -p "${label} (${hint}): " value
  else
    read -r -p "${label}: " value
  fi

  [[ -n "${value}" ]] || die "${label} is required"
  printf -v "$var_name" '%s' "$value"
}

require_file() {
  local f="$1"
  [[ -f "$f" ]] || die "File not found: $f"
}

require_dir() {
  local d="$1"
  [[ -d "$d" ]] || die "Directory not found: $d"
}

escape_sed_repl() {
  # Escape for sed replacement (/, &, \)
  printf '%s' "$1" | sed -e 's/[\/&\\]/\\&/g'
}

render_template() {
  local template_path="$1"
  local out_path="$2"

  require_file "$template_path"

  local pc pt pd len lru lth gmap
  pc="$(escape_sed_repl "$PROJECT_CODE")"
  pt="$(escape_sed_repl "$PROJECT_TITLE")"
  pd="$(escape_sed_repl "$PUBLICATION_DATE")"
  len="$(escape_sed_repl "$LOCATION_EN")"
  lru="$(escape_sed_repl "$LOCATION_RU")"
  lth="$(escape_sed_repl "$LOCATION_TH")"
  gmap="$(escape_sed_repl "$GOOGLE_MAP_LINK")"

  sed \
    -e "s/{{PROJECT_CODE}}/${pc}/g" \
    -e "s/{{PROJECT_TITLE}}/${pt}/g" \
    -e "s/{{PUBLICATION_DATE}}/${pd}/g" \
    -e "s/{{LOCATION_EN}}/${len}/g" \
    -e "s/{{LOCATION_RU}}/${lru}/g" \
    -e "s/{{LOCATION_TH}}/${lth}/g" \
    -e "s/{{GOOGLE_MAP_LINK}}/${gmap}/g" \
    "$template_path" > "$out_path"
}

# --- Inputs ----------------------------------------------------------------

prompt PROJECT_CODE "New project code" "e.g. 39"
prompt PREVIOUS_CODE "Previous project code" "e.g. 38"
prompt PROJECT_TITLE "Project title" "e.g. Sunrise Village Villa"
prompt PUBLICATION_DATE "Publication date" "YYYY-MM-DD HH:MM (e.g. 2026-01-13 10:01)"
prompt LOCATION_EN "Location (EN)" "District, Province in eng (e.g. Bang Tao, Phuket)"
prompt LOCATION_RU "Location (RU)" "District, Province in rus (e.g. Бангтао, Пхукет)"
prompt LOCATION_TH "Location (TH)" "District, Province in thai (e.g. บางเทา, ภูเก็ต)"
prompt GOOGLE_MAP_LINK "Google map link" "https://maps.app.goo.gl/..."

# Basic validation (lightweight)
[[ "$PROJECT_CODE" =~ ^[0-9]+$ ]] || die "Project code must be a number"
[[ "$PREVIOUS_CODE" =~ ^[0-9]+$ ]] || die "Previous project code must be a number"

CONFIG_FILE="_config.yml"
PORTFOLIO_DIR="_portfolio"
TEMPLATES_DIR="scripts/templates"

require_file "$CONFIG_FILE"
require_dir "$PORTFOLIO_DIR"
require_dir "$TEMPLATES_DIR"

T_EN="${TEMPLATES_DIR}/project.en.tmpl"
T_RU="${TEMPLATES_DIR}/project.ru.tmpl"
T_TH="${TEMPLATES_DIR}/project.th.tmpl"
require_file "$T_EN"
require_file "$T_RU"
require_file "$T_TH"

# --- Check project images --------------------------------------------------

PROJECT_IMAGES_DIR="assets/images/projects/${PROJECT_CODE}"
PROJECT_COVER_IMAGE="${PROJECT_IMAGES_DIR}/00.jpg"

if [[ ! -d "$PROJECT_IMAGES_DIR" ]]; then
die "Project images directory does not exist: ${PROJECT_IMAGES_DIR}"
fi

if [[ ! -f "$PROJECT_COVER_IMAGE" ]]; then
die "Project cover image not found: ${PROJECT_COVER_IMAGE}"
fi

# --- 1) Update _config.yml --------------------------------------------------

tmp_config="$(mktemp)"

# We insert a new defaults block right after the line containing "project: PREVIOUS_CODE"
# but only after we have seen the matching "path: assets/images/projects/PREVIOUS_CODE".
awk -v prev="$PREVIOUS_CODE" -v cur="$PROJECT_CODE" '
BEGIN { seen_path=0; inserted=0; }
{
  print $0

  if ($0 ~ "path: \"assets/images/projects/" prev "\"") {
    seen_path=1
  }

  # Insert right after the previous project number line, but only if we saw the path match.
  if (seen_path==1 && inserted==0 && $0 ~ "project: " prev "$") {
    print "  - scope:"
    print "      path: \"assets/images/projects/" cur "\""
    print "    values:"
    print "      project: " cur
    inserted=1
    seen_path=0
  }
}
END {
  if (inserted==0) {
    exit 42
  }
}
' "$CONFIG_FILE" > "$tmp_config" || {
  rc=$?
  if [[ $rc -eq 42 ]]; then
    rm -f "$tmp_config"
    die "Could not find previous project block in _config.yml for code: $PREVIOUS_CODE"
  fi
  rm -f "$tmp_config"
  die "Failed to update _config.yml"
}

cp "$CONFIG_FILE" "${CONFIG_FILE}.bak"
mv "$tmp_config" "$CONFIG_FILE"

# --- 2) Create portfolio files ---------------------------------------------

OUT_EN="${PORTFOLIO_DIR}/${PROJECT_CODE}.en.html"
OUT_RU="${PORTFOLIO_DIR}/${PROJECT_CODE}.ru.html"
OUT_TH="${PORTFOLIO_DIR}/${PROJECT_CODE}.th.html"

[[ -e "$OUT_EN" || -e "$OUT_RU" || -e "$OUT_TH" ]] && die "Portfolio files already exist for project: $PROJECT_CODE"

render_template "$T_EN" "$OUT_EN"
render_template "$T_RU" "$OUT_RU"
render_template "$T_TH" "$OUT_TH"

# --- Done ------------------------------------------------------------------

echo "✅ Done"
echo "• Updated: ${CONFIG_FILE} (backup: ${CONFIG_FILE}.bak)"
echo "• Created:"
echo "  - ${OUT_EN}"
echo "  - ${OUT_RU}"
echo "  - ${OUT_TH}"