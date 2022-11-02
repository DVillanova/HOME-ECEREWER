# set -e
#IMPORTANTE PONER LOS LC
export LC_NUMERIC=C.UTF-8;

#Últimos requisitos de PyLaia
conda activate pylaia

#Variables, parámetros y rutas para Docker
GPU=2
BatchSize=8
WorkDir=/root/directorioTrabajo/DOC-NER/NER_GW/
PartDir=${WorkDir}/PARTITIONS
TextDir=${WorkDir}/TEXT
DataDir=${WorkDir}/washingtondb-v1.0/
LangDir=${WorkDir}/lang
CharDir=${LangDir}/char
ModelDir=${WorkDir}/model
TmpDir=${WorkDir}/TMP
NerDir=${WorkDir}/NER
NerNoRepDir=${WorkDir}/NER-NoRep

img_dirs=${DataDir}/data/line_images_normalized/

##################################################################################################################################################################################
python $WorkDir/scripts/generate_tagged_line_transcription.py \
     $WorkDir/gw/full_tagged_gw.txt $DataDir/ground_truth/transcription.txt \
     $DataDir/ground_truth/index.words


rm -rf ${TextDir}
mkdir ${TextDir}
cd ${TextDir}

cp $DataDir/ground_truth/index.words ./index.words

# Create data dir
cd ${WorkDir}
rm -rf ${CharDir}
mkdir -p ${CharDir}
cd ${CharDir}

cat ${TextDir}/index.words | awk '{
      printf("%s", $1);
      for(i=2;i<=NF;++i) {
              if($i!~"@"){  
                      for(j=1;j<=length($i);++j) 
                              printf(" %s", substr($i, j, 1));
                      if ((i < NF) && ($(i+1)!~"@")) printf(" <space>");
              }else{ 
                      printf " "$i" ";
                      if (i < NF) printf("<space>");
              }; 
      }
      printf("\n");
}' | sed 's/"/'\'' '\''/g;s/#/<stroke>/g' > char.total.txt

#Extraer vocaboluario y número de símbolos en el vocabulario
cat char.total.txt | cut -f 2- -d\  | tr \  \\n| sort -u -V | awk 'BEGIN{   N=0;   printf("%-12s %d\n", "<eps>", N++);   printf("%-12s %d\n", "<ctc>", N++);  }NF==1{  printf("%-12s %d\n", $1, N++);}' >  symb.txt
# NSYMBOLS=$(sed -n '${ s|.* ||; p; }' "symb.txt");

cd ${WorkDir}

#PREPROCESO PARA CREACIÓN DE FICHEROS .TXT CON NOMBRE ARCHIVO Y TRANSCRIP.
#A PARTIR DE ARCHIVO INDEX.WORDS CON TODAS LAS PALABRAS Y .LST CON FICHEROS
#DE PARTICION --> VOLCAR TODO EN WorkDir/TMP/
rm -rf ${TmpDir}
mkdir ${TmpDir}
cd ${TmpDir}

cp ${PartDir}/test.lst ./test.lst
cp ${PartDir}/train.lst ./train.lst
cp ${PartDir}/val.lst ./val.lst

for f in $(<./train.lst); do grep "${f}\b" ${TextDir}/index.words; done > ./train.txt
for f in $(<./test.lst); do grep "${f}\b" ${TextDir}/index.words; done > ./test.txt
for f in $(<./val.lst); do grep "${f}\b" ${TextDir}/index.words; done > ./val.txt

# CREACION CHAR.TRAIN CHAR.VAL CHAR.TEST
for f in $(<./train.lst); do grep "${f}\b" ${TextDir}/index.words; done |
awk '{
printf("%s", $1);
for(i=2;i<=NF;++i) {
  if($i!~"@"){  
    for(j=1;j<=length($i);++j) 
      printf(" %s", substr($i, j, 1));
    if ((i < NF) && ($(i+1)!~"@")) printf(" <space>");
  }else{ 
    printf " "$i" ";
    if (i < NF) printf("<space>");
  }; 
}
printf("\n");
}' | sed 's/"/'\'' '\''/g;s/#/<stroke>/g' > char.train.txt

for f in $(<./val.lst); do grep "${f}\b" ${TextDir}/index.words; done |
awk '{
printf("%s", $1);
for(i=2;i<=NF;++i) {
  if($i!~"@"){  
    for(j=1;j<=length($i);++j) 
      printf(" %s", substr($i, j, 1));
    if ((i < NF) && ($(i+1)!~"@")) printf(" <space>");
  }else{ 
    printf " "$i" ";
    if (i < NF) printf("<space>");
  }; 
}
printf("\n");
}' | sed 's/"/'\'' '\''/g;s/#/<stroke>/g' > char.val.txt

for f in $(<./test.lst); do grep "${f}\b" ${TextDir}/index.words; done |
awk '{
printf("%s", $1);
for(i=2;i<=NF;++i) {
  if($i!~"@"){  
    for(j=1;j<=length($i);++j) 
      printf(" %s", substr($i, j, 1));
    if ((i < NF) && ($(i+1)!~"@")) printf(" <space>");
  }else{ 
    printf " "$i" ";
    if (i < NF) printf("<space>");
  }; 
}
printf("\n");
}' | sed 's/"/'\'' '\''/g;s/#/<stroke>/g' > char.test.txt


#Símbolos con método Vicente
for p in train test val; do cat char.${p}.txt | cut -f 2- -d\  | tr \  \\n; done | sort -u -V | awk 'BEGIN{
N=0;
printf("%-12s %d\n", "<ctc>", N++);
}NF==1{
printf("%-12s %d\n", $1, N++);
}' >  symb.txt


cd ${WorkDir}
rm -rf ${ModelDir}
mkdir ${ModelDir}

