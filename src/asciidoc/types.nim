import std/[tables,strformat, logging]
import log


# Document Header
type
  AuthorObj* = object
    name*:string
    email*:string

  DocumentHeaderObj* = object
    level*:int
    title*:string
    authors*:seq[AuthorObj]
    revnumber*:string
    revdate*:string
    revremark*:string
    metadata*:OrderedTable[string, string] 
  
proc `$`*(dh:DocumentHeaderObj):string =
  result = &"Document Header: {dh.title}\n"
  result &= &"  - level: {dh.level}\n"
  result &= "  - authors:\n"
  for author in dh.authors:
    result &= &"    - {author.name} <{author.email}>\n"
  result &= "  - rev:\n"
  result &= &"    - number: {dh.revnumber}\n" 
  result &= &"    - date: {dh.revdate}\n" 
  result &= &"    - number: {dh.revremark}\n"      
  result &= "  - metadata:\n"
  for (key,value) in dh.metadata.pairs:
    result &= &"    - {key}: {value}\n"  

# List
type
  AttributesObj* = OrderedTable[string,string]

type
  ListTitleObj* = object
    level*:int
    title*:string

  ListItemType* = enum
    ordered
    unordered
    listDescription
  ListItemObj* = object
    level*:int
    listLevel*:int
    typ*:ListItemType
    term*:string
    txt*:string
    
  ListItemTmpObj* = object
    symbol*:string
    #typ*:ListItemType
    term*:string
    txt*:string


proc `$`(attr:AttributesObj):string =
  result = "Attributes:\n"
  for (key,value) in attr.pairs():
    result &= &"    - {key}: {value}\n"  

proc `$`*(lt:ListTitleObj):string =
  result = &"ListTitle: {lt.title}\n"
  result &= &"  - level: {lt.level}\n"

proc `$`*(item:ListItemObj):string =
  # result = &"List:\n"
  # result &= &"  - items: {v.items.len}\n"
  
  #for item in v.items:
  result = "List Item:\n"
  result &= &"  - level: {item.level}\n"
  result &= &"  - listLevel: {item.listLevel}\n"
  result &= &"  - typ: {item.typ}\n"
  if item.term != "":
    result &= &"  - term: {item.term}\n"
  result &= &"  - txt: {item.txt}\n"   


# Directives
# - includes
type
  IncludeObj* = object
    line*:string
    target*:string
    attributes*:OrderedTable[string,string]


proc `$`*(incl:IncludeObj):string =
  result = "Include:\n"
  result &= &"  - target: {incl.target}\n"
  result &= &"  - attributes:\n"
  for (key,value) in incl.attributes.pairs():
    result &= &"    - {key}: {value}\n"

# Sections
type
  SectionObj* = object
    level*:int
    txt*:string
    attrib*:OrderedTable[string,string]

proc `$`*(sect:SectionObj):string =
  result = "Section:\n"
  result &= &"  - level: {sect.level}\n"
  result &= &"  - txt: {sect.txt}\n"
  result &= "  - attrib:\n"
  for (key,value) in sect.attrib.pairs():
    result &= &"    - {key}:{value}\n"


# Paragraph
type
  ParagraphObj* = object
    level*: int
    lines*: seq[string]
    attrib*:OrderedTable[string,string]    

proc `$`*(sect:ParagraphObj):string =
  result = "Paragraph:\n"
  result &= &"  - level: {sect.level}\n"
  result &= "  - lines:\n"
  for line in sect.lines:
    result &= &"    - {line}\n"
  result &= "  - attrib:\n"
  for (key,value) in sect.attrib.pairs():
    result &= &"    - {key}:{value}\n"


type
  BlockType* = enum
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
  LimitType* = enum
    starting
    ending
  BlockDelimiterObj* = object
    level*:int
    symbol*:string
    typ*:BlockType
    limitType*:LimitType
    # title*:string
    # id*:string
    # roles*:seq[string]
    # attributes*:OrderedTable[string,string]
    # txt*:string
    # typ*:BlockType

