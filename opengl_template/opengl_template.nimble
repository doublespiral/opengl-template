# Package

version       = "0.1.0"
author        = "helix"
description   = "An openGL template for Nim. Uses the staticglfw and opengl libraries"
license       = "GPL-3.0-or-later"
binDir        = "built"
srcDir        = "source"
bin           = @["opengl_template"]


# Dependencies

requires "nim >= 2.2.0"
requires "staticglfw"
requires "opengl"