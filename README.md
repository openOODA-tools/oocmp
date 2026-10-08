# oocmp: Sovereign BYTE COMPARATOR

<div align="center">

```
================================================================================
                                oocmp
               Sovereign openOODA BYTE COMPARATOR
================================================================================
```

**Sovereign BYTE COMPARATOR**  
*Instant byte-by-byte file comparison reporting first byte difference, line count, and octal diffs.*  
*Two Faces, One Engine:* Modern terminal ergonomics for humans • Zero-leakage MCP for AI agents  
Written in 100% pure [openOODA](https://github.com/openOODA).

[![License: Apache-2.0](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![openOODA](https://img.shields.io/badge/openOODA-1.0-emerald.svg)](https://openooda.org)
[![Version: 0.2.0](https://img.shields.io/badge/version-0.2.0-blue.svg)](https://github.com/openOODA-tools/oocmp/releases/tag/v0.2.0)
[![Architecture: x86_64 | aarch64](https://img.shields.io/badge/Arch-x86__64%20%7C%20aarch64-lightgrey.svg)]()

</div>

---

## 1. Quick Install

### Automated Installer (Linux x86_64 & aarch64)
```bash
curl -fsSL https://openooda-tools.github.io/oocmp/install.sh | bash
```

### Native Package Managers
```bash
# Arch Linux (AUR / PKGBUILD)
yay -S oocmp-bin
# Or manual PKGBUILD:
cd packaging/arch && makepkg -si

# Debian / Ubuntu (.deb)
curl -fsSL https://openooda-tools.github.io/oocmp/install.sh | bash -s -- --deb

# Fedora / RHEL (.rpm)
curl -fsSL https://openooda-tools.github.io/oocmp/install.sh | bash -s -- --rpm
```

### Uninstallation
```bash
oocmp-uninstall
# or: curl -fsSL https://openooda-tools.github.io/oocmp/uninstall.sh | bash
```

---

## 2. CLI Usage

```
usage: oocmp [OPTION]... FILE1 [FILE2 [SKIP1 [SKIP2]]]

Compare two files byte by byte.

Options:
  -b, --print-bytes          print differing bytes
  -i, --ignore-initial=SKIP  skip first SKIP bytes of both inputs
  -i, --ignore-initial=SKIP1:SKIP2  skip first SKIP1 bytes of FILE1 and SKIP2 bytes of FILE2
  -l, --verbose              output byte numbers and differing byte values (octal)
  -n, --bytes=LIMIT          compare at most LIMIT bytes
  -s, --quiet, --silent      suppress all normal output
      --demo                 run demonstration comparison scenarios
      --json                 output formatted as JSON telemetry
  -h, --help                 display this help and exit
  -v, -V, --version          output version information and exit
      --mcp                  run as Model Context Protocol stdio server
```

### Exit Status
- `0`: Inputs are byte-for-byte identical.
- `1`: Differences were encountered (or EOF reached on one input before the other).
- `2`: Trouble encountered (file missing, permission denied, or invalid arguments).

---

## 3. Model Context Protocol (MCP)

When invoked with `--mcp`, `oocmp` runs a JSON-RPC 2.0 stdio server exposing five sovereign comparison tools for autonomous agents:

| Tool Name | Parameters | Description |
|-----------|------------|-------------|
| `cmp_compare` | `path1`, `path2`, `content1`, `content2`, `skip1`, `skip2`, `limit`, `print_bytes`, `verbose` | Full comparison returning POSIX or verbose differential reports. |
| `cmp_diff_list` | `path1`, `path2`, `content1`, `content2`, `max_diffs`, `print_bytes` | Collects structured byte divergence records with octal and char representations. |
| `cmp_are_identical` | `path1`, `path2`, `content1`, `content2` | Fast boolean equivalence check returning identical status and compared byte count. |
| `cmp_similarity` | `path1`, `path2`, `content1`, `content2` | Calculates similarity percentage and mismatch metrics across compared buffers. |
| `cmp_audit` | `path1`, `path2`, `content1`, `content2` | Comprehensive audit report combining POSIX diagnostics and JSON telemetry. |

```bash
printf '{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"cmp_are_identical","arguments":{"content1":"foo","content2":"foo"}}}\n' | oocmp --mcp
```

---

## 4. Security & Zero Ambient Authority

* **Pure Capability Bounded:** Operates strictly with explicit tokens (`&FsReadCap`, `&ProcessCap`, `&EnvCap`). Physical absence of ambient filesystem or network leakage.
* **Negative-Trust Architecture:** Strict input bounds checking, bounded memory footprints, and zero dynamic interpreter evaluation.
* **Hermetic Native Binary:** Compiled natively via `oodac` into a standalone, zero-dependency ELF executable.

---

## 5. License

Apache License, Version 2.0. See [LICENSE](LICENSE) for details.
