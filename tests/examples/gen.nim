import std/os

for i in walkFiles("*.adoc"):
  discard execShellCmd("asciidoctor  " & i)
  #discard execShellCmd("asciidoctor -e " & i)
  #exec("asciidoctor  " & i)
  #exec("asciidoctor -e " & i)


