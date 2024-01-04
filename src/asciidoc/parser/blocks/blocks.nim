import npeg
import std/[strutils, strformat, tables]
import ../../types



let parserBlockDelimiter* = peg("blockDelimiter", blk: BlockDelimiterObj):
  bdComment   <- adoc.bdComment:
    blk.typ = comment
  bdExample   <- adoc.bdExample:
    blk.typ = example
  bdListing   <- adoc.bdListing:
    blk.typ = listing    
  bdLiteral   <- adoc.bdLiteral:
    blk.typ = literal    
  bdOpen      <- adoc.bdOpen:
    blk.typ = open    
  bdSidebar   <- adoc.bdSidebar:
    blk.typ = sidebar    
  bdTable1    <- adoc.bdTable1:
    blk.typ = table1    
  bdTable2    <- adoc.bdTable2:
    blk.typ = table2    
  bdTable3    <- adoc.bdTable3:
    blk.typ = table3  
  bdTable4    <- adoc.bdTable4:
    blk.typ = table3    
  bdQuote     <- adoc.bdQuote:
    blk.typ = quote   

  blockDelimiter <- >adoc.blockDelimiters * adoc.crlf:
    blk.symbol = $1


#[ let parserBlocks* = peg("blocks", blk: BlocksObj):
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
    blk.txt = $1 ]#