#Creación del modelo óptico. 
pylaia-htr-create-model \
--print_args True \
--train_path ${ModelDir} \
--model_filename model \
--logging_level info \
--fixed_input_height 0 \
--cnn_kernel_size 3 3 3 3 \
--adaptive_pooling "avgpool-16" \
--cnn_dilation 1 1 1 1 \
--cnn_num_features 32 64 96 128 \
--cnn_batchnorm True True True True \
--cnn_activations LeakyReLU LeakyReLU LeakyReLU LeakyReLU \
--cnn_poolsize 2 2 0 2 \
--use_masked_conv=true \
--rnn_type LSTM \
--rnn_layers 3 \
--rnn_units 256 \
--rnn_dropout 0.5 \
--lin_dropout 0.5 \
3 ${TmpDir}/symb.txt

#--cnn_num_features 16 32 64 96 \

#Entrenamiento del modelo óptico.
pylaia-htr-train-ctc-rgb \
--print_args TRUE --gpu ${GPU} \
--train_path ${ModelDir} --model_filename model \
--use_baidu_ctc=true \
--add_logsoftmax_to_loss=false \
--logging_level info \
--logging_also_to_stderr info \
--logging_file train-crnn.log \
--show_progress_bar True \
--batch_size ${BatchSize} \
--learning_rate 0.0003 \
--use_distortions True \
--max_nondecreasing_epochs 50 \
--delimiters="<space>" \
${TmpDir}/symb.txt $img_dirs ${TmpDir}/char.train.txt ${TmpDir}/char.val.txt
#syms img_dirs [img_dirs...] tr_txt_table va_txt_table



mkdir ${TmpDir}/decode
cd ${TmpDir}/decode 

#Aquí ponerse a hacer rutas completas es un cacao

#DECODIFICACION TEST Y VAL PARA WER
#CER (SPACE = "<SPACE>", JOIN_STR = " ")
pylaia-htr-decode-ctc-rgb \
--print_args True \
--gpu ${GPU} \
--train_path ${ModelDir} \
--model_filename model \
--logging_level info \
--logging_also_to_stderr info \
--logging_file test-crnn.log \
--batch_size ${BatchSize} \
--print_img_ids \
--use_letters \
--separator=" " \
--space "<space>" \
--join_str " " \
${TmpDir}/symb.txt $img_dirs ${TmpDir}/test.lst > ${TmpDir}/decode/test.txt

pylaia-htr-decode-ctc-rgb \
--print_args True \
--gpu ${GPU} \
--train_path ${ModelDir} \
--model_filename model \
--logging_level info \
--logging_also_to_stderr info \
--logging_file test-crnn.log \
--batch_size ${BatchSize} \
--print_img_ids \
--use_letters \
--separator=" " \
--space "<space>" \
--join_str " " \
${TmpDir}/symb.txt $img_dirs ${TmpDir}/val.lst > ${TmpDir}/decode/va.txt


# Get word-level transcript hypotheses (CALCULO WER A POSTERIORI)
awk '{
printf("%s ", $1);
for (i=2;i<=NF;++i) {
  if ($i == "<space>")
    printf(" ");
  else
    printf("%s", $i);
}
printf("\n");
}' ${TmpDir}/decode/test.txt > ${TmpDir}/decode/wordtest.txt;

awk '{
printf("%s ", $1);
for (i=2;i<=NF;++i) {
  if ($i == "<space>")
    printf(" ");
  else
    printf("%s", $i);
}
printf("\n");
}' ${TmpDir}/decode/va.txt > ${TmpDir}/decode/wordva.txt;

cd ${CharDir}

awk '{
printf("%s ", $1);
for (i=2;i<=NF;++i) {
  if ($i == "<space>")
    printf(" ");
  else
    printf("%s", $i);
}
printf("\n");
}' char.total.txt > word.total.txt;


# Compute CER/WER.
cd ${TmpDir}/decode
if $(which compute-wer &> /dev/null); then
#CALCULO CER
echo "test" > $WorkDir/res_exp.txt
compute-wer --mode=present ark:${CharDir}/char.total.txt ark:${TmpDir}/decode/test.txt | grep WER | sed -r 's|%WER|%CER|g' >> $WorkDir/res_exp.txt
echo "val" >> $WorkDir/res_exp.txt
compute-wer --mode=present ark:${CharDir}/char.total.txt ark:${TmpDir}/decode/va.txt | grep WER | sed -r 's|%WER|%CER|g' >> $WorkDir/res_exp.txt

#CALCULO WER
echo "test" >> $WorkDir/res_exp.txt
compute-wer --mode=present  ark:${CharDir}/word.total.txt ark:${TmpDir}/decode/wordtest.txt |  grep WER >> $WorkDir/res_exp.txt
echo "val" >> $WorkDir/res_exp.txt
compute-wer --mode=present  ark:${CharDir}/word.total.txt ark:${TmpDir}/decode/wordva.txt |  grep WER >> $WorkDir/res_exp.txt

echo "------------" >> $WorkDir/res_exp.txt

sed 's/\([.,:;?]\)/ \1/g;s/\([¿¡]\)/\1 /g' wordtest.txt > SeparateSimbols-wordtest.txt
#sed 's/\([.,:;?]\)/ \1/g;s/\([¿¡]\)/\1 /g' corrected_wordtest.txt > SeparateSimbols-corrected_wordtest.txt
sed 's/\([.,:;?]\)/ \1/g;s/\([¿¡]\)/\1 /g' wordva.txt > SeparateSimbols-wordva.txt
sed 's/\([.,:;?]\)/ \1/g;s/\([¿¡]\)/\1 /g' ${CharDir}/word.total.txt > SeparateSimbols-word.txt
sed 's/ \.line/\.line/g;s/ \.r\([0-9]\)/\.r\1/g' -i SeparateSimbols-word.txt
sed 's/ \.line/\.line/g;s/ \.r\([0-9]\)/\.r\1/g' -i SeparateSimbols-wordtest.txt
#sed 's/ \.line/\.line/g;s/ \.r\([0-9]\)/\.r\1/g' -i SeparateSimbols-corrected_wordtest.txt
sed 's/ \.line/\.line/g;s/ \.r\([0-9]\)/\.r\1/g' -i SeparateSimbols-wordva.txt

