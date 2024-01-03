import npeg
import ../../types
import ../grammar/adocgrammar
import std/[strutils, strformat, tables]

# https://docs.asciidoctor.org/asciidoc/latest/directives/include/



let parserAttributes* = peg("attributes", v: Table[string,string]):
  key       <- ':' * +(1 - ':' - '\n' - '\r' - ' ') * ": "
  crlfcont <- (1 - ' ') * (1 - '\\') * ?'\r' * '\n'
  value     <- @crlfcont#+lineCont * line  | line):  #lineCont #(line )| +lineCont * line ) 
    #echo ">",$0,"<"
  attribute <- >key * >(adoc.crlf | value): # a key with an optional value
    var key = ($1)[1 ..< (($1).high-1)]
    var value = if capture.len == 3:
                 ($2).strip()
                else:
                  ""
    value = value.replace("\\\n","")
    v[key] = value
  attributes <- +attribute