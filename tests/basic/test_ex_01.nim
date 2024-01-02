import asciidoc

proc main() =
  var adocTxt = readFile("../examples/ex_01.adoc")
  var adocParsed = adocTxt.parseAdoc
  #echo adocParsed
  var adocHtml = adocParsed.convertToHtml
  "ex01.html".writeFile( $adocHtml )


#main
#assert true
main()