sed 's/</ </g;s/>/> /g' SeparateSimbols-word.txt | sed 's/  / /g' > k; mv k SeparateSimbols-word.txt
sed 's/</ </g;s/>/> /g' SeparateSimbols-wordtest.txt | sed 's/  / /g' > k; mv k SeparateSimbols-wordtest.txt
#sed 's/</ </g;s/>/> /g' SeparateSimbols-corrected_wordtest.txt | sed 's/  / /g' > k; mv k SeparateSimbols-corrected_wordtest.txt
sed 's/</ </g;s/>/> /g' SeparateSimbols-wordva.txt | sed 's/  / /g' > k; mv k SeparateSimbols-wordva.txt

#Cálculo WER con la separación de los caracteres de arriba ^ (hola! -> hola !)
compute-wer --mode=present ark:SeparateSimbols-word.txt ark:SeparateSimbols-wordtest.txt >> $WorkDir/res_exp.txt
echo "------------" >> $WorkDir/res_exp.txt
compute-wer --mode=present ark:SeparateSimbols-word.txt ark:SeparateSimbols-wordva.txt >> $WorkDir/res_exp.txt
echo "------------" >> $WorkDir/res_exp.txt

#WER with tagging fix
python $WorkDir/scripts/fix_separate_symb_output.py $TmpDir/decode/SeparateSimbols-wordtest.txt $TmpDir/decode/fixed_SeparateSimbols-wordtest.txt
python $WorkDir/scripts/fix_separate_symb_output.py $TmpDir/decode/SeparateSimbols-word.txt $TmpDir/decode/fixed_SeparateSimbols-word.txt
python $WorkDir/scripts/fix_separate_symb_output.py $TmpDir/decode/SeparateSimbols-wordva.txt $TmpDir/decode/fixed_SeparateSimbols-wordva.txt  

compute-wer --mode=present ark:fixed_SeparateSimbols-word.txt ark:fixed_SeparateSimbols-wordtest.txt >> $WorkDir/res_exp.txt
echo "------------" >> $WorkDir/res_exp.txt
compute-wer --mode=present ark:fixed_SeparateSimbols-word.txt ark:fixed_SeparateSimbols-wordva.txt >> $WorkDir/res_exp.txt
echo "------------" >> $WorkDir/res_exp.txt


rm Separate*

else
echo "ERROR: Kaldi's compute-wer was not found in your PATH!" >&2;
fi;


######################################################################################################
## Genero el GT de las NER

cd ${WorkDir}

mkdir ${NerDir}
cd ${NerDir}
$WorkDir/scripts/extractNER-GT_GW.sh ${TextDir}/index.words 

cd -
mkdir ${NerNoRepDir}
cd ${NerNoRepDir}
$WorkDir/scripts/extractNER-GT-noRep.sh ${TextDir}/index.words


########################################################################################################################
################# Incluir modelo de lenguaje ###########################################################################
########################################################################################################################

# Force alignment

# Obtaining confMats
cd ${TmpDir}/decode

pylaia-htr-netout-rgb \
--show_progress_bar True \
--print_args True \
--train_path ${ModelDir} \
--model_filename model \
--logging_level info \
--logging_also_to_stderr info \
--logging_file CMs-crnn.log  \
--batch_size ${BatchSize} \
--output_transform log_softmax \
--output_matrix confMats_ark-test.txt \
$img_dirs ${TmpDir}/test.lst

pylaia-htr-netout-rgb \
--show_progress_bar True \
--print_args True \
--train_path ${ModelDir} \
--model_filename model \
--logging_level info \
--logging_also_to_stderr info \
--logging_file CMs-crnn.log  \
--batch_size ${BatchSize} \
--output_transform log_softmax \
--output_matrix confMats_ark-validation.txt \
$img_dirs ${TmpDir}/val.lst

awk '{print $1}' ${TmpDir}/symb.txt > ${TmpDir}/decode/chars.lst


#Processing development feature samples into Kaldi format
########################Y###################################################################################
mkdir -p $TmpDir/decode/test

copy-matrix "ark,t:confMats_ark-validation.txt" "ark,scp:test/confMats_alp0.3-validation.ark,test/confMats_alp0.3-validation.scp"
copy-matrix "ark,t:confMats_ark-test.txt" "ark,scp:test/confMats_alp0.3-test.ark,test/confMats_alp0.3-test.scp"

# Prepare Kaldi's lang directories
############################################################################################################
# Preparing Lexic (L)
cd ${LangDir}
mkdir lm

cp $TmpDir/decode/chars.lst ./chars.lst
#awk 'NR>1{print $1}' ./char/symb.txt > chars.lst



BLANK_SYMB="<ctc>"                        # BLSTM non-character symbol
WHITESPACE_SYMB="<space>"                 # White space symbol
DUMMY_CHAR="<DUMMY>"                      # Especial HMM used for modelling "</s>" end-sentence

$WorkDir/scripts/prepare_lang_cl-ds.sh lm ./chars.lst "${BLANK_SYMB}" "${WHITESPACE_SYMB}" "${DUMMY_CHAR}"

cd lm/

# Preparing LM (G) ==> 5-GRAM BECAUSE THE CORPUS HAS LESS DATA

for f in $(<${PartDir}/train.lst); do
nn=`basename ${f/.png/}`; grep $nn ../char/char.total.txt;
done | cut -d " " -f 2- | ngram-count -vocab ../chars.lst -text - -lm lang/LM.arpa -order 5 -wbdiscount1 -kndiscount -interpolate

#LA GRAMÁTICA GENERADA ES PROBABILÍSTICA PERO PROBABILIDADES NO SUMAN 1 (SE USAN SCORES)
$WorkDir/scripts/prepare_lang_test-ds.sh lang/LM.arpa lang lang_test "$DUMMY_CHAR"

python $WorkDir/scripts/generate_categorical_sfsa_gw.py $LangDir/lm/lang/phones.txt $WorkDir/CAT_FST/Categorical.fst
$WorkDir/scripts/prepare_lang_test_categorical.sh $WorkDir/CAT_FST/Categorical.fst lang lang_test "$DUMMY_CHAR"


##########################################################################################################
# Prepare HMM models
##########################################################################################################
# Create HMM topology file
cd $ModelDir
mkdir -p HMMs/train
ln -s $TmpDir/decode/test/ .

