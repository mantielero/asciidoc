#from htmlgen import nil
import asciidoc
import karax / [karaxdsl, vdom, vstyles]
import std/[strformat,tables, strutils]
import ../../types
import ../../stylesheet/[stylesheet]
import header, paragraph, list, breaks, sections
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




proc convertToHtml*(doc:ADoc):VNode =
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