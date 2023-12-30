import npeg

grammar "adoc":
  crlf      <- ?'\r' * '\n'
  comment   <- "//" * *(1-'\r'-'\n') * crlf
  emptyLine <- *' ' * crlf
  key       <- +(1 - '[' - ']' - ',' - '=' - '"')
  value1    <- +(1 - '[' - ']' - '=' - ',' - '"')
  value2    <- '"' * +(1 - '"') * '"'
  txt       <- +(1 - '\r' - '\n')
  listSeparator <- (emptyLine * comment * emptyLine)  