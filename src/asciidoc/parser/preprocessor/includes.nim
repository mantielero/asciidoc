import npeg
import ../../types
import std/[strutils, strformat, tables]

# https://docs.asciidoctor.org/asciidoc/latest/directives/include/



let parserIncludes* = peg("includes", incl: IncludeObj):
  crlf      <- ?'\r' * '\n'
  target    <- +(1 - '[' - '\r' - '\n')
  key       <- +(1 - '[' - ']' - ',' - '=')
  value1    <- +(1 - '[' - ']' - '=' - ',' - '"')
  value2    <- '"' * +(1 - '"') * '"' 
  namedAttribute <- >key * '=' * >(value1 | value2) * ?',':
    var tmp = $2
    if tmp.startsWith('"') and tmp.endsWith('"'):
      incl.attributes[$1] = tmp[1..< tmp.high]
    else:
      incl.attributes[$1] = tmp
  option   <- >+(1 - '[' - ']' - '=' - ',' - '"') * ?',':
    incl.attributes[$1] = ""
  attribute <- namedAttribute | option
  attributes <- '[' * *attribute * ']'
  includes  <- !'\\' * "include::" * >target * attributes * crlf:
    incl.target = $1
    incl.line   = $0

let parserSubs* = patt '{' * >+(1-'}') * '}'

#peg("substitution", target: string):
  #substitution <- '{' * (1-'}') * '}'