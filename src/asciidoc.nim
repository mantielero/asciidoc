# nim js -r -d:nodejs -d:release asciidoctor
import std/[tables,strformat,strutils]
import npeg
import asciidoc/[types]
import asciidoc/docheader/[docheader]
import asciidoc/lists/[lists]
#import asciidoc/directives/[includes]
import asciidoc/sections/[sections]
import asciidoc/paragraph/[paragraph]
import asciidoc/breaks/[breaks]
import asciidoc/preprocessor/[includes,variables]

import asciidoc/exporters/html/[html]
export types
import karax / [vdom]

export html, vdom

proc parseAdoc*(txt:var string):ADoc =
  # PREPROCESSOR DIRECTIVES - include::target[...]
  # https://docs.asciidoctor.org/asciidoc/latest/directives/conditionals/
  # https://docs.asciidoctor.org/asciidoc/latest/directives/include/#include-processing
  #var lines = txt.splitLines
  var backupTxt = txt
  var variables:Table[string,string]
  var includes:Table[string,string]
  var nn = 0
  while txt.len > 0:
    var flag = true
    # Parse variables
    var res = parserAttributes.match(txt, variables)    
    if res.ok:
      flag = false
      txt =  txt[res.matchMax .. txt.high]
      #echo variables 

    # Parse includes
    var incl:IncludeObj
    res = parserIncludes.match(txt, incl)

    if res.ok:
      flag = false
      txt =  txt[res.matchMax .. txt.high]

      #echo incl.target
      var tmp = parserSubs.match(incl.target).captures
      echo variables
      for i in tmp:
        incl.target = incl.target.replace("{" & i & "}", variables[i])
      echo incl

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

  # =====
  txt = backupTxt
  for (line,value) in includes.pairs:
    txt = txt.replace(line, value)


  # ===========================

  # 1. Parse Doc Header
  var
    adoc:ADoc
    #doc:seq[Table[string,string]]
    

  # After preprocessor
  var n = 0
  var flag = true
  variables.clear #newTable[string,string]() # Reiniciamos
  while txt.len > 0:
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

    # Parse variables
    res = parserAttributes.match(txt, variables)    
    if res.ok:
      flag = false
      txt =  txt[res.matchMax .. txt.high]
    # 2. Parse includes
    # if flag:
    #   var incl:IncludeObj
    #   # echo "-------------------------------"
    #   # echo txt
    #   res = parserIncludes.match(txt, incl)
    #   if res.ok:
    #     #echo list
    #     adoc.includes &= incl
    #     adoc.items &= (itIncludes, adoc.includes.high)      
    #     flag = false
    #     txt =  txt[res.matchMax .. txt.high]  

    # 3. Parse list.
    if flag:
      var list:ListObj
      #echo "----PARSING IN LIST----"
      #echo txt
      #echo "-----------------------"
      res = parserList.match(txt, list)
      if res.ok:
        # echo ">>>>"
        # echo list
        # echo "<<<<"
        adoc.lists &= list
        adoc.items &= (itList, adoc.lists.high)      
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
        adoc.paragraphs &= para
        adoc.items &= (itParagraph, adoc.paragraphs.high)      
        flag = false
        txt =  txt[res.matchMax .. txt.high]  
    
    #echo "FLAG: ", flag
    if flag:
      break

  #echo adoc
  #echo adoc.items[adoc.items.high]
  
  if flag:
    echo "============================"
    echo "BREAKING SINCE NOT IMPROVING"
    echo "============================"
    echo txt
    echo "----------------------------"
  
  return adoc

# when isMainModule:


#   # HTML Converter
#   var tmp = adoc.convertToHtml
#   echo $tmp

#main()