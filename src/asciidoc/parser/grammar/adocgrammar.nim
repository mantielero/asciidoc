import npeg

grammar "adoc":
  crlf      <- ?'\r' * '\n'
  comment   <- "//" * *(1-'\r'-'\n') * crlf
  emptyLine <- *' ' * crlf
  headerMark <- ('='|'#')[2..10] * ' '  
  key       <- +(1 - '[' - ']' - ',' - '=' - '"')
  value1    <- +(1 - '[' - ']' - '=' - ',' - '"')
  value2    <- '"' * +(1 - '"') * '"'
  txt       <- +(1 - '\r' - '\n')
  listSeparator <- (emptyLine * comment * emptyLine)  

  #crlf        <- ?'\r' * '\n' # 0 or 1 '\r'; then 1 '\n'
  #emptyLine   <- *' ' * crlf  # 0 or many spaces; then crlf
  noSlash     <- &!'/'        # 1 not '/' but it doesn't consume any character

  comment        <- "//" * noSlash * *txt * crlf
  emptyorcomment <- (emptyLine | comment)

  # Blocks delimiters
  bdPass      <- "++++" * *('+')
  bdComment   <- "////" * *('/')
  bdExample   <- "====" * *('=')
  bdListing   <- "----" * *('-')   
  bdLiteral   <- "...." * *('.')   
  bdOpen      <- "--"
  bdSidebar   <- "****" * *('*')   
  bdTable1    <- "|===" * *('=') 
  bdTable2    <- ",===" * *('=')  
  bdTable3    <- ":===" * *('=')
  bdTable4    <- "!===" * *('=')    
  bdQuote     <- "____" * *('_') 
  blockDelimiters <- (bdPass | bdComment | bdExample | bdListing | bdLiteral | bdOpen | bdSidebar | bdTable1 | bdTable2 | bdTable3 | bdTable4 | bdQuote)