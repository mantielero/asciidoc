import npeg
import ../types
import ../grammar/[adocgrammar]
import std/[strutils, strformat, tables, options]
# TODO: el número no es el nivel del nesting, sino el cambio de símbolo.
# https://docs.asciidoctor.org/asciidoc/latest/lists/unordered/

  

let parserList* = peg("list", l: ListObj):
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
    #var key = &":attrib{n}:{attrib}"
    l.attrib[key] = value

  # - options 
  option            <- >+adoc.key * ?',': 
    var key = $1
    l.attrib[key] = ""

  attribute  <- namedAttribute | option
  attributes <- '[' * *attribute * ']' * adoc.crlf
  
  # List Items
  item      <- >+('*'|'-'|'.'|'#') * ' ' * >adoc.txt * adoc.crlf:   
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
    it.txt  &= $2

    l.items &= it

  list <- ?title * ?attributes * +( (item|adoc.emptyLine|adoc.comment) * &!adoc.listSeparator)
