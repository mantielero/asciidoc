import npeg
import std/[strutils, strformat, tables]

# https://docs.asciidoctor.org/asciidoc/latest/directives/include/

type
  IncludeObj = object
    target:string
    attributes:OrderedTable[string,string]

let parserIncludes* = peg("includes", incl: IncludeObj):
  crlf      <- ?'\r' * '\n'
  target    <- +(1 - '[')
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
  includes  <- "include::" * >target * attributes * crlf:
    incl.target = $1

proc main =
  var incl:IncludeObj
  var txt = """
include::attributes-settings.adoc[leveloffset=+1,lines="1..10,15..20",prueba=7;14..25;28..43,adios]
"""
  echo "--------------"
  echo txt
  echo "--------------"  
  var res = parserIncludes.match(txt, incl)

  echo $incl

main()

