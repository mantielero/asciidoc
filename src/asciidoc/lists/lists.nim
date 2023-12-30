import npeg
import ../types
import std/[strutils, strformat, tables, options]
# TODO: el número no es el nivel del nesting, sino el cambio de símbolo.
# https://docs.asciidoctor.org/asciidoc/latest/lists/unordered/

  


grammar "adoc":
  crlf      <- ?'\r' * '\n'
  comment   <- "//" * *(1-'\r'-'\n') * crlf
  emptyLine <- *' ' * crlf
  key       <- +(1 - '[' - ']' - ',' - '=' - '"')
  value1    <- +(1 - '[' - ']' - '=' - ',' - '"')
  value2    <- '"' * +(1 - '"') * '"'
  txt       <- +(1 - '\r' - '\n')
  listSeparator <- (emptyLine * comment * emptyLine)  

let parserList* = peg("list", l: ListObj):
  # List Title
  title     <- '.' * >adoc.txt * adoc.crlf:
    l.title = ($1).strip

  # List Attributes
  # - named attribute
  namedAttribute    <- >adoc.key * '=' * >(adoc.value1 | adoc.value2) * ?',':
    #item[":type"] = "list"

    # var n = -1
    # for key in item.keys:
    #   if key.startsWith(":attrib"):
    #     var tmp = key.split(":attrib")[1]
    #     tmp = tmp.split(":",1)[0]
    #     var tmpVal = tmp.parseInt
    #     if tmpVal > n:
    #       n = tmpVal
    # n += 1

    var value = $2
    if value.startsWith('"') and value.endsWith('"'):
      value = value[1 ..< value.high] 

    var key = $1
    #var key = &":attrib{n}:{attrib}"
    l.attrib[key] = value

  # - options 
  option            <- >+adoc.key * ?',': 
    #item[":type"] = "list"

    # var n = -1
    # for key in item.keys:
    #   if key.startsWith(":attrib"):
    #     var tmp = key.split(":attrib")[1]
    #     tmp = tmp.split(":",1)[0]
    #     var tmpVal = tmp.parseInt
    #     if tmpVal > n:
    #       n = tmpVal
    # n += 1
    
    var key = $1
    #var key = &":attrib{n}:{$attrib}"
    l.attrib[key] = ""

  attribute  <- namedAttribute | option
  attributes <- '[' * *attribute * ']' * adoc.crlf
  
  # List Items
  item      <- >+('*'|'-'|'.'|'#') * ' ' * >adoc.txt * adoc.crlf:   
    #item[":type"] = "list"
        
    # var n = -1
    # for key in item.keys:
    #   if key.startsWith(":item"):
    #     var tmp = key.split(":item")[1]
    #     tmp = tmp.split(":",1)[0]
    #     var tmpVal = tmp.parseInt
    #     if tmpVal > n:
    #       n = tmpVal
    # n += 1
    
    #var symbol = $1
    #var key = &":item{n}:{symbol}"
    #var value = ($2).strip
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

    #item[key] = value#i.items &= item

  list <- ?title * ?attributes * +( (item|adoc.emptyLine|adoc.comment) * &!adoc.listSeparator)




#[ when isMainModule:
  var items:ItemsObj
  var txt = """
.Possible DefOps manual locations
[square]
* West wood maze
// This is a comment
** Maze heart

[circle]
*** Reflection pool
** Secret exit
* Untracked file in git repository
// The next one split's the list
//-
* This is a new List
"""
  echo "--------------"
  echo txt
  echo "--------------"  
  var res = parserItems.match(txt, items)

  echo $items


  # Case 2-------------- List separator

  txt = """
.Possible DefOps manual locations
[square]
* West wood maze
// This is a comment
- Maze heart

//

*** Reflection pool
** Secret exit
* Untracked file in git repository
// The next one split's the list
//-
* This is a new List
"""

  items.title = none(string)
  items.attrib = none(OrderedTable[string,string])  
  items.orderedSymbols = @[]
  items.unorderedSymbols = @[]  
  items.items = @[]
  echo "--------------"
  echo txt
  echo "--------------"  
  res = parserItems.match(txt, items)

  echo $items


  # Case 2-------------- List separator

  txt = """
.Possible DefOps manual locations
[square]
. West wood maze
// This is a comment
.. Maze heart
# Another test
* test1
** trest 2

//

*** Reflection pool
** Secret exit
* Untracked file in git repository
// The next one split's the list
//-
* This is a new List
"""

  items.title = none(string)
  items.attrib = none(OrderedTable[string,string]) 
  items.orderedSymbols = @[]
  items.unorderedSymbols = @[]     
  items.items = @[]
  echo "--------------"
  echo txt
  echo "--------------"  
  res = parserItems.match(txt, items)

  echo $items
 ]#