import std/[tables,strformat]


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
  ListItemType* = enum
    ordered
    unordered
  ItemObj* = object
    level*:int
    typ*:ListItemType
    txt*:seq[string]

  ListObj* = object
    title*:string
    unorderedSymbols*:seq[string]
    orderedSymbols*:seq[string]
    attrib*:OrderedTable[string,string]
    items*:seq[ItemObj]

proc `$`*(v:ListObj):string =
  result = &"List: {v.title}\n"
  result &= "  - attrib:\n"
  for (key,value) in v.attrib.pairs():
    result &= &"    - {key}: {value}\n"
  result &= "  - items:\n"
  for item in v.items:
    result &= &"    - level: {item.level}\n"
    result &= &"      typ: {item.typ}\n"    
    result &= &"      txt: {item.txt}\n"   


# Directives
# - includes
type
  IncludeObj* = object
    target*:string
    attributes*:OrderedTable[string,string]

proc `$`*(incl:IncludeObj):string =
  result = "Include:\n"
  result &= &"  - target: {incl.target}\n"
  result &= &"  - attributes:\n"
  for (key,value) in incl.attributes.pairs():
    result &= &"    - {key}: {value}\n"

# ADoc
type
  ItemType* = enum
    itDocHeader
    itList
    itIncludes
  Adoc* = object
    items*:seq[tuple[kind:ItemType, n:int]]
    docheader*:seq[DocumentHeaderObj]
    lists*:seq[ListObj]
    includes*:seq[IncludeObj]

proc `$`*(doc:Adoc):string =
  for item in doc.items:
    if item.kind == itDocHeader:
      result &= $doc.docheader[item.n] & "\n"
    elif item.kind == itList:
      result &= $doc.lists[item.n] & "\n" 
    elif item.kind == itIncludes:
      result &= $doc.includes[item.n] & "\n" 

  