import npeg




let parser = peg("block", d: Dict):
  blockDelimiterComment <- "////"

proc main =
  var txt = """=== Document Title
      // this is a comment
This document provides...

[#mi-id]  
////
Mi comentario
multilínea
////


[quote#mi-nuevo-id]
Es muy interesantes
cómo se puede crear un párrafo.

Saludos
"""