phones_list=( $(cat ${LangDir}/lm/lang_test/phones/{,non}silence.int) )
featdim=$(feat-to-dim scp:test/confMats_alp0.3-test.scp - 2>/dev/null)
dummyID=$(awk -v d="$DUMMY_CHAR" '{if (d==$1) print $2}' ${LangDir}/lm/lang/phones.txt)
blankID=$(awk -v bs="${BLANK_SYMB}" '{if (bs==$1) print $2}' ${LangDir}/lm/lang/pdf_blank.txt)

HMM_LOOP_PROB=0.5                         # Self-Loop HMM-state probability
HMM_NAC_PROB=0.5                          # BLSTM-NaC HMM-state probability

$WorkDir/scripts/create_proto_rnn-ds.sh $featdim ${HMM_LOOP_PROB} ${HMM_NAC_PROB} HMMs/train ${dummyID} ${blankID} ${phones_list[@]}





# Compose FSTs
############################################################################################################

mkdir HMMs/test
$WorkDir/scripts/mkgraph.sh --mono --transition-scale 1.0 --self-loop-scale 1.0 $LangDir/lm/lang_test HMMs/train/new.mdl HMMs/train/new.tree HMMs/test/graph

############################################################################################################



# Lattice Generation
############################################################################################################
cd $TmpDir/decode
mkdir lattices

ASF=0.818485839158                        # Acoustic Scale Factor
MAX_NUM_ACT_STATES=2007483647             # Maximum number of active states
BEAM_SEARCH=15                            # Beam search
LATTICE_BEAM=12                           # Lattice generation beam
N_CORES=1     

latgen-faster-mapped --verbose=2 --allow-partial=true --acoustic-scale=${ASF} --max-active=${MAX_NUM_ACT_STATES} --beam=${BEAM_SEARCH} --lattice-beam=${LATTICE_BEAM} --max-mem=4194304 $ModelDir/HMMs/train/new.mdl $ModelDir/HMMs/test/graph/HCLG.fst scp:test/confMats_alp0.3-test.scp "ark:|gzip -c > lattices/lat-test.gz" ark,t:lattices/RES-test 2>lattices/LOG-Lats-test
latgen-faster-mapped --verbose=2 --allow-partial=true --acoustic-scale=${ASF} --max-active=${MAX_NUM_ACT_STATES} --beam=${BEAM_SEARCH} --lattice-beam=${LATTICE_BEAM} --max-mem=4194304 $ModelDir/HMMs/train/new.mdl $ModelDir/HMMs/test/graph/HCLG.fst scp:test/confMats_alp0.3-validation.scp "ark:|gzip -c > lattices/lat-validation.gz" ark,t:lattices/RES-validation 2>lattices/LOG-Lats-validation


# Final Evaluation
###########################################################################################################
ASF=1.39176532 
WIP=-1.16902908

cd lattices

$WorkDir/scripts/score.sh --wip $WIP --lmw $ASF $ModelDir/HMMs/test/graph/words.txt "ark:gzip -c -d lat-test.gz |" $LangDir/char/char.total.txt hypotheses-test 2>log
$WorkDir/scripts/score.sh --wip $WIP --lmw $ASF $ModelDir/HMMs/test/graph/words.txt "ark:gzip -c -d lat-validation.gz |" $LangDir/char/char.total.txt hypotheses-validation 2>log




#No funciona bien el simplex porque el parser de comandos se atasca
#Lo he editado para que use python2
#SIGUE PETANDO PORQUE NO SACA RESULTADOS (???) PERO LUEGO NO SE USAN LOS RES.???
simplex.py -v -m "/root/directorioTrabajo/TFM-NER/scripts/opt_gsf-wip_cl.sh {$ASF} {$WIP}" > result-simplex
#/root/directorioTrabajo/TFM-NER/scripts/

ASF=1.27216049 
WIP=-0.76260881

$WorkDir/scripts/score.sh --wip $WIP --lmw $ASF $ModelDir/HMMs/test/graph/words.txt "ark:gzip -c -d lat-test.gz |" $LangDir/char/char.total.txt hypotheses-test 2>log


# Pasar el modelo de lenguaje de categorías y generar output
lattice-lmrescore --lm-scale=1.0 "ark:gzip -c -d lat-test.gz |" ${LangDir}/lm/lang_test/G_cat.fst "ark:|gzip -c > rescored_lat-test.gz"
lattice-lmrescore --lm-scale=1.0 "ark:gzip -c -d lat-validation.gz |" ${LangDir}/lm/lang_test/G_cat.fst "ark:|gzip -c > rescored_lat-validation.gz"
$WorkDir/scripts/score.sh --wip $WIP --lmw $ASF $ModelDir/HMMs/test/graph/words.txt "ark:gzip -c -d rescored_lat-test.gz |" $LangDir/char/char.total.txt rescored_hypotheses-test 2>log
$WorkDir/scripts/score.sh --wip $WIP --lmw $ASF $ModelDir/HMMs/test/graph/words.txt "ark:gzip -c -d rescored_lat-validation.gz |" $LangDir/char/char.total.txt rescored_hypotheses-validation 2>log

#Rescoring lattice -> Pasar modelo de lenguaje -> generar output (Resultados algo peores)
# lattice-scale --acoustic-scale=${ASF} "ark:gzip -c -d lat-test.gz |" ark:- | \
# lattice-add-penalty --word-ins-penalty=${WIP} ark:- ark:- | \
# lattice-lmrescore --lm-scale=1.0 ark:- ${LangDir}/lm/lang_test/G_cat.fst "ark:|gzip -c > rescored_lat-test.gz"
# lattice-best-path "ark:gzip -c -d rescored_lat-test.gz |" ark,t:rescored_hypotheses-test

# lattice-scale --acoustic-scale=${ASF} "ark:gzip -c -d lat-validation.gz |" ark:- | \
# lattice-add-penalty --word-ins-penalty=${WIP} ark:- ark:- | \
# lattice-lmrescore --lm-scale=1.0 ark:- ${LangDir}/lm/lang_test/G_cat.fst "ark:|gzip -c > rescored_lat-validation.gz"
# lattice-best-path "ark:gzip -c -d rescored_lat-validation.gz |" ark,t:rescored_hypotheses-validation

