import npeg
import ../../types
import ../grammar/[adocgrammar]
import std/[strutils, strformat, tables, options]
# TODO: description list
# https://docs.asciidoctor.org/asciidoc/latest/lists/description/
# https://docs.asciidoctor.org/asciidoc/latest/lists/unordered/


let parserListTitle* = peg("title", l: ListTitleObj):
  title     <- *adoc.emptyorcomment * '.' * !(' '|'.') * >adoc.txt * adoc.crlf:
    l.title = ($1).strip


let parserListSeparator* = peg("listSeparator"):
  # List Items
  listSeparator <- adoc.listSeparator

let parserListItem* = peg("list", it: ListItemTmpObj):
  # List Items
  item      <- >(*' ' * +('*'|'-'|'.'|'#')) * ' ' * >adoc.txt * adoc.crlf:
    it.symbol = $1
    it.txt    = $2

    # elif symbol[0] == '.' or symbol[0] == '#':
    #   it.typ = ordered
    #   if not (symbol in l.orderedSymbols):
    #     l.orderedSymbols &= symbol
    #     it.level = l.orderedSymbols.high     
    #   else:
    #     it.level = l.orderedSymbols.find(symbol)      
    #it.term = ""
    #it.txt  &= $2
    #l.items &= it

  # List description
  #avoidDirective <- +(1-':'-'\r'-'\n') * "::" * (1-'['-']'-'\r'-'\n') * '[' * (1-'['-']'-'\r'-'\n') * ']' * crlf
  listDescription <- >+(1-':'-'\r'-'\n') * >("::"|":::"|"::::"|";;") * (" " * >+(1-'\r'-'\n')) * adoc.crlf:
    #var it:ListItemTmpObj
    #echo $0
    it.symbol = $2
    #it.typ = listDescription
    # if not (symbol in l.listDescriptionSymbols):
    #   l.listDescriptionSymbols &= symbol
    #   it.level = l.listDescriptionSymbols.high
    # else:
    #   it.level = l.listDescriptionSymbols.find(symbol)

    it.term = $1
    #echo $1
    #echo capture.len
    var tmp = if capture.len == 4:
                ($3).strip()
              else:
                ""
    it.txt = tmp
    #l.items &= it

  list <- *adoc.emptyorcomment * (item|listDescription)
