#from htmlgen import nil
import asciidoc
import karax / [karaxdsl, vdom]
import std/[strformat]
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

  #return paragraph(class="paragraph", content)

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

proc convertToHtml*(doc:ADoc):VNode =
  # var tmp = buildHtml(style):
  #             text(CssDefault)
  # echo tmp

  buildHtml(html):
    head:
      meta(charset="UTF-8")
      meta(http-equiv="X-UA-Compatible", content="IE=edge")
      meta(name="viewport", content="width=device-width, initial-scale=1.0")
      meta(name="generator", content="Asciidoctor 2.0.17") # FIXME
      title:
        text "Untitled"   # FIXME
      link(rel="stylesheet", href="https://fonts.googleapis.com/css?family=Open+Sans:300,300italic,400,400italic,600,600italic%7CNoto+Serif:400,400italic,700,700italic%7CDroid+Sans+Mono:400,700")
      style:
        verbatim(CssDefault)

    var revnumber:string = "" 
    # ARTICLE (DEFAULT) - only one header
    body(class="article"):

      var i = 0
      while i != doc.items.high:
        var item = doc.items[i]
        if item.kind == itDocHeader:
          var tmp = header( doc.docheader[item.n] )
          revnumber = doc.docheader[item.n].revnumber
          tmp
          break
        i += 1

      tdiv(id="content"):
        while i != doc.items.high:
          var item = doc.items[i]

          if item.kind == itList:

            list( doc.lists[item.n] ) 
          # elif item.kind == itIncludes:
          #   result &= $doc.includes[item.n] & "\n" 
          # elif item.kind == itSection:
          #   result &= $doc.sections[item.n] & "\n"    
          elif item.kind == itParagraph:
            paragraph( doc.paragraphs[item.n] )
            #echo tmp
          i += 1
          #result &= $& "\n" 
        # elif item.kind == itBreak:
        #   result &= $doc.breaks[item.n] & "\n"    

      tdiv(id="footer"):
        tdiv(id="footer-text"):
          if revnumber != "":
            text revnumber
            br() 
            text "Last updated 2024-01-01"  





      

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
<head>


<style>
...
</head>
]#