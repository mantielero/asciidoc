#!/usr/bin/env nim

for i in listFiles("./"):
  discard execShellCmd("asciidoctor  " & i)
  #exec("asciidoctor -e " & i)


