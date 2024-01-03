import npeg
import ../../types
import ../grammar/[adocgrammar]
import std/[strutils, strformat, tables, options]
# TODO: description list
# https://docs.asciidoctor.org/asciidoc/latest/lists/description/
# https://docs.asciidoctor.org/asciidoc/latest/lists/unordered/

  
let parserList* = peg("list", l: ListObj):
  crlf        <- ?'\r' * '\n' # 0 or 1 '\r'; then 1 '\n'
  noSlash     <- &!'/'        # 1 not '/' but it doesn't consume any character
  txt <- +(1 - '\r' - '\n')    
  comment        <- "//" * noSlash * *txt * crlf
  emptyLine   <- *' ' * crlf  # 0 or many spaces; then crlf  
  emptyorcomment <- (emptyLine | comment)
  # List Title
  title     <- '.' * >adoc.txt * adoc.crlf:
    l.title = ($1).strip

  # List Attributes
  # - named attribute
  namedAttribute    <- >adoc.key * '=' * >(adoc.value1 | adoc.value2) * ?',':
    var value = $2
    if value.startsWith('"') and value.endsWith('"'):
      value = value[1 ..< value.high] 

    var key = $1
    l.attrib[key] = value

  # - options 
  option            <- >+adoc.key * ?',': 
    var key = $1
    l.attrib[key] = ""

  attribute  <- namedAttribute | option
  attributes <- '[' * *attribute * ']' * adoc.crlf
  
  # List Items
  item      <- >+('*'|'-'|'.'|'#') * ' ' * >adoc.txt * adoc.crlf:
    #echo "--OK--" 
    var it:ItemObj
    var symbol:string = $1
    if symbol[0] == '*' or symbol[0] == '-':
      it.typ = unordered
      if not (symbol in l.unorderedSymbols):
        l.unorderedSymbols &= symbol
        it.level = l.unorderedSymbols.high

      else:
        it.level = l.unorderedSymbols.find(symbol)

    elif symbol[0] == '.' or symbol[0] == '#':
      it.typ = ordered
      if not (symbol in l.orderedSymbols):
        l.orderedSymbols &= symbol
        it.level = l.orderedSymbols.high     
      else:
        it.level = l.orderedSymbols.find(symbol)      
    #it.term = ""
    it.txt  &= $2
    l.items &= it

  # List description
  #avoidDirective <- +(1-':'-'\r'-'\n') * "::" * (1-'['-']'-'\r'-'\n') * '[' * (1-'['-']'-'\r'-'\n') * ']' * crlf
  listDescription <- >+(1-':'-'\r'-'\n') * >("::"|":::"|"::::"|";;") * (" " * >+(1-'\r'-'\n')) * crlf:
    var it:ItemObj
    var symbol:string = $2
    it.typ = listDescription
    if not (symbol in l.listDescriptionSymbols):
      l.listDescriptionSymbols &= symbol
      it.level = l.listDescriptionSymbols.high
    else:
      it.level = l.listDescriptionSymbols.find(symbol)

    it.term = $1

    var tmp = if capture.len == 3:
                ($3).strip()
              else:
                ""
    it.txt &= tmp
    l.items &= it

  list <- *emptyorcomment * ?title * ?attributes * +((item|listDescription) * adoc.emptyorcomment[0..2]) * &!adoc.listSeparator
