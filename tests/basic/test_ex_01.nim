# nim c -r test_ex_01.nim && tidy -i --indent-spaces 2  -quiet --tidy-mark no ex01.html > ex01_new.html
import asciidoc

proc main() =
  var adocTxt = readFile("../examples/ex_01.adoc")
  var adocParsed = parseAdoc(adocTxt, "../examples/")
  #echo adocParsed
  var adocHtml = adocParsed.convertToHtml
  "ex01.html".writeFile( "<!DOCTYPE html>\n" & $adocHtml )


#main
#assert true
main()