echo -e "\nGenerating file of hypotheses: hypotheses_t" 1>&2
int2sym.pl -f 2- $LangDir/lm/lang_test/words.txt hypotheses-test > hypotheses-test_t
int2sym.pl -f 2- $LangDir/lm/lang_test/words.txt hypotheses-validation > hypotheses-validation_t

int2sym.pl -f 2- $LangDir/lm/lang_test/words.txt rescored_hypotheses-test > rescored_hypotheses-test_t
int2sym.pl -f 2- $LangDir/lm/lang_test/words.txt rescored_hypotheses-validation > rescored_hypotheses-validation_t


#RECOMBINAR LOS OUTPUTS PARA QUE SE COJA EL OUTPUT DEL RESCORED Y EL OTRO EN CASO DE DUDA
python $WorkDir/scripts/combine_hypotheses_files.py rescored_hypotheses-test_t hypotheses-test_t combined_hypotheses-test_t
python $WorkDir/scripts/combine_hypotheses_files.py rescored_hypotheses-validation_t hypotheses-validation_t combined_hypotheses-validation_t 

############################################################################################################

mkdir word-lm

# Get word-level transcript hypotheses
awk '{
printf("%s ", $1);
for (i=2;i<=NF;++i) {
  if ($i == "<space>")
    printf(" ");
  else
    printf("%s", $i);
}
printf("\n");
}' hypotheses-test_t > word-lm/hyp_word-test.txt;

awk '{
printf("%s ", $1);
for (i=2;i<=NF;++i) {
  if ($i == "<space>")
    printf(" ");
  else
    printf("%s", $i);
}
printf("\n");
}' hypotheses-validation_t > word-lm/hyp_word-validation.txt;

awk '{
printf("%s ", $1);
for (i=2;i<=NF;++i) {
  if ($i == "<space>")
    printf(" ");
  else
    printf("%s", $i);
}
printf("\n");
}' combined_hypotheses-test_t > word-lm/combined_hyp_word-test.txt;

awk '{
printf("%s ", $1);
for (i=2;i<=NF;++i) {
  if ($i == "<space>")
    printf(" ");
  else
    printf("%s", $i);
}
printf("\n");
}' combined_hypotheses-validation_t > word-lm/combined_hyp_word-validation.txt;


#ALINEAR LOS OUTPUT PARA GENERAR HIPOTESIS CON TRANSC 1-BEST Y TAGGING CORRECTO
# python $WorkDir/scripts/align_hypotheses.py word-lm/hyp_word-validation.txt word-lm/combined_hyp_word-validation.txt \
# word-lm/aligned_hypotheses-validation.txt

# python $WorkDir/scripts/align_hypotheses.py word-lm/hyp_word-test.txt word-lm/combined_hyp_word-test.txt \
# word-lm/aligned_hypotheses-test.txt

python $WorkDir/scripts/align_hypotheses.py hypotheses-validation_t  combined_hypotheses-validation_t  \
aligned_hypotheses-validation_t > log.txt

python $WorkDir/scripts/align_hypotheses.py hypotheses-test_t combined_hypotheses-test_t \
aligned_hypotheses-test_t > log.txt

#ALIGNMENT AT WORD LEVEL
python $WorkDir/scripts/align_hypotheses_wer.py hypotheses-validation_t  combined_hypotheses-validation_t  \
wer_aligned_hypotheses-validation_t > log.txt

python $WorkDir/scripts/align_hypotheses_wer.py hypotheses-test_t combined_hypotheses-test_t \
wer_aligned_hypotheses-test_t > log.txt


awk '{
printf("%s ", $1);
for (i=2;i<=NF;++i) {
  if ($i == "<space>")
    printf(" ");
  else
    printf("%s", $i);
}
printf("\n");
}' aligned_hypotheses-test_t > word-lm/aligned_hyp_word-test.txt;

awk '{
printf("%s ", $1);
for (i=2;i<=NF;++i) {
  if ($i == "<space>")
    printf(" ");
  else
    printf("%s", $i);
}
printf("\n");
}' aligned_hypotheses-validation_t  > word-lm/aligned_hyp_word-validation.txt;

awk '{
printf("%s ", $1);
for (i=2;i<=NF;++i) {
  if ($i == "<space>")
    printf(" ");
  else
    printf("%s", $i);
}
printf("\n");
}' wer_aligned_hypotheses-test_t > word-lm/wer_aligned_hyp_word-test.txt;

awk '{
printf("%s ", $1);
for (i=2;i<=NF;++i) {
  if ($i == "<space>")
    printf(" ");
  else
    printf("%s", $i);
}
printf("\n");
}' wer_aligned_hypotheses-validation_t  > word-lm/wer_aligned_hyp_word-validation.txt;


echo "==============" >> $WorkDir/res_exp.txt
echo "Resultados tras añadir LM" >> $WorkDir/res_exp.txt

#cd $TmpDir/decode/
#Compute CER/WER.
if $(which compute-wer &> /dev/null); then
echo "Test cer" >> $WorkDir/res_exp.txt
compute-wer --mode=present  ark:$LangDir/char/char.total.txt ark:hypotheses-test_t | grep WER | sed -r 's|%WER|%CER|g' >> $WorkDir/res_exp.txt;
echo "Test wer" >> $WorkDir/res_exp.txt
compute-wer --mode=present  ark:$LangDir/char/word.total.txt ark:word-lm/hyp_word-test.txt |  grep WER >> $WorkDir/res_exp.txt;

echo "Test cer (COMBINED)" >> $WorkDir/res_exp.txt
compute-wer --mode=present  ark:$LangDir/char/char.total.txt ark:combined_hypotheses-test_t | grep WER | sed -r 's|%WER|%CER|g' >> $WorkDir/res_exp.txt;
echo "Test wer (COMBINED)" >> $WorkDir/res_exp.txt
compute-wer --mode=present  ark:$LangDir/char/word.total.txt ark:word-lm/combined_hyp_word-test.txt |  grep WER >> $WorkDir/res_exp.txt;

