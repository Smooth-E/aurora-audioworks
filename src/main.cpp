
#include <auroraapp.h>
#include <QtQuick>

int main(int argc, char *argv[])
{
    QScopedPointer<QGuiApplication> application(Aurora::Application::application(argc, argv));
    application->setOrganizationName(QStringLiteral("moe.smoothie"));
    application->setApplicationName(QStringLiteral("audioworks"));

    QScopedPointer<QQuickView> view(Aurora::Application::createView());
    view->setSource(Aurora::Application::pathTo(QStringLiteral("qml/moe.smoothie.audioworks.qml")));
    view->show();

    return application->exec();
}
