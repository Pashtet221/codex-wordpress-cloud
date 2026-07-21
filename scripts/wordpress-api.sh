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
wp-plugins|plugins) posts_by_type wp-plugins "${2:-100}";;
list-type) posts_by_type "${2:?post type required}" "${3:-100}";;
find) find_posts "${2:-}" "${3:-}";;
find-wp-plugins|find-plugins) find_posts "${2:-}" wp-plugins;;
get) curl_api "$API/posts/$2";;
create) curl_api -X POST -H "Content-Type: application/json" --data-binary @"$2" "$API/posts";;
acf) curl_api "$API/posts/$2/acf";;
update) curl_api -X PATCH -H "Content-Type: application/json" --data-binary @"$3" "$API/posts/$2";;
update-acf) curl_api -X PATCH -H "Content-Type: application/json" --data-binary @"$3" "$API/posts/$2/acf";;
scan-links) curl_api -X POST "$API/links/scan";;
replace-links) curl_api -X POST -H "Content-Type: application/json" --data-binary @"$2" "$API/links/replace";;
audit) curl_api "$API/audit";;
*) echo "health pages posts wp-plugins plugins list-type find find-wp-plugins find-plugins get create acf update update-acf scan-links replace-links audit";;
esac
