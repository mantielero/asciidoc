import npeg
import std/[strutils, strformat, tables]
import ../../types

proc parserBlocksGen():auto =
  var db:Block
  new(db)
  db.done = false

  return  peg("blocks", blk: Block):
            # ---- Delimited Blocks ----: https://docs.asciidoctor.org/asciidoc/latest/blocks/delimited/
            # Title
            title     <- '.' * >adoc.txt * adoc.crlf:
              db.title = $1
            
            attributeId <- "[[" * >@("]]" * ?'\r' * '\n'): # Legacy Id
              var txt = ($0).splitLines()[0]
              txt = txt[2..(txt.high - 2)]
              db.attributes[":id"] = txt

            blockKind  <- >*(1-'#'-'%'-'.'-','-']'):
              db.attributes[$1] = ""
              case ($1): 
              of "example":
                db.kind = example
              of "listing": 
                db.kind = listing
                db.done = true
              of "literal": 
                db.kind = literal
                db.done = true
              of "pass":    
                db.kind = pass
                db.done = true
              of "quote":   
                db.kind = quote
              of "sidebar": 
                db.kind = sidebar
              of "source":  
                db.kind = source
              of "stem":    
                db.kind = stem
              of "verse":   
                db.kind = verse 
              else:
                db.kind = paragraph              
            id <- '#' * >+(1-'#'-'%'-'.'-','-']'):
              db.attributes[":id"] = $1
            role <- '.' * >+(1-'#'-'%'-'.'-','-']'):
              db.attributes[$0] = ""
            onlyKey <- ',' * >+(1 - ',' - '=' - ']'):
              db.attributes[$1] = ""
            keyValue <- ',' * >+(1 - ',' - '=' - ']') * '=' * >+(1 - ',' - '=' - ']'):
              db.attributes[$1] = $2                         
            attributes <- '[' * ?blockKind * ?id * *role * *(keyValue|onlyKey) * ']' * adoc.crlf

            delimitedBlocks <- *adoc.emptyorcomment * ?title * ?(attributeId|attributes) * >R("blockDelimiter", adoc.blockDelimiters  * adoc.crlf ) * >*(!R("blockDelimiter") * *(1 - '\r' - '\n') * adoc.crlf) * R("blockDelimiter"):
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
              # Cleaning
              db.title = ""
              db.content = ""
              db.done = false
              db.attributes.clear()              

            # ---- Doc Header ---
            titleDocHeader <- "= " * >adoc.txt * adoc.crlf:
              db.title = $1
            docheader <- *adoc.emptyorcomment * titleDocHeader * >*(1 - adoc.emptyLine):#adoc.crlf[2]):#>@adoc.crlf[2]:
              #echo $1
              db.content = $1
              db.done = true
              db.kind = documentHeader
              blk.blocks &= db.deepCopy
              db.clear()  # Cleaning
              
            # ---- Lists ----
            listTitle     <- '.' * >adoc.txt * adoc.crlf:
              db.kind = listTitle
              db.title = $1
              blk.blocks &= db.deepCopy
              db.clear()              
            listSeparator <- adoc.listSeparator:
              db.kind = listSeparator
              blk.blocks &= db.deepCopy
              db.clear() 
            listBullet    <- *' ' * +('*'|'-'|'.'|'#')
            listContinuationSymbol  <- !adoc.emptyorcomment * '+' * adoc.crlf * !adoc.emptyorcomment :
              db.kind = listContinuationSymbol
              blk.blocks &= db.deepCopy
              db.clear()               

            endListItem   <- (adoc.crlf * listBullet) | (adoc.crlf[2]) | (adoc.crlf * listContinuationSymbol)
            listItem      <- *adoc.emptyorcomment * ?listTitle * >listBullet * ' ' * >+(1-endListItem) * adoc.crlf:
              db.attributes[":symbol"]  = $1
              db.content = $2
              db.kind = listItem
              blk.blocks &= db.deepCopy
              db.clear()    

            listDescriptionTerm   <- +(1 - ':' - ';' - '\r' - '\n') 
            listDescriptionSymbol <- ("::"|":::"|"::::"|";;")
            listDescriptionStop   <- (adoc.crlf * listDescriptionTerm * listDescriptionSymbol) | endListItem
            listDescription <- *adoc.emptyorcomment * >listDescriptionTerm * >listDescriptionSymbol * (' '|adoc.crlf) * >*(1-listDescriptionStop):# * adoc.crlf:
              db.attributes[":symbol"] = $2
              db.title = $1
              db.kind = listDescriptionItem
              var tmp = if capture.len == 4:
                          ($3).strip()
                        else:
                          ""
              db.content = tmp
              blk.blocks &= db.deepCopy
              db.clear()   
            # ---- Indented Paragraph ---- 
            # TODO

            # ---- Paragraph ----
            paragraph <- *adoc.emptyorcomment  * !adoc.blockDelimiters * ?attributes * >+(1 - adoc.crlf[2]-listContinuationSymbol):#>@adoc.emptyLine:
              db.title = ""
              db.content = $1
              #if db.attributes == "":
              #  db.kind = paragraph
                
              db.done = true
              blk.blocks &= db.deepCopy
             # Cleaning
              db.title = ""
              db.content = ""
              db.done = false
              db.attributes.clear()

            # ---- cite blocks ---
            cite      <- '"' * >@('"' * ?'\r' * '\n'):
              db.content = ($0)[1 .. (($0).high - 2)]
              if db.content[db.content.high] == '"':
                db.content = db.content[0..<db.content.high]
              
            citeRef   <- "-- " * >+(1 - '\r' - '\n') * adoc.crlf:
              var txt = ($1).split(",",1)
              db.attributes[":author"] = txt[0]
              if txt.len > 1:
                db.attributes[":reference"] = txt[1]
              db.done = true
            citeBlock <-  *adoc.emptyorcomment * cite * citeRef:
              blk.blocks &= db.deepCopy
              # Cleaning
              db.title = ""
              db.content = ""
              db.kind = quote
              db.done = false
              db.attributes.clear()              
      
            # ---- Sections ----
            #sectionContent <- 
            sectionTitle <- >adoc.headerMark * >adoc.txt * adoc.crlf:
              db.title = $2#($2).strip
              db.kind = section
              db.attributes[":level"] = $(($1).len - 1)
              #db.attrisect.level = ($1).len - 1
              #sect.txt = ($2).strip 


            variables  <- ':' * +(1 - '\r' - '\n') * adoc.crlf

            section  <- +adoc.emptyorcomment * *(attributes | variables) * sectionTitle * *variables:
              blk.blocks &= db.deepCopy

              # Cleaning
              db.title = ""
              db.content = ""
              db.kind = quote
              db.done = false
              db.attributes.clear()

            # ALL BLOCKS
            blocks <- *(docheader | delimitedBlocks | citeBlock | section | listContinuationSymbol | listSeparator | listItem | listDescription | paragraph)


let parserBlocks* = parserBlocksGen()


# TODO: listContinuationSymbol
# (listItem | listDescriptionItem) * *(listContinuationSymbol * anyBlock)