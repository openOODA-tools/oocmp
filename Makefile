# oocmp v0.2.0 Makefile

OODA_COMPILER ?= $(firstword $(wildcard $(HOME)/.openooda/bin/oodac $(CURDIR)/../../openOODA/oodac/bin/oodac))
OODACODEX ?= $(HOME)/.openooda/northstar.oot
OO_LIST_AMBIENT_QUOTA ?= 8589934592
BIN := dist/oocmp

PREFIX ?= /usr/local
BINDIR ?= $(PREFIX)/bin

SRC := $(wildcard *.oo) $(wildcard */*.oo)
VERSION ?= $(shell cat VERSION 2>/dev/null || echo 0.2.0)

.PHONY: build check line-cap file-law academy density verify clean test package package-deb package-rpm package-arch install uninstall parity

build: $(BIN)

$(BIN): $(SRC)
	@mkdir -p dist .ooda-cache/ooda-tmp
	OO_LIST_AMBIENT_QUOTA=$(OO_LIST_AMBIENT_QUOTA) OODACODEX=$(OODACODEX) OODA_COMPILER=$(OODA_COMPILER) OODA_NO_JAIL=1 $(OODA_COMPILER) build main.oo -o $(BIN)
	@chmod +x $(BIN)
	@cp -a $(BIN) dist/oocmp-linux-x86_64
	@sha256sum dist/oocmp-linux-x86_64 > dist/oocmp-linux-x86_64.sha256
	@echo "built $(BIN) (and dist/oocmp-linux-x86_64)"

# --- Verification gate ---------------------------------------------------------

line-cap:
	@violations=0; \
	for f in $$(find . -name "*.oo" -o -name "*.oot" | grep -v "/dist/" | grep -v "/.ooda-cache/"); do \
		n=$$(wc -l < "$$f"); \
		if [ $$n -gt 256 ]; then \
			echo "VIOLATION: $$f = $$n lines (exceeds 256)"; violations=$$((violations+1)); \
		fi; \
		code=$$(grep -vE '^[[:space:]]*(//.*)?$$' "$$f" | grep -cvE '^[[:space:]]*import[[:space:]]+"'); \
		if [ "$$code" = "0" ]; then continue; fi; \
		if [ $$n -lt 16 ]; then \
			echo "VIOLATION: $$f = $$n lines (under 16-line floor, not a shim)"; violations=$$((violations+1)); \
		fi; \
	done; \
	if [ $$violations -gt 0 ]; then echo "FAIL: $$violations files violate the Page Rule"; exit 1; fi; \
	echo "PASS: Page Rule sizing (16-256 lines, shims exempt from floor) holds"

file-law:
	@forbidden="js ts rb pl json yaml toml"; \
	violations=0; \
	for ext in $$forbidden; do \
		found=$$(find . -name "*.$$ext" -not -path "./.git/*" -not -path "./.github/*" -not -path "./dist/*" -not -path "./.ooda-cache/*" 2>/dev/null | head -3); \
		if [ -n "$$found" ]; then \
			echo "VIOLATION: .$$ext forbidden:"; echo "$$found"; violations=$$((violations+1)); \
		fi; \
	done; \
	for f in $$(find . -name "*.md" -not -path "./.git/*" -not -path "./.github/*" -not -path "./dist/*" -not -path "./.ooda-cache/*" 2>/dev/null); do \
		if [ "$$f" != "./README.md" ] && [ "$$f" != "./AGENTS.md" ]; then \
			echo "VIOLATION: .md forbidden outside README.md and AGENTS.md: $$f"; violations=$$((violations+1)); \
		fi; \
	done; \
	for f in $$(find . -name "*.sh" -not -path "./.git/*" -not -path "./dist/*" 2>/dev/null); do \
		if [ "$$f" != "./install.sh" ] && [ "$$f" != "./uninstall.sh" ]; then \
			echo "VIOLATION: .sh forbidden outside install.sh and uninstall.sh: $$f"; violations=$$((violations+1)); \
		fi; \
	done; \
	if [ $$violations -gt 0 ]; then echo "FAIL: file-law violations"; exit 1; fi; \
	echo "PASS: file law holds"

academy:
	@failures=0; \
	for f in $$(find . -name "*.oo" -not -path "./dist/*"); do \
		header=$$(head -7 "$$f"); \
		missing=""; \
		echo "$$header" | grep -q "^// # "        || missing="$$missing title"; \
		echo "$$header" | grep -q "^// Logline:"  || missing="$$missing logline"; \
		echo "$$header" | grep -q "^// Setup:"    || missing="$$missing setup"; \
		echo "$$header" | grep -q "^// Beats:"    || missing="$$missing beats"; \
		if [ -n "$$missing" ]; then \
			echo "FAIL: $$f missing Academy element(s):$$missing"; failures=$$((failures+1)); \
		fi; \
	done; \
	if [ $$failures -gt 0 ]; then echo "FAIL: $$failures academy header violations"; exit 1; fi; \
	echo "PASS: academy headers hold (all 4 elements present in first 7 lines)"

density:
	@violations=0; \
	for d in $$(find . -type d -not -path "./.git*" -not -path "./dist*" -not -path "./.ooda-cache*" -not -path "./packaging*" -not -path "./qa*"); do \
		n=$$(ls "$$d"/*.oo "$$d"/*.oot 2>/dev/null | grep -v '\*' | wc -l); \
		if [ $$n -gt 8 ]; then \
			echo "VIOLATION: $$d holds $$n pages (exceeds 8)"; violations=$$((violations+1)); \
		fi; \
	done; \
	if [ $$violations -gt 0 ]; then echo "FAIL: $$violations directories exceed the density bound"; exit 1; fi; \
	echo "PASS: directory density (<= 8 pages per directory) holds"

check:
	@for f in $$(find . -name "*.oo" -not -path "./dist/*"); do \
		OO_LIST_AMBIENT_QUOTA=$(OO_LIST_AMBIENT_QUOTA) OODACODEX=$(OODACODEX) OODA_COMPILER=$(OODA_COMPILER) OODA_NO_JAIL=1 $(OODA_COMPILER) check "$$f" > /dev/null || exit 1; \
	done; \
	echo "PASS: oodac check holds on all .oo files"

verify: line-cap file-law academy density check

parity: $(BIN)
	@mkdir -p .ooda-cache .ooda-cache/parity
	$(OODA_COMPILER) build qa/parity/run.oo -o .ooda-cache/parity-run
	@chmod +x .ooda-cache/parity-run
	@.ooda-cache/parity-run

test: $(BIN) parity
	@echo "=== testing --help ==="
	@./$(BIN) --help > /dev/null && echo "PASS: --help"
	@echo "=== testing --version ==="
	@./$(BIN) --version | grep -q "0.2.0" && echo "PASS: --version"
	@echo "=== testing demo mode ==="
	@./$(BIN) --demo | grep -q "differ: byte 7, line 1" && echo "PASS: demo mode"
	@echo "=== testing demo json output ==="
	@./$(BIN) --demo --json | grep -q '"tool":"oocmp"' && echo "PASS: demo json output"
	@echo "=== testing file comparison: identical ==="
	@printf "apple banana\n" > .test_a.txt && printf "apple banana\n" > .test_b.txt; \
	./$(BIN) .test_a.txt .test_b.txt && echo "PASS: identical files exit 0"; \
	rm -f .test_a.txt .test_b.txt
	@echo "=== testing file comparison: difference ==="
	@printf "apple banana\n" > .test_a.txt && printf "apple orange\n" > .test_b.txt; \
	./$(BIN) .test_a.txt .test_b.txt > .test_out.txt || code=$$?; \
	test "$$code" = "1" && grep -q "differ: byte 7, line 1" .test_out.txt && echo "PASS: differing files exit 1"; \
	rm -f .test_a.txt .test_b.txt .test_out.txt
	@echo "=== testing file comparison: verbose print-bytes ==="
	@printf "abc" > .test_a.txt && printf "axc" > .test_b.txt; \
	./$(BIN) -l -b .test_a.txt .test_b.txt > .test_out.txt || true; \
	grep -q "2 142 b 170 x" .test_out.txt && echo "PASS: verbose print-bytes octal and char format"; \
	rm -f .test_a.txt .test_b.txt .test_out.txt
	@echo "=== testing file comparison: skip and limit ==="
	@printf "12345hello" > .test_a.txt && printf "99999hello" > .test_b.txt; \
	./$(BIN) -i 5:5 -n 5 .test_a.txt .test_b.txt && echo "PASS: skip and limit match"; \
	rm -f .test_a.txt .test_b.txt
	@echo "=== testing file comparison: missing file error exit ==="
	@./$(BIN) .nonexistent_1.txt .nonexistent_2.txt > /dev/null 2>&1 || code=$$?; \
	test "$$code" = "2" && echo "PASS: error exits with code 2"
	@echo "=== testing MCP initialize ==="
	@printf '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{}}\n' | ./$(BIN) --mcp | grep -q "protocolVersion" && echo "PASS: MCP initialize"
	@echo "=== testing MCP tools/list ==="
	@printf '{"jsonrpc":"2.0","id":2,"method":"tools/list","params":{}}\n' | ./$(BIN) --mcp | grep -q "cmp_compare" && echo "PASS: MCP tools/list"
	@echo "=== testing MCP tools/call cmp_are_identical ==="
	@printf '{"jsonrpc":"2.0","id":3,"method":"tools/call","params":{"name":"cmp_are_identical","arguments":{"content1":"abc","content2":"abc"}}}\n' | ./$(BIN) --mcp | grep -q 'identical' && echo "PASS: MCP cmp_are_identical"
	@echo "=== testing MCP tools/call cmp_similarity ==="
	@printf '{"jsonrpc":"2.0","id":4,"method":"tools/call","params":{"name":"cmp_similarity","arguments":{"content1":"abcdef","content2":"abcxyz"}}}\n' | ./$(BIN) --mcp | grep -q 'similarity_pct' && echo "PASS: MCP cmp_similarity"
	@echo "=== testing MCP tools/call cmp_diff_list ==="
	@printf '{"jsonrpc":"2.0","id":5,"method":"tools/call","params":{"name":"cmp_diff_list","arguments":{"content1":"foo","content2":"bar"}}}\n' | ./$(BIN) --mcp | grep -q '146' && echo "PASS: MCP cmp_diff_list"
	@echo "=== testing MCP tools/call cmp_audit ==="
	@printf '{"jsonrpc":"2.0","id":6,"method":"tools/call","params":{"name":"cmp_audit","arguments":{"content1":"test1","content2":"test2"}}}\n' | ./$(BIN) --mcp | grep -q 'oocmp' && echo "PASS: MCP cmp_audit"
	@echo "ALL TESTS PASSED"

install: $(BIN)
	@mkdir -p $(DESTDIR)$(BINDIR)
	install -m 0755 $(BIN) $(DESTDIR)$(BINDIR)/oocmp
	install -m 0755 uninstall.sh $(DESTDIR)$(BINDIR)/oocmp-uninstall
	@echo "installed oocmp and oocmp-uninstall to $(DESTDIR)$(BINDIR)"

uninstall:
	@rm -f $(DESTDIR)$(BINDIR)/oocmp $(DESTDIR)$(BINDIR)/oocmp-uninstall
	@if [ "$(PURGE)" = "1" ]; then rm -rf $(HOME)/.cache/oocmp $(HOME)/.config/oocmp; echo "purged user cache and config"; fi
	@echo "uninstalled oocmp and oocmp-uninstall from $(DESTDIR)$(BINDIR)"

package-deb: $(BIN)
	@mkdir -p dist/deb-root/DEBIAN dist/deb-root/usr/bin
	@sed "s/^Version:.*/Version: $(VERSION)-1/" packaging/debian/control.binary > dist/deb-root/DEBIAN/control
	@cp $(BIN) dist/deb-root/usr/bin/oocmp
	@chmod 0755 dist/deb-root/usr/bin/oocmp
	@cp uninstall.sh dist/deb-root/usr/bin/oocmp-uninstall
	@chmod 0755 dist/deb-root/usr/bin/oocmp-uninstall
	@dpkg-deb --build --root-owner-group dist/deb-root dist/oocmp_$(VERSION)-1_amd64.deb
	@rm -rf dist/deb-root
	@echo "built dist/oocmp_$(VERSION)-1_amd64.deb"

package-rpm: $(BIN)
	@mkdir -p ~/rpmbuild/SOURCES ~/rpmbuild/SPECS ~/rpmbuild/RPMS
	@cp $(BIN) ~/rpmbuild/SOURCES/oocmp-linux-x86_64
	@cp uninstall.sh ~/rpmbuild/SOURCES/uninstall.sh
	@sed "s/^Version:.*/Version: $(VERSION)/" packaging/oocmp.spec > ~/rpmbuild/SPECS/oocmp.spec
	@rpmbuild -bb ~/rpmbuild/SPECS/oocmp.spec
	@cp ~/rpmbuild/RPMS/x86_64/oocmp-$(VERSION)*.rpm dist/
	@echo "built dist RPM package"

package-arch: $(BIN)
	@mkdir -p dist/arch-pkg/usr/bin
	@cp $(BIN) dist/arch-pkg/usr/bin/oocmp
	@chmod 0755 dist/arch-pkg/usr/bin/oocmp
	@cp uninstall.sh dist/arch-pkg/usr/bin/oocmp-uninstall
	@chmod 0755 dist/arch-pkg/usr/bin/oocmp-uninstall
	@printf "pkgname = oocmp\npkgbase = oocmp\npkgver = $(VERSION)-1\npkgdesc = Sovereign byte-by-byte file comparison with octal diffs and MCP server.\nurl = https://github.com/openOODA-tools/oocmp\nbuilddate = $$(date +%s)\npackager = openOODA-tools <ops@openooda.org>\nsize = $$(stat -c %s $(BIN))\narch = x86_64\nlicense = Apache-2.0\ndepend = glibc\nprovides = oocmp\n" > dist/arch-pkg/.PKGINFO
	@tar --zstd -cf dist/oocmp-$(VERSION)-1-x86_64.pkg.tar.zst -C dist/arch-pkg .PKGINFO usr
	@rm -rf dist/arch-pkg
	@bash -n packaging/arch/PKGBUILD
	@cp packaging/arch/PKGBUILD packaging/PKGBUILD
	@echo "built dist/oocmp-$(VERSION)-1-x86_64.pkg.tar.zst and validated PKGBUILD"

package: package-deb package-rpm package-arch
	@cd dist && sha256sum oocmp* > checksums.txt 2>/dev/null || true
	@echo "built all packages and dist/checksums.txt"

clean:
	@rm -rf dist .ooda-cache
	@echo "cleaned"
