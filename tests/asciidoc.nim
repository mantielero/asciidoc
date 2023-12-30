import std/[strutils, sets, strformat, setutils, tables, options]

type
  InlineContext* = enum
    Bold
    Italic
    Url

type
  Attribute = object
    first:string
    id:string
    role:string
    options:seq[string]
    values:OrderedTable[string, string]

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

  Block = object
    title:Option[string]
    fenceId:string
    typ:BlockType
    attrib:Option[Attribute]


type
  DocumentObj = object
    title:string
    attrib:Table[string,string]

  Document = ref DocumentObj
type
  Line = object
    txt:string
    comment:string
    # For blocks
    blocks:seq[Block] #Table[string, string]
    isBlockTitle:bool
    attrib:Option[Attribute]
    # For Document
    doc:Option[Document]

  #Document = object
  #  lines:seq[Line]


type
  LineContext* = enum
    EmptyLine
    Header
    BlockTitle

    # ID block
    BlockId

    # BlockParagraph
    BlockParagraph

  #Line = tuple[txt, comment:string, context:set[LineContext]]

const
  # Structural containers https://docs.asciidoctor.org/asciidoc/latest/blocks/delimited/#summary-of-structural-containers
  STRUCTURAL_BLOCKS = @[
    ("////", comment),
    ("====", example), 
    ("----", listing), 
    ("....", literal),
    ("--",   open), 
    ("****", sidebar),
    ("|===", table1),
    (",===", table2),
    (":===", table3),
    ("!===", table4),
    ("++++", pass),
    ("____", quote),
    ]

      

proc isNotLiteral(ctx:seq[Block]):bool =
  result = true
  for blk in ctx:
    if blk.typ == listing or blk.typ == literal:
      result = false

proc parseAttributes(txt:string):Attribute =
  var tmp = txt[1..<txt.high]
  var commaSeparated = tmp.split(',')
  var options:seq[string]
  var remain:string = commaSeparated[0]
  if '%' in remain:
    var tmp = remain.split('%')
    result.options = tmp[1..tmp.high]
    remain = tmp[0]
  
  if '.' in remain:
    var tmp = remain.split('.')
    result.role = tmp[1]
    remain = tmp[0]

  if '#' in  remain:
    var tmp = remain.split('#')
    result.id = tmp[1]
    remain = tmp[0]
  result.first = remain

  if commaSeparated.len > 1:
    for i in 1..commaSeparated.high:
      var tmp = commaSeparated[1].split('=')
      result.values[tmp[0]] = tmp[1]
  


# proc `$`(val:seq[Line]):string =
#   #result = ""
#   for line in val:
#     result &= line.txt & &" || {line.context}\n"

