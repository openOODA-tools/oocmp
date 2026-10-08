Name:           oocmp
Version:        0.2.0
Release:        1%{?dist}
Summary:        Instant byte-by-byte file comparison reporting first byte difference and line count.
License:        ASL 2.0
URL:            https://github.com/openOODA-tools/oocmp
Source0:        oocmp-linux-x86_64
Source1:        uninstall.sh
BuildArch:      x86_64
Requires:       glibc

%description
oocmp is a sovereign, capability-bounded byte comparator written in
pure openOODA, featuring zero ambient authority, octal/decimal byte
difference reporting, and an MCP stdio server.

%install
mkdir -p %{buildroot}/usr/bin
install -m 0755 %{SOURCE0} %{buildroot}/usr/bin/oocmp
install -m 0755 %{SOURCE1} %{buildroot}/usr/bin/oocmp-uninstall

%files
/usr/bin/oocmp
/usr/bin/oocmp-uninstall

%changelog
* Thu Oct 08 2026 openOODA-tools <ops@openooda.org> - 0.2.0-1
- Elevation to pure openOODA v0.2.0 with POSIX cmp muscle and MCP server
