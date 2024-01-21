# nim c -r --deepcopy:on test_ex_01 &&   tidy -i --indent-spaces 2  -quiet --tidy-mark no ex01.html > ex01_new.html
# nim js -r -d:nodejs -d:release asciidoctor
import std/[tables, strformat, strutils, os]
import npeg
import asciidoc/[types, log]
#import asciidoc/parser/grammar/[adocgrammar]
import asciidoc/parser/attributes/[attributes]
import asciidoc/parser/docheader/[docheader]
import asciidoc/parser/lists/[lists]
#import asciidoc/directives/[includes]
import asciidoc/parser/sections/[sections]
import asciidoc/parser/paragraph/[paragraph]
import asciidoc/parser/breaks/[breaks]
import asciidoc/parser/preprocessor/[includes,variables]
import asciidoc/parser/blocks/[blocks]
import asciidoc/parser/comment/[comment]
import asciidoc/exporters/html/[html]
#export types
import karax / [vdom]

#export types # Needed by 
export vdom  # Needed by the example
export html
export types # Needed for the tests


proc `in`(val:string; values:seq[tuple[symbol:string;level:int]]):bool =
  for (s,l) in values:
    if s == val:
      return true
  return false


proc preprocess(txt:var string; folder:string) =
  debug("asciidoc.nim - preprocess: entering")
  #var txt = text
  var backupTxt = txt
  var variables:Table[string,string]
  var includes:Table[string,string]
  var nn = 0
  while txt.len > 0:
    var flag = true
    # Parse variables
    var res = parserVariables.match(txt, variables)    
    if res.ok:
      flag = false
      txt =  txt[res.matchMax .. txt.high]
      #echo variables 

    # Parse includes
    var incl:IncludeObj
    res = parserIncludes.match(txt, incl)

    # TODO: probably this needs to be done only for .adoc, .asc, .asciidoc, ...
    if res.ok:
      flag = false
      txt =  txt[res.matchMax .. txt.high]

      var tmp = parserSubs.match(incl.target).captures
      #echo variables
      for i in tmp:
        incl.target = incl.target.replace("{" & i & "}", variables[i])
      
      # Now we need to refer to the location where the original file is located
      if folder != "":
        incl.target = folder / incl.target

      # Try to read the file
      var fileTxt = ""
      try:
        var fileTxt = readFile(incl.target)

      except IOError:
        echo "Failed to read file: " & incl.target

      #txt =  txt[res.matchMax .. txt.high]
      if fileTxt != "":
        if not fileTxt.endsWith('\n'):
          fileTxt &= '\n'
      includes[incl.line] = fileTxt

    if flag:
      if '\n' in txt:
        txt = txt.split('\n',1)[1]
      else:
        break

  txt = backupTxt
  for (line,value) in includes.pairs:
    txt = txt.replace(line, value)
  debug("asciidoc.nim - preprocess: leaving")

proc postProcess(blk:Block) =
  if blk.kind == BlckType.paragraph:
    if blk.content.startsWith(" "):
      blk.kind = BlckType.literal
  if blk.blocks.len > 0:
    for b in blk.blocks:
      b.postProcess

