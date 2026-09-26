#!/usr/bin/env bash
# Run inside parent folder: bash scan-local.sh REPO_FOLDER
# Example: bash scan-local.sh deenai-fe

REPO_DIR="${1:-.}"
cd "$REPO_DIR" || { echo "Cannot enter $REPO_DIR"; exit 1; }

echo "Scanning: $(pwd)"
echo "----------------------------------------"

FOUND=false

# ── 1. TEXT PATTERN SCAN ─────────────────────
PATTERNS=(
  "global\['\!'\]"
  "_\\\$_1e42"
  "sfL\[EKc\]"
  "8-3182"
  "8-2503-2"
  "temp_auto_push"
  "temp_interactive_push"
  "branch_structure\.json"
  "node \./public/fonts/"
  "fa-solid-400\.woff2"
  "eval.atob."
  "eval.proxyInfo."
  "PolinRider"
  "@tanstack/setup"
  "var _\\\$_"
  "String\.fromCharCode.*split.*join.*return"
)

for pattern in "${PATTERNS[@]}"; do
  results=$(grep -rE "$pattern" . \
    --include="*.js" \
    --include="*.mjs" \
    --include="*.cjs" \
    --include="*.ts" \
    --include="*.tsx" \
    --include="*.json" \
    --include="*.yml" \
    --include="*.yaml" \
    --exclude-dir=node_modules \
    --exclude-dir=.git \
    --exclude-dir=vendor \
    --exclude-dir=public \
    -l 2>/dev/null \
    | grep -v "^\./.github/")

  if [[ -n "$results" ]]; then
    FOUND=true
    echo "[HIT] Pattern: $pattern"
    echo "$results" | sed 's/^/      /'
    echo ""
  fi
done


# ── 2. BOTTOM-INJECTION CHECK ─────────────────
for configfile in \
  "postcss.config.mjs" \
  "postcss.config.js" \
  "tailwind.config.js" \
  "tailwind.config.ts" \
  "next.config.mjs" \
  "next.config.ts"; do
  if [[ -f "$configfile" ]]; then
    if tail -20 "$configfile" | grep -qE "global\[|_\\\$_|sfL|8-3182|eval.atob"; then
      FOUND=true
      echo "[HIT] Bottom injection detected in: $configfile"
      echo ""
    else
      echo "[OK]  $configfile"
    fi
  fi
done


# ── 3. FONT FILE CHECK ────────────────────────
FONT_HITS=$(find . \
  -not -path "*/node_modules/*" \
  -not -path "*/.git/*" \
  -not -path "*/vendor/*" \
  -not -path "*/public/vendor/*" \
  -not -path "*/.github/*" \
  -type f \( \
    -name "fa-solid-400.woff2" \
    -o -name "fa-solid-900.woff2" \
    -o -name "fa-solid-900.eot" \
    -o -name "fa-solid-900.ttf" \
    -o -name "fa-brands-400.woff2" \
    -o -name "fa-brands-400.ttf" \
    -o -name "fa-regular-400.woff2" \
    -o -name "fa-regular-400.ttf" \
  \) 2>/dev/null)

if [[ -n "$FONT_HITS" ]]; then
  FOUND=true
  echo "[HIT] Suspicious font files found:"
  echo "$FONT_HITS" | sed 's/^/      /'
  echo ""
fi


# ── 4. VSCODE TASKS CHECK ─────────────────────
if [[ -f ".vscode/tasks.json" ]]; then
  if grep -qE "node \./public/fonts/|fa-solid" ".vscode/tasks.json" 2>/dev/null; then
    FOUND=true
    echo "[HIT] Malicious .vscode/tasks.json detected"
    echo ""
  else
    echo "[OK]  .vscode/tasks.json"
  fi
fi


# ── 5. GITIGNORE CHECK ────────────────────────
if [[ -f ".gitignore" ]]; then
  if grep -qE "branch_structure\.json|temp_auto_push\.bat|temp_interactive_push\.bat" ".gitignore" 2>/dev/null; then
    FOUND=true
    echo "[HIT] Malicious entries in .gitignore"
    echo ""
  fi
fi


# ── RESULT ────────────────────────────────────
echo "----------------------------------------"
if $FOUND; then
  echo "STATUS: !! INFECTED — do not push to new org !!"
else
  echo "STATUS: CLEAN — safe to migrate"
fi
echo ""