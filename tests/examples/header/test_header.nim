import asciidoc

proc main() =
  var adocTxt = readFile("header_04.adoc")
  var blocks = parseAdoc(adocTxt, "../examples/")
  #echo blocks
  # var adocParsed = parseAdoc(adocTxt, "../examples/")
  # echo adocParsed
  # echo "<<<<<<<<<<<--------------->>>>>>>>>>>>>>>>"
  var adocHtml = blocks.convertToHtml
  # #var txt:string = $adocHtml
  "header_05.html".writeFile( "<!DOCTYPE html>\n" & ($adocHtml).string )

main()