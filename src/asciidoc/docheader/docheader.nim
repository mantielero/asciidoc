#[
Document Header
https://docs.asciidoctor.org/asciidoc/latest/document/header/

]#
import npeg
import ../types
import std/[strutils, strformat, tables]
#import ../types







#let parserDocumentHeader* = peg("header", item: Table[string, string]):
let parserDocumentHeader* = peg("header", item: DocumentHeaderObj):
  crlf        <- ?'\r' * '\n' # 0 or 1 '\r'; then 1 '\n'
  emptyLine   <- *' ' * crlf  # 0 or many spaces; then crlf
  noSlash     <- &!'/'        # 1 not '/' but it doesn't consume any character

  headerMark <- +'='
  txt <- +(1 - '\r' - '\n')

  comment        <- "//" * noSlash * *txt * crlf
  emptyorcomment <- (emptyLine | comment)

  # Header
  title <- >headerMark * +Space * >txt * crlf:
    #
    #item[":type"]  = "docheader"
    #item[":level"] = &"{($1).len - 1}"
    item.level = ($1).len - 1
    #var title = ($2).strip
    #item[":title"] = &"{title}"
    item.title = ($2).strip

  # Author
  authorName  <- +(1 - '<' - ';' - '\r' - '\n')
  authorEmail <- '<' * +(1 - '<' - '>') * '>'
  author <- >authorName * ?(>authorEmail) * ?';':
    # var n = -1
    # for i in item.keys():
    #   if i.startsWith(":authorName"):
    #     var tmp = (i.split(":authorName")[1]).parseInt
    #     if tmp > n:
    #       n = tmp
    # n += 1
    # item[&":authorName{n}"] = ($1).strip
  
    var name = ($1).strip
    var email:string
    if capture.len == 3:
      email = ($2)[1 ..< ($2).high].strip       
    
    item.authors &= AuthorObj( name: name, email: email )
  
  authors <- +author * *(1 - '\r' - '\n') * crlf

  # Revision https://docs.asciidoctor.org/asciidoc/latest/document/revision-information/
  revnumber <- >(Digit * *(Digit | '.')):
    item.revNumber = ($1).strip
  revdate   <- >(+Digit * '-' * +Digit * '-' * +Digit):
    item.revDate   = ($1).strip
  revremark <- >(+(1 - '\n' - '\r')):
    item.revRemark = ($1).strip
  revinfo <- ?'v' * revnumber * ?(',' * *Space * >revdate * ?(':' * *Space * >revremark)) * crlf

    
  # Attributes https://docs.asciidoctor.org/asciidoc/latest/document/metadata/
  #lineContinuation <- " \\" * crlf
  key       <- ':' * +(1 - ':' - '\n' - '\r' - ' ') * ':'
  #line      <- +(1 - (?" \\"  * ?'\r' * '\n')) * crlf #+(1 - '\r' - '\n') * crlf
  #line <- (+(1-lineContinuation - '\r' - '\n') | lineContinuation) * crlf
  #line <- (1 - lineContinuation - crlf | lineContinuation) * crlf  
  #lineCont  <- @lineContinuation#!lineContinuation * lineContinuation
  crlfcont <- (1 - ' ') * (1 - '\\') * ?'\r' * '\n'
  value     <- @crlfcont#+lineCont * line  | line):  #lineCont #(line )| +lineCont * line ) 
    #echo ">",$0,"<"
  attribute <- >key * >(crlf | value): # a key with an optional value
    var key = ($1)[1 ..< ($1).high]
    #echo "key: ", key

    var value = if capture.len == 3:
                 ($2).strip()
                else:
                  ""
    #echo "value: ", value
    item.metadata[key] = value
  attributes <- *attribute

  # Content

  header <- *emptyorcomment * title * authors * revinfo * attributes * emptyLine 




#[ 
let parserDocumentHeader2* = peg("header", h: AsciiDocItem):
  crlf        <- ?'\r' * '\n' # 0 or 1 '\r'; then 1 '\n'
  emptyLine   <- *' ' * crlf  # 0 or many spaces; then crlf
  noSlash     <- &!'/'          # 1 not '/' but it doesn't consume any character

  headerMark <- +'='
  txt <- +(1 - '\r' - '\n')

  comment        <- "//" * noSlash * *txt * crlf
  emptyorcomment <- (emptyLine | comment)

  # Header
  title <- >headerMark * +Space * >txt * crlf:
    h.level = ($1).len - 1
    h.title = ($2).strip

  # Author
  authorName  <- +(1 - '<' - ';' - '\r' - '\n')
  authorEmail <- '<' * +(1 - '<' - '>') * '>'
  author <- >authorName * ?(>authorEmail) * ?';':
    var name = ($1).strip
    var email = if capture.len == 3:
                 ($2)[1 ..< ($2).high].strip
                else:
                  ""    
    h.authors &= AuthorObj( name: name, email: email)
  
  authors <- +author * *(1 - '\r' - '\n') * crlf

  # Revision https://docs.asciidoctor.org/asciidoc/latest/document/revision-information/
  revnumber <- >(Digit * *(Digit | '.')):
    h.revnumber = ($1).strip
  revdate   <- >(+Digit * '-' * +Digit * '-' * +Digit):
    h.revdate   = ($1).strip
  revremark <- >(+(1 - '\n' - '\r')):
    h.revremark = ($1).strip
  revinfo <- ?'v' * revnumber * ?(',' * *Space * >revdate * ?(':' * *Space * >revremark)) * crlf

    
  # Attributes https://docs.asciidoctor.org/asciidoc/latest/document/metadata/
  lineContinuation <- '\\' * *' ' * crlf
  key       <- ':' * +(1 - ':' - '\n' - '\r' - ' ') * ':'
  line      <- +(1 - '\n' - '\r' - '\\') 
  lineCont  <- line * lineContinuation
  value     <- (+lineCont * line | line) 
  attribute <- >key * ?(>value) * crlf: # a key with an optional value
    #echo $0
    var key = ($1)[1 ..< ($1).high]
    var value = if capture.len == 3:
                 ($2).strip()
                else:
                  ""
    h.metadata &= AttributeObj(
      key: key, 
      value: value) 
  attributes <- *attribute

  # Content

  header <- *emptyorcomment * title * authors * revinfo * attributes * emptyLine 
 ]#

# proc main() =
#   var txt = """  
# //
# //Prueba 1
   
# //prueba2
# = Document Title
# Author Name <author@email.org>; Jose Maria; Hello You <hello@example.org>
# v2.0, 2019-03-22: this is a remark
# :toc:
# :homepage: https://example.org
# :description: A story chronicling the inexplicable \ 
# hazards and unique challenges a team must vanquish \
# on their journey to finding an open source \
# project's true power.

# This document provides..."""  
 
#   var
#     doc:seq[Table[string,string]]
#   echo "--------------"    
#   echo txt
#   echo "--------------"
#   let res = parserDocumentHeader.match(txt, doc)#.ok
#   echo $doc


# main()