echo "Test cer (ALIGNED)" >> $WorkDir/res_exp.txt
compute-wer --mode=present  ark:$LangDir/char/char.total.txt ark:aligned_hypotheses-test_t | grep WER | sed -r 's|%WER|%CER|g' >> $WorkDir/res_exp.txt;
echo "Test wer (ALIGNED)" >> $WorkDir/res_exp.txt
compute-wer --mode=present  ark:$LangDir/char/word.total.txt ark:word-lm/aligned_hyp_word-test.txt |  grep WER >> $WorkDir/res_exp.txt;

echo "Test cer (WER ALIGNED)" >> $WorkDir/res_exp.txt
compute-wer --mode=present  ark:$LangDir/char/char.total.txt ark:wer_aligned_hypotheses-test_t | grep WER | sed -r 's|%WER|%CER|g' >> $WorkDir/res_exp.txt;
echo "Test wer (WER ALIGNED)" >> $WorkDir/res_exp.txt
compute-wer --mode=present  ark:$LangDir/char/word.total.txt ark:word-lm/wer_aligned_hyp_word-test.txt |  grep WER >> $WorkDir/res_exp.txt;


sed 's/\([.,:;?]\)/ \1/g;s/\([¿¡]\)/\1 /g' word-lm/hyp_word-test.txt > SeparateSimbols-wordtest.txt
sed 's/\([.,:;?]\)/ \1/g;s/\([¿¡]\)/\1 /g' $LangDir/char/word.total.txt > SeparateSimbols-word.txt
sed 's/ \.line/\.line/g;s/ \.r\([0-9]\)/\.r\1/g;s/ \.region/\.region/g' -i SeparateSimbols-word.txt
sed 's/ \.line/\.line/g;s/ \.r\([0-9]\)/\.r\1/g;s/ \.region/\.region/g' -i SeparateSimbols-wordtest.txt
sed 's/</ </g' SeparateSimbols-wordtest.txt | sed 's/>/> /g' | sed 's/  / /g' > k; mv k SeparateSimbols-wordtest.txt
sed 's/</ </g' SeparateSimbols-word.txt | sed 's/>/> /g' | sed 's/  / /g' > k; mv k SeparateSimbols-word.txt



echo "Test wer separate" >> $WorkDir/res_exp.txt
compute-wer --mode=present ark:SeparateSimbols-word.txt ark:SeparateSimbols-wordtest.txt >> $WorkDir/res_exp.txt

echo "Test wer separate (fixed)" >> $WorkDir/res_exp.txt
python $WorkDir/scripts/fix_separate_symb_output_alt.py $TmpDir/decode/SeparateSimbols-wordtest.txt $TmpDir/decode/fixed_SeparateSimbols-wordtest.txt
python $WorkDir/scripts/fix_separate_symb_output_alt.py $TmpDir/decode/SeparateSimbols-word.txt $TmpDir/decode/fixed_SeparateSimbols-word.txt
compute-wer --mode=present ark:fixed_SeparateSimbols-word.txt ark:fixed_SeparateSimbols-wordtest.txt >> $WorkDir/res_exp.txt

sed 's/\([.,:;?]\)/ \1/g;s/\([¿¡]\)/\1 /g' word-lm/combined_hyp_word-test.txt > SeparateSimbols-wordtest.txt
sed 's/ \.line/\.line/g;s/ \.r\([0-9]\)/\.r\1/g' -i SeparateSimbols-wordtest.txt
sed 's/</ </g' SeparateSimbols-wordtest.txt | sed 's/>/> /g' | sed 's/  / /g' > k; mv k SeparateSimbols-wordtest.txt

echo "Test wer separate (COMBINED)" >> $WorkDir/res_exp.txt
compute-wer --mode=present ark:SeparateSimbols-word.txt ark:SeparateSimbols-wordtest.txt >> $WorkDir/res_exp.txt

sed 's/\([.,:;?]\)/ \1/g;s/\([¿¡]\)/\1 /g' word-lm/aligned_hyp_word-test.txt > SeparateSimbols-wordtest.txt
sed 's/ \.line/\.line/g;s/ \.r\([0-9]\)/\.r\1/g' -i SeparateSimbols-wordtest.txt
sed 's/</ </g' SeparateSimbols-wordtest.txt | sed 's/>/> /g' | sed 's/  / /g' > k; mv k SeparateSimbols-wordtest.txt

echo "Test wer separate (ALIGNED)" >> $WorkDir/res_exp.txt
compute-wer --mode=present ark:SeparateSimbols-word.txt ark:SeparateSimbols-wordtest.txt >> $WorkDir/res_exp.txt

sed 's/\([.,:;?]\)/ \1/g;s/\([¿¡]\)/\1 /g' word-lm/wer_aligned_hyp_word-test.txt > SeparateSimbols-wordtest.txt
sed 's/ \.line/\.line/g;s/ \.r\([0-9]\)/\.r\1/g' -i SeparateSimbols-wordtest.txt
sed 's/</ </g' SeparateSimbols-wordtest.txt | sed 's/>/> /g' | sed 's/  / /g' > k; mv k SeparateSimbols-wordtest.txt

echo "Test wer separate (WER ALIGNED)" >> $WorkDir/res_exp.txt
compute-wer --mode=present ark:SeparateSimbols-word.txt ark:SeparateSimbols-wordtest.txt >> $WorkDir/res_exp.txt

echo "--------------" >> $WorkDir/res_exp.txt
echo "Val cer" >> $WorkDir/res_exp.txt
compute-wer --mode=present  ark:$LangDir/char/char.total.txt ark:hypotheses-validation_t |   grep WER | sed -r 's|%WER|%CER|g' >> $WorkDir/res_exp.txt;

echo "Val wer" >> $WorkDir/res_exp.txt
compute-wer --mode=present  ark:$LangDir/char/word.total.txt ark:word-lm/hyp_word-validation.txt |  grep WER >> $WorkDir/res_exp.txt;

