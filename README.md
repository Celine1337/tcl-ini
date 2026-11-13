<p align="center">
  <img src="assets/banner.svg" width="830" alt="tcl-ini banner">
</p>
<p align="center">
  <a href="https://github.com/Celine1337/tcl-ini/releases"><img src="assets/nav-releases.svg" alt="Releases"></a>
  <a href="https://en.wikipedia.org/wiki/INI_file"><img src="assets/nav-spec.svg" alt="INI format"></a>
  <a href="LICENSE"><img src="assets/nav-mit.svg" alt="MIT"></a>
</p>

<img src="assets/section-about.svg" width="830" alt="About">

**tcl-ini** lints and queries **INI files** from the shell, with nothing but a stock `tclsh`. It parses sections, `key = value` / `key: value` assignments and `#`/`;` comments, then reports the structural mistakes that silently corrupt config: duplicate keys, keys stranded before any section, duplicate sections, unterminated headers and malformed lines — each with a line number. It also works as a tiny config reader: `get`, `sections` and `keys` let shell scripts pull values out of an INI without `grep`/`sed` guesswork.

Why Tcl? Because it is already on virtually every Unix, starts in milliseconds, and has real data structures (`dict`) — so a single self-contained script is a legitimate config tool, not a toy. No runtime to install, no package manager, no build.

<img src="assets/section-features.svg" width="830" alt="Features">

- **Structural linting** — duplicate keys, orphan keys, duplicate sections, empty names, unterminated `[section]` headers and lines with no separator, all reported with line numbers.
- **Errors vs warnings** — hard problems exit `1`; a repeated section is a warning (values merge), so CI can gate on real breakage only.
- **Both separators** — `=` and `:` are accepted, matching the loose INI dialects found in the wild.
- **Scriptable reads** — `get`, `sections`, `keys` print plain values/names, one per line, for easy consumption in shell pipelines.
- **Zero dependencies** — one Tcl file; runs on any system with `tclsh` 8.6+.
- **Tested** — a self-contained `test.sh` builds fixtures and asserts exit codes and output.

<img src="assets/section-stack.svg" width="830" alt="Tech stack">

<img src="assets/section-install.svg" width="830" alt="Install">

Requires `tclsh` (Tcl 8.6+), present by default on most Unix systems.

```bash
git clone https://github.com/Celine1337/tcl-ini.git
cd tcl-ini
./build.sh          # writes a launcher at bin/tcl-ini
./bin/tcl-ini validate app.ini
```

Or run the source directly, no build at all:

```bash
tclsh src/main.tcl validate app.ini
```

<img src="assets/section-usage.svg" width="830" alt="Usage">

```bash
tcl-ini validate app.ini              # lint; exit 1 on errors
tcl-ini get app.ini server port       # print a value
tcl-ini sections app.ini              # list section names
tcl-ini keys app.ini server           # list keys in a section
```

```text
$ tcl-ini validate broken.ini
ERROR line 3: duplicate key "port" in section [server]
ERROR line 7: key "lonely" appears before any section
WARN  line 9: duplicate section [db] (later values merge)
2 error(s), 1 warning(s)
```

Exit codes: `0` clean (or successful read), `1` lint errors / missing key, `2` bad usage or unreadable file.

<img src="assets/section-license.svg" width="830" alt="License">

MIT — see [LICENSE](LICENSE).