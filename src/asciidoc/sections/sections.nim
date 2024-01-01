#[
https://docs.asciidoctor.org/asciidoc/latest/sections/titles-and-levels/

]#
import npeg
import ../types
import ../grammar/[adocgrammar]
import std/[strutils, strformat, tables]



let parserSection* = peg("section", sect: SectionObj):
  crlf        <- ?'\r' * '\n' # 0 or 1 '\r'; then 1 '\n'
  emptyLine   <- *' ' * crlf  # 0 or many spaces; then crlf
  noSlash     <- &!'/'        # 1 not '/' but it doesn't consume any character

  headerMark <- ('='|'#')[2..100] * ' '

  txt <- +(1 - '\r' - '\n')

  comment        <- "//" * noSlash * *txt * crlf
  emptyorcomment <- (emptyLine | comment)
  # Section
  sectionTitle <- *emptyorcomment * >headerMark * >txt * crlf:
    sect.level = ($1).len - 1
    sect.txt = ($2).strip 
     

  # List Attributes
  # - named attribute
  namedAttribute    <- >adoc.key * '=' * >(adoc.value1 | adoc.value2) * ?',':
    var value = $2
    if value.startsWith('"') and value.endsWith('"'):
      value = value[1 ..< value.high] 

    var key = $1
    #var key = &":attrib{n}:{attrib}"
    sect.attrib[key] = value

  # - options 
  option            <- >+adoc.key * ?',': 
    var key = $1
    sect.attrib[key] = ""

  attribute  <- namedAttribute | option
  attributes <- '[' * *attribute * ']' * adoc.crlf


  section  <- +adoc.emptyorcomment * *attributes * sectionTitle