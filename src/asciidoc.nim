# nim js -r -d:nodejs -d:release asciidoctor
import std/[tables,strformat,strutils]
import npeg
import asciidoc/[types]
import asciidoc/docheader/[docheader]
import asciidoc/lists/[lists]
# import npeg, tables
# import std/[strutils, strformat, options]
# import synthesis

#[
La unidad principal es el bloque. Un documento es un tipo de bloque.
]#

#var level = 0 # To control the global level during parsing

   
#[ proc `$`(doc:seq[Table[string, string]]):string =
  result = """
=================  
ASCIIDOC DOCUMENT
=================

""" 
  for item in doc:
    # 1. Document Header
    if item[":type"] == "docheader":
      result &= """
Document Header
---------------
"""
      var title = item[":title"]
      result &= &"  - title: {title}\n"
      var level = item[":level"]
      result &= &"  - level: {level}\n"
      result &= &"  - authors:\n"
      var n = -1
      for k in item.keys():
        if k.startsWith(":authorName"):
          var tmp = (k.split(":authorName")[1]).parseInt
          if tmp > n:
            n = tmp
      if n > -1:
        for i in 0..n:
          var author = item[&":authorName{i}"]
          var email:string
          if &":authorEmail{i}" in item:
            email = item[&":authorEmail{i}"]          
          result &= &"    {author} <{email}>\n"

      result &=  "  - revision:\n"
      var revNumber = item[":revNumber"]
      var revDate   = item[":revDate"]      
      var revRemark = item[":revRemark"] 
      result &= &"""    - number: {revNumber}
    - date: {revDate}
    - remark: {revRemark}
""" 
      result &=  "  - metadata:\n"
      for key in item.keys:
        if not key.startsWith(":"):
          result &=  &"    - {key}: {item[key]}\n"

    # 2. Lists
    elif item[":type"] == "list":           
      result &= """

List
----
""" 

      var title = ""
      if ":title" in item:
        title = item[":title"]
      result &= &"  - title: {title}\n"
      result &= "  - attributes:\n"
      var n = -1
      for key in item.keys:
        if key.startsWith(":attrib"):
          var k = key.split(":")[2]
          var value = item[key]
          result &= &"    - {k}: {value}\n"
      
        if key.startsWith(":item"):
          var tmp = key.split(":item")[1]
          tmp = tmp.split(":")[0]
          var tmpVal = tmp.parseInt
          if tmpVal > n:
            n = tmpVal

      result &= "  - items:\n"
      for i in 0..n:
        var key = &":item{i}:"
        for k in item.keys():
          if k.startsWith(key):
            var symbol = k.split(key)[1]
            result &= &"    - {symbol}: {item[k]}\n"
 ]#
#proc parseDocHeader()

proc main =
  var txt = """
//
//Prueba 1
   
//prueba2
= Document Title
Author Name <author@email.org>; Jose Maria; Hello You <hello@example.org>
v2.0, 2019-03-22: this is a remark
:toc:
:homepage: https://example.org
:description: A story chronicling the inexplicable \
hazards and unique challenges a team must vanquish \
on their journey to finding an open source \
project's true power.

.Possible DefOps manual locations
[square]
* West wood maze
// This is a comment
- Maze heart

//

*** Reflection pool
** Secret exit
* Untracked file in git repository
// The next one split's the list
//-
* This is a new List
"""
  # 1. Parse Doc Header
  var
    adoc:ADoc
    doc:seq[Table[string,string]]
    

  var n = 0
  while txt.len > 0:
    var flag = true
    var item:Table[string, string]    
    var dh:DocumentHeaderObj
    var res = parserDocumentHeader.match(txt, dh)
    #echo dh
    if res.ok:
      #echo dh
      adoc.docheader &= dh
      adoc.items &= (itDocHeader, adoc.docheader.high)
      #doc &= item
      flag = false
      txt =  txt[res.matchMax .. txt.high]


    # 2. Parse list.
    var list:ListObj
    res = parserList.match(txt, list)
    if res.ok:
      #echo list
      adoc.lists &= list
      adoc.items &= (itList, adoc.lists.high)      
      flag = false
      txt =  txt[res.matchMax .. txt.high]  

    if flag:
      echo "BREAKING SINCE NOT IMPROVING"
      break

  echo adoc

main()