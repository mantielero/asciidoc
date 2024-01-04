#[
https://docs.asciidoctor.org/asciidoc/latest/sections/titles-and-levels/

]#
import npeg
import ../../types
import ../grammar/[adocgrammar]
import std/[strutils, strformat, tables]



let parserParagraph* = peg("paragraph", para: ParagraphObj):
  
  #paragraphLine <- !('*'|'-'|'.'|'#'|'=') *  >adoc.txt * adoc.crlf * !('*'|'-'|'.'|'#'|'='):
  paragraphLine <- !adoc.blockDelimiters * >adoc.txt * adoc.crlf:
    para.lines &= ($1).strip

  paragraph  <- *adoc.emptyorcomment * +paragraphLine 