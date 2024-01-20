#from htmlgen import nil
import asciidoc
import karax / [karaxdsl, vdom, vstyles]
import std/[strformat,tables, strutils, sequtils]
import ../../[types, log]
import stylesheet/[stylesheet]
import header, paragraph, breaks, sections, list



proc genListItem(item:Block):seq[VNode]

proc genList(item:Block):VNode =
  var listRoot = buildHtml(tdiv())

  # add the title if it exists
  if item.kind == BlckType.list:
    var title = item.title
    if title != "":
      var node =  buildHtml(tdiv(class="title")):
                    text title
      listRoot.add node




  # TODO: add attribs
  # if attribs != "":
  #   myUl.setAttr("class", attribs)
  var firstItem = true
  var listTyp:Vnode
  for b in item.blocks:
    if b.kind == BlckType.listItem:
      if firstItem:
        var cls = case b.attributes[":listType"]
                  of "unordered": "ulist"
                  of "ordered":   "olist"
                  of "dlist":     "dlist"
                  else:           ""
          # and set the div class accordingly
        if cls != "":
          listRoot.setAttr("class", cls)

        if cls == "ulist":
          listTyp = buildHtml(ul())
          listRoot.add listTyp
        elif cls == "olist":
          listTyp = buildHtml(ol())
          listRoot.add listTyp
        elif cls == "dlist":
          listTyp = buildHtml(dl())
          listRoot.add listTyp

        firstItem = false

      var tmp = genListItem(b)
      for val in tmp:
        listTyp.add val
    else:
      # FIXME: TAKE ME OUTSIDE THIS FUNCTION
      var content = b.content.splitWhitespace.join(" ")

      if b.kind == BlckType.paragraph:
        var otherNode = buildHtml(tdiv(class="paragraph")):
                            p:
                              text content
        listRoot.add otherNode
      elif b.kind == BlckType.literal:
        var otherNode = buildHtml(tdiv(class="literalblock")):
                          tdiv(class="content"):
                            pre: text content
                              #text content        

                # <div class="literalblock">
                #   <div class="content">
                #     <pre>$ cd projects/my-book</pre>
                #   </div>
                # </div>        
        listRoot.add otherNode
  return listRoot


proc genListItem(item:Block):seq[VNode] =
  if item.attributes[":listType"] in @["ordered", "unordered"]:
    var newLi = buildHtml(li())

    # Content
    var content = item.content.splitWhitespace.join(" ")
    var para =  buildHtml(p):
                  text content
    newLi.add para
    if item.blocks.len > 0:
      #genListItem(newLi, b)
      var tmp = genList(item)
      newLi.add tmp
    result &= newLi  

  # description list case
  elif item.attributes[":listType"] == "dlist":
    var level = item.attributes[":level"]
    var cls = &"hdlist{level}"
    
    # add <dt class="hdlist1">First term</dt> 
    var newTerm = buildHtml(dt(class=cls)): # 
                    text item.title     
    var content = item.content.splitWhitespace.join(" ") 

    # add <dd> ...      
    var newDesc = buildHtml(dd()):
                    p: text content

    if item.blocks.len > 0:
      var tmp = genList(item)
      newDesc.add tmp    
    result &= newTerm
    result &= newDesc


