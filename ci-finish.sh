#!/usr/bin/env bash
set -euo pipefail

# Remote CI finalizer for PR #9 (no local builds). Requires GH_TOKEN in env.
# Usage:
#   export GH_TOKEN="<your PAT>"   # fine‑grained, contents:write for this repo
#   bash ci-finish.sh

OWNER="matheus-rech"
REPO="meta-analysis-mvp-standalone"
PR_BRANCH="chore/ci-notify-webhook"

: "${GH_TOKEN:?Set GH_TOKEN env var with a repo-scoped PAT}"

api() {
  curl -sS \
    -H "Authorization: Bearer $GH_TOKEN" \
    -H "Accept: application/vnd.github+json" \
    "https://api.github.com$1"
}

api_put() {
  local path="$1" data="$2"
  curl -sS -X PUT \
    -H "Authorization: Bearer $GH_TOKEN" \
    -H "Accept: application/vnd.github+json" \
    -d "$data" \
    "https://api.github.com$path"
}

# Extract top-level .sha from a GitHub contents response using Node (no jq dependency)
json_get_sha() {
  node -e 'let d="";process.stdin.on("data",c=>d+=c).on("end",()=>{try{const j=JSON.parse(d);console.log(j && j.sha ? j.sha : "");}catch{console.log("")}})'
}

get_sha() {
  local path="$1"
  api "/repos/$OWNER/$REPO/contents/$path?ref=$PR_BRANCH" | json_get_sha
}

put_file() {
  local path="$1" content="$2" message="$3"
  local b64 sha json
  b64="$(printf "%s" "$content" | base64 | tr -d '\n')"
  sha="$(get_sha "$path")"
  if [[ -n "$sha" ]]; then
    json=$(node -e 'const msg=process.argv[1],content=process.argv[2],branch=process.argv[3],sha=process.argv[4];process.stdout.write(JSON.stringify({message:msg,content,branch,sha}))' \
            "$message" "$b64" "$PR_BRANCH" "$sha")
  else
    json=$(node -e 'const msg=process.argv[1],content=process.argv[2],branch=process.argv[3];process.stdout.write(JSON.stringify({message:msg,content,branch}))' \
            "$message" "$b64" "$PR_BRANCH")
  fi
  api_put "/repos/$OWNER/$REPO/contents/$path" "$json" >/dev/null
  echo "Updated $path"
}

echo "Fixing docker-build.yml branch name..."
TMP_FILE="$(mktemp)" || true
curl -sS -H "Authorization: Bearer $GH_TOKEN" -H "Accept: application/vnd.github+json" \
  "https://api.github.com/repos/$OWNER/$REPO/contents/.github/workflows/docker-build.yml?ref=$PR_BRANCH" \
  | node -e 'let d="";process.stdin.on("data",c=>d+=c).on("end",()=>{try{const j=JSON.parse(d);if(j.content){process.stdout.write(Buffer.from(j.content,"base64").toString("utf8"))}}catch{}})' \
  > "$TMP_FILE" || true

if [[ ! -s "$TMP_FILE" ]]; then
  DEFBR=$(api "/repos/$OWNER/$REPO" | node -e 'let d="";process.stdin.on("data",c=>d+=c).on("end",()=>{try{const j=JSON.parse(d);console.log(j.default_branch||"")}catch{}})')
  curl -sS -H "Authorization: Bearer $GH_TOKEN" -H "Accept: application/vnd.github+json" \
    "https://api.github.com/repos/$OWNER/$REPO/contents/.github/workflows/docker-build.yml?ref=$DEFBR" \
    | node -e 'let d="";process.stdin.on("data",c=>d+=c).on("end",()=>{try{const j=JSON.parse(d);if(j.content){process.stdout.write(Buffer.from(j.content,"base64").toString("utf8"))}}catch{}})' \
    > "$TMP_FILE" || true
fi

if [[ -s "$TMP_FILE" ]]; then
  sed -E 's/production-grade-features/publication-grade-features/g' "$TMP_FILE" > "$TMP_FILE.new"
  put_file ".github/workflows/docker-build.yml" "$(cat "$TMP_FILE.new")" "ci: fix branch name to publication-grade-features"
else
  echo "Warning: could not fetch docker-build.yml; skipping"
fi

echo "Updating ci-notify.yml..."
read -r -d '' CI_NOTIFY <<'YAML'
name: CI Notifications

on:
  workflow_run:
    workflows: ["Build and Push Docker Image"]
    types: [completed]

jobs:
  notify:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      issues: write
    steps:
      - name: Prepare message
        id: prep
        run: |
          echo "STATUS=${{ github.event.workflow_run.conclusion }}" >> $GITHUB_OUTPUT
          echo "URL=${{ github.event.workflow_run.html_url }}" >> $GITHUB_OUTPUT
          echo "BRANCH=${{ github.event.workflow_run.head_branch }}" >> $GITHUB_OUTPUT
          echo "SHA=${{ github.event.workflow_run.head_sha }}" >> $GITHUB_OUTPUT

      - name: Ensure jq is available
        run: |
          if ! command -v jq >/dev/null 2>&1; then
            sudo apt-get update -y
            sudo apt-get install -y jq
          fi

      - name: Slack notify (if webhook configured)
        if: ${{ secrets.SLACK_WEBHOOK_URL != '' }}
        env:
          SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK_URL }}
        run: |
          payload=$(jq -n --arg status "${{ steps.prep.outputs.STATUS }}" \
                          --arg url "${{ steps.prep.outputs.URL }}" \
                          --arg branch "${{ steps.prep.outputs.BRANCH }}" \
                          --arg sha "${{ steps.prep.outputs.SHA }}" \
                          '{text: ("CI (Build and Push Docker Image) finished with status: " + $status + "\nBranch: " + $branch + "\nSHA: " + $sha + "\n" + $url)}')
          curl -s --fail -X POST -H 'Content-type: application/json' --data "$payload" "$SLACK_WEBHOOK_URL"

      - name: Fallback GitHub issue update
        if: ${{ secrets.SLACK_WEBHOOK_URL == '' }}
        env:
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        run: |
          title="CI: Build and Push Docker Image completed (${{ steps.prep.outputs.STATUS }})"
          body="Workflow: ${{ steps.prep.outputs.URL }}\nBranch: ${{ steps.prep.outputs.BRANCH }}\nSHA: ${{ steps.prep.outputs.SHA }}"
          label="ci-notification"
          existing=$(gh issue list --state open --label "$label" --json number -q '.[0].number' || true)
          if [ -z "$existing" ]; then
            gh issue create --title "$title" --body "$body" --label "$label" || true
          else
            gh issue comment "$existing" --body "$body" || true
          fi
YAML
put_file ".github/workflows/ci-notify.yml" "$CI_NOTIFY" "ci: robust notifications (secrets-based, ensure jq)"

echo "Adding MCP smoke test..."
read -r -d '' MCP_SMOKE <<'YAML'
name: MCP Smoke Test
on:
  push:
    branches: [publication-grade-features]
  workflow_dispatch:

jobs:
  smoke:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '18'
      - run: npm ci
      - run: npm run build
      - name: Run MCP inspector (handshake)
        run: npx --yes @modelcontextprotocol/inspector@latest --ci node build/index.js
YAML
put_file ".github/workflows/mcp-smoke.yml" "$MCP_SMOKE" "ci: add MCP handshake smoke test"

echo "All done. CI will run on publication-grade-features. Revoke the token after running."

