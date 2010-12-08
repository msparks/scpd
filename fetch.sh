#!/bin/bash

# The contents of this file are dedicated to the public domain. To the extent
# that dedication to the public domain is not available, everyone is granted a
# worldwide, perpetual, royalty-free, non-exclusive license to exercise all
# rights associated with the contents of this file for any purpose whatsoever.
# No rights are reserved.

makefile=$(mktemp)

prefix=
while getopts "hp:" OPT; do
  case $OPT in
    p)
      prefix=${OPTARG%/}/
      ;;
    h)
      cat >&2 <<EOF
Usage: $0 [-p VIDEO_DIR] [-- MAKE_ARGS] < URLS_FILE

Downloads the SCPD videos at the given URLs.

URLS_FILE should have one http://....wmv URL per line. Videos are (roughly)
downloaded in the order they appear in the file, so you may want to sort it.

VIDEO_DIR is the directory underneath which all videos will be saved. It
defaults to the current working directory. A subdirectory for each course will
be created beneath VIDEO_DIR.

The script works by creating and executing a makefile that describes how to
download each video using mplayer. MAKE_ARGS are passed on to the make program,
and -j and -n are particularly useful.
EOF
      exit 1
      ;;
  esac
done
shift $(($OPTIND - 1))

echo "all:" >> $makefile
echo ".PHONY: all" >> $makefile

read url
while [ $? -eq 0 ]; do
  url=${url/#http/mms}
  dir=$(echo $url | cut -d/ -f5)
  out=$prefix$dir/20$(echo $url | cut -d/ -f6).wmv
  echo "all: $out" >> $makefile
  echo "$out:" >> $makefile
  echo "	@mkdir -p $dir" >> $makefile
  echo "	@echo fetch $out" >> $makefile
  echo "	@mplayer -dumpstream -dumpfile $out $url" >> $makefile
  read url
done

make -f $makefile $* && rm $makefile
