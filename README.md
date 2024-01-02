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
line 1 column 1 - Warning: missing <!DOCTYPE> declaration
line 411 column 9 - Warning: <span> anchor "author" already defined
line 413 column 9 - Warning: <span> anchor "author" already defined
line 415 column 9 - Warning: <span> anchor "email" already defined
line 419 column 9 - Warning: <span> anchor "revdate" already defined
line 409 column 9 - Warning: <span> proprietary attribute "author"
line 415 column 9 - Warning: <span> proprietary attribute "author"
```

# TODO
