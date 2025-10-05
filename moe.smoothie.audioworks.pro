TARGET = moe.smoothie.audioworks

CONFIG += auroraapp

DISTFILES += \
    qml/cover/CoverPage.qml \
    qml/moe.smoothie.audioworks.qml \
    qml/pages/About.qml \
    qml/pages/Chorus.qml \
    qml/pages/FirstPage.qml \
    qml/pages/Flanger.qml \
    qml/pages/Phaser.qml \
    qml/pages/SavePage.qml \
    rpm/moe.smoothie.audioworks.spec \
    translations/*.ts \
    moe.smoothie.audioworks.desktop

AURORAAPP_ICONS = 86x86 108x108 128x128 172x172

CONFIG += auroraapp_i18n

TRANSLATIONS += translations/moe.smoothie.audioworks-*.ts

SOURCES += src/moe.smoothie.audioworks.cpp

# Vendor libraries

libdir = /usr/share/$$TARGET/lib
libexecdir = /usr/libexec/$$TARGET
cpython_version = "3.8"

message(Building for architecture $$QT_ARCH)
equals(QT_ARCH, arm64) {
    vendor = vendor/aarch64
    lib_subdir = lib64
}
# qmake in Aurora Platform SDK armv7hl prefix reports QT_ARCH as just arm...
equals(QT_ARCH, arm) {
    # But cmake, which we use for building cpython, reports it as armv7l
    vendor = vendor/armv7l
    lib_subdir = lib
}
message(Selected vendor dir $$vendor)

vendored_bin.path = $$libexecdir
vendored_bin.files = $$vendor/bin/python3 \
                     $$vendor/bin/python$$cpython_version \
                     $$vendor/bin/ffmpeg \
                     $$vendor/bin/ffprobe \
                     $$vendor/bin/lame

vendored_lib.path = $$libdir
vendored_lib.files = $$vendor/lib/python$$cpython_version \
                     $$vendor/lib/*.so*

pyotherside.path = $$libdir/
pyotherside.files = $$vendor/usr/$$lib_subdir/qt5

INSTALLS += vendored_bin vendored_lib pyotherside
