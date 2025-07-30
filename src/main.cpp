#include <auroraapp.h>
#include <QtQuick>
#include <QDebug>

extern "C" {
    #include "libavcodec/avcodec.h"
}

int main(int argc, char *argv[])
{
    QScopedPointer<QGuiApplication> application(Aurora::Application::application(argc, argv));
    application->setOrganizationName(QStringLiteral("moe.smoothie"));
    application->setApplicationName(QStringLiteral("audioworks"));

    QScopedPointer<QQuickView> view(Aurora::Application::createView());
    view->setSource(Aurora::Application::pathTo(QStringLiteral("qml/moe.smoothie.audioworks.qml")));
    view->show();

    qDebug() << "Shipping FFMPEG " << av_version_info();

    return application->exec();
}
