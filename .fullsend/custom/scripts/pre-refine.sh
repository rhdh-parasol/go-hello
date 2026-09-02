#!/usr/bin/env bash
# pre-refine.sh — Load the triggering work item before the sandbox starts.
#
# Runs on the trusted runner. Reads the dispatch NormalizedEvent (Jira poll or
# GitHub BYOA) and writes issue-context.json for the sandbox.

set -euo pipefail

EVENT_FILE=".fullsend/dispatch/event-payload.json"
CONTEXT_DIR="/tmp/workspace"
CONTEXT_FILE="${CONTEXT_DIR}/issue-context.json"
mkdir -p "${CONTEXT_DIR}"

ISSUE_KEY="${ISSUE_KEY:-}"
ISSUE_SOURCE="${ISSUE_SOURCE:-}"
HUMAN_INSTRUCTION="${HUMAN_INSTRUCTION:-}"
REPO_FULL_NAME="${REPO_FULL_NAME:-}"
META_FILE="${CONTEXT_DIR}/refine-meta.json"

payload_get() {
  local query="$1"
  if [[ -f "${EVENT_FILE}" ]]; then
    jq -r "${query}" "${EVENT_FILE}" 2>/dev/null || true
  fi
}

jira_key_from_url() {
  local url="$1"
  if [[ "${url}" =~ /browse/([A-Z][A-Z0-9]+-[0-9]+) ]]; then
    printf '%s' "${BASH_REMATCH[1]}"
  fi
}

if [[ -f "${EVENT_FILE}" ]]; then
  echo "Reading dispatch event payload from ${EVENT_FILE}"
  if [[ -z "${ISSUE_SOURCE}" || "${ISSUE_SOURCE}" == "null" ]]; then
    ISSUE_SOURCE="$(payload_get '.source.system // empty')"
  fi
  if [[ -z "${ISSUE_KEY}" || "${ISSUE_KEY}" == "null" ]]; then
    ISSUE_KEY="$(payload_get '.entity.key // empty')"
  fi
  if [[ -z "${HUMAN_INSTRUCTION}" || "${HUMAN_INSTRUCTION}" == "none" ]]; then
    HUMAN_INSTRUCTION="$(payload_get '.transition.comment.instruction // empty')"
  fi
  if [[ -z "${HUMAN_INSTRUCTION}" ]]; then
    COMMENT_BODY="$(payload_get '.comment.body // empty')"
    if [[ -n "${COMMENT_BODY}" ]]; then
      HUMAN_INSTRUCTION="$(printf '%s' "${COMMENT_BODY}" \
        | sed -E 's|^[[:space:]]*/fs-refine[[:space:]]*||' \
        | sed -E 's|^[[:space:]]+||; s|[[:space:]]+$||')"
    fi
  fi
  if [[ -z "${REPO_FULL_NAME}" ]]; then
    REPO_FULL_NAME="$(payload_get '.repo // empty')"
  fi
  if [[ -z "${GITHUB_ISSUE_URL:-}" ]]; then
    GITHUB_ISSUE_URL="$(payload_get '.entity.url // .issue.html_url // empty')"
  fi
fi

# v0.37 jira-poll writes a GitHub-shaped stub: issue.html_url is the browse
# URL, issue.number is Jira's internal id (not PROJ-123). Never treat that
# number as a GitHub issue.
if [[ -z "${ISSUE_KEY}" || "${ISSUE_KEY}" == "null" ]]; then
  ISSUE_KEY="$(jira_key_from_url "${GITHUB_ISSUE_URL:-}")"
fi
if [[ -z "${ISSUE_SOURCE}" || "${ISSUE_SOURCE}" == "null" ]]; then
  if [[ "${GITHUB_ISSUE_URL:-}" == *".atlassian.net/"* ]] \
    || [[ "${ISSUE_KEY}" =~ ^[A-Z][A-Z0-9]+-[0-9]+$ ]]; then
    ISSUE_SOURCE="jira"
  fi
fi
if [[ -z "${ISSUE_KEY}" || "${ISSUE_KEY}" == "null" ]]; then
  if [[ "${ISSUE_SOURCE}" != "jira" ]]; then
    ENTITY_ID="$(payload_get '.issue.number // .entity.id // empty')"
    if [[ "${ENTITY_ID}" =~ ^[1-9][0-9]*$ ]]; then
      ISSUE_KEY="${ENTITY_ID}"
    fi
  fi
fi
if [[ -z "${ISSUE_SOURCE}" || "${ISSUE_SOURCE}" == "null" ]]; then
  if [[ "${ISSUE_KEY}" =~ ^[A-Z][A-Z0-9]+-[0-9]+$ ]]; then
    ISSUE_SOURCE="jira"
  else
    ISSUE_SOURCE="github"
  fi
fi

errors=0
if [[ -z "${ISSUE_KEY}" ]]; then
  echo "::error::Could not derive ISSUE_KEY from event payload"
  errors=$((errors + 1))
fi
if [[ "${errors}" -gt 0 ]]; then
  exit 1
fi

MAX_INSTRUCTION_BYTES=10000
if [[ -n "${HUMAN_INSTRUCTION}" && "${HUMAN_INSTRUCTION}" != "none" ]]; then
  if [[ "${#HUMAN_INSTRUCTION}" -gt "${MAX_INSTRUCTION_BYTES}" ]]; then
    echo "::error::HUMAN_INSTRUCTION is ${#HUMAN_INSTRUCTION} bytes (max: ${MAX_INSTRUCTION_BYTES})."
    exit 1
  fi
fi

