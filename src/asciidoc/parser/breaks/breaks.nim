#[
https://docs.asciidoctor.org/asciidoc/latest/sections/titles-and-levels/

]#
import npeg
import ../../types
import ../grammar/[adocgrammar]
import std/[strutils, strformat, tables]



let parserBreak* = peg("breaks", b: BreakObj):
  crlf        <- ?'\r' * '\n' # 0 or 1 '\r'; then 1 '\n'
  breaks      <- adoc.emptyLine * >("<<<"|"'''"|"---"|"- - -"|"***"|"* * *") * crlf:  # 0 or many spaces; then crlf
    b.symbol = $1
    if b.symbol == "<<<":
      b.isPageBreak = true