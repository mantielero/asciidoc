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

      # 3. Block Delimiter
      if flag:
        #debug("Found block delimiter:")
        var blockDelimiter:BlockDelimiterObj
        res = parserBlockDelimiter.match(txt, blockDelimiter)
        
        if res.ok:
          blockDelimiter.level = currentLevel
          if not (blockDelimiter.symbol in blocks):
            blockDelimiter.limitType = starting
            blocks &= (blockDelimiter.symbol, currentLevel)
            currentLevel += 1 # Increase the nesting
          else:
            blockDelimiter.limitType = ending
            #debug("deleting block delimiter")
            #debug("block: " & $blocks)
            var tmp:string
            var n = -1
            for j in 0..blocks.high:
              var blk = blocks[j]
              if blk.symbol == blockDelimiter.symbol:
                blockDelimiter.level = blk.level
                n = j
            blocks.delete( n )
            #debug("block: " & $blocks)             
            currentLevel = blockDelimiter.level - 1
            #blockDelimiter.level = currentLevel
          #blocks &= blockDelimiter.symbol
          
          adoc.blockDelimiters &= blockDelimiter
          adoc.items &= (itBlockDelimiter, adoc.blockDelimiters.high)      
          flag = false
          #debug(blockDelimiter)
          txt =  txt[res.matchMax .. txt.high]

          if blockDelimiter.typ == BlockType.comment and blockDelimiter.limitType == LimitType.starting:
            isComment = true
          #debug("TXT:" & txt)
          #debug("Found block delimiter:\n" & $blockDelimiter)

      # 4. Parse list separator.
      if flag:
        res = parserListSeparator.match(txt)
        if res.ok:
          adoc.items &= (itListSeparator, -1)    
          flag = false
          txt =  txt[res.matchMax .. txt.high]
          # TODO: find more conditions to init the lists 
          unorderedList   = @[]
          orderedList     = @[]
          descriptionList = @[]
          debug("LIST SEPARATOR")
          debug("blocklevels: " & $blockLevels)
          currentLevel = blockLevels[blockLevels.high]
          #blockLevels.delete(blockLevels.high)

      # 5. Parse list title
      if flag:
        var listTitle:ListTitleObj
        res = parserListTitle.match(txt, listTitle)
        
        if res.ok:
          listTitle.level = currentLevel
          blockLevels &= currentLevel
          currentLevel += 1 # Increase the nesting
          adoc.listTitles &= listTitle
          adoc.items &= (itListTitle, adoc.listTitles.high)      
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




      # 7. Parse list.        
      if flag:
        var listItemTmp:ListItemTmpObj
        res = parserListItem.match(txt, listItemTmp)

        if res.ok:
          var listItem:ListItemObj
          listItem.txt = listItemTmp.txt
          if listItemTmp.symbol in @["::",":::","::::",";;"]:
            listItem.typ = listDescription
            listItem.term = listItemTmp.term          
          elif listItemTmp.symbol.contains("*") or listItemTmp.symbol.contains("-"):
            listItem.typ = unordered
            if not (listItemTmp.symbol in unorderedList):
              unorderedList &= listItemTmp.symbol
              listItem.listLevel = unorderedList.high
              listItem.level = currentLevel
              currentLevel += 1
            else:
              listItem.listLevel = unorderedList.find(listItemTmp.symbol)
              listItem.level = currentLevel - (unorderedList.high - listItem.listLevel)  # FIXME

            
          elif listItemTmp.symbol.contains(".") or listItemTmp.symbol.contains("#"):
            listItem.typ = ordered                    
          


          adoc.listItems &= listItem
          adoc.items &= (itListItem, adoc.listItems.high)      
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


proc restructure(blk:var Block) =
  # Find max level
  var level = -1
  for b in blk.blocks:
    if b.kind == section:
      var lvl = b.attributes[":level"].parseInt 
      if lvl > level:
        level = lvl
  
  ## Gives a proper structure for sections
  #var currentLevel = -1
  #echo level
  var ids:seq[int]
  var deleteList:seq[int]
  var flag = true
  while flag:
    flag = false # we will stop when no more sections found
    # Check all blocks from end to start
    for i in 0..blk.blocks.high:
      var idx = blk.blocks.high - i
      var b = blk.blocks[idx]
      #echo idx, b.kind, "----"
      if b.kind == section: # a section
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
        ids &= idx

    for j in deleteList:
      blk.blocks.delete(j)
    deleteList = @[]

    ids = @[]      
    #  echo ids
    level -= 1
    if level == 1:
      flag = false
      

proc parserBlks(txt:string):Block =
  var blkDoc:Block
  new(blkDoc)
  #blkDoc.txt = @[]
  blkDoc.kind = document
  blkDoc.done = false
  var text = """
= Document Title (Level 0)

This is some text

== Level 1 Section Title

=== Level 2 Section Title

==== Level 3 Section Title

===== Level 4 Section Title

////
== Fake level 1 Section Title
////

====== Level 5 Section Title

== Another Level 1 Section Title
"""

  var res = parserBlocks.match(text, blkDoc)
  blkDoc.restructure()
  #echo res
  #echo blkDoc
  #if res.ok:
  #  echo res.captures
  
  #pb(blkDoc)
  #echo "????????????"
  echo blkDoc
  #echo "------------"

  return blkDoc





proc parseAdoc*(txt:var string; folder: string = "") =#:ADoc =
  # PREPROCESSOR DIRECTIVES - include::target[...]
  # https://docs.asciidoctor.org/asciidoc/latest/directives/conditionals/
  # https://docs.asciidoctor.org/asciidoc/latest/directives/include/#include-processing
  #var lines = txt.splitLines
  txt.preprocess(folder)


  var blk =  txt.parserBlks()
  
  #echo repr blk

  
  #return adoc


#[
LEVELS:
- 0: <body class="article">
- 1:    <div id="header">
- 1:    <div id="content">
          <div id="preamble">
- 2:        <div class="sectionbody">
- 2:      <div class="sect1">
]#