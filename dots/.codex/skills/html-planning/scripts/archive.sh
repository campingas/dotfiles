#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "usage: archive.sh [--check] FILE PROJECT SLUG KIND TITLE AGENT" >&2
  exit 64
}

check_only=false
if [[ ${1:-} == "--check" ]]; then
  check_only=true
  shift
fi
[[ $# -eq 6 ]] || usage

file=$1
project=$2
slug=$3
kind=$4
title=$5
agent=$6

[[ -r $file ]] || { echo "plan-saver: unreadable artifact: $file" >&2; exit 66; }
[[ -n $project && -n $slug && -n $title && -n $agent ]] || { echo "plan-saver: project, slug, title, and agent are required" >&2; exit 64; }
[[ $kind == "plan" || $kind == "report" ]] || { echo "plan-saver: kind must be plan or report" >&2; exit 64; }

config=${PLAN_SAVER_CONFIG:-${XDG_CONFIG_HOME:-${HOME:?HOME is required}/.config}/plan-saver/config.json}
[[ -r $config ]] || { echo "plan-saver: config not found: $config" >&2; exit 78; }

url=$(jq -er '.url | strings | select(length > 0)' "$config") || { echo "plan-saver: config has no URL" >&2; exit 78; }
token=$(jq -er '.token | strings | select(length > 0)' "$config") || { echo "plan-saver: config has no token" >&2; exit 78; }

payload=$(mktemp "${TMPDIR:-/tmp}/html-planning-payload.XXXXXX")
response=$(mktemp "${TMPDIR:-/tmp}/html-planning-response.XXXXXX")
trap 'rm -f "$payload" "$response"' EXIT

branch=$(git branch --show-current 2>/dev/null || true)
repo_path=$PWD
host=$(hostname)

jq -n \
  --arg project "$project" --arg slug "$slug" --arg kind "$kind" --arg title "$title" --arg agent "$agent" \
  --rawfile html "$file" --arg branch "$branch" --arg repoPath "$repo_path" --arg hostname "$host" \
  '{project:$project, slug:$slug, kind:$kind, title:$title, html:$html,
    meta:{agent:$agent, branch:$branch, repoPath:$repoPath, generator:"html-planning@4", hostname:$hostname}}' \
  > "$payload"

if $check_only; then
  jq -cn --arg endpoint "${url%/}/api/v1/documents" --arg project "$project" --arg slug "$slug" --arg kind "$kind" --arg agent "$agent" \
    '{ready:true, endpoint:$endpoint, project:$project, slug:$slug, kind:$kind, agent:$agent, tokenConfigured:true}'
  exit 0
fi

set +e
status=$(
  printf 'header = "Authorization: Bearer %s"\nheader = "Content-Type: application/json"\n' "$token" |
    curl -sS -o "$response" -w '%{http_code}' -m 30 -X POST \
      --config - --data-binary "@$payload" "${url%/}/api/v1/documents"
)
curl_exit=$?
set -e

if [[ $curl_exit -ne 0 ]]; then
  echo "plan-saver: upload failed (curl exit $curl_exit)" >&2
  exit 69
fi
if [[ ! $status =~ ^2[0-9][0-9]$ ]]; then
  echo "plan-saver: upload failed (HTTP $status)" >&2
  jq -c . "$response" >&2 2>/dev/null || true
  exit 69
fi
if ! jq -e '(.url | type == "string" and length > 0) and (.version | type == "number")' "$response" >/dev/null; then
  echo "plan-saver: upload returned an invalid success response" >&2
  exit 69
fi

jq -c '{archived:true, url, version}' "$response"
