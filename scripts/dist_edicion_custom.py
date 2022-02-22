import os
#import fastwer

root_dir = "/home/dvillanova/hunterFinal/directorioTrabajo/TFM-NER/"

#Coste = CER o WER normalizado
def calc_dist_sus(dec_ne, gt_ne, char_level):
    #Comprobar coincidencia etiquetas
    if dec_ne.split()[0] != gt_ne.split()[0]:
        return 2.0
    
    clean_dec_ne = ' '.join(filter(lambda x: x[0] != '<', dec_ne.split()))
    clean_gt_ne = ' '.join(filter(lambda x: x[0] != '<', gt_ne.split()))

    if not char_level:
        clean_dec_ne = clean_dec_ne.split()
        clean_gt_ne = clean_gt_ne.split()
    
    #Tuplas de (dist, corr.  )
    vec_dist_pre = [(i, 0) for i in range(len(clean_gt_ne) + 1)]
    vec_dist_act = [(0, 0)] * (len(clean_gt_ne) + 1)

    for j in range(len(clean_dec_ne)):
        vec_dist_act[0] = (j+1, 0)
        for i in range(len(clean_gt_ne)):
            dist_ins = (vec_dist_act[i][0] + 1, vec_dist_act[i][1])
            dist_bor = (vec_dist_pre[i+1][0] + 1, vec_dist_pre[i+1][1])
            
            cost_sus = 0 if clean_dec_ne[j] == clean_gt_ne[i] else 1
            dist_sus = (vec_dist_pre[i][0] + cost_sus, vec_dist_pre[i][1] + (1-cost_sus))

            vec_dist_act[i+1] = min(dist_ins, dist_bor, dist_sus)
            # print(dist_ins, dist_bor, dist_sus)
            # print(i, j, clean_dec_ne[j], clean_gt_ne[i], cost_sus, vec_dist_act[i+1])
        
        vec_dist_pre, vec_dist_act = vec_dist_act, vec_dist_pre
    
    return 2*(vec_dist_pre[-1][0] / float(sum(vec_dist_pre[-1])))


def calc_dist_ed(dec_ne_list, gt_ne_list, char_level):
    vec_dist_pre = [i for i in range(len(gt_ne_list) + 1)]
    vec_dist_act = [0] * (len(gt_ne_list) + 1)

    for j in range(len(dec_ne_list)):
        vec_dist_act[0] = j+1
        for i in range(len(gt_ne_list)):
            dist_ins = vec_dist_act[i] + 1
            dist_bor = vec_dist_pre[i+1] + 1
            dist_sus = vec_dist_pre[i] + calc_dist_sus(dec_ne_list[j], gt_ne_list[i], char_level)
            
            vec_dist_act[i+1] = min(dist_ins, dist_bor, dist_sus) 
    
        vec_dist_pre, vec_dist_act = vec_dist_act, vec_dist_pre

    return vec_dist_pre[-1]


with open(root_dir + "TMP/test.lst", "r") as file_list:
    test_list = list(map(lambda x: x.strip()+'.txt', file_list.readlines()))

#VARIABLES
num_dist_wer = 0.0
den_dist_wer = 0.0
num_dist_cer = 0.0
den_dist_cer = 0.0

#print(test_list)
for test_filename in test_list:
    #Intentar abrir archivos
    exists_gt = True        
    exists_dec = True
    
    dec_ne_list = list()
    gt_ne_list = list()

    #Hipótesis
    try:
        with open(root_dir + "PREC-REC/NER-CORRECTED/" + test_filename, "r") as f:
            dec_ne_list = list(map(lambda x: x.strip(), f.readlines()))
    except:
        exists_dec = False

    #Referencia
    try:
        with open(root_dir + "PREC-REC/NER-GT/" + test_filename, "r") as f:
            gt_ne_list = list(map(lambda x: x.strip(), f.readlines()))
    except:
        exists_gt = False

    #Si no se abre ninguno continuar
    if (not exists_dec) and (not exists_gt):
        continue

    #Sumar numero de n.e. a denominador
    den_dist_wer = den_dist_wer + len(dec_ne_list) + len(gt_ne_list)
    den_dist_cer = den_dist_cer + len(dec_ne_list) + len(gt_ne_list)

    #Si se abre 1 sumar errores
    if exists_dec ^ exists_gt:
        num_dist_wer = num_dist_wer + len(dec_ne_list) + len(gt_ne_list)
        num_dist_cer = num_dist_cer + len(dec_ne_list) + len(gt_ne_list)
        continue
        
    #Si se abren 2 calcular distancias
    num_dist_wer = num_dist_wer + calc_dist_ed(dec_ne_list, gt_ne_list, False)
    num_dist_cer = num_dist_cer + calc_dist_ed(dec_ne_list, gt_ne_list, True)

print("ERROR (WER) = {}".format(num_dist_wer/den_dist_wer))
print("ERROR (CER) = {}".format(num_dist_cer/den_dist_cer))