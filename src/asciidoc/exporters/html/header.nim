import karax / [karaxdsl, vdom] #, vstyles]
import ../../types
import std/[strformat]

proc header*(h:DocumentHeaderObj):VNode =
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