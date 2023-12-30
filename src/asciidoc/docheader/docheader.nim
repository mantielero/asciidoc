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

  #headerMark <- +'='
  txt <- +(1 - '\r' - '\n')

  comment        <- "//" * noSlash * *txt * crlf
  emptyorcomment <- (emptyLine | comment)

  # Header
  title <- "= " * >txt * crlf:
    #
    #item[":type"]  = "docheader"
    #item[":level"] = &"{($1).len - 1}"
    item.level = 1
    #var title = ($2).strip
    #item[":title"] = &"{title}"
    item.title = ($1).strip

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
  key       <- ':' * +(1 - ':' - '\n' - '\r' - ' ') * ':'
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


