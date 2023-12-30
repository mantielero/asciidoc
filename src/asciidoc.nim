# nim js -r -d:nodejs -d:release asciidoctor
import std/[tables,strformat,strutils]
import npeg
import asciidoc/[types]
import asciidoc/docheader/[docheader]
import asciidoc/lists/[lists]
import asciidoc/directives/[includes]
import asciidoc/sections/[sections]

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

include::attributes-settings.adoc[leveloffset=+1,lines="1..10,15..20",prueba=7;14..25;28..43,adios]

[#tigers-subspecies,reftext=Subspecies]
== Section Level 1

This is a paragraph.

"""
  # 1. Parse Doc Header
  var
    adoc:ADoc
    #doc:seq[Table[string,string]]
    

  var n = 0
  var flag = true
  while txt.len > 0:
    flag = true
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

    # 3. Parse includes
    var incl:IncludeObj
    res = parserIncludes.match(txt, incl)
    if res.ok:
      #echo list
      adoc.includes &= incl
      adoc.items &= (itIncludes, adoc.includes.high)      
      flag = false
      txt =  txt[res.matchMax .. txt.high]  

    # 4. Parse section
    var sect:SectionObj
    res = parserSection.match(txt, sect)
    if res.ok:
      #echo list
      adoc.sections &= sect
      adoc.items &= (itSection, adoc.includes.high)      
      flag = false
      txt =  txt[res.matchMax .. txt.high]  

    if flag:
      break

  echo adoc
  echo adoc.items[adoc.items.high]
  
  if flag:
    echo "============================"
    echo "BREAKING SINCE NOT IMPROVING"
    echo "============================"
    echo txt

main()