#!/usr/bin/env bash

for file in *.jxl; do
  djxl "$file" "${file%.*}.png"
done
#rm *.png *.jpg *.jpeg
