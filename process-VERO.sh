# set -e
#IMPORTANTE PONER LOS LC
export LC_NUMERIC=C.UTF-8;

#Variables, parámetros y rutas para Docker
GPU=1
BatchSize=8
WorkDir=/root/directorioTrabajo/TFM-NER
PartDir=${WorkDir}/PARTITIONS
TextDir=${WorkDir}/TEXT
DataDir=${WorkDir}/DATA
LangDir=${WorkDir}/lang
CharDir=${LangDir}/char
ModelDir=${WorkDir}/model
TmpDir=${WorkDir}/TMP
NerDir=${WorkDir}/NER
NerNoRepDir=${WorkDir}/NER-NoRep

awk '{
printf("%s ", $1);
for (i=2;i<=NF;++i) {
  if ($i == "<space>")
    printf(" ");
  else
    printf("%s", $i);
}
printf("\n");
}' ${TmpDir}/decode/test-VERO.txt > ${TmpDir}/decode/wordtest-VERO.txt;