fetch_ok=0
case "${ISSUE_SOURCE}" in
  jira)
    if [[ ! "${ISSUE_KEY}" =~ ^([A-Z][A-Z0-9]+)-([0-9]+)$ ]]; then
      echo "::error::Jira ISSUE_KEY must look like PROJ-123, got: '${ISSUE_KEY}'"
      exit 1
    fi
    JIRA_PROJECT="${BASH_REMATCH[1]}"
    JIRA_NUMBER="${BASH_REMATCH[2]}"
    if [[ -z "${JIRA_BASE_URL:-}" || -z "${JIRA_TOKEN:-}" || -z "${JIRA_USER_EMAIL:-}" ]]; then
      echo "::error::JIRA_BASE_URL, JIRA_TOKEN, and JIRA_USER_EMAIL are required for Jira refine"
      exit 1
    fi
    if command -v fullsend >/dev/null 2>&1; then
      if fullsend issues get \
        --tracker jira \
        --project "${JIRA_PROJECT}" \
        --number "${JIRA_NUMBER}" \
        --fullsend-dir .fullsend > "${CONTEXT_FILE}"; then
        fetch_ok=1
      else
        echo "::warning::fullsend issues get failed; falling back to Jira REST"
      fi
    fi
    if [[ "${fetch_ok}" -ne 1 ]]; then
      AUTH="$(printf '%s:%s' "${JIRA_USER_EMAIL}" "${JIRA_TOKEN}" | base64 | tr -d '\n')"
      BASE="${JIRA_BASE_URL%/}"
      if curl -fsS \
        -H "Authorization: Basic ${AUTH}" \
        -H "Accept: application/json" \
        "${BASE}/rest/api/3/issue/${ISSUE_KEY}?fields=summary,description,comment,labels,status,issuetype,assignee,parent" \
        > "${CONTEXT_FILE}"; then
        fetch_ok=1
      fi
    fi
    ;;
  github)
    _TOKEN="${REVIEW_TOKEN:-${GH_TOKEN:-}}"
    PROJECT="${REPO_FULL_NAME}"
    if [[ -z "${PROJECT}" ]]; then
      echo "::error::REPO_FULL_NAME is required for GitHub refine"
      exit 1
    fi
    if [[ ! "${ISSUE_KEY}" =~ ^[1-9][0-9]*$ ]]; then
      echo "::error::GitHub issue number must be numeric, got: '${ISSUE_KEY}'"
      exit 1
    fi
    if command -v fullsend >/dev/null 2>&1; then
      if fullsend issues get \
        --tracker github \
        --project "${PROJECT}" \
        --number "${ISSUE_KEY}" \
        --fullsend-dir .fullsend > "${CONTEXT_FILE}"; then
        fetch_ok=1
      fi
    fi
    if [[ "${fetch_ok}" -ne 1 && -n "${_TOKEN}" ]]; then
      if GH_TOKEN="${_TOKEN}" gh issue view "${ISSUE_KEY}" --repo "${PROJECT}" --json number,title,body,labels,comments,url \
        > "${CONTEXT_FILE}"; then
        fetch_ok=1
      fi
    fi
    ;;
  *)
    echo "::error::Unsupported ISSUE_SOURCE: '${ISSUE_SOURCE}'"
    exit 1
    ;;
esac

if [[ "${fetch_ok}" -ne 1 ]]; then
  echo "::error::Failed to fetch issue context for ${ISSUE_SOURCE} ${ISSUE_KEY}"
  exit 1
fi

export ISSUE_KEY ISSUE_SOURCE REPO_FULL_NAME GITHUB_ISSUE_URL HUMAN_INSTRUCTION
jq -n \
  --arg key "${ISSUE_KEY}" \
  --arg source "${ISSUE_SOURCE}" \
  --arg repo "${REPO_FULL_NAME}" \
  --arg url "${GITHUB_ISSUE_URL:-}" \
  '{issue_key:$key, issue_source:$source, repo_full_name:$repo, issue_url:$url}' \
  > "${META_FILE}"

# GITHUB_ENV does not reach the post-script in the same composite action
# step — post-refine reads refine-meta.json / the event payload.
if [[ -n "${GITHUB_ENV:-}" ]]; then
  {
    echo "ISSUE_KEY=${ISSUE_KEY}"
    echo "ISSUE_SOURCE=${ISSUE_SOURCE}"
    echo "REPO_FULL_NAME=${REPO_FULL_NAME}"
    if [[ -n "${GITHUB_ISSUE_URL:-}" ]]; then
      echo "GITHUB_ISSUE_URL=${GITHUB_ISSUE_URL}"
    fi
  } >> "${GITHUB_ENV}"
  if [[ -n "${HUMAN_INSTRUCTION}" ]]; then
    DELIM="REFINE_INSTR_$(openssl rand -hex 8)"
    {
      echo "HUMAN_INSTRUCTION<<${DELIM}"
      printf '%s\n' "${HUMAN_INSTRUCTION}"
      echo "${DELIM}"
    } >> "${GITHUB_ENV}"
  fi
fi

echo "Refine pre-check passed:"
echo "  ISSUE_SOURCE=${ISSUE_SOURCE}"
echo "  ISSUE_KEY=${ISSUE_KEY}"
echo "  REPO_FULL_NAME=${REPO_FULL_NAME}"
echo "  CONTEXT_FILE=${CONTEXT_FILE}"
if [[ -n "${HUMAN_INSTRUCTION}" && "${HUMAN_INSTRUCTION}" != "none" ]]; then
  echo "  HUMAN_INSTRUCTION=${HUMAN_INSTRUCTION:0:200}"
else
  echo "  HUMAN_INSTRUCTION=<empty>"
fi