#[ proc parser(txt:var string):ADoc =
  debug("asciidoc.nim: entering parser")
  # 1. Parse Doc Header  
  var
    adoc:ADoc
    unorderedList:seq[string]   = @[]
    orderedList:seq[string]     = @[]
    descriptionList:seq[string] = @[]

  # After preprocessor
  var n = 0
  var flag = true
  var variables:Table[string,string]
  var currentLevel = 0  # Tracking the nesting level
  var blockLevels:seq[int] = @[]
  var blocks:seq[tuple[symbol:string;level:int]]   = @[]
  var isComment = false
  while txt.len > 0:
    # ==== Not in a comment block ====
    if not isComment:
      
      flag = true
      # 1. Looking for Document Header
      var item:Table[string, string]    
      var dh:DocumentHeaderObj
      var res = parserDocumentHeader.match(txt, dh)
      #echo dh
      if res.ok:
        adoc.docheader &= dh
        adoc.items &= (itDocHeader, adoc.docheader.high)
        flag = false
        txt =  txt[res.matchMax .. txt.high]
        currentLevel += 1


      # 2. Parse variables: this updates the table "variables"
      res = parserVariables.match(txt, variables)    
      if res.ok:
        flag = false
        txt =  txt[res.matchMax .. txt.high]



      # 6. Parse attributes.
      if flag:
        var attr:AttributesObj
        res = parserAttributes.match(txt, attr)

        if res.ok:
          adoc.attributes &= attr
          adoc.items &= (itAttributes, adoc.attributes.high)      
          flag = false
          txt =  txt[res.matchMax .. txt.high]  


      # 8. Parse section
      if flag:
        var sect:SectionObj
        res = parserSection.match(txt, sect)
        if res.ok:
          adoc.sections &= sect
          adoc.items &= (itSection, adoc.sections.high)      
          flag = false
          txt =  txt[res.matchMax .. txt.high]  


      # 9. Break
      if flag:
        var b:BreakObj
        res = parserBreak.match(txt, b)
        if res.ok:
          adoc.breaks &= b
          adoc.items &= (itBreak, adoc.breaks.high)      
          flag = false
          txt =  txt[res.matchMax .. txt.high]  

      # 10. Paragraph
      if flag:
        var para:ParagraphObj
        res = parserParagraph.match(txt, para)
        if res.ok:
          #echo list
          para.level = currentLevel
          adoc.paragraphs &= para
          adoc.items &= (itParagraph, adoc.paragraphs.high)      
          flag = false
          # if para.lines[0].contains("First paragraph"):
          #   echo "FROM|" & txt & "|"

          #txt =  txt[res.matchMax .. txt.high]  
          txt =  txt[res.matchLen .. txt.high] 
          # if para.lines[0].contains("First paragraph"):
          #   echo "  TO|" & txt & "|"  

      if flag:
        res = parserCommentOrEmpty.match(txt)  
        if res.ok:
          #echo list
          # para.level = currentLevel
          # adoc.paragraphs &= para
          # adoc.items &= (itParagraph, adoc.paragraphs.high)      
          flag = false
          # if para.lines[0].contains("First paragraph"):
          #   echo "FROM|" & txt & "|"

          #txt =  txt[res.matchMax .. txt.high]  
          txt =  txt[res.matchLen .. txt.high] 

    # ==== In a comment block ====
    else: # It is a comment
      var res = parserCommentedLine.match(txt)
      if res.ok:
        flag = false
        txt =  txt[res.matchLen .. txt.high]
      else:
        isComment = false


    #echo "FLAG: ", flag
    if flag:
      break

  
  if flag:
    error(&"""BREAKING SINCE NOT IMPROVING. Remaining text:
{txt}
""")
  debug("asciidoc.nim: leaving parser")
 ]#

proc pb(myBlock:Block) =
  # If not done, process content
  if not myBlock.done:
    var b:Block = myBlock
    var res = parserBlocks.match( myBLock.content, b)
    #echo res
    #for i in 0 .. myBlock.blocks.high:
    for b in myBlock.blocks:
      pb(b)
    # if myBlock.blocks.len > 0:
    #   for i in 0..myBlock.blocks.high:
    #     var b = myBlock.blocks[i]
    #     var txt = b.content
    #     #echo txt
    #     var res = parserBlocks.match( txt, b)