sed 's/\([.,:;?]\)/ \1/g;s/\([¿¡]\)/\1 /g' word-lm/hyp_word-validation.txt > SeparateSimbols-wordvalidation.txt
sed 's/ \.line/\.line/g;s/ \.r\([0-9]\)/\.r\1/g' -i SeparateSimbols-wordvalidation.txt
sed 's/</ </g' SeparateSimbols-wordvalidation.txt | sed 's/>/> /g' | sed 's/  / /g' > k; mv k SeparateSimbols-wordvalidation.txt

echo "Val wer separate" >> $WorkDir/res_exp.txt
compute-wer --mode=present ark:SeparateSimbols-word.txt ark:SeparateSimbols-wordvalidation.txt >> $WorkDir/res_exp.txt

rm Separate*

else
echo "ERROR: Kaldi's compute-wer was not found in your PATH!" >&2;
fi;

##########################################################################
## ORACLE METRICS

$WorkDir/scripts/oracle_transc.sh $TmpDir $LangDir/lm/lang $TmpDir/decode/lattices/

int2sym.pl -f 2- $LangDir/lm/lang_test/words.txt $TmpDir/decode/lattices/oracle_transc.txt > $TmpDir/decode/lattices/oracle_transc_t

#CALC CER WITH ORACLE_TRANSC
echo "ORACLE CER" >> $WorkDir/res_exp.txt
compute-wer --mode=present  ark:$lang/../../char/char.total.txt ark:$TmpDir/decode/lattices/oracle_transc_t | grep WER | sed -r 's|%WER|%CER|g' >> $WorkDir/res_exp.txt

#CALC WER
awk '{
printf("%s ", $1);
for (i=2;i<=NF;++i) {
  if ($i == "<space>")
    printf(" ");
  else
    printf("%s", $i);
}
printf("\n");
}' $TmpDir/decode/lattices/oracle_transc_t > $TmpDir/decode/lattices/word-lm/oracle_transc-test.txt;

sed 's/\([.,:;?]\)/ \1/g;s/\([¿¡]\)/\1 /g' $TmpDir/decode/lattices/word-lm/oracle_transc-test.txt > $TmpDir/decode/lattices/SeparateSimbols-wordtest.txt
sed 's/ \.line/\.line/g;s/ \.r\([0-9]\)/\.r\1/g' -i $TmpDir/decode/lattices/SeparateSimbols-wordtest.txt
sed 's/</ </g' $TmpDir/decode/lattices/SeparateSimbols-wordtest.txt | sed 's/>/> /g' | sed 's/  / /g' > k; mv k $TmpDir/decode/lattices/SeparateSimbols-wordtest.txt

echo "ORACLE WER (SEPARATE)" >> $WorkDir/res_exp.txt
compute-wer --mode=present ark:$TmpDir/decode/lattices/SeparateSimbols-word.txt ark:$TmpDir/decode/lattices/SeparateSimbols-wordtest.txt >> $WorkDir/res_exp.txt


##########################################################################
## EVALUACIÓN PRECISIÓN - RECALL
cd $TmpDir/decode/

python $WorkDir/scripts/fix_separate_symb_output.py $TmpDir/decode/SeparateSimbols-wordtest.txt $TmpDir/decode/fixed_SeparateSimbols-wordtest.txt
python $WorkDir/scripts/fix_separate_symb_output.py $TmpDir/decode/SeparateSimbols-word.txt $TmpDir/decode/fixed_SeparateSimbols-word.txt

cd $TmpDir
for f in $(<$PartDir/test.lst); do grep "${f}\b" ${TmpDir}/decode/fixed_SeparateSimbols-word.txt; done > ./fixed_SeparateSimbols-GT_test.txt

mkdir $WorkDir/PREC-REC
cd $WorkDir/PREC-REC/

rm -rf $WorkDir/PREC-REC/NOT_PARENTHESIZED_NER-GT
mkdir $WorkDir/PREC-REC/NOT_PARENTHESIZED_NER-GT
cd $WorkDir/PREC-REC/NOT_PARENTHESIZED_NER-GT
python $WorkDir/scripts/extract_ner_not_parenthesized_gw.py $TmpDir/fixed_SeparateSimbols-GT_test.txt ./
for f in *; do sed 's/^ //g' -i $f; done
cd ..

rm -rf $WorkDir/PREC-REC/NOT_PARENTHESIZED_NER-DECODE
mkdir $WorkDir/PREC-REC/NOT_PARENTHESIZED_NER-DECODE
cd $WorkDir/PREC-REC/NOT_PARENTHESIZED_NER-DECODE
python $WorkDir/scripts/extract_ner_not_parenthesized_gw.py $TmpDir/decode/fixed_SeparateSimbols-wordtest.txt ./
for f in *; do sed 's/^ //g' -i $f; done
cd ..

# ORACLE

rm -rf $WorkDir/PREC-REC/ORACLE_NER
mkdir $WorkDir/PREC-REC/ORACLE_NER
cd $WorkDir/PREC-REC/ORACLE_NER
$WorkDir/scripts/extractNERHip2.sh $TmpDir/decode/lattices/word-lm/oracle_transc-test.txt .
for f in *; do sed 's/^ //g' -i $f; done

cd ..

mkdir $WorkDir/PREC-REC/NER-GT
cd $WorkDir/PREC-REC/NER-GT
$WorkDir/scripts/extractNER-GT_GW.sh $TmpDir/SeparateSimbols-GT_test.txt .
for f in *; do sed 's/^ //g' -i $f; done

cd ..

#NER NORMAL
python $WorkDir/scripts/calc_prec_rec.py ./NOT_PARENTHESIZED_NER-GT ./NOT_PARENTHESIZED_NER-DECODE >> $WorkDir/res_exp.txt
python $WorkDir/scripts/dist_edicion_custom_saturated.py ./NER-GT ./NER-DECODE >> $WorkDir/res_exp.txt


echo "ORACLE NER RESULTS" >> $WorkDir/res_exp.txt
python $WorkDir/scripts/calc_prec_rec.py ./NER-GT ./ORACLE_NER >> $WorkDir/res_exp.txt
python $WorkDir/scripts/dist_edicion_custom_saturated.py ./NER-GT ./ORACLE_NER >> $WorkDir/res_exp.txt

######################################################################################################
## obtengo los NER y calculo el error

