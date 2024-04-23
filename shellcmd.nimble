# Package

version       = "0.1.0"
author        = "alogani"
description   = "Collection of Terminal commands to be used inside nim"
license       = "MIT"
srcDir        = "src"


# Dependencies

requires "nim >= 2.0.2"
requires "asyncproc >= 0.1.0"
requires "aloganimisc = 0.1.1"

task reinstall, "Reinstalls this package":
    var path = "~/.nimble/pkgs2/" & projectName() & "-" & $version & "-*"
    exec("rm -rf " & path)
    exec("nimble install")
