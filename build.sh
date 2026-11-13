#!/usr/bin/env bash
# Build a launcher at bin/tcl-ini (Tcl is interpreted; no compilation needed).
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p bin
cat > bin/tcl-ini <<'WRAP'
#!/usr/bin/env bash
DIR="$(cd "$(dirname "$0")/.." && pwd)"
exec tclsh "$DIR/src/main.tcl" "$@"
WRAP
chmod +x bin/tcl-ini
echo "built bin/tcl-ini"