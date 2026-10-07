Name:           oocmp
Version:        0.1.0
Release:        1%{?dist}
Summary:        Instant byte-by-byte file comparison reporting first byte difference and line count.
License:        ASL 2.0
URL:            https://github.com/openOODA-tools/oocmp
Source0:        oocmp-linux-x86_64
Source1:        uninstall.sh
BuildArch:      x86_64
Requires:       glibc

%description
oocmp is a sovereign, capability-bounded BYTE COMPARATOR written
in pure openOODA, featuring zero ambient authority, oote color themes,
and an MCP stdio server.

%install
mkdir -p %{buildroot}/usr/bin
install -m 0755 %{SOURCE0} %{buildroot}/usr/bin/oocmp
install -m 0755 %{SOURCE1} %{buildroot}/usr/bin/oocmp-uninstall

%files
/usr/bin/oocmp
/usr/bin/oocmp-uninstall

%changelog
* Wed Oct 07 2026 openOODA-tools <ops@openooda.org> - 0.1.0-1
- Initial sovereign blueprint scaffolding
