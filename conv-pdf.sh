#!/bin/bash

set -e

case "$(uname -s)" in
Linux*)
	PDF_VIEWER=xdg-open
	;;
Darwin*)
	PDF_VIEWER=open
	;;
CYGWIN*) ;;
MINGW*) PDF_VIEWER="powershell.exe";;
MSYS_NT*) PDF_VIEWER='' ;;
*) ;;
esac

OUTPUT=${1/.md/}

pandoc -V geometry:margin=0.5in "$OUTPUT".md -o "$OUTPUT".pdf

shift
if [ "$1" == '-n' ]; then
	exit 0
fi
$PDF_VIEWER "$OUTPUT".pdf &
disown
