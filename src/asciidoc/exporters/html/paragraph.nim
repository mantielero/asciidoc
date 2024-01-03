import karax / [karaxdsl, vdom] #, vstyles]
import ../../types
#import std/[strformat]

proc paragraph*(para:ParagraphObj):VNode =
  var content:string
  for line in para.lines:
    content &= line & " "

  buildHtml(tdiv(class = "paragraph")):
    p: text content