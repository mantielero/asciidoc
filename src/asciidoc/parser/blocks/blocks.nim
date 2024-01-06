import npeg
import std/[strutils, strformat, tables]
import ../../types



proc parserBlocksGen():auto =
  var db:Block
  new(db)

  return  peg("blocks", blk: Block):
            # ---- Delimited Blocks ----: https://docs.asciidoctor.org/asciidoc/latest/blocks/delimited/
            # Title
            title     <- '.' * >adoc.txt * adoc.crlf:
              db.title = $1
            attributes <- '[' * >*(1 - '[' - ']' - '\r' - '\n') * ']' * adoc.crlf:
              db.attributes = $1
            delimitedBlocks <- *adoc.emptyorcomment * ?title * ?attributes * >R("blockDelimiter", adoc.blockDelimiters  * adoc.crlf ) * >*(!R("blockDelimiter") * *(1 - '\r' - '\n') * adoc.crlf) * R("blockDelimiter"):
              db.content = $2
              db.done = false
              var delimiter = ($1).splitLines[0]
              if delimiter.startsWith("////"):
                db.done = true
                db.kind = comment
              elif delimiter.startsWith("===="):
                db.done = false
                db.kind = example      
              elif delimiter.startsWith("----"):
                db.done = true
                db.kind = listing
              elif delimiter.startsWith("...."):
                db.done = true
                db.kind = literal
              elif delimiter.startsWith("--"):
                db.done = false
                db.kind = open      
              elif delimiter.startsWith("****"):
                db.done = false
                db.kind = sidebar
              elif delimiter.startsWith("|==="):
                db.done = false
                db.kind = table1
              elif delimiter.startsWith(",==="):
                db.done = false
                db.kind = table2
              elif delimiter.startsWith(":==="):
                db.done = false
                db.kind = table3
              elif delimiter.startsWith("!==="):
                db.done = false
                db.kind = table4    
              elif delimiter.startsWith("____"):
                db.done = false
                db.kind = quote          
              elif delimiter.startsWith("++++"):
                db.done = true
                db.kind = quote 
              blk.blocks &= db.deepCopy

            # ---- Doc Header ---
            titleDocHeader <- "= " * >adoc.txt * adoc.crlf:
              db.title = $1
            docheader <- *adoc.emptyorcomment * titleDocHeader * >@adoc.crlf[2]:#adoc.emptyLine:
              #echo $1
              db.content = $1
              db.done = true
              db.kind = documentHeader
              blk.blocks &= db.deepCopy

            # ---- Paragraph ----
            paragraph <- *adoc.emptyorcomment  * !adoc.blockDelimiters * >+(1 - adoc.crlf[2]):#>@adoc.emptyLine:
              db.title = ""
              db.content = $1
              db.kind = paragraph
              db.done = true
              blk.blocks &= db.deepCopy


            blocks <- *(docheader | delimitedBlocks | paragraph)

let parserBlocks* = parserBlocksGen()

#===================================================

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