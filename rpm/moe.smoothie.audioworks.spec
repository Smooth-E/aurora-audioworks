Name:       moe.smoothie.audioworks

# >> macros
%define _binary_payload w2.xzdio
%define __provides_exclude_from ^%{_datadir}/%{name}/lib/.*\\.so\\>
%define __requires_exclude_from ^%{_datadir}/%{name}/lib/.*\\.so\\>
# << macros

Summary:    Audiocut
Version:    1.5.2
Release:    1
Group:      Qt/Qt
License:    GPLv3
URL:        https://github.com/poetaster/harbour-audiocut
Source0:    %{name}-%{version}.tar.bz2
Requires:   sailfishsilica-qt5 >= 0.10.9
Requires:   pyotherside-qml-plugin-python3-qt5

BuildRequires:  qt5-qttools-linguist
BuildRequires:  pkgconfig(auroraapp)
BuildRequires:  pkgconfig(Qt5Core)
BuildRequires:  pkgconfig(Qt5Qml)
BuildRequires:  pkgconfig(Qt5Quick)
BuildRequires:  desktop-file-utils

# Requires: lame

%description
Audioworks is a small audio workbench. Trim/Splice, add echo! WIP.

%prep
%setup -q -n %{name}-%{version}

%build
%cmake -GNinja
%ninja_build

%install
%ninja_install

%files
%defattr(-,root,root,-)
%{_bindir}/%{name}
%defattr(0644,root,root,-)
%{_datadir}/%{name}
%{_datadir}/applications/%{name}.desktop
%{_datadir}/icons/hicolor/*/apps/%{name}.png
%attr(644,root,root) %{_datadir}/%{name}/qml/py/audiox.py
