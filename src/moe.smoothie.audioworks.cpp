#include <QtQuick>
#include <auroraapp.h>

int main(int argc, char *argv[])
{
    // For vendored python to work
    qputenv("PYTHONHOME", QString("/usr/share/moe.smoothie.audioworks/").toUtf8().constData());

    QScopedPointer<QGuiApplication> app(Aurora::Application::application(argc, argv));
    app->setOrganizationName("moe.smoothie");
    app->setApplicationName("audioworks");

    QScopedPointer<QQuickView> view(Aurora::Application::createView());

    // Vendored pyotherside
    view->engine()->addImportPath(Aurora::Application::pathTo("lib/qt5/qml").toString());

    view->setSource(Aurora::Application::pathToMainQml());
    view->show();

    return app->exec();
}