proc convertToHtml*(doc:Block):VNode =
  debug("convertToHtml: starting")
  var description = ""
  var author = ""
  var title  = ""
  var revNumber = ""

  # Doc Header
  for item in doc.blocks:
    if item.kind == documentHeader:
      # if "description" in doc.docheader[item.n].metadata:
      #   description = doc.docheader[item.n].metadata["description"]
      #   description = description.replace(" \\\n", " ")
      #   for a in doc.docheader[item.n].authors:
      #     author &= a.name
      #     author &= ", "
      #   if author.endsWith(", ") and author.len > 2:
      #     author = author[0..(author.high - 2)]

      #   title = doc.docheader[item.n].title
      break
  
  var i = 0  # Tracks current item in the document.
  result = buildHtml(html):
    # ARTICLE (DEFAULT) - only one header
    head:
      meta(charset="UTF-8")
      meta(http-equiv="X-UA-Compatible", content="IE=edge")
      meta(name="viewport", content="width=device-width, initial-scale=1.0")
      meta(name="generator", content="Asciidoctor 2.0.17") # FIXME
      if description != "":
        meta(name="description", content = description)
      if author != "":
        meta(name="author", content = author)

      title:
        if title == "":
          text "Untitled"
        else:
          text title
      link(rel="stylesheet", href="https://fonts.googleapis.com/css?family=Open+Sans:300,300italic,400,400italic,600,600italic%7CNoto+Serif:400,400italic,700,700italic%7CDroid+Sans+Mono:400,700")
      style:
        verbatim(CssDefault)

 
  # Body
  var bodyArticle = buildHtml(body(class="article"))

  # - Document Header
  #debug("HTML i: " & $i )
  #debug("HTML high: " & $doc.blocks.high )
  while i != doc.blocks.high:
    var item = doc.blocks[i]
    if item.kind == documentHeader:
      # var tmp = header( doc.docheader[item.n] )
      # revNumber = doc.docheader[item.n].revnumber
      # bodyArticle.add tmp
      break
    i += 1
  result.add bodyArticle        # add the body to the HTML
  #var contents = @[bodyContent] # track the body

  if i == doc.blocks.high:
    i = 0
  #[
  LEVELS:
  - 0: <body class="article">
  - 1:    <div id="header">
  - 1:    <div id="content">
            <div id="preamble">
  - 2:        <div class="sectionbody">
  - 2:      <div class="sect1">
  ]#
  var insertPoint:seq[VNode] = @[bodyArticle]  # Level 0
  var bodyLevel = 0
  var currentLevel = 0

  var articleContents = buildHtml(tdiv(id="content"))
  insertPoint[currentLevel].add articleContents  # add it to HTML
  insertPoint &= articleContents                 # Track this level
  var contentLevel = 1
  currentLevel = 1

  #bodyContent.add articleContents  # add it to the HTML
  #contents.add articleContents        # track it
  #var currentContent = articleContents    # set it as default content target



  var isPreamble = true

  var isList = false
  var listPreviousType:ListItemType
  var currentTitle = ""
  var currentAttribute:AttributesObj
  var lastListLevel:int = -1
  #debug("HTML i: " & $i )
  #debug("HTML high: " & $doc.blocks.high )
  while i <= doc.blocks.high:
    var item = doc.blocks[i]

    # Optional: any content prior to first section is a preamble.
    if item.kind != section and isPreamble:
      debug("HTML - PREAMBLE: Creating preamble")
      # Create preamble.
      var preamble = buildHtml(tdiv(id="preamble"))
      var sectionBody = buildHtml(tdiv(class="sectionbody"))
      preamble.add sectionBody
      insertPoint[currentLevel].add preamble
      insertPoint &= sectionBody # Current level 2
      currentLevel += 1
      isPreamble = false
      debug("HTML - PREAMBLE: insertPoint: " & $insertPoint)

    # -------------- ListItem ------------------
    if item.kind == BlckType.list:
      debug("HTML: list found") # & $insertPoint)
      #debug(item)
      # 1. Create the root node
      var listRoot = genList(item)
      insertPoint[currentLevel].add listRoot

    # if item.kind == listItem:
    #   var listItem = doc.listItems[item.n]

    #   # Attribs
    #   var attribs = ""
    #   if currentAttribute.keys.toSeq.len > 0:
    #     for (key,value) in currentAttribute.pairs():
    #       if value == "":
    #         attribs &= " " & key

    #     currentAttribute.clear()
     
    #   # add the class to the div
    #   if previous != nil:
    #     previous.setAttr("class", cls & attribs)

    #   # Gen node
    #   var listItemVNode = list( listItem, attribs )


    #   if listItem.listLevel > lastListLevel:
    #     debug("listLevel change") 
    #     var myUl = buildHtml(ul())
    #     #myDiv.add myUl
    #     if attribs != "":
    #       myUl.setAttr("class", attribs)
    #     previous.add myUl
    #     myUl.add listItemVNode

    #     if (insertPoint.len) <= listItem.level + 1:
    #       insertPoint &= myUl
    #       debug("inserting myUl")
    #     else:
    #       debug("replacing myUl")
    #       debug("  insertPoint.len:" & $insertPoint.len)
    #       debug("  listItem.level:" & $listItem.level)
    #       insertPoint[listItem.level+1] = myUl
    #       #debug("ok")

    #     if (insertPoint.len) <= (listItem.level+2): 
    #       debug("inserting LI")
    #       insertPoint &= listItemVNode[0]
    #     else:
    #       debug("replacing LI")          
    #       insertPoint[listItem.level+2] = listItemVNode[0]

    #   elif previous == nil:
    #     previous = listItemVNode

    #   else:
    #     debug("cleaning insertPoint")
    #     debug("    insertPoint.len:"  & $insertPoint.len)
    #     while insertPoint.high > (listItem.level+1):
    #       insertPoint.delete(insertPoint.high)        
    #     debug("    insertPoint.len:"  & $insertPoint.len)          
    #   #else:
    #   #  previous.add listItemVNode
    #     #insertPoint[currentLevel].add previous

    #   debug("HTML - LIST ITEM: item to insert:" & $previous)        
    #   debug("HTML - LIST ITEM: insertPoint:" & $insertPoint.len)         
    #   #echo previous
    #   #echo "n: ", currentLevel + listItem.level
    #   #echo insertPoint 
    #   #insertPoint[currentLevel + listItem.level].add previous
    #   insertPoint[listItem.level + listItem.listLevel].add previous
    #   #echo currentLevel, " "
    #   #if listItem.typ == listPreviousType:
    #   #  insertPoint[currentLevel].add listItemVNode


    #   #echo previous
    #   #echo insertPoint
    #   #insertPoint[currentLevel].add previous
    #   lastListLevel = listItem.listLevel



    # # --------------- List Title ---------------
    # elif item.kind == itListTitle:
    #   var it = doc.listTitles[item.n]
    #   currentTitle = it.title


    # elif item.kind == itAttributes:
    #   currentAttribute = doc.attributes[item.n]


    # elif item.kind == itListSeparator:
    #   listPreviousType = none
    #   currentTitle = ""
    #   currentAttribute.clear()
    #   lastListLevel = -1
    #   insertPoint = insertPoint[0..1]
    #   currentLevel = insertPoint.len
    #   isList = false

    # # ---- Section ----
    # elif item.kind == itSection:
    #   isList = false
    #   #insertPoint[2] = insertPoint[0..0]
    #   #currentLevel = 0
    #   var sect = doc.sections[item.n] 
    #   var (node,content) = section2html( sect )
    #   insertPoint[contentLevel].add node
    #   if sect.level == 2:
    #     insertPoint[sect.level] = node # Replace the level 2 with this section
    #     if insertPoint.len <= (sect.level + 1):
    #       insertPoint &= content
    #     else:
    #       insertPoint[sect.level + 1] = content
    #   currentLevel = sect.level
    #   #insertPoint[currentLevel] = content
    
    # elif item.kind == itBreak:
    #   insertPoint[currentLevel].add break2html(doc.breaks[item.n])

    # elif item.kind == itParagraph:
    #   var tmp = paragraph( doc.paragraphs[item.n] )
    #   insertPoint[currentLevel].add tmp
    i += 1
   

  # FOOTER
  var footer  = buildHtml(tdiv(id="footer")):
                  tdiv(id="footer-text"):
                    if revNumber != "":
                      text "Version " & revNumber
                      br() 
                      text "Last updated 2024-01-01\n"  
  bodyArticle.add footer



#[
Admonition - Note
<div class="admonitionblock note">
<table>
<tr>
<td class="icon">
<div class="title">Note</div>
</td>
<td class="content">
An admonition draws the reader&#8217;s attention to auxiliary information.
</td>
</tr>
</table>
</div>
]#



#[
TOC

    <div id="toc" class="toc">
      <div id="toctitle">
        Table of Contents
      </div>
      <ul class="sectlevel1">
        <li>
          <a href="#tigers-subspecies">Section Level 1</a>
        </li>
      </ul>
    </div>
]#



#[
      <div class="sectionbody">
        <div class="ulist square">
          <div class="title">
            Possible DefOps manual locations
          </div>
]#