cd ..
mkdir NER
cd NER
../../scripts/extractNERHip.sh ../lattices/word-lm/hyp_word-test.txt .
for f in *; do sed 's/^ //g' -i $f; done 
cd ..

mkdir NER2
cd NER2
../../scripts/extractNERHip2.sh ../lattices/word-lm/hyp_word-test.txt .
for f in *; do sed 's/^ //g' -i $f; done
cd ..

mkdir NER-NoRep
cd NER-NoRep
../../scripts/extractNERHip-noRep.sh ../lattices/word-lm/hyp_word-test.txt .
for f in *; do sed 's/^ //g' -i $f; done

../scripts/evaluacioNER.sh ../NER/ ./NER/ ../PARTITIONS/test-lines.lst 
../scripts/evaluacioNER.sh ../NER/ ./NER2/ ../PARTITIONS/test-lines.lst
../scripts/evaluacioNER.sh ../NER-NoRep/ ./NER-NoRep/ ../PARTITIONS/test-lines.lst

##Ficheros para Chris Kermovant

for f in $(<../PARTITIONS/test-lines.lst); do echo "line "`basename ${f/.png/}`; echo "line "`basename ${f/.png/}` > list; ../scripts/evaluacioNER.sh ../NER/ ./NER2/ list ; done 2> /tmp/kk > kk

for f in $(<../PARTITIONS/test-lines.lst); do grep `basename ${f/.png/}`" " ../TEXT/index.words; done | sed 's/</ </g;s/>/> /g' | sed 's/  / /g' > Results/ref_word-test.txt
ed 's/</ </g;s/>/> /g' ./lattices/word-lm/hyp_word-test.txt | sed 's/  / /g' > Results/hyp_word-test.txt

for f in $(<../PARTITIONS/test-lines.lst); do echo "line "`basename ${f/.png/}`; echo "line "`basename ${f/.png/}` > list; ../scripts/evaluacioNER.sh ../NER/ ./NER2/ list ; done 2> /tmp/kk > kk  
grep -v "precision"  kk | awk '{printf $0" "; getline ; printf $0" "; getline; print $0" "}' | sed 's/line//g' > results
awk 'BEGIN{ref=0; hip=0;ac=0;}{ref=ref+$2; hyp=hyp+$3; ac=ac+$4}END{print ref,hyp,ac; precision=ac/hyp; recall=ac/ref;print precision" "recall }' results 


##################### Generar Grafos en formato HTK ###########################

mkdir Grafos
mkdir tmp_dir

lattice-copy "ark:gunzip -c ../lat-test.gz |" ark,t:lat-test.txt

awk -v RS= '{ print $0 > "tmp_dir/"$1".lat"}' lat-test.txt


mkdir words_lat
mkdir words-lat-out
cp ../../$ModelDir/HMMs/test/graph/words.txt .
awk '{print $1"& "$2}' words.txt > k; mv k words.txt

#para pasarlo a nivel de palabras
for f in tmp_dir/*.lat; do 
echo $f; 
n=`basename $f`

timeout -s 9 10s /home/vromero/software/lattice-char-to-word/lattice-char-to-word2/lattice-char-to-word --beam=10 --save-symbols="symbs"_${n/lat/sym} "1 2 3 4 5 6 714 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 95 97 98" ark:$f ark:tmp_dir/words.$n || /home/vromero/software/lattice-char-to-word/lattice-char-to-word2/lattice-char-to-word --beam=5 --save-symbols="symbs"_${n/lat/sym} "1 2 3 4 5 6 714 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 95 97 98" ark:$f ark:tmp_dir/words.$n

awk '{print $2" "$1}' symbs_${n/lat/sym} | sed 's/_/ /g' | int2sym.pl -f 2- words.txt | awk '{for(i=2;i<=NF;i++) printf("%s", $i); print " "$1}' > words.dic

lattice-copy ark:tmp_dir/words.$n  ark,t:- | int2sym.pl -f 3 words.dic > k; mv k words_lat/words.$n; 

/home/vromero/software/kaldi/egs/rm/s5/utils/convert_slf.pl words_lat/words.$n words-lat-out/

done

cd words-lat-out 
for f in *; do gunzip $f; done
for f in *; do sed 's/&//g' -i $f ;done 


##################### Generar Grafos de entidades ###########################

mkdir Grafos2
cd Grafos2
mkdir tmp_dir

lattice-copy "ark:gunzip -c ../lat-test.gz |" ark,t:lat-test.txt

awk -v RS= '{ print $0 > "tmp_dir/"$1".lat"}' lat-test.txt


mkdir words_lat
mkdir words-lat-out
cp ../../$ModelDir/HMMs/test/graph/words.txt .
awk '{print $1"& "$2}' words.txt > k; mv k words.txt

#para pasarlo a nivel de palabras

for f in tmp_dir/*.lat; do
echo $f;
n=`basename $f`

timeout -s 9 10s /home/vromero/software/lattice-char-to-word/lattice-char-to-word2/lattice-char-to-word --beam=10 --save-symbols="symbs"_${n/lat/sym} "16 17 18 19 20 22 23 24 25 26" ark:$f ark:tmp_dir/words.$n || /home/vromero/software/lattice-char-to-word/lattice-char-to-word2/lattice-char-to-word --beam=5 --save-symbols="symbs"_${n/lat/sym} "16 17 18 19 20 22 23 24 25 26" ark:$f ark:tmp_dir/words.$n

done 

for f in tmp_dir/*.lat; do
echo $f;
n=`basename $f`


awk '{print $2" "$1}' symbs_${n/lat/sym} | sed 's/_/ /g' | int2sym.pl -f 2- words.txt | awk '{for(i=2;i<=NF;i++) printf("%s", $i); print " "$1}' > words.dic

lattice-copy ark:tmp_dir/words.$n  ark,t:- | int2sym.pl -f 3 words.dic > k; mv k words_lat/words.$n;

/home/vromero/software/kaldi/egs/rm/s5/utils/convert_slf.pl words_lat/words.$n words-lat-out/

done

cd words-lat-out
for f in *; do gunzip $f; done
for f in *; do sed 's/&//g' -i $f ;done

