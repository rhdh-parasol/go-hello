#!/usr/bin/env bash
# post-refine.sh — Post refine output to the triggering Jira or GitHub issue.
#
# Runs on the trusted runner AFTER the sandbox is destroyed.
# Agent output is untrusted: extract via jq, truncate, post via --result file.

set -euo pipefail

EVENT_FILE=".fullsend/dispatch/event-payload.json"
MARKER="<!-- fullsend:refine -->"
MAX_BODY_CHARS=60000
RUN_URL="${RUN_URL:-${STATUS_RUN_URL:-}}"

payload_get() {
  local query="$1"
  if [[ -f "${EVENT_FILE}" ]]; then
    jq -r "${query}" "${EVENT_FILE}" 2>/dev/null || true
  fi
}

ISSUE_KEY="${ISSUE_KEY:-}"
ISSUE_SOURCE="${ISSUE_SOURCE:-}"
REPO_FULL_NAME="${REPO_FULL_NAME:-}"
META_FILE="/tmp/workspace/refine-meta.json"

jira_key_from_url() {
  local url="$1"
  if [[ "${url}" =~ /browse/([A-Z][A-Z0-9]+-[0-9]+) ]]; then
    printf '%s' "${BASH_REMATCH[1]}"
  fi
}

if [[ -f "${META_FILE}" ]]; then
  ISSUE_KEY="$(jq -r '.issue_key // empty' "${META_FILE}")"
  ISSUE_SOURCE="$(jq -r '.issue_source // empty' "${META_FILE}")"
  REPO_FULL_NAME="$(jq -r '.repo_full_name // empty' "${META_FILE}")"
  if [[ -z "${GITHUB_ISSUE_URL:-}" ]]; then
    GITHUB_ISSUE_URL="$(jq -r '.issue_url // empty' "${META_FILE}")"
  fi
fi

if [[ -z "${ISSUE_KEY}" && -f "${EVENT_FILE}" ]]; then
  ISSUE_KEY="$(payload_get '.entity.key // empty')"
fi
if [[ -z "${ISSUE_SOURCE}" && -f "${EVENT_FILE}" ]]; then
  ISSUE_SOURCE="$(payload_get '.source.system // empty')"
fi
if [[ -z "${REPO_FULL_NAME}" && -f "${EVENT_FILE}" ]]; then
  REPO_FULL_NAME="$(payload_get '.repo // empty')"
fi
if [[ -z "${GITHUB_ISSUE_URL:-}" && -f "${EVENT_FILE}" ]]; then
  GITHUB_ISSUE_URL="$(payload_get '.entity.url // .issue.html_url // empty')"
fi
if [[ -z "${ISSUE_KEY}" ]]; then
  ISSUE_KEY="$(jira_key_from_url "${GITHUB_ISSUE_URL:-}")"
fi
if [[ -z "${ISSUE_SOURCE}" ]]; then
  if [[ "${GITHUB_ISSUE_URL:-}" == *".atlassian.net/"* ]] \
    || [[ "${ISSUE_KEY}" =~ ^[A-Z][A-Z0-9]+-[0-9]+$ ]]; then
    ISSUE_SOURCE="jira"
  else
    ISSUE_SOURCE="github"
  fi
fi

if [[ -z "${ISSUE_KEY}" ]]; then
  echo "::error::ISSUE_KEY is required to post refine output"
  exit 1
fi

OUTPUT_FILE=""
if [[ -n "${FULLSEND_VALIDATED_ITERATION_DIR:-}" && -f "${FULLSEND_VALIDATED_ITERATION_DIR}/output.jsonl" ]]; then
  OUTPUT_FILE="${FULLSEND_VALIDATED_ITERATION_DIR}/output.jsonl"
else
  for dir in iteration-*/; do
    if [[ -f "${dir}/output.jsonl" ]]; then
      OUTPUT_FILE="${dir}/output.jsonl"
    fi
  done
fi

