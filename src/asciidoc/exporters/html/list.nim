import karax / [karaxdsl, vdom] #, vstyles]
import ../../types
#import std/[strformat]

# Define a function to traverse the VNode tree


proc list*(item:ListItemObj; attr:string = ""):VNode =
    if item.typ == unordered:
      var myLi = buildHtml(li())
      var para = buildHtml(p):
                  text item.txt
      myLi.add para
      return myLi

    elif item.typ == ordered:
      let levels:seq[tuple[class,typ:string]] = @[ 
        ("arabic", ""),
        ("loweralpha", "a"),
        ("lowerroman", "i"),
        ("upperalpha", "A"),
        ("upperroman", "I")
      ]

      # Do we have an "ol" at the right level?
      #var latest = result.findLastUList(item.level, VnodeKind.ol)
      # - if not, we create one one level below under the latest "li"
      #if latest == nil: # If the list is empty, we create the root
      var tmp = buildHtml(ol()):
                  li() #tree(VNodeKind.ol)
      tmp.setAttr("class", levels[item.listLevel].class)
      if item.listLevel > 0:
        tmp.setAttr("type", levels[item.listLevel].typ)

      var myLi  = buildHtml(li):
                    p: 
                      text item.txt
      tmp.add myLi
      return tmp

    elif item.typ == listDescription:
      # TODO: fix nested description
      var tmp = buildHtml(dt(class="hdlist1")):
                  text item.term
      var ctx = tmp
      if item.txt != "":
        var myDd = buildHtml(dd):
          p:
            text item.txt
        tmp.add myDd
        ctx = myDd
      return tmp

