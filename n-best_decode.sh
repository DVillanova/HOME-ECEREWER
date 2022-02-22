#!/bin/bash
# N-BEST HYPOTHESES DECODING(USAR EN DOCKER)

#IMPORTANTE PONER LOS LC
export LC_NUMERIC=C.UTF-8;

#Activate pylaia env (Docker)
conda activate pylaia

#Variables and Paths for Docker
GPU=1
BatchSize=8
WorkDir=/root/directorioTrabajo/TFM-NER
ScriptsDir=${WorkDir}/scripts
PartDir=${WorkDir}/PARTITIONS
TextDir=${WorkDir}/TEXT
DataDir=${WorkDir}/DATA
LangDir=${WorkDir}/lang
CharDir=${LangDir}/char
ModelDir=${WorkDir}/model
TmpDir=${WorkDir}/TMP
NerDir=${WorkDir}/NER
NerNoRepDir=${WorkDir}/NER-NoRep

ASF=1.27216049
WIP=-0.76260881
MAX_NUM_ACT_STATES=2007483647             # Maximum number of active states
BEAM_SEARCH=15                            # Beam search
LATTICE_BEAM=12                           # Lattice generation beam
N_CORES=1   

img_dirs=$(find ${DataDir}/*_charters -mindepth 3 -maxdepth 3 -type d)

echo "Results N-best decoding" > $WorkDir/results-nbest-decoding.txt

#Iterate over different values of N
for N in 1 10 50 100 500 1000 2500 5000 10000
do

#Lattices should be generated from initial_exp.sh
cd $TmpDir/decode
cd lattices

cp ${LangDir}/lm/lang/words.txt ./words.txt

#OBTAIN N-BEST TRANSCRIPTIONS IN VALIDATION
rm ${N}-best-lat-validation.gz
lattice-scale --acoustic-scale=${ASF} "ark:gzip -c -d lat-validation.gz |" ark:- | \
lattice-to-nbest --n=${N} --acoustic-scale=${ASF} "ark:gzip -c -d lat-validation.gz |" "ark:|gzip -c > ${N}_best-lat-validation.gz"
#lattice-copy ark:'gunzip -c n_best-lat-validation.gz|' ark,t:n_best-lat-validation.txt
nbest-to-linear "ark:gzip -c -d ${N}_best-lat-validation.gz |" ark,t:${N}_best-validation.ali 'ark,t:|int2sym.pl -f 2- words.txt > n_best-validation-transcriptions.txt'

awk '{
  printf("%s ", $1);
  for (i=2;i<=NF;++i) {
    if ($i == "<space>")
      printf(" ");
    else
      printf("%s", $i);
  }
  printf("\n");
}' n_best-validation-transcriptions.txt > ../n_best-validation-words.txt;

#OBTAIN N-BEST TRANSCRIPTIONS IN TEST
rm ${N}-best-lat-test.gz
lattice-scale --acoustic-scale=${ASF} "ark:gzip -c -d lat-test.gz |" ark:- | \
lattice-add-penalty --word-ins-penalty=${WIP} ark:- ark:- | \
lattice-to-nbest --n=${N} --acoustic-scale=${ASF} ark:- "ark:|gzip -c > ${N}-best-lat-test.gz"
#lattice-copy ark:'gunzip -c n_best-lat-test.gz|' ark,t:n_best-lat-test.txt
rm best-test-transcriptions.txt
nbest-to-linear "ark:gzip -c -d ${N}-best-lat-test.gz |" ark,t:${N}-best-test.ali 'ark,t:|int2sym.pl -f 2- words.txt > best-test-transcriptions.txt'

rm ${N}-best-test.ali

rm ../${N}-best-test-words.txt
awk '{
  printf("%s ", $1);
  for (i=2;i<=NF;++i) {
    if ($i == "<space>")
      printf(" ");
    else
      printf("%s", $i);
  }
  printf("\n");
}' best-test-transcriptions.txt > ../${N}-best-test-words.txt;


#CRAWLING IN THE N-BEST
echo "N=" ${N} >> $WorkDir/results-nbest-decoding.txt

cd ..
rm ${N}-best-compliant-test-words.txt
python ${ScriptsDir}/nbest_hyp_crawler.py ./${N}-best-test-words.txt ./${N}-best-compliant-test-words.txt $WorkDir/histogram-${N}-best.txt ./crawler-log.txt

#CHAR LEVEL TRANSCRIPT
python ${ScriptsDir}/char_transcript_extractor.py ./${N}-best-compliant-test-words.txt  ./${N}-best-compliant-test-chars.txt
echo "Test CER" >> $WorkDir/results-nbest-decoding.txt 
compute-wer --mode=present  ark:$LangDir/char/char.total.txt ark:./${N}-best-compliant-test-chars.txt | grep WER | sed -r 's|%WER|%CER|g' >> $WorkDir/results-nbest-decoding.txt;

sed 's/\([.,:;?]\)/ \1/g;s/\([¿¡]\)/\1 /g' ./${N}-best-compliant-test-words.txt > SeparateSimbols-wordtest.txt
sed 's/\([.,:;?]\)/ \1/g;s/\([¿¡]\)/\1 /g' $LangDir/char/word.total.txt > SeparateSimbols-word.txt
sed 's/ \.line/\.line/g;s/ \.r\([0-9]\)/\.r\1/g;s/ \.region/\.region/g' -i SeparateSimbols-word.txt
sed 's/ \.line/\.line/g;s/ \.r\([0-9]\)/\.r\1/g;s/ \.region/\.region/g' -i SeparateSimbols-wordtest.txt
sed 's/</ </g' SeparateSimbols-wordtest.txt | sed 's/>/> /g' | sed 's/  / /g' > k; mv k SeparateSimbols-wordtest.txt
sed 's/</ </g' SeparateSimbols-word.txt | sed 's/>/> /g' | sed 's/  / /g' > k; mv k SeparateSimbols-word.txt

echo "Test WER" >> $WorkDir/results-nbest-decoding.txt
compute-wer --mode=present ark:SeparateSimbols-word.txt ark:SeparateSimbols-wordtest.txt >> $WorkDir/results-nbest-decoding.txt;

rm SeparateSimbols-*

#EXTRACT NEs
cd $WorkDir/PREC-REC/
rm -rf NER-${N}BEST-TEST
mkdir NER-${N}BEST-TEST
cd NER-${N}BEST-TEST
${ScriptsDir}/extractNERHip2.sh $TmpDir/decode/${N}-best-compliant-test-words.txt

#EVALUATION OF PREC-REC AND EDIT DISTANCE
cd ..

python ${ScriptsDir}/calc_prec_rec.py ./NER-GT ./NER-${N}BEST-TEST >> $WorkDir/results-nbest-decoding.txt
python ${ScriptsDir}/dist_edicion_custom_saturated.py ./NER-GT ./NER-${N}BEST-TEST/ >> $WorkDir/results-nbest-decoding.txt
echo "" >> $WorkDir/results-nbest-decoding.txt

done
