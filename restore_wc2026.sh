#!/usr/bin/env bash
# Restores WordPress from component zips + db.gz, performs URL replace, rewrites, salts, and cache flush.
# Usage:
#   bash restore_wc2026.sh \
#     --path=/var/www/html \
#     --archive=/backups \
#     --old-url="https://old.example.com" \
#     --new-url="https://staging.example.com" \
#     --db-name=wpdb --db-user=wpuser --db-pass=secret --db-host=localhost
set -euo pipefail

WP_PATH=""
ARCHIVE_DIR=""
OLD_URL=""
NEW_URL=""
DB_NAME=""
DB_USER=""
DB_PASS=""
DB_HOST="localhost"

PLUGINS_ZIP=""
THEMES_ZIP=""
MU_PLUGINS_ZIP=""
UPLOADS_ZIP=""
DB_GZ=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --path=*) WP_PATH="${1#*=}"; shift ;;
    --archive=*) ARCHIVE_DIR="${1#*=}"; shift ;;
    --old-url=*) OLD_URL="${1#*=}"; shift ;;
    --new-url=*) NEW_URL="${1#*=}"; shift ;;
    --db-name=*) DB_NAME="${1#*=}"; shift ;;
    --db-user=*) DB_USER="${1#*=}"; shift ;;
    --db-pass=*) DB_PASS="${1#*=}"; shift ;;
    --db-host=*) DB_HOST="${1#*=}"; shift ;;
    *) shift ;;
  esac
done

if [[ -z "${WP_PATH}" || -z "${ARCHIVE_DIR}" || -z "${NEW_URL}" || -z "${DB_NAME}" || -z "${DB_USER}" ]]; then
  echo "Missing required arguments. See header for usage."
  exit 1
fi

cd "${WP_PATH}"

# Detect archives
PLUGINS_ZIP=$(ls "${ARCHIVE_DIR}"/*-plugins.zip 2>/dev/null | head -n1 || true)
THEMES_ZIP=$(ls "${ARCHIVE_DIR}"/*-themes.zip 2>/dev/null | head -n1 || true)
MU_PLUGINS_ZIP=$(ls "${ARCHIVE_DIR}"/*-mu-plugins.zip 2>/dev/null | head -n1 || true)
UPLOADS_ZIP=$(ls "${ARCHIVE_DIR}"/*-uploads.zip 2>/dev/null | head -n1 || true)
DB_GZ=$(ls "${ARCHIVE_DIR}"/*-db.gz 2>/dev/null | head -n1 || true)

echo "==> Using archives:"
echo "plugins:   ${PLUGINS_ZIP}"
echo "themes:    ${THEMES_ZIP}"
echo "mu-plugins:${MU_PLUGINS_ZIP}"
echo "uploads:   ${UPLOADS_ZIP}"
echo "db:        ${DB_GZ}"

# Ensure wp-cli works
wp core version

# Create wp-config.php if missing
if ! wp config path >/dev/null 2>&1; then
  echo "==> Creating wp-config.php"
  wp config create --dbname="${DB_NAME}" --dbuser="${DB_USER}" --dbpass="${DB_PASS}" --dbhost="${DB_HOST}" --skip-check
fi

# Ensure DB
echo "==> Ensuring DB exists"
wp db create || true

# Import DB
if [[ -n "${DB_GZ}" ]]; then
  echo "==> Importing database"
  gunzip -c "${DB_GZ}" | wp db import -
fi

# Search-replace (skip GUIDs)
if [[ -n "${OLD_URL}" && -n "${NEW_URL}" ]]; then
  echo "==> Rewriting URLs ${OLD_URL} => ${NEW_URL}"
  wp search-replace "${OLD_URL}" "${NEW_URL}" --skip-columns=guid
fi

# Restore wp-content
mkdir -p wp-content
[[ -n "${PLUGINS_ZIP}"    ]] && unzip -oq "${PLUGINS_ZIP}"    -d wp-content/
[[ -n "${THEMES_ZIP}"     ]] && unzip -oq "${THEMES_ZIP}"     -d wp-content/
[[ -n "${MU_PLUGINS_ZIP}" ]] && unzip -oq "${MU_PLUGINS_ZIP}" -d wp-content/
[[ -n "${UPLOADS_ZIP}"    ]] && unzip -oq "${UPLOADS_ZIP}"    -d wp-content/

# Flush + salts + caches
echo "==> Flushing rewrites and caches"
wp rewrite structure '/%postname%/' --hard
wp rewrite flush --hard
wp cache flush || true
wp transient delete --all || true

echo "==> Refreshing keys and salts"
wp config shuffle-salts

echo "==> Done. Visit the site and save Permalinks once if needed."
