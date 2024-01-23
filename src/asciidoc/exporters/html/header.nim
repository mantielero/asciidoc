import karax / [karaxdsl, vdom] #, vstyles]
import std/[strformat, tables, strutils]
import ../../[types, log]

proc genHeader*(item:Block): VNode =
  var headerHtml  = buildHtml(tdiv(id="header")):
                      h1:
                        text item.title
  # Authors
  var flagDetails = false
  var detailsHtml = buildHtml(tdiv(class="details"))

  var revNumber = ""
  var revDate = ""
  var revRemark = ""
  for key in item.attributes.keys:
    
    if key.startsWith(":authorName"):
      flagDetails = true
      var n = key.split(":authorName")[1].parseInt
      var id = "author"
      if n > 1:
        id &= $n
      var authorName = buildHtml(span(id=id,class="author")):
                          text item.attributes[key]
                          
      detailsHtml.add authorName
      detailsHtml.add buildHtml(br())

    elif key.startsWith(":authorEmail"):
      flagDetails = true
      var n = key.split(":authorEmail")[1].parseInt
      var id = "email"
      if n > 1:
        id &= $n
      var email = item.attributes[key]
      var authorEmail = buildHtml(span(id=id, class="email")):
                          a(href="mailto:" & email ):
                            text email

      detailsHtml.add authorEmail
      detailsHtml.add buildHtml(br()) 
    elif key == ":revNumber":
      revNumber = item.attributes[key]
    elif key == ":revDate":
      revDate = item.attributes[key]
    elif key == ":revRemark":
      revRemark = item.attributes[key]

  if flagDetails:
    headerHtml.add detailsHtml

  if revNumber != "":
    var tmp = buildHtml(span(id="revnumber")):
                      text "version " & revNumber & ","
    detailsHtml.add tmp
  if revDate != "":
    var tmp = buildHtml(span(id="revdate")):
                text revDate 
    detailsHtml.add tmp      
  if revRemark != "":
    var tmp = buildHtml(span(id="revremark")):
                text revRemark  
    detailsHtml.add tmp

  return headerHtml

# proc header*(h:DocumentHeaderObj):VNode =
#   buildHtml(tdiv(id = "header")):
#     h1: text h.title
#     if h.authors.len > 0 or h.revnumber != "" or h.revdate != "" or h.revremark != "":
#       tdiv(class="details"):
#         for i in 0..h.authors.high:
#           var author = h.authors[i]
#           var id = "author"
#           if i > 0:
#             id &= $(i+1)

#           span(id=id,class="author"):
#             text author.name
#           if i < h.authors.high or (i == h.authors.high and author.email != ""):
#             br()
#           if author.email != "":# or i < h.authors.high:
#             #br()
#             id = "email"
#             if i > 0:
#               id &= $(i+1)
#             span(id=id, class="email"):
#               var email = &"mailto:{author.email}"
#               a(href=email):
#                 text author.email
#           if author.email != "" and i < h.authors.high:
#             br()
#           if author.email != "" and i == h.authors.high and (h.revnumber != "" or h.revdate != "" or h.revremark != ""):
#             br()
#         if h.revnumber != "":
#           span(id="revnumber"):
#             text "Version " & h.revnumber & ","
#         if h.revdate != "":
#           span(id="revdate"):
#             text h.revdate
#           br()       
#         if h.revremark != "":
#           span(id="revremark"):
#             text h.revremark  