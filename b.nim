# https://docs.asciidoctor.org/asciidoc/latest/

#import npeg, strutils, tables
import strutils


type
  Context = enum
    cCompound, cSimple, cVerbatim, cRaw, cEmpty
  Ablock = object
    context:Context
    


#type Dict = Table[string, int]

#[
type
  DocHeader = string
  DocBody = string
  Document* = ref object of RootObj
    header*: DocHeader  # the * means that `name` is accessible from other modules
    body: DocBody       # no * means that the field is hidden from other modules
]#

let example1 = """This is a basic AsciiDoc document.

This document contains two paragraphs.
Veamos



"""

proc splitDocument(data:string):seq[seq[string]] =
  ## split in blocks and each block in lines
  var blocks: seq[seq[string]]
  for aBlock in data.split("\n\n"):
    if aBlock != "":
      blocks &= aBlock.splitLines()  
  return blocks

echo splitDocument(example1)