proc restructure(blk:var Block; kind:BlckType = section) =
  ## nesting sections (by default) and lists 
  
  # Find max level
  var level = -1
  for b in blk.blocks:
    if b.kind == kind:
      var lvl = b.attributes[":level"].parseInt 
      if lvl > level:
        level = lvl
  
  # Gives a proper parent-child structure for sections and lists
  var ids:seq[int]
  var deleteList:seq[int]
  var flag = true
  while flag:
    flag = false # we will stop when no more sections found
    # Check all blocks from end to start
    for i in 0..blk.blocks.high:
      var idx = blk.blocks.high - i
      var b = blk.blocks[idx]

      if b.kind == kind: # a section or a listItem
        var lvl = b.attributes[":level"].parseInt
        flag = true

        # There are children
        if ids.len > 0:        
          for j in 0..ids.high:
            var n = ids.high - j
            b.blocks &= blk.blocks[ids[n]]
          
          deleteList &= ids
          ids = @[]

        # If no children:
        elif lvl == level:
          ids &= idx
        elif lvl < level:
          ids = @[]
        
      else: # Not a section
        if kind == listItem and b.kind == listSeparator:
          ids = @[]
        else:
          ids &= idx

    for j in deleteList:
      blk.blocks.delete(j)
    deleteList = @[]

    ids = @[]      
    #  echo ids
    level -= 1
    if level == 1:
      flag = false


proc listNesting(blk:var Block) =
  ## nesting listItems 
  ## FIXME: Literal Paragraph
  var idx = blk.blocks.high
  var lastTyp   = ""
  var lastLevel = -1
  while idx != 0:
    var kind = blk.blocks[idx].kind 
    if kind == listItem:
      var itemTyp   = blk.blocks[idx].attributes[":listType"]
      var itemLevel = blk.blocks[idx].attributes[":level"]
      var idx2 = idx-1
      while idx2 != 0:
        if blk.blocks[idx2].kind == listItem: 
          var prevTyp   =  blk.blocks[idx2].attributes[":listType"]
          var prevLevel =  blk.blocks[idx2].attributes[":level"]      
          if itemTyp != prevTyp:
            blk.blocks[idx2].blocks.insert(blk.blocks[idx], 0) 
            blk.blocks.delete(idx)
            break
          elif itemTyp == prevTyp:
            if itemLevel > prevLevel:
              blk.blocks[idx2].blocks.insert(blk.blocks[idx], 0) 
              blk.blocks.delete(idx)
              break
        else:
          break
        idx2 -= 1

    # Automatic continuation for literal block
    elif kind == literal:
      var idx2 = idx-1
      if blk.blocks[idx2].kind == listItem:
        blk.blocks[idx2].blocks.insert(blk.blocks[idx], 0) 
        blk.blocks.delete(idx)        



    idx -= 1



proc restructureList(blk:Block) =
  # Calculates the level for the list
  var unorderedSymbols:seq[string]
  var orderedSymbols:seq[string]
  var dlistSymbols:seq[string]  
  for b in blk.blocks:
    # Unordered/Ordered case
    if b.kind == listItem:
      var symbol = b.attributes[":symbol"]
      # Unordered list
      if symbol.contains('*') or symbol.contains('-'):
        b.attributes[":listType"] = "unordered"
        if not (symbol in unorderedSymbols):
          unorderedSymbols &= symbol
          b.attributes[":level"] = $(unorderedSymbols.high + 1)
        else:
          var n = unorderedSymbols.find(symbol)
          if n < unorderedSymbols.high and unorderedSymbols.high > 1:
            for i in (n+1)..unorderedSymbols.high:
              unorderedSymbols.delete(n+1)
          b.attributes[":level"] = $(n+1)
      
      # Ordered list
      elif symbol.contains('.') or symbol.contains('#'):
        b.attributes[":listType"] = "ordered"        
        if not (symbol in orderedSymbols):
          orderedSymbols &= symbol       
          b.attributes[":level"] = $(orderedSymbols.high + 1) 
        else:
          b.attributes[":level"] = $(orderedSymbols.find(symbol) + 1)

    # Description list case
    elif b.kind == listDescriptionItem:
      var symbol = b.attributes[":symbol"]
      b.attributes[":listType"] = "dlist"
      if not (symbol in dlistSymbols):  # if symbol not in the list, we add it
        dlistSymbols &= symbol      
        b.attributes[":level"] = $(dlistSymbols.high + 1)
      else:
        var n = dlistSymbols.find(symbol)
        # if we reduce the level, we "forget" the higher level symbols
        if n < dlistSymbols.high and dlistSymbols.high > 1:
          for i in (n+1)..dlistSymbols.high:
            dlistSymbols.delete(n+1)
        b.attributes[":level"] = $(n+1)
      b.kind = listItem    

    # restart the list if "listSeparator" found 
    elif b.kind == listSeparator:
      unorderedSymbols = @[]
      orderedSymbols   = @[]  
      dlistSymbols     = @[]   

  # Continuation Symbol: if followed by continuation symbol (+)
  # adds the next block as a child
  var deleteList:seq[int]
  var flag = true
  while flag:
    flag = false
    for i in 0..<blk.blocks.high:
      if blk.blocks[i+1].kind == listContinuationSymbol:
        blk.blocks[i].blocks &= blk.blocks[i+2]
        deleteList &= i+2
        deleteList &= i+1
        flag = true
        break
    for i in deleteList:
      blk.blocks.delete(i)
    deleteList = @[] 



