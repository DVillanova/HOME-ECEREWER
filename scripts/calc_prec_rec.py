import sys, os

if len(sys.argv) != 3:
    print("Uso: python3 calc_prec_rec.py <ruta_a_carpeta_ner_gt> <ruta_a_carpeta_ner_hyp>")
    print("<carpeta_ner_gt>: Carpeta con la extracción de entidades nombradas sobre los archivos de ground truth.")
    print("<carpeta_ner_hyp>: Carpeta con la extracción de entidades nombradas sobre las hipótesis generadas.")
    sys.exit(1)

path_ner_gt_folder = sys.argv[1]
#print(path_ner_gt_folder)
files_ner_gt = os.listdir(path_ner_gt_folder)

path_ner_hyp_folder = sys.argv[2]
#print(path_ner_hyp_folder)
files_ner_hyp = os.listdir(path_ner_hyp_folder)

true_positives = 0
false_positives = 0
true_positives_2 = 0
false_negatives = 0

#Calculo true positives y false positives
for f in files_ner_hyp:
    ner_hyp = ""
    path_file_hyp = os.path.join(path_ner_hyp_folder, f) 
    if os.path.exists(path_file_hyp):
        with open(path_file_hyp, 'r') as file_hyp:
            ner_hyp = file_hyp.read()
    
    ner_gt = ""
    path_file_gt = os.path.join(path_ner_gt_folder, f) 
    if os.path.exists(path_file_gt):
        with open(path_file_gt, 'r') as file_gt:
            ner_gt = file_gt.read()
    
    #DEBUG PRINT
    # print(os.path.join(path_ner_hyp_folder, f))
    # print(ner_hyp)
    # print(os.path.join(path_ner_gt_folder, f))
    # print(ner_gt)

    for named_entity in ner_hyp.splitlines():
        if named_entity in ner_gt:
            true_positives = true_positives + 1
        else:
            false_positives = false_positives + 1
        
print("TRUE POSITIVES:", true_positives)

#Calculo false negatives
for f in files_ner_gt:
    ner_hyp = ""
    path_file_hyp = os.path.join(path_ner_hyp_folder, f) 
    if os.path.exists(path_file_hyp):
        with open(path_file_hyp, 'r') as file_hyp:
            ner_hyp = file_hyp.read()
    
    ner_gt = ""
    path_file_gt = os.path.join(path_ner_gt_folder, f) 
    if os.path.exists(path_file_gt):
        with open(path_file_gt, 'r') as file_gt:
            ner_gt = file_gt.read()
    
    #ERROR: ESTO NO SE ESTÁ RECORRIENDO COMO YO CREO
    for named_entity in ner_gt.splitlines():
        if named_entity not in ner_hyp:
            false_negatives = false_negatives + 1
        else:
            true_positives_2 = true_positives_2 + 1

print("TRUE POSITIVES (CHECKSUM):", true_positives_2)
print("")

true_positives = max(true_positives, true_positives_2)

print("TRUE POSITIVES:", true_positives)
print("FALSE POSITIVES:", false_positives)
precision = (true_positives / (true_positives + false_positives))
print("PRECISION %.5f" % (precision))
print("")
print("TRUE POSITIVES:", true_positives)
print("FALSE NEGATIVES:", false_negatives)
recall = (true_positives / (true_positives + false_negatives))
print("RECALL %.5f" % (recall))
print("")
print("F1: %.5f" % (2*(precision * recall) / (precision + recall)))