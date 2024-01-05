import asciidoc
import parsexml
var adoc = readFile("list_01.adoc")
var doc = adoc.parseAdoc
var adocHtml = adocParsed.convertToHtml

var html = readFile("list_01.html")