SUMMARY=""
if [[ -n "${OUTPUT_FILE}" ]]; then
  echo "Reading agent output from: ${OUTPUT_FILE}"
  SUMMARY=$(jq -s -r '
    [ .[]
      | select(.type == "assistant")
      | .message.content[]?
      | select(.type == "text")
      | .text
    ]
    | if length == 0 then empty else .[-1] end
  ' "${OUTPUT_FILE}" || true)
fi

if [[ -z "${SUMMARY}" ]]; then
  SUMMARY="⚠️ Refine agent produced no output. Check the [workflow run](${RUN_URL:-}) for logs."
fi

# Drop chain-of-thought if the agent ignored the "start at heading" rule.
if printf '%s' "${SUMMARY}" | grep -qE '^#{1,3}[[:space:]]+.*Refine'; then
  SUMMARY=$(printf '%s' "${SUMMARY}" | awk '
    /^#{1,3}[[:space:]]+.*Refine/ { keep=1 }
    keep { print }
  ')
fi

SUMMARY="${SUMMARY:0:${MAX_BODY_CHARS}}"

BODY="${MARKER}
${SUMMARY}

---
<sub>Posted by refine agent · [Run logs](${RUN_URL:-})</sub>"

TMP_BODY="$(mktemp)"
printf '%s' "${BODY}" > "${TMP_BODY}"

posted=0
case "${ISSUE_SOURCE}" in
  jira)
    if [[ ! "${ISSUE_KEY}" =~ ^([A-Z][A-Z0-9]+)-([0-9]+)$ ]]; then
      echo "::error::Jira ISSUE_KEY must look like PROJ-123, got: '${ISSUE_KEY}'"
      rm -f "${TMP_BODY}"
      exit 1
    fi
    JIRA_PROJECT="${BASH_REMATCH[1]}"
    JIRA_NUMBER="${BASH_REMATCH[2]}"
    if [[ -z "${JIRA_BASE_URL:-}" || -z "${JIRA_TOKEN:-}" || -z "${JIRA_USER_EMAIL:-}" ]]; then
      echo "::error::JIRA_BASE_URL, JIRA_TOKEN, and JIRA_USER_EMAIL are required to post to Jira"
      rm -f "${TMP_BODY}"
      exit 1
    fi
    if ! command -v fullsend >/dev/null 2>&1; then
      echo "::error::fullsend CLI is required to post a Jira comment"
      rm -f "${TMP_BODY}"
      exit 1
    fi
    if fullsend issues post-comment \
      --tracker jira \
      --project "${JIRA_PROJECT}" \
      --number "${JIRA_NUMBER}" \
      --marker "${MARKER}" \
      --result "${TMP_BODY}" \
      --fullsend-dir .fullsend; then
      posted=1
    fi
    ;;
  github)
    _TOKEN="${REVIEW_TOKEN:-${GH_TOKEN:-}}"
    if [[ -z "${_TOKEN}" ]]; then
      echo "::error::REVIEW_TOKEN or GH_TOKEN is required to post to GitHub"
      rm -f "${TMP_BODY}"
      exit 1
    fi
    export GH_TOKEN="${_TOKEN}"
    if [[ ! "${ISSUE_KEY}" =~ ^[1-9][0-9]*$ ]]; then
      echo "::error::GitHub issue number must be numeric, got: '${ISSUE_KEY}'"
      rm -f "${TMP_BODY}"
      exit 1
    fi
    if [[ ! "${REPO_FULL_NAME}" =~ ^[a-zA-Z0-9._-]+/[a-zA-Z0-9._-]+$ ]]; then
      echo "::error::REPO_FULL_NAME is not set or invalid: '${REPO_FULL_NAME}'"
      rm -f "${TMP_BODY}"
      exit 1
    fi
    if command -v fullsend >/dev/null 2>&1; then
      if fullsend issues post-comment \
        --tracker github \
        --project "${REPO_FULL_NAME}" \
        --number "${ISSUE_KEY}" \
        --marker "${MARKER}" \
        --result "${TMP_BODY}" \
        --fullsend-dir .fullsend; then
        posted=1
      fi
    fi
    if [[ "${posted}" -ne 1 ]]; then
      if gh issue comment "${ISSUE_KEY}" --repo "${REPO_FULL_NAME}" --body-file "${TMP_BODY}"; then
        posted=1
      fi
    fi
    ;;
  *)
    echo "::error::Unsupported ISSUE_SOURCE: '${ISSUE_SOURCE}'"
    rm -f "${TMP_BODY}"
    exit 1
    ;;
esac

rm -f "${TMP_BODY}"

if [[ "${posted}" -ne 1 ]]; then
  echo "::error::Failed to post refine comment to ${ISSUE_SOURCE} ${ISSUE_KEY}"
  exit 1
fi

echo "Refine comment posted on ${ISSUE_SOURCE} ${ISSUE_KEY}"
