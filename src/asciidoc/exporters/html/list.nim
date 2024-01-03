import karax / [karaxdsl, vdom] #, vstyles]
import ../../types
#import std/[strformat]

# Define a function to traverse the VNode tree
proc findLastUList(node: VNode; level: int = -1; typ: VnodeKind = VnodeKind.ul): VNode =
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
      if child.kind == typ:
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

proc list*(l:ListObj):VNode =
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

    elif item.typ == ordered:
      #echo "ok"
      let levels:seq[tuple[class,typ:string]] = @[ 
        ("arabic", ""),
        ("loweralpha", "a"),
        ("lowerroman", "i"),
        ("upperalpha", "A"),
        ("upperroman", "I")
      ]
      # Do we have an "ol" at the right level?
      var latest = result.findLastUList(item.level, VnodeKind.ol)
      # - if not, we create one one level below under the latest "li"
      if latest == nil: # If the list is empty, we create the root
        var myDiv = tree(VNodeKind.tdiv)
        myDiv.class = "olist " & levels[item.level].class  # <--
        var myLu = tree(VNodeKind.ol) # <--
        myLu.setAttr("class", levels[item.level].class) # <--
        if levels[item.level].typ != "":
          myLu.setAttr("type", levels[item.level].typ)

        myDiv.add myLu
        latest = myLu
        if item.level == 0:
          result = myDiv

        else:  # If it is a sublevel, search for the latest "li" and add it there.
          var levelBelow = result.findLastUList(item.level - 1, VnodeKind.ol)
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
