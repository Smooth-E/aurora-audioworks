from conan import ConanFile

class Application(ConanFile):
    settings = "os", "compiler", "arch", "build_type"
    generators = "PkgConfigDeps"

    requires = (
        "ffmpeg/7.0.1@aurora",
    )
