# nim c -r test_ex_01.nim && tidy -i --indent-spaces 2  -quiet --tidy-mark no ex01.html > ex01_new.html
# asciidoctor ../examples/ex_01.adoc
# tidy -i --indent-spaces 2  -quiet --tidy-mark no ../examples/ex_01.html > ex01_orig.html

import asciidoc

proc main() =
  var adocTxt = readFile("../examples/ex_01.adoc")
  var blocks = parseAdoc(adocTxt, "../examples/")
  echo blocks
  # var adocParsed = parseAdoc(adocTxt, "../examples/")
  # echo adocParsed
  # echo "<<<<<<<<<<<--------------->>>>>>>>>>>>>>>>"
  var adocHtml = blocks.convertToHtml
  # #var txt:string = $adocHtml
  # "ex01.html".writeFile( "<!DOCTYPE html>\n" & ($adocHtml).string )

main()