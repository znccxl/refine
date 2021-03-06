#!/usr/bin/env bash

set -e
set -u

if [ $# -eq 0 ] ; then
    for filename in `git diff --name-only` ; do
	if [[ "$filename" == *.c ]] || [[ "$filename" == *.h ]] ; then
	    echo $filename
	    $0 ../$filename
	fi
    done
    exit 0
fi

if [ "$1" = "--all" ] ; then
    for filename in `ls *.h *.c` ; do
	$0 ${filename}
    done
    exit 0
fi

if (( $# > 1 )) ; then
    for filename in "$@" ; do
	$0 ${filename}
    done
    exit 0
fi

#uncrustify -c ../uncrustify-gnu.cfg --replace $1*.h $1*.c

clang-format -style=Google -i $1

