import karax / [karaxdsl, vdom] #, vstyles]
import ../../types
import std/[strformat, tables, strutils, sequtils]  

proc genListItem*(item:Block):seq[VNode]

proc genList*(item:Block):VNode =
  var listRoot = buildHtml(tdiv())

  # add the title if it exists
  if item.kind == BlckType.list:
    var title = item.title
    if title != "":
      var node =  buildHtml(tdiv(class="title")):
                    text title
      listRoot.add node

  # TODO: add attribs
  # if attribs != "":
  #   myUl.setAttr("class", attribs)
  var firstItem = true
  var listTyp:Vnode
  for b in item.blocks:
    if b.kind == BlckType.listItem:
      if firstItem:
        var cls = case b.attributes[":listType"]
                  of "unordered": "ulist"
                  of "ordered":   "olist"
                  of "dlist":     "dlist"
                  else:           ""
          # and set the div class accordingly
        if cls != "":
          listRoot.setAttr("class", cls)

        if cls == "ulist":
          listTyp = buildHtml(ul())
          listRoot.add listTyp
        elif cls == "olist":
          listTyp = buildHtml(ol())
          listRoot.add listTyp
        elif cls == "dlist":
          listTyp = buildHtml(dl())
          listRoot.add listTyp

        firstItem = false

      var tmp = genListItem(b)
      for val in tmp:
        listTyp.add val
    else:
      # FIXME: TAKE ME OUTSIDE THIS FUNCTION
      var content = b.content.splitWhitespace.join(" ")

      if b.kind == BlckType.paragraph:
        var otherNode = buildHtml(tdiv(class="paragraph")):
                            p:
                              text content
        listRoot.add otherNode
      elif b.kind == BlckType.literal:
        var otherNode = buildHtml(tdiv(class="literalblock")):
                          tdiv(class="content"):
                            pre: text content
                              #text content        

                # <div class="literalblock">
                #   <div class="content">
                #     <pre>$ cd projects/my-book</pre>
                #   </div>
                # </div>        
        listRoot.add otherNode
  return listRoot


proc genListItem*(item:Block):seq[VNode] =
  if item.attributes[":listType"] in @["ordered", "unordered"]:
    var newLi = buildHtml(li())

    # Content
    var content = item.content.splitWhitespace.join(" ")
    var para =  buildHtml(p):
                  text content
    newLi.add para
    if item.blocks.len > 0:
      #genListItem(newLi, b)
      var tmp = genList(item)
      newLi.add tmp
    result &= newLi  

  # description list case
  elif item.attributes[":listType"] == "dlist":
    var level = item.attributes[":level"]
    var cls = &"hdlist{level}"
    
    # add <dt class="hdlist1">First term</dt> 
    var newTerm = buildHtml(dt(class=cls)): # 
                    text item.title     
    var content = item.content.splitWhitespace.join(" ") 

    # add <dd> ...      
    var newDesc = buildHtml(dd()):
                    p: text content

    if item.blocks.len > 0:
      var tmp = genList(item)
      newDesc.add tmp    
    result &= newTerm
    result &= newDesc

# Define a function to traverse the VNode tree


proc list_old*(item:ListItemObj; attr:string = ""):VNode =
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

