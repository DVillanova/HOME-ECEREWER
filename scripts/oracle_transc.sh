#!/bin/bash


# Copyright Johns Hopkins University (Author: Daniel Povey)  2013
# Apache 2.0.

# Begin configuration section.
wildcard_symbols=
cmd=run.pl
acwt=0.08333
beam=
stage=0
cleanup=true
# End configuration section.


echo "$0 $@"  # Print the command line for logging

if [ $# != 3 ]; then
   echo "Compute lattice oracle WER and depth, optionally pruning and minimizing the lattice"
   echo "beforehand.  To produce oracle WER, requires there to be a file 'char.test.txt' in data dir"
   echo "(not usable if only stm is present)"
   echo ""
   echo "Usage: $0 <data-dir> <lang-dir> <decode-dir>"
   exit 1;
fi


data=$1 #$TmpDir/
lang=$2 #$LangDir/lm/lang/
dir=$3  #$TmpDir/decode/lattices


for f in $data/char.test.txt $lang/words.txt $dir/1-best-lat-test.gz; do
  [ ! -f $f ] && echo "$0: expected file $f to exist" && exit 1;
done

cat $data/char.test.txt | \
scripts/sym2int.pl -f 2- $lang/words.txt | \
lattice-oracle --word-symbol-table=$lang/words.txt \
"ark:gunzip -c $dir/lat-test.gz |" ark:- ark,t:$dir/oracle_transc.txt \
2>$dir/oracle.log
