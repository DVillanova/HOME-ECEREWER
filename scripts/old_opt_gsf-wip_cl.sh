#!/bin/bash

echo -n "$1 $2 " >> RES_LM

../../scripts/score.sh --wip $2 --lmw $1 ../../models/HMMs/test/graph/words.txt "ark:gzip -c -d lat-test.gz |" ../../lang/char/char.total.txt hypotheses-test 2>log | awk 'NR==1{print $2}' | tee -a RES_LM

