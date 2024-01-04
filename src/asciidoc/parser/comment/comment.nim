import npeg
import ../../types
import ../grammar/[adocgrammar]
import std/[strutils, strformat, tables, options]
# TODO: description list
# https://docs.asciidoctor.org/asciidoc/latest/lists/description/
# https://docs.asciidoctor.org/asciidoc/latest/lists/unordered/


let parserCommentOrEmpty* = peg("commentorempty"):
  commentorempty     <- adoc.emptyorcomment

let parserCommentedLine* = peg("commentline"):
  commentline <- !adoc.bdComment * *(1 - '\r' - '\n') * adoc.crlf