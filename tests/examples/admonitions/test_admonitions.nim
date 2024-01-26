import asciidoc
import std/strformat

proc main() =

  for i in 2..2:
    var adocTxt = readFile(&"admonitions_{i:02}.adoc")
    var blocks = parseAdoc(adocTxt, "../examples/")
    echo blocks
    var adocHtml = blocks.convertToHtml
    # #var txt:string = $adocHtml
    var newName = &"admonitions_{i:02}_new.html"
    newName.writeFile( "<!DOCTYPE html>\n" & ($adocHtml).string )

main()