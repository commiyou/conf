#!/bin/bash

cut -f1,10  | sed -n  "2,30p" |  { echo "query\tlabel url\tgsb\t备注\tGSB=\t0.5:0:-05="; awk '{print $1"\t=HYPERLINK(\""$2"\")"}' }  | pbcopy

open /Applications/Microsoft\ Excel.app
