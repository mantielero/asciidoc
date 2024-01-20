version     = "0.0.1"
author      = "Jose Maria Garcia"
description = "AsciiDoc parser"
license     = "MIT"

# Deps

requires "nim >= 2.0.0"
requires "karax >= 1.3.3"

bin = @["bin"]

task compileBin, "Compile the binary":
  exec "nim c -d:release --deepCopy:on -o:bin/asciidoc src/asciidoc.nim"

