#from htmlgen import nil
import karax / [karaxdsl, vdom]
import std/[strformat]
import ../../types

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
  #var content:string

  buildHtml(tdiv(class = "header")):
    h1: text h.title
    if h.authors.len > 0 or h.revnumber != "" or h.revdate != "" or h.revremark != "":
      tdiv(class="details"):
        for i in 0..h.authors.high:
          var author = h.authors[i]
          span(id="author",class="author"):
            text author.name
          if i < h.authors.high or (i == h.authors.high and author.email != ""):
            br()
          if author.email != "":# or i < h.authors.high:
            #br()
            span(id="email", author="email"):
              var email = &"mailto:{author.email}"
              a(href=email):
                text author.email
          if author.email != "" and i < h.authors.high:
            br()
          if author.email != "" and i == h.authors.high and (h.revnumber != "" or h.revdate != "" or h.revremark != ""):
            br()
        if h.revnumber != "":
          span(id="revnumber"):
            text h.revnumber
        if h.revdate != "":
          span(id="revdate"):
            text h.revdate          

#[
  AuthorObj* = object
    name*:string
    email*:string          
]#
#[
<span id="revnumber">version 2.0,</span>
<span id="revdate">2019-03-22</span>
]#
    

proc paragraph(para:ParagraphObj):VNode =
  var content:string
  for line in para.lines:
    content &= line & " "

  buildHtml(tdiv(class = "paragraph")):
    p: text content

  #return paragraph(class="paragraph", content)

#echo admonition("note", "An admoniton draw the reader's attention to auxiliary information.")

proc convertToHtml*(doc:ADoc):string =
  var htmlDoc = buildHtml(html):
    body(class="article"): # Default is article
      for item in doc.items:
        if item.kind == itDocHeader:
          var tmp = header( doc.docheader[item.n] )
          tmp
        #   result &= $doc.docheader[item.n] & "\n"
        # elif item.kind == itList:
        #   result &= $doc.lists[item.n] & "\n" 
        # elif item.kind == itIncludes:
        #   result &= $doc.includes[item.n] & "\n" 
        # elif item.kind == itSection:
        #   result &= $doc.sections[item.n] & "\n"    
        elif item.kind == itParagraph:
          paragraph( doc.paragraphs[item.n] )
          #echo tmp
          
          #result &= $& "\n" 
        # elif item.kind == itBreak:
        #   result &= $doc.breaks[item.n] & "\n"    

  echo htmlDoc


# echo page.render

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

<div id="content">
<div class="paragraph">
<p>This document provides&#8230;&#8203;</p>
</div>
<div class="paragraph">
<p>Another paragraph</p>
</div>
</div>
<div id="footer">
<div id="footer-text">
Version 2.0<br>
Last updated 2024-01-01 17:56:41 +0100
</div>
</div>

]#