#!/usr/bin/env bash
# Self-contained test suite for tcl-ini. Requires only tclsh.
set -uo pipefail
cd "$(dirname "$0")"
TCL="${TCLSH:-tclsh}"
command -v "$TCL" >/dev/null 2>&1 || { echo "FAIL: tclsh not found"; exit 1; }
./build.sh >/dev/null
INI="./bin/tcl-ini"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
pass=0; fail=0
ok(){ pass=$((pass+1)); }
bad(){ fail=$((fail+1)); echo "FAIL: $1"; }
# assert that a command's exit code and stdout match expectations
check(){ # name expected_exit expected_substring actual_exit actual_out
  local name="$1" want_rc="$2" want="$3" rc="$4" out="$5"
  if [ "$rc" != "$want_rc" ]; then bad "$name (exit $rc, want $want_rc)"; return; fi
  if [ -n "$want" ] && ! printf '%s' "$out" | grep -qF -- "$want"; then
    bad "$name (output missing '$want')"; return
  fi
  ok
}

cat > "$TMP/clean.ini" <<'EOF'
# a clean file
[server]
host = localhost
port = 8080
[db]
user: admin
EOF
out=$($INI validate "$TMP/clean.ini"); rc=$?
check "clean validates" 0 "0 error(s), 0 warning(s)" "$rc" "$out"

cat > "$TMP/dup.ini" <<'EOF'
[server]
port = 1
port = 2
EOF
out=$($INI validate "$TMP/dup.ini"); rc=$?
check "duplicate key flagged" 1 'duplicate key "port"' "$rc" "$out"

cat > "$TMP/orphan.ini" <<'EOF'
lonely = 1
[server]
port = 2
EOF
out=$($INI validate "$TMP/orphan.ini"); rc=$?
check "key before section flagged" 1 "before any section" "$rc" "$out"

cat > "$TMP/bad.ini" <<'EOF'
[server]
this line has no separator
EOF
out=$($INI validate "$TMP/bad.ini"); rc=$?
check "malformed line flagged" 1 "malformed line" "$rc" "$out"

cat > "$TMP/dupsec.ini" <<'EOF'
[a]
x = 1
[a]
y = 2
EOF
out=$($INI validate "$TMP/dupsec.ini"); rc=$?
check "duplicate section warns" 0 "duplicate section [a]" "$rc" "$out"

out=$($INI get "$TMP/clean.ini" server port); rc=$?
check "get value" 0 "8080" "$rc" "$out"

out=$($INI get "$TMP/clean.ini" db user); rc=$?
check "get colon value" 0 "admin" "$rc" "$out"

out=$($INI get "$TMP/clean.ini" server nope 2>/dev/null); rc=$?
check "get missing exits 1" 1 "" "$rc" "$out"

out=$($INI sections "$TMP/clean.ini"); rc=$?
check "sections lists" 0 "server" "$rc" "$out"
printf '%s' "$out" | grep -qF "db" && ok || bad "sections includes db"

out=$($INI keys "$TMP/clean.ini" server); rc=$?
check "keys lists" 0 "host" "$rc" "$out"

echo "----------------------------------------"
echo "tcl-ini: $pass passed, $fail failed"
[ "$fail" -eq 0 ] && echo "ALL CHECKS PASSED" || exit 1