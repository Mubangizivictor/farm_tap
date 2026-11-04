#!/usr/bin/env bash
# FarmTap: switch on everything that needs the Blaze plan (decision 0024).
#
# Run ONCE, from the repo folder on your computer, after upgrading the
# Firebase project to Blaze (Firebase console > Upgrade):
#
#   bash tool/activate-blaze.sh
#
# It builds the website, installs and tests the server code, deploys the
# website, rules, indexes, file storage rules and server functions, then
# switches the server jobs on. Safe to run again. API keys are NOT needed
# here: paste them later in the control panel (Admin > APIs and keys); each
# job waits for its key.
set -euo pipefail

PROJECT="${FARMTAP_PROJECT:-farm-tap-1dd15}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

step() { printf '\n\033[1;32m==> %s\033[0m\n' "$1"; }
need() { command -v "$1" >/dev/null 2>&1 || { echo "Missing $1. $2"; exit 1; }; }

need node "Install Node.js 22 from https://nodejs.org"
need npm "Install Node.js 22 from https://nodejs.org"
FIREBASE="firebase"
command -v firebase >/dev/null 2>&1 || FIREBASE="npx --yes firebase-tools@latest"

step "Checking you are signed in to Firebase"
$FIREBASE projects:list >/dev/null 2>&1 || $FIREBASE login

step "Building the website"
(cd webapp && npm ci && npm run build)

step "Installing and testing the server code"
(cd functions && npm ci && npm test)

step "Deploying website, rules, indexes, file storage and server functions"
$FIREBASE deploy --project "$PROJECT" --only hosting,firestore:rules,firestore:indexes,storage,functions --force

step "Switching the server jobs on"
if command -v gcloud >/dev/null 2>&1; then
  gcloud auth application-default print-access-token >/dev/null 2>&1 || gcloud auth application-default login
  (cd functions && FARMTAP_PROJECT="$PROJECT" node scripts/activate.mjs)
else
  echo "Google Cloud CLI (gcloud) is not installed, so the switches were not changed."
  echo "Switch them on in the control panel instead: Admin > Integrations > Server jobs > turn all on > Save."
fi

cat <<'DONE'

Done. FarmTap's server jobs are live:
  - Mobile Money / card payments (after keys in Admin > APIs and keys and a gateway turned on in Admin > Payments)
  - Reminder notifications, SMS and WhatsApp (SMS/WhatsApp wait for their keys)
  - Receipt and invoice PDFs stored on the server
  - Refunds paid through the provider (waits for the refund keys)
  - Closed accounts erased after 90 days
  - Photos and documents stored in file storage
Check: Admin > Integrations shows every server job ON.
DONE