proc groupList(blk:Block) = 
  # Convert listSeparators into "list"
  var idx = 0
  while idx < blk.blocks.high:
    var b = blk.blocks[idx]
    if b.kind == listSeparator:
      b.kind = list
    idx += 1

  # Group in lists
  idx = 0
  while idx < blk.blocks.high:
    var b = blk.blocks[idx]

    if b.kind in @[listTitle, list]:
      b.kind = list
      idx += 1

      # Put all the following listItem's into the list
      while blk.blocks[idx].kind == listItem:# and idx < blk.blocks.high:
        b.blocks &= blk.blocks[idx]
        blk.blocks.delete(idx)
        
        if idx > blk.blocks.high: # end of blocks reached
          break
    
    # elif not (b.kind in @[listTitle, listItem]):
    #   var b2:Block
    #   new(b2)
    #   b2.kind = list
    #   blk.blocks.insert(b2, idx+1)
      #if b2.kind == listItem and not isList:
    #idx += 1

 

proc parserBlks(txt:string):Block =
  var blkDoc:Block
  new(blkDoc)
  #blkDoc.txt = @[]
  blkDoc.kind = document
  blkDoc.done = false

  var res = parserBlocks.match(txt, blkDoc)
  blkDoc.postProcess
  blkDoc.restructureList
  blkDoc.listNesting
  echo blkDoc
  blkDoc.groupList()

  blkDoc.restructure(section)

  return blkDoc





proc parseAdoc*(txt:var string; folder: string = ""):Block = # ADoc =
  # PREPROCESSOR DIRECTIVES - include::target[...]
  # https://docs.asciidoctor.org/asciidoc/latest/directives/conditionals/
  # https://docs.asciidoctor.org/asciidoc/latest/directives/include/#include-processing
  #var lines = txt.splitLines
  txt.preprocess(folder)


  var blk =  txt.parserBlks()
  #echo blk
  #echo repr blk

  
  return blk


#[
LEVELS:
- 0: <body class="article">
- 1:    <div id="header">
- 1:    <div id="content">
          <div id="preamble">
- 2:        <div class="sectionbody">
- 2:      <div class="sect1">
]#

# CLI part

when isMainModule:
  import cligen/argcvt, cligen
  proc asciidoc(adocName:string = "../examples/ex_01.adoc";
             outputName:string = "ex01.html") =
    var adocTxt = readFile(adocName)
    var blocks = parseAdoc(adocTxt, "../examples/")
    echo blocks

    var adocHtml = blocks.convertToHtml
    outputName.writeFile( "<!DOCTYPE html>\n" & ($adocHtml).string )
  dispatch asciidoc