proc `$`*(bl:BlockDelimiterObj):string =
  result = "BlockDelimiter:\n"
  result &= &"  - level: {bl.level}\n"
  result &= &"  - symbol: {bl.symbol}\n"  
  result &= &"  - typ: {bl.typ}\n"  
  result &= &"  - limitType: {bl.limitType}\n"  


# Breaks
type
  BreakObj* = object
    level*: int
    symbol*:string
    isPageBreak*:bool = false

proc `$`*(b:BreakObj):string =
  result = "Break:\n"
  result &= &"  - symbol: {b.symbol}\n"
  result &= &"  - isPageBreak: {b.isPageBreak}\n"

# ADoc
type
  ItemType* = enum
    itDocHeader
    itListItem
    itListTitle
    itAttributes
    itIncludes
    itSection
    itParagraph
    itBreak
    itListSeparator
    itBlockDelimiter
    itCommentOrEmpty

  Adoc* = object
    items*:seq[tuple[kind:ItemType, n:int]]
    attributes*:seq[AttributesObj]
    docheader*:seq[DocumentHeaderObj]
    listTitles*:seq[ListTitleObj]
    listItems*:seq[ListItemObj]
    #listSeparator*:seq[ListSeparator]
    includes*:seq[IncludeObj]
    sections*:seq[SectionObj]
    paragraphs*:seq[ParagraphObj]
    breaks*:seq[BreakObj]
    blockDelimiters*:seq[BlockDelimiterObj]

proc `$`*(doc:Adoc):string =
  #debug("types.nim > proc `$`*(doc:Adoc): start")
  # for item in doc.items:
  #   debug(item)
  for item in doc.items:
    if item.kind == itDocHeader:
      #debug("types.nim > proc `$`*(doc:Adoc): start itDocHeader")      
      result &= $doc.docheader[item.n] & "\n"
      #debug("types.nim > proc `$`*(doc:Adoc): end itDocHeader")       
    elif item.kind == itListTitle:
      #debug("types.nim > proc `$`*(doc:Adoc): start itListTitle")        
      result &= $doc.listTitles[item.n] & "\n" 
      #debug("types.nim > proc `$`*(doc:Adoc): end itListTitle")      
    elif item.kind == itAttributes:
      #debug("types.nim > proc `$`*(doc:Adoc): start itAttributes")        
      result &= $doc.attributes[item.n] & "\n" 
      #debug("types.nim > proc `$`*(doc:Adoc): end itAttributes") 
    elif item.kind == itListItem:
      #debug("types.nim > proc `$`*(doc:Adoc): start itList")      
      #debug("doc.lists.len:" & $doc.lists.len & "   item.n:" & $item.n)
      #for i in doc.lists:
      #  debug(i)
      result &= $doc.listItems[item.n] & "\n"
      #debug("types.nim > proc `$`*(doc:Adoc): end itList")       
    #elif item.kind == itIncludes:
    #  result &= $doc.includes[item.n] & "\n" 
    elif item.kind == itSection:
      #debug("types.nim > proc `$`*(doc:Adoc): start itSection")       
      result &= $doc.sections[item.n] & "\n"  
      #debug("types.nim > proc `$`*(doc:Adoc): end itList")         
    elif item.kind == itParagraph:
      #debug("types.nim > proc `$`*(doc:Adoc): start itParagraph")       
      result &= $doc.paragraphs[item.n] & "\n" 
      #debug("types.nim > proc `$`*(doc:Adoc): end itParagraph")       
    elif item.kind == itBreak:
      #debug("types.nim > proc `$`*(doc:Adoc): start itParagraph")       
      result &= $doc.breaks[item.n] & "\n"   
      #debug("types.nim > proc `$`*(doc:Adoc): end itParagraph")  
    elif item.kind == itListSeparator:
      #debug("types.nim > proc `$`*(doc:Adoc): start itListSeparator")       
      result &= "ListSeparator.\n\n"  
      #debug("types.nim > proc `$`*(doc:Adoc): end itListSeparator")    
    elif item.kind == itBlockDelimiter:
      result &= $doc.blockDelimiters[item.n] & "\n"           

  #debug("types.nim > proc `$`*(doc:Adoc): end")      