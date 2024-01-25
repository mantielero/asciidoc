import asciidoc

proc main() =
  var adocTxt = readFile("section_01.adoc")
  var blocks = parseAdoc(adocTxt, "../examples/")
  #echo blocks
  var adocHtml = blocks.convertToHtml
  # #var txt:string = $adocHtml
  "section_01_new.html".writeFile( "<!DOCTYPE html>\n" & ($adocHtml).string )

main()