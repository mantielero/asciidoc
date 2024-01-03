#from htmlgen import nil
import asciidoc
import karax / [karaxdsl, vdom, vstyles]
import std/[strformat,tables, strutils]
import ../../types
import ../../stylesheet/[stylesheet]

# proc admonition(typ,content:string):NimNode =
#   var myClass = "admonitionblock " & typ
#   return htmlgen.`div`(class=myClass,
#     htmlgen.table(
#       htmlgen.tr(
#         htmlgen.td(class="icon",
#           htmlgen.`div`(class="title", "Note")
#         ),
#         htmlgen.td(class="content", content
#         )
#       )
#     ) 
#     )


proc header(h:DocumentHeaderObj):VNode =
  buildHtml(tdiv(id = "header")):
    h1: text h.title
    if h.authors.len > 0 or h.revnumber != "" or h.revdate != "" or h.revremark != "":
      tdiv(class="details"):
        for i in 0..h.authors.high:
          var author = h.authors[i]
          var id = "author"
          if i > 0:
            id &= $(i+1)

          span(id=id,class="author"):
            text author.name
          if i < h.authors.high or (i == h.authors.high and author.email != ""):
            br()
          if author.email != "":# or i < h.authors.high:
            #br()
            id = "email"
            if i > 0:
              id &= $(i+1)
            span(id=id, class="email"):
              var email = &"mailto:{author.email}"
              a(href=email):
                text author.email
          if author.email != "" and i < h.authors.high:
            br()
          if author.email != "" and i == h.authors.high and (h.revnumber != "" or h.revdate != "" or h.revremark != ""):
            br()
        if h.revnumber != "":
          span(id="revnumber"):
            text "Version " & h.revnumber & ","
        if h.revdate != "":
          span(id="revdate"):
            text h.revdate
          br()       
        if h.revremark != "":
          span(id="revremark"):
            text h.revremark   
    

proc paragraph(para:ParagraphObj):VNode =
  var content:string
  for line in para.lines:
    content &= line & " "

  buildHtml(tdiv(class = "paragraph")):
    p: text content

#echo admonition("note", "An admoniton draw the reader's attention to auxiliary information.")

# Define a function to traverse the VNode tree
proc findLastUList(node: VNode, level: int = -1): VNode =
  if node == nil:
    return nil
  # Your traversal logic here
  # This is a simplified example, adapt it based on your actual VNode structure
  var flag = true

  var l = -1
  var uList:seq[tuple[node:VNode;l:int]] = @[(node,l)]
  var results:seq[VNode]
  while uList.len > 0:
    # Get the first item from the list
    var (tmp, lvlValue) = uList[0]
    uList.delete(0)

    var firstFlag = true
    for child in tmp:
      if child.kind == VnodeKind.ul:
        if firstFlag:
          l += 1
          firstFlag = false
        if l == level:
          results &= child
      uList &= (child, l)  

  if results.len == 0:
    return nil
  else:
    return results[results.high]

proc list(l:ListObj):VNode =
  for item in l.items:

    # Unordered case
    if item.typ == unordered:
      # Do we have an "ul" at the right level?
      var latest = result.findLastUList(item.level)
      # - if not, we create one one level below under the latest "li"
      if latest == nil: # If the list is empty, we create the root
        var myDiv = tree(VNodeKind.tdiv)
        myDiv.class = "ulist"
        var myLu = tree(VNodeKind.ul)
        myDiv.add myLu
        latest = myLu
        if item.level == 0:
          result = myDiv

        else:  # If it is a sublevel, search for the latest "li" and add it there.
          var levelBelow = result.findLastUList(item.level - 1)
          # Now we find the latest "li"
          var latestLi:VNode
          for child in levelBelow:
            if child.kind == VnodeKind.li:
              latestLi = child
          latestLi.add myDiv

      # Add the "li"
      var i = buildHtml(li()):
                p:
                  text item.txt[0]
      #i.add p: text item.txt
      latest.add i
  echo result

proc section2html(sect:SectionObj):tuple[node,content:VNode] =
  var tmp = buildHtml(tdiv(class="sect" & $(sect.level-1))):
              case sect.level
              of 1:
                h1()
              of 2:
                h2()
              of 3:
                h3()
              of 4:
                h4()
              of 5:
                h5()                                                                        
              else:
                h6()

  # Set id
  var id = ""
  for key in sect.attrib.keys():
    if key.startsWith("#"):
      id = key[1..key.high]
  #tmp[0].attrs &= &"""id="{id}""""
  tmp[0].setAttr("id", id)

  tmp[0].add buildHtml(text sect.txt)


  var content = buildHtml(tdiv(class="sectionbody"))
  tmp.add content
  return (tmp,content)
              
proc break2html(b:BreakObj):VNode =
  if b.isPageBreak:
    buildHtml(tdiv(style="page-break-after: always;".toCss))
  else:
    buildHtml(hr())
        #        <div style="page-break-after: always;"></div>

      #[
          BreakObj* = object
    symbol*:string
    isPageBreak*:bool = false
      ]#  

proc convertToHtml*(doc:ADoc):VNode =
  # var tmp = buildHtml(style):
  #             text(CssDefault)
  # echo tmp

  var description = ""
  var author = ""
  var title  = ""
  var revNumber = ""
  for item in doc.items:
    if item.kind == itDocHeader:
      if "description" in doc.docheader[item.n].metadata:
        description = doc.docheader[item.n].metadata["description"]
        description = description.replace(" \\\n", " ")
        for a in doc.docheader[item.n].authors:
          author &= a.name
          author &= ", "
        if author.endsWith(", ") and author.len > 2:
          author = author[0..(author.high - 2)]

        title = doc.docheader[item.n].title
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
  var bodyContent = buildHtml(body(class="article")):
                          while i != doc.items.high:
                            var item = doc.items[i]
                            if item.kind == itDocHeader:
                              var tmp = header( doc.docheader[item.n] )
                              revNumber = doc.docheader[item.n].revnumber
                              tmp
                              break
                            i += 1
  result.add bodyContent        # add the body to the HTML
  var contents = @[bodyContent] # track the body

  var articleContents = buildHtml(tdiv(id="content"))
  bodyContent.add articleContents  # add it to the HTML
  contents.add articleContents        # track it
  var currentContent = articleContents    # set it as default content target

  #var currentContent = contents[0]
  #tdiv(id="content"):
  while i != doc.items.high:
    var item = doc.items[i]

    if item.kind == itList:
      var tmp = list( doc.lists[item.n] )
      currentContent.add tmp

    elif item.kind == itSection:
      var (node,content) = section2html( doc.sections[item.n] )
      currentContent.add node
      contents &= content
      currentContent = content
    elif item.kind == itBreak:
      currentContent.add break2html(doc.breaks[item.n])

    elif item.kind == itParagraph:
      var tmp = paragraph( doc.paragraphs[item.n] )
      currentContent.add tmp
    i += 1
    #result &= $& "\n" 
  # elif item.kind == itBreak:
  #   result &= $doc.breaks[item.n] & "\n"    

  var footer  = buildHtml(tdiv(id="footer")):
                  tdiv(id="footer-text"):
                    if revNumber != "":
                      text "Version " & revNumber
                      br() 
                      text "Last updated 2024-01-01\n"  
  bodyContent.add footer




      

    #if item.term != "":
    #  result &= &"      term: {item.term}\n"
    #result &= &"      txt: {item.txt}\n"   


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