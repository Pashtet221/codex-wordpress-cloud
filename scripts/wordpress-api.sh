#!/usr/bin/env bash
set -euo pipefail
API="${WORDPRESS_URL:-}"
API="${API%/}/wp-json/codex-bridge/v1"

curl_api(){
  : "${WORDPRESS_URL:?WORDPRESS_URL is required}"
  : "${WORDPRESS_USERNAME:?WORDPRESS_USERNAME is required}"
  : "${WORDPRESS_APP_PASSWORD:?WORDPRESS_APP_PASSWORD is required}"
  local auth="${WORDPRESS_USERNAME}:${WORDPRESS_APP_PASSWORD}"
  curl --silent --show-error --fail-with-body --user "$auth" "$@"
}
posts_by_type(){ curl_api --get --data-urlencode "post_type=$1" --data-urlencode "per_page=${2:-100}" "$API/posts"; }
wp_native(){
  : "${WORDPRESS_URL:?WORDPRESS_URL is required}"
  local path="$1"
  shift
  local base="${WORDPRESS_URL%/}/wp-json/wp/v2"
  curl_api "$@" "$base/$path"
}
wp_native_get(){ wp_native "plugin/$1"; }
wp_native_plugins(){ wp_native "plugin?per_page=${1:-100}"; }
wp_native_update(){ wp_native "plugin/$1" -X POST -H "Content-Type: application/json" --data-binary @"$2"; }
wp_native_terms(){ wp_native "plugin_category?per_page=${1:-100}"; }
find_posts(){
  local search="${1:-}"
  local post_type="${2:-}"
  if [[ -n "$post_type" ]]; then
    curl_api --get --data-urlencode "search=$search" --data-urlencode "post_type=$post_type" "$API/posts"
  else
    curl_api --get --data-urlencode "search=$search" "$API/posts"
  fi
}
case "${1:-help}" in
health) curl_api "$API/health";;
pages) posts_by_type page;;
posts) posts_by_type post;;
wp-plugins|plugins) wp_native_plugins "${2:-100}";;
list-type) posts_by_type "${2:?post type required}" "${3:-100}";;
find) find_posts "${2:-}" "${3:-}";;
find-wp-plugins|find-plugins) find_posts "${2:-}" wp-plugins;;
get)
  if ! curl_api "$API/posts/$2" >/tmp/codex-bridge-get.$$ 2>/tmp/codex-bridge-get.err.$$; then
    cat /tmp/codex-bridge-get.err.$$ >&2 || true
    wp_native_get "$2"
  else
    cat /tmp/codex-bridge-get.$$
  fi
  rm -f /tmp/codex-bridge-get.$$ /tmp/codex-bridge-get.err.$$;;
create) curl_api -X POST -H "Content-Type: application/json" --data-binary @"$2" "$API/posts";;
acf) curl_api "$API/posts/$2/acf";;
update)
  if ! curl_api -X PATCH -H "Content-Type: application/json" --data-binary @"$3" "$API/posts/$2" >/tmp/codex-bridge-update.$$ 2>/tmp/codex-bridge-update.err.$$; then
    cat /tmp/codex-bridge-update.err.$$ >&2 || true
    wp_native_update "$2" "$3"
  else
    cat /tmp/codex-bridge-update.$$
  fi
  rm -f /tmp/codex-bridge-update.$$ /tmp/codex-bridge-update.err.$$;;
update-acf) curl_api -X PATCH -H "Content-Type: application/json" --data-binary @"$3" "$API/posts/$2/acf";;
scan-links) curl_api -X POST "$API/links/scan";;
replace-links) curl_api -X POST -H "Content-Type: application/json" --data-binary @"$2" "$API/links/replace";;
plugin-categories) wp_native_terms "${2:-100}";;
audit) curl_api "$API/audit";;
*) echo "health pages posts wp-plugins plugins plugin-categories list-type find find-wp-plugins find-plugins get create acf update update-acf scan-links replace-links audit";;
esac
