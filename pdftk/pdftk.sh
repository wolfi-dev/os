#!/bin/sh
CP='/usr/share/java/bcprov/bcprov.jar:/usr/share/java/commons-lang/commons-lang.jar:/usr/share/java/pdftk/pdftk.jar'
exec /usr/bin/java -cp "$CP" com.gitlab.pdftk_java.pdftk "$@"