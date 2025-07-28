TARGET = moe.smoothie.audioworks

CONFIG += auroraapp_qml

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

# to disable building translations every time, comment out the
# following CONFIG line
CONFIG += auroraapp_i18n

# German translation is enabled as an example. If you aren't
# planning to localize your app, remember to comment out the
# following TRANSLATIONS line. And also do not forget to
# modify the localized app name in the the .desktop file.
TRANSLATIONS += translations/moe.smoothie.audioworks-de.ts \
                translations/moe.smoothie.audioworks-sv.ts \
                translations/moe.smoothie.audioworks-zh_CN.ts \
                translations/moe.smoothie.audioworks-ru.ts

HEADERS +=

# include precompiled static library according to architecture
equals(QT_ARCH, arm64): {
  ffmpeg_static.files = lib/ffmpeg/arm64/ffmpeg.tar
  lame.files = lib/lame/arm64/lame.tar
}
equals(QT_ARCH, x86_64): {
  ffmpeg_static.files = lib/ffmpeg/x86_64/ffmpeg.tar
  lame.files = lib/lame/x86_64/lame.tar
}

ffmpeg_static.path = /usr/share/moe.smoothie.audioworks/bin
lame.path = /usr/share/moe.smoothie.audioworks/bin

INSTALLS += ffmpeg_static lame

DISTFILES += lib/pydub \

python.files = lib/pydub/*
python.path = "/usr/share/moe.smoothie.audioworks/lib/pydub"
INSTALLS += python
