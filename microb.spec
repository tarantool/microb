Summary: tarantool benchmarking service
Name: microb-module
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
sed -i "s#APP_DIR = .*#APP_DIR = '%{luadir}'#" try/init.lua
install -m 644 try/init.lua %{buildroot}%{luadir}

install -d %{buildroot}%{_sysconfdir}/cron.d
echo -e '0 4 * * * root %{containersh} cron'> %{buildroot}%{_sysconfdir}/cron.d/%{name}

install -d %{buildroot}%{_sysconfdir}/sudoers.d
echo -e '%tarantool ALL = NOPASSWD: %{containersh} start, \\\n\t\t%{containersh} stop *'> %{buildroot}%{_sysconfdir}/sudoers.d/%{name}
chmod 440 %{buildroot}%{_sysconfdir}/sudoers.d/%{name}

install -d %{buildroot}%{luadir}/container
install -m 644 try/container/CentOS-Tarantool.repo %{buildroot}%{luadir}/container/
install -m 644 try/container/Dockerfile %{buildroot}%{luadir}/container/
install -m 755 try/container/container.lua %{buildroot}%{luadir}/container/
install -m 755 try/container/container.sh %{buildroot}%{luadir}/container/

install -d %{buildroot}%{luadir}/templates
install -m 644 try/templates/index.html  %{buildroot}%{luadir}/templates/index.html

install -d %{buildroot}%{luadir}/public

install -d %{buildroot}%{luadir}/public/js
install -m 644 try/public/js/jquery-1.7.1.min.js  %{buildroot}%{luadir}/public/js/
install -m 644 try/public/js/jquery.mousewheel-min.js %{buildroot}%{luadir}/public/js/
install -m 644 try/public/js/jquery.terminal-min.js  %{buildroot}%{luadir}/public/js/

install -d %{buildroot}%{luadir}/public/css
install -m 644 try/public/css/jquery.terminal.css  %{buildroot}%{luadir}/public/css/

install -d %{buildroot}%{_sysconfdir}/tarantool/instances.available/
install -m 644 start.lua %{buildroot}%{_sysconfdir}/tarantool/instances.available/try.lua

%files
%defattr(-,root,root,-)
%doc README.md
%{_sysconfdir}/cron.d/%{name}
%{_sysconfdir}/sudoers.d/%{name}
%{_sysconfdir}/tarantool/instances.available/try.lua
%{luadir}/*
