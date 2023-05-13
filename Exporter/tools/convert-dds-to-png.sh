#!/bin/bash

for file in $(find $1 -name '*.dds'); do
	magick mogrify -format png $file;
	rm $file;
done;
