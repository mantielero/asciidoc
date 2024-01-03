import karax / [karaxdsl, vdom, vstyles]
import std/[tables, strutils]
import ../../types

proc section2html*(sect:SectionObj):tuple[node,content:VNode] =
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

  tmp[0].setAttr("id", id)

  tmp[0].add buildHtml(text sect.txt)


  var content = buildHtml(tdiv(class="sectionbody"))
  tmp.add content
  return (tmp,content)