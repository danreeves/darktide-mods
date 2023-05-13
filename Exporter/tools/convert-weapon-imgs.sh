#!/bin/bash

mkdir -p "$1/pngs"

for black_file in "$1"/*_black.dds; do
	white_file="${black_file/black/white}"
	filename="$(basename -- $black_file)"
	out_file="$1/pngs/${filename/_black.dds/.png}"
	echo $out_file;
	convert $black_file $white_file -alpha off \
		\( -clone 0,1 -compose difference -composite -negate \) \
		\( -clone 0,2 +swap -compose divide -composite \) \
		-delete 0,1 +swap -compose Copy_Opacity -composite \
		$out_file
done;
