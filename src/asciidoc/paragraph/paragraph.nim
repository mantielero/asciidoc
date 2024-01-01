#[
https://docs.asciidoctor.org/asciidoc/latest/sections/titles-and-levels/

]#
import npeg
import ../types
import ../grammar/[adocgrammar]
import std/[strutils, strformat, tables]



let parserParagraph* = peg("paragraph", para: ParagraphObj):
  crlf        <- ?'\r' * '\n' # 0 or 1 '\r'; then 1 '\n'
  emptyLine   <- *' ' * crlf  # 0 or many spaces; then crlf
  noSlash     <- &!'/'        # 1 not '/' but it doesn't consume any character

  comment        <- "//" * noSlash * *txt * crlf
  emptyorcomment <- (emptyLine | comment)

  headerMark <- ('='|'#')[2..100] * ' '

  txt <- +(1 - '\r' - '\n')

  comment        <- "//" * noSlash * *txt * crlf
  emptyorcomment <- (emptyLine | comment)
  # Section
  paragraph <- !('*'|'-'|'.'|'#'|'=') *  >txt * crlf:
    para.lines &= ($1).strip
     

  # List Attributes
  # - named attribute
  namedAttribute    <- >adoc.key * '=' * >(adoc.value1 | adoc.value2) * ?',':
    var value = $2
    if value.startsWith('"') and value.endsWith('"'):
      value = value[1 ..< value.high] 

    var key = $1
    #var key = &":attrib{n}:{attrib}"
    para.attrib[key] = value

  # - options 
  option            <- >+adoc.key * ?',': 
    var key = $1
    para.attrib[key] = ""

  attribute  <- namedAttribute | option
  attributes <- '[' * *attribute * ']' * adoc.crlf


  paragraph  <- *emptyorcomment * *attributes * +paragraph  