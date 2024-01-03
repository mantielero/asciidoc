import npeg
import std/[strutils, strformat, tables]
import ../../types

type
  BlockType = enum
    comment  # ////
    example  # ====
    listing  # ----
    literal  # ....
    open     # --
    sidebar  # ****
    table1   # |===
    table2   # ,===     
    table3   # :===    
    table4   # !===    
    pass     # ++++
    quote    # ____
  BlocksObj = object
    title:string
    id:string
    roles:seq[string]
    attributes:OrderedTable[string,string]
    txt:string
    typ:BlockType
  
  Blocks = ref BlocksObj


let parserBlocks* = peg("blocks", blk: BlocksObj):
  crlf      <- ?'\r' * '\n'
  bdComment   <- "////" * *('/'):
    blk.typ = comment
  bdExample   <- "====" * *('='):
    blk.typ = example
  bdListing   <- "----" * *('-'):
    blk.typ = listing    
  bdLiteral   <- "...." * *('.'):
    blk.typ = literal    
  bdOpen      <- "--":
    blk.typ = open    
  bdSidebar   <- "****" * *('*'):
    blk.typ = sidebar    
  bdTable1    <- "|===" * *('='):
    blk.typ = table1    
  bdTable2    <- ",===" * *('='):
    blk.typ = table2    
  bdTable3    <- ":===" * *('='):
    blk.typ = table3  
  bdTable4    <- "!===" * *('='):
    blk.typ = table3    
  bdQuote     <- "____" * *('_'):
    blk.typ = quote    

  title     <- '.' * >+(1 - '\r' - '\n') * crlf:
    blk.title = $1
  option    <- >+(1 - '[' - ']' - ',' - '=' - '#' - '.' - '%'):
    blk.attributes[$1] = ""
  value     <- +(1 - '"')

  # Named Attributes
  # https://docs.asciidoctor.org/asciidoc/latest/attributes/positional-and-named-attributes/#named
  keyvalue  <- >option * '=' * '"' * >value * '"':
    blk.attributes[$1] = $2
  attribute <- (keyvalue | option) * ?','
  
  id       <- '#' * >+(1 - '[' - ']' - ',' - '=' - '#' - '.' - '%'):
    blk.id = $1
  role     <- '.' * >+(1 - '[' - ']' - ',' - '=' - '.' - '%'):
    blk.roles &= $1
  attributes <- '[' * ?id * *role  * ?'%' * *attribute * ']' * crlf
  blockDelimiter <- (bdComment | bdExample | bdListing | bdLiteral | bdOpen | bdSidebar | bdTable1 | bdTable2 | bdTable3 | bdTable4 | bdQuote)

  blocks <- ?title * ?attributes * R("blockDelimiter", blockDelimiter  * crlf ) * >*(!R("blockDelimiter") * *(1 - '\r' - '\n') * crlf) * R("blockDelimiter"):
    blk.txt = $1


# ====================

proc main() =
  var text = """
.This is the title
[#my-id.role1.role2%prueba,caption="Esto es una prueba"]
========
Here are your options:

.Red Pill
[example%collapsible]
======
Escape into the real world.
======

.Blue Pill
[%collapsible]
======
Live within the simulated reality without want or fear.
======
========
"""  
  var
    blocks,blk:BlocksObj
    res = parserBlocks.match(text, blocks)
  
  echo "------------"
  echo text
  echo "------------"
  echo blocks
  # Sub blocks
  
  #res = parserBlocks.match(blocks.txt, blk)
  #echo blk


  
main()