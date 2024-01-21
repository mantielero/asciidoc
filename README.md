# asciidoc
Pure Nim AsciiDoc parser. Just a proof of concept (not even alpha status).

## About AsciiDoc
One of the selling points of asciidoc is that is [Governed by a language specification, always evolving](https://asciidoc.org/#specifications). Nonetheless, I have not seen it. It looks like it is a work in progress activity. On the other hand, there aren't many implementations so this prevents fragmentation as occurs with MarkDown.

## Parsing
For parsing, [npeg](https://github.com/zevv/npeg) is used. The structures populate different objects.

In order to export to HTML, [karax](https://github.com/karaxnim/karax) is used.

For testing the idea is to use `testament`:
```
testament run tests/basic/test_ex_01
```


# Notes
It is useful:
```sh
tidy -i --indent-spaces 2  -quiet --tidy-mark no ../examples/ex_01.html > ex01_orig.html
```


```sh
$ tidy -i --indent-spaces 2  -quiet --tidy-mark no ex_01.html > ex01_new.html
```

# TODO
## Cli
- [X] CLI: started; just input/output

## Parsing
- [ ] Parsing
  
  - [ ] Document Header

  - [ ] Paragraphs

    - [ ] Hard line breaks
    - [ ] Preamble and lead style
    - [ ] Lead role
    - [ ] Paragraph alignment

 
  - [ ] Sections

    - [ ] Document [preamble ](https://docs.asciidoctor.org/asciidoc/latest/sections/titles-and-levels/)
    - [ ] Handle [`sectlinks` attribute](https://docs.asciidoctor.org/asciidoc/latest/sections/title-links/#link)
    - [ ] [Auto-ids](https://docs.asciidoctor.org/asciidoc/latest/sections/auto-ids/)

      - [ ] [`sectids` attribute](https://docs.asciidoctor.org/asciidoc/latest/sections/auto-ids/)
      - [ ] [`idprefix` attribute](https://docs.asciidoctor.org/asciidoc/latest/sections/id-prefix-and-separator/)
      - [ ] [`idseparator` attribute](https://docs.asciidoctor.org/asciidoc/latest/sections/id-prefix-and-separator/)
      - [X] [Custom ids](https://docs.asciidoctor.org/asciidoc/latest/sections/custom-ids/)
      - [ ] [Leagacy block anchor syntax](https://docs.asciidoctor.org/asciidoc/latest/sections/custom-ids/)
      - [ ] [Auxiliary IDs](https://docs.asciidoctor.org/asciidoc/latest/sections/custom-ids/#assign-auxiliary-ids)
      - [ ] [Section numbers](https://docs.asciidoctor.org/asciidoc/latest/sections/numbers/)
      
    - [ ] [Section styles](https://docs.asciidoctor.org/asciidoc/latest/sections/styles/)

      - [ ] [Article](https://docs.asciidoctor.org/asciidoc/latest/sections/styles/#article-section-styles)
      - [ ] [Book](https://docs.asciidoctor.org/asciidoc/latest/sections/styles/#book-section-styles)

    - [ ] Handling [rules violation](https://docs.asciidoctor.org/asciidoc/latest/sections/titles-and-levels/)

  - [ ] Discrete headings
  - [X] Breaks
  - [ ] Text formatting

    - [ ] Bold
    - [ ] Italic
    - [ ] Monospace
    - [ ] ...

  - [-] Lists

    - [-] Unordered
    - [-] Ordered
    - [-] Description
    - [X] Separating lists
    - [ ] Complex List Items

  - [ ] Links
  - [ ] Cross References
  - [ ] Footnotes
  - [ ] Images
  - [ ] Audio and Video
  - [ ] Icons
  - [ ] Keyboard macro
  - [ ] Button and Menu UI Macros
  - [ ] Admonitions
  - [ ] Sidebars
  - [ ] Example blocks
  - [ ] Blockquotes
  - [ ] Verses
  - [ ] Verbatim and Source Blocks
  - [ ] Tables
  - [ ] Equation and Formulas (STEM)
  - [ ] Open Blocks
  - [ ] Collapsible Blocks
  - [ ] Comments
  - [ ] Automatic Table of Contents
  - [ ] Docinfo files
  - [ ] Includes
  - [ ] Conditionals
  - [ ] Substitutions
  - [ ] Passthroughs
  - [ ] Reference
  - [ ] Document Types

    - [ ] article
    - [ ] book
    - [ ] manpage
    - [ ] inline
 
## Exporting
- [ ] Exporting:
### HTML
  - [ ] HTML