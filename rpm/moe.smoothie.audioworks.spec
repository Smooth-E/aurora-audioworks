Name:       moe.smoothie.audioworks

# >> macros
%define _binary_payload w2.xzdio
%define __requires_exclude (libpython3*|libpyside2*|libcrypt.*|libffi.*|python3dist|lib.*)
%define __provides_exclude_from ^%{_datadir}/.*$
# << macros

Summary:    Audiocut
Version:    1.5.2.2
Release:    1
Group:      Qt/Qt
License:    GPLv3
URL:        https://github.com/poetaster/harbour-audiocut
Source0:    %{name}-%{version}.tar.bz2
Requires:   sailfishsilica-qt5 >= 0.10.9

BuildRequires:  qt5-qttools-linguist
BuildRequires:  pkgconfig(auroraapp) >= 1.0.2
BuildRequires:  pkgconfig(Qt5Core)
BuildRequires:  pkgconfig(Qt5Qml)
BuildRequires:  pkgconfig(Qt5Quick)
BuildRequires:  desktop-file-utils

%description
Audioworks is a small audio workbench. Trim/Splice, add echo! WIP.

%prep
%setup -q -n %{name}-%{version}

%build
%qmake5 
make %{?_smp_mflags}

%install
rm -rf %{buildroot}
%qmake5_install

desktop-file-install --delete-original       \
  --dir %{buildroot}%{_datadir}/applications             \
   %{buildroot}%{_datadir}/applications/*.desktop

%files
%defattr(-,root,root,-)
%{_bindir}/%{name}
%{_libexecdir}/%{name}
%defattr(644,root,root,-)
%{_datadir}/%{name}
%{_datadir}/applications/%{name}.desktop
%{_datadir}/icons/hicolor/*/apps/%{name}.png
