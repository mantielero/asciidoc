import npeg
import std/[strutils, strformat, tables]

# https://docs.asciidoctor.org/asciidoc/latest/blocks/admonitions/

type
  AdmonitionType = enum
    note
    tip
    important
    caution
    warning

  AdmonitionObj = object
    typ:AdmonitionType
    txt:seq[string]
    #attributes:OrderedTable[string,string]

let parserAdmonition* = peg("admonition", ad: AdmonitionObj):
  crlf      <- ?'\r' * '\n'
  adNote        <- "NOTE: " * >+(1 - '\r' - '\n') * crlf:
    ad.typ = note
    ad.txt &= $1
  adTip         <- "TIP: " * >+(1 - '\r' - '\n') * crlf:
    ad.typ = tip
    ad.txt &= $1  
  adImportant   <- "IMPORTANT: " * >+(1 - '\r' - '\n') * crlf:
    ad.typ = important
    ad.txt &= $1 
  adCaution     <- "CAUTION: " * >+(1 - '\r' - '\n') * crlf:
    ad.typ = caution
    ad.txt &= $1 
  adWarning     <- "WARNING: " * >+(1 - '\r' - '\n') * crlf:
    ad.typ = warning
    ad.txt &= $1 
  admon <- (adNote | adTip | adImportant | adCaution | adWarning)
  line  <- >+(1 - '\r' - '\n') * crlf:
    ad.txt &= $1
  admonition <- admon * *line


proc main =
  var adm:AdmonitionObj
  var txt = """
WARNING: Wolpertingers are known to nest in server racks.
Enter at your own risk.
"""
  echo "--------------"
  echo txt
  echo "--------------"  
  var res = parserAdmonition.match(txt, adm)

  echo $adm

main()