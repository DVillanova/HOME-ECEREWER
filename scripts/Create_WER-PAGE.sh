#!/bin/bash

export PATH=$PATH:export PATH=$PATH:$HOME/HTR/bin:.

if [ $# -ne 2 ]; then
 echo "Uso: ${0##*/} <Directorio-resultados> <Directorio-Labels>" 
 exit
fi

D=`pwd`

PAGEFORMAT=$(which page_format_tool)
[ -z "$PAGEFORMAT" ] && { echo "ERROR: \"page_format_tool\" soft is not installed/found "'!' 1>&2; exit 1; }

cd $1
mkdir trans-hip

for F in *.xml; do
  $PAGEFORMAT -i ${F/.xml/.jpg} -l ${F} -m FILE || \
      {
        echo "ERROR: \"page_format_tool\" with sample ${F/\.$IEXT/.JPG}" >> ../LOG_Line-Extraction
        cd ..; continue
      }
  mv *txt trans-hip;
  rm *png;
done
cd ..

cd $2
mkdir trans

for F in *xml; do
  $PAGEFORMAT -i ${F/.xml/.jpg} -l ${F} -m FILE || \
      {
        echo "ERROR: \"page_format_tool\" with sample ${F/\.$IEXT/.JPG}" >> ../LOG_Line-Extraction
        cd ..; continue
      }
  mv *txt trans;
  rm *png;
done
cd $D

for file in `find $1 -name "*.txt"`;
do


   NAME=$2/trans/$(basename $file)

   awk '{if (NR>=1) printf("%s",$0);}END{printf(" $ ")}' $NAME
   awk '{if (NR>=1) printf("%s ",$0);}END{printf("\n")}' $file

done |ascii2uni -a K | sed 's/\x22\x27\x22/\x27/g' | sed 's/\x27\x22\x27/\x22/g' | sed 's/\([0-9]\) \([0-9]\)/\1\2/g' | sed 's/\([0-9]\) \([0-9]\)/\1\2/g' | sed 's/[<>]//g' | sed 's/  / /g' > fich_results

sed 's/\([.,:;]\)/ \1/g' fich_results  > fich_results_WER

sed 's/^ //g;s/ $//g;s/ [ ]*/ /g;s/ \$ /\$/g' fich_results | sed 's/ /@/g' | sed 's/\(.\)\(.\)/\1 \2 /g' > fich_results_CER

tasas fich_results_CER -ie -s " "  -f "$" | awk '{printf("%.2f\n",$1)}'
tasas fich_results_WER -ie -s " "  -f "$" | awk '{printf("%.2f\n",$1)}'


