Summary: tarantool benchmarking service
Name: tarantool-microb-module
Version: 1.0
Release: 1
License: BSD
BuildArch: noarch
Group: Development/Tools
Requires: tarantool >= 1.6.3
Source0: tarantool-microb-module.tar.gz

%global debug_package %{nil}

%define luadir %{_datadir}/tarantool/microb

%description
Microb is system for running, store and display tarantool
benchmark results

######################################################
%prep

%setup -q -n %{name}

%build

%install

install -d %{buildroot}%{luadir}
sed -i "s#APP_DIR = .*#APP_DIR = '%{luadir}'#" microb/web.lua
install -m 644 microb/web.lua %{buildroot}%{luadir}
install -m 644 microb/storage.lua %{buildroot}%{luadir}
install -m 644 microb/runner.lua %{buildroot}%{luadir}
install -m 644 microb/cfg.lua %{buildroot}%{luadir}
install -m 644 microb/time.lua %{buildroot}%{luadir}

install -d %{buildroot}%{luadir}/benchmarks
install -m 644 microb/benchmarks/benchmarks.lua %{buildroot}%{luadir}/benchmarks

install -d %{buildroot}%{luadir}/templates
install -m 644 microb/templates/index.html  %{buildroot}%{luadir}/templates/index.html

install -d %{buildroot}%{_sysconfdir}/tarantool/instances.available/
install -m 644 start_web.lua %{buildroot}%{_sysconfdir}/tarantool/instances.available/microb_web.lua
install -m 644 start_storage.lua %{buildroot}%{_sysconfdir}/tarantool/instances.available/microb_storage.lua

install -d %{buildroot}%{_bindir}
install -m 644 start_runner.lua %{buildroot}%{_bindir}/microb_run.lua

%files
%defattr(-,root,root,-)
%doc README.md
%{_sysconfdir}/tarantool/instances.available/microb_storage.lua
%{_sysconfdir}/tarantool/instances.available/microb_web.lua
%{_bindir}/microb_run.lua
%{luadir}/*
