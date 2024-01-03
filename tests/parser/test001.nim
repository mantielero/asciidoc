import asciidoc, tables,sequtils

var adoc = "This is a basic AsciiDoc document.\n"
var doc  = adoc.parseAdoc

assert doc.items.len == 1 
assert doc.items[0] == (itParagraph,0)
assert doc.paragraphs[0].lines[0] == "This is a basic AsciiDoc document."
assert doc.paragraphs[0].attrib.keys().toSeq.len == 0