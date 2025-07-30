Name:       moe.smoothie.audioworks

%define _cmake_skip_rpath %{nil}
%define __provides_exclude_from ^%{_datadir}/%{name}/lib/.*$
%define __requires_exclude ^(libavcodec.*|libavdevice.*|libavfilter.*|libavformat.*|libavutil.*|libswresample.*|libswscale.*)$

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
BuildRequires:  conan

# Requires: lame

%description
Audioworks is a small audio workbench. Trim/Splice, add echo! WIP.

%prep
%setup -q -n %{name}-%{version}

%build
# Prepare conan
CONAN_LIB_DIR="%{_builddir}/conan-libs/"
%{set_build_flags}
conan-install-if-modified --source-folder="%{_sourcedir}/.." --output-folder="$CONAN_LIB_DIR" -vwarning
PKG_CONFIG_PATH="$CONAN_LIB_DIR":$PKG_CONFIG_PATH
export PKG_CONFIG_PATH
# Build
%cmake -GNinja
%ninja_build

%install
# Install everything else
%ninja_install
# Deploy conan shared libraries
CONAN_LIB_DIR="%{_builddir}/conan-libs/"
SHARED_LIBRARIES="%{buildroot}/%{_datadir}/%{name}/lib"
mkdir -p "$SHARED_LIBRARIES"
conan-deploy-libraries "%{buildroot}/%{_bindir}/%{name}" "$CONAN_LIB_DIR" "$SHARED_LIBRARIES"

%files
%defattr(-,root,root,-)
%{_bindir}/%{name}
%defattr(0644,root,root,-)
%{_datadir}/%{name}
%{_datadir}/applications/%{name}.desktop
%{_datadir}/icons/hicolor/*/apps/%{name}.png
%attr(644,root,root) %{_datadir}/%{name}/qml/py/audiox.py
