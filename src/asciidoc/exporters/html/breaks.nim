import karax / [karaxdsl, vdom, vstyles]
#import std/[strformat,tables, strutils]
import ../../types
#import ../../stylesheet/[stylesheet]

proc break2html*(b:BreakObj):VNode =
  if b.isPageBreak:
    buildHtml(tdiv(style="page-break-after: always;".toCss))
  else:
    buildHtml(hr())
