for i in *.adoc; do
    [ -f "$i" ] || break
    asciidoctor -e $i
done
