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

proc parseAdoc*(text:string; folder: string = ""):ADoc =
  # PREPROCESSOR DIRECTIVES - include::target[...]
  # https://docs.asciidoctor.org/asciidoc/latest/directives/conditionals/
  # https://docs.asciidoctor.org/asciidoc/latest/directives/include/#include-processing
  #var lines = txt.splitLines
  debug("asciidoc.nim > proc parseAdoc: entering preprocessor")
  var txt = text
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


  # ===========================
  debug("asciidoc.nim > proc parseAdoc: starting parsing")
  # 1. Parse Doc Header
  var
    adoc:ADoc
    unorderedList:seq[string]   = @[]
    orderedList:seq[string]     = @[]
    descriptionList:seq[string] = @[]

  # After preprocessor
  var n = 0
  var flag = true
  variables.clear       # Reinit the table
  var currentLevel = 0  # Tracking the nesting level
  var blockLevels:seq[int] = @[]
  var blocks:seq[tuple[symbol:string;level:int]]   = @[]
  var isComment = false
  while txt.len > 0:
    if not isComment:
      flag = true
      var item:Table[string, string]    
      var dh:DocumentHeaderObj
      var res = parserDocumentHeader.match(txt, dh)
      #echo dh
      if res.ok:
        #echo dh
        adoc.docheader &= dh
        adoc.items &= (itDocHeader, adoc.docheader.high)
        #doc &= item
        flag = false
        txt =  txt[res.matchMax .. txt.high]

      #echo "--------->", flag
      #var flag = true

      # 1. Parse variables: this updates the table "variables"
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

      # 3. Parse list separator.
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
          currentLevel = blockLevels[blockLevels.high]
          blockLevels.delete(blockLevels.high)

      # 2. Parse list title
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

      # 3. Parse attributes.
      if flag:
        var attr:AttributesObj
        res = parserAttributes.match(txt, attr)

        if res.ok:
          adoc.attributes &= attr
          adoc.items &= (itAttributes, adoc.attributes.high)      
          flag = false
          txt =  txt[res.matchMax .. txt.high]  




      # 3. Parse list.        
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
          
  #[
      # if symbol[0] == '*' or symbol[0] == '-':
      #   it.typ = unordered
      #   if not (symbol in l.unorderedSymbols):
      #     l.unorderedSymbols &= symbol
      #     it.level = l.unorderedSymbols.high

      #   else:
      #     it.level = l.unorderedSymbols.find(symbol)
  ]#

          adoc.listItems &= listItem
          adoc.items &= (itListItem, adoc.listItems.high)      
          flag = false
          txt =  txt[res.matchMax .. txt.high]  


      # 4. Parse section
      if flag:
        var sect:SectionObj
        res = parserSection.match(txt, sect)
        if res.ok:
          adoc.sections &= sect
          adoc.items &= (itSection, adoc.sections.high)      
          flag = false
          txt =  txt[res.matchMax .. txt.high]  


      # 5. Break
      if flag:
        var b:BreakObj
        res = parserBreak.match(txt, b)
        if res.ok:
          adoc.breaks &= b
          adoc.items &= (itBreak, adoc.breaks.high)      
          flag = false
          txt =  txt[res.matchMax .. txt.high]  

      # 5. Paragraph
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
  
  return adoc
