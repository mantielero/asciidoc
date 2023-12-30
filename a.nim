# https://docs.asciidoctor.org/asciidoc/latest/

import std/[strutils, strformat]
#[ import npeg, tables

type Dict = Table[string, int] ]#

# https://docs.asciidoctor.org/asciidoc/latest/document-structure/
#[ type
  DocHeader = string
  DocBody = string
  Document* = ref object of RootObj
    header*: DocHeader  # the * means that `name` is accessible from other modules
    body: DocBody       # no * means that the field is hidden from other modules
 ]#


# AsciiDoc is line oriented
type
  AsciiString* = ref object of RootObj
    txt*:string
    header*:int
    attributeName*:string
    attributeValue*:string




proc `$`(val:AsciiString):string =
  result = "AsciiString\n"
  result &= &"  txt: {val.txt}\n"
  if val.header > 0:
    result &= &"  header: {val.header}\n"
  if val.attributeName != "":
    result &= &"  attributeName: {val.attributeName}\n"
    if val.attributeValue != "":
      result &= &"  attributeValue: {val.attributeValue}\n"
  

proc preprocess(txt:string):seq[AsciiString] =
  var tmp = txt.splitLines()
  for i in 0 .. high(tmp):
    result &= AsciiString( txt:  tmp[i].strip(leading = false), 
                           header: 0 )
  

# MAL: porque depende del contexto
proc parseHeader(line:var AsciiString) = 
  #for i in 0 .. high(doc):
  if line.txt.startsWith('#'):      
    var tmp = line.txt.strip(chars = {'#'})
    line.header = len(line.txt) - len(tmp)
    line.txt = tmp.strip()
      
proc parseAttribute(line:var AsciiString) =
  # https://docs.asciidoctor.org/asciidoc/latest/attributes/document-attributes/#where-are-document-attributes-defined-set-and-unset
  if line.txt.startsWith(':'):
    let words = line.txt.split(':', 2)
    if words.len == 3:
      line.attributeName = words[1]
      if words[2].len > 1:
        if words[2][0] == ' ':
          line.attributeValue = words[2].strip
    
    #if line.lsplt(':'):
      #line.attributeName = line[0 ..< line.high]


#let example1 = """This is a basic AsciiDoc document."""

# Split the document in blocks 
#[
let blocks = patt *(*"\n\n" * > +(1-"\n\n"))
let lines = patt *(*"\n" * > +(1-"\n"))

let tmp = blocks.match(example1).captures
echo tmp

let tmp1 = lines.match(tmp[1]).captures
echo tmp1
]#

#grammar "adoc":
#  blocks <- *(*"\n\n" * > +(1-"\n\n"))
#  lines = patt *(*"\n" * > +(1-"\n"))

#[ type
  Aline = string
  Ablock = object
    lines:seq[Aline]
  Adoc = object
    blocks:seq[Ablock] ]#


#[ let linesParser = peg("line", allLines:string):
  line <- > +(1-"\n"):
    allLines = $1 ]#

#[#
let linesParser = peg("myline", l:seq[string]):
  #ablock <- > (myline * *(myline)):
  #  l &= $1
  myline <- > (line | "\n"): #"This" * +(1):#
    l &= $1
  line <- +(1-'\n')
    #echo $1
]#
#[ let linesParser = peg("lines", l:seq[string]):
  #ablock <- *(*"\n\n" * lines)   # > *(*"\n\n" * > +(1-"\n\n")):
  #  l &= $1
  lines <- > *(> *(1-"\n") * "\n" ): #"This" * +(1):#
    l &= $0
    #l &= $1
  #line <- +(1-'\n')    
#let lines = peg("blocks", doc:Adoc):
  #blocks <- lines * *('\n' * lines)
  #
  #ablock <- +(nonemptyline - emptyline)
  #nonemptyline <- > +(1-'\n')
#  emptyline <- '\n'

#let  tmp2 = parser.match(tmp1).captures
#echo tmp2
var data:seq[string]
echo linesParser.match(example1, data).captures
echo data ]#


proc main =
  var example1 = """This is a basic AsciiDoc document.   
# My header

## Mysubheader
This document contains two paragraphs.   
Veamos   



"""
  var temp = example1.preprocess
  #for i in example1.preprocess:
  #  echo i
  #temp.markHeaders
  for i in temp:
    echo i

  #var line = AsciiString(txt:":prueba: valor")
  var line = AsciiString(txt:":prueba: valor")  
  line.parseAttribute()
  echo line

main()