proc main =
  var txt = """

= Document Title 
:url-org: https://example.org/projects
:name-of-an-attribute:

This document provides...

== First section

.Mis comentarios
[#mi-id]  
////
Mi comentario
multilínea
////


[quote#mi-nuevo-id]
Es muy interesantes
cómo se puede crear un párrafo.

Saludos

[#rules.prominent%incremental]
* Work hard
* Play hard
* Be happy

====
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
====
"""
  var txtLines = txt.splitLines()
  var lines:seq[Line] = @[]

  # Structural block markers
  var context:seq[Block]
  var blockTitle = ""
  var blockAttributes:Attribute


  # FIRST PASS
  var lastDoc = -1  # Tracks the last Document entry detected
  for i,txtLine in txtLines:
    var line:Line
    line.txt = txtLine

    # Check for structural blocks delimiter
    for (beg, blockTyp) in STRUCTURAL_BLOCKS:
      if line.txt.startsWith(beg):
        var blk:Block
        blk.typ = blockTyp
        line.txt = line.txt[4 .. line.txt.high]
        if line.txt.len > beg.len:
          blk.fenceId = line.txt
          line.txt = ""
          # if context.isNotLiteral and blockTyp != comment:
          #   if blk.fenceId.len > 2:  
          #     var tmp = blk.fenceId.split("//", 1)
          #     blk.fenceId  = tmp[0]
          #     if tmp.len > 1:
          #       line.comment = tmp[1]


        # Update context
        if context.len > 0:
          if context[context.high] == blk:
            discard context.pop()
          else:
            context &= blk
        else:
          context &= blk

    # Split comments when not in literal
    if context.isNotLiteral and not line.txt.startsWith("///") and line.txt.startsWith("//"):
      #if line.txt.len > 2:
        var tmp = line.txt.split("//", 1)
        line.txt     = tmp[0]
        if tmp.len > 1:
          line.comment = tmp[1]

    # Right strip
    line.txt = line.txt.strip(false)


    # Attributes
    if line.txt.startsWith('[') and line.txt.endsWith(']'):
       line.attrib = some(parseAttributes(line.txt))
       line.txt = ""

    # Block title
    if line.txt.startsWith('.'):
      line.txt = line.txt[1..line.txt.high]
      line.isBlockTitle = true

    # Document attributes
    if line.txt.startsWith(":") and line.txt[1..line.txt.high].contains(":"):
      var tmp = line.txt[1..line.txt.high].split(':', 1)
      line.txt = ""
      if lastDoc > -1:
        lines[lastDoc].doc.get.attrib[tmp[0]] = tmp[1]
    else:
      lastDoc = -1  # This line needs to go before "Parsing document"

    # Parsing document
    if line.txt.startsWith("= "):
      var doc = Document(title:line.txt[2..line.txt.high])
      line.doc = some(doc)
      line.txt = ""
      lastDoc = i





    line.blocks = context
    #echo repr line          
    lines &= line 

      #line.checkBlockDelimiter(beg, ctx)

  # SECOND PASS
  # 1. Set block titles if any
  var remove:seq[int]
  for i in 0..lines.high:
    var line = lines[i]
    if line.isBlockTitle:
      var n = line.blocks.len
      var j = i+1
      while j < lines.high:
        if lines[j].attrib.isNone:
          if lines[j].blocks.len > n:
            lines[j].blocks[lines[j].blocks.high].title = line.txt.some
            lines[i].txt = ""
            remove &= i
          else:
            break
        j += 1

  # 2. Set attribs
  for i in 0..lines.high:
    var line = lines[i]
    if line.attrib.isSome:
      var n = line.blocks.len
      var j = i+1
      while j < lines.high:
        if lines[j].attrib.isNone:
          if lines[j].blocks.len > n:          
            lines[j].blocks[lines[j].blocks.high].attrib = line.attrib
            remove &= i
          else:
            break
        j += 1

  # Delete unnecesary lines
  for i in remove.high .. 0:
    #echo remove[i]
    lines.delete(remove[i])
  #for line in lines:



  # 
    
    # 1. Split the comment from the line
    #if not i.startsWith("////"):
    #  var tmp = i.split("//", 1) # No aplica a bloques verbatim.

#[     # Check if this is a header
    var tmp = i.split(' ', 1)
    var symbols = tmp[0].toHashSet
    if '=' in symbols and symbols.len == 1:
      line.context = line.context + {Header}
      #line.context &= Header

    # Check block delimiters
    if i.startsWith("////") and i.len == 4:
      line.context = line.context + {BlockDelimiterComment}

    # Check if empty line
    tmp = i.split("//",1)
    symbols = tmp[0].toHashSet
    if (symbols - [' ', '\t'].toHashSet).len == 0 and not (BlockDelimiterComment in line.context):
      line.context = line.context + {EmptyLine} ]#






  # Pretty printing
  for line in lines:
    echo "|" & line.txt & "|"
    if line.doc.isSome:
      echo ">> DOCUMENT TITLE: " & line.doc.get.title
      #line.doc.get.attrib
      echo "    " & $line.doc.get.attrib
    #if line.attrib.isSome:
      #echo "  Attribute:"
  #echo $lines
    if line.blocks.len > 0:
      echo "  " & "BLOCKS"
    for i in 0..line.blocks.high:
      echo "    ".repeat(i+1) & $line.blocks[i]

# proc main =
#   var a:seq[Node]
#   a &= ("Hola", {})
#   a &= ("Hola", {Bold})
#   echo a

main()
