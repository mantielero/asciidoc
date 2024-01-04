import npeg
import ../../types
import ../grammar/[adocgrammar]
import std/[strutils, strformat, tables, options]

let parserAttributes* = peg("attributes", attr:AttributesObj):
  # named attribute
  namedAttribute    <- >adoc.key * '=' * >(adoc.value1 | adoc.value2) * ?',':
    var value = $2
    if value.startsWith('"') and value.endsWith('"'):
      value = value[1 ..< value.high] 

    var key = $1
    attr[key] = value

  # options 
  option            <- >+adoc.key * ?',': 
    var key = $1
    attr[key] = ""

  attribute  <- namedAttribute | option
  attributes <- '[' * *attribute * ']' * adoc.crlf  