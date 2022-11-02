#Script to include correct tagging in 1-best hypotheses via alignment of outputs at char level
import sys
import numpy as np
from copy import deepcopy

#WER path
def best_wer_path(best_hyp, correct_hyp):

    #Matriz de distancias [i][j][0] y backpointers [i][j][1] [i][j][2]
    mat_dist = [[(0,0,0) for _ in range((len(correct_hyp)+1))] for _ in range((len(best_hyp)+1))] 

    for i in range(1, len(best_hyp) + 1):
        mat_dist[i][0] = (i,i-1,0)

    for j in range(1, len(correct_hyp) + 1):
        mat_dist[0][j] = (j,0,j-1)

    for j in range(1,len(correct_hyp)+1):
        for i in range(1,len(best_hyp)+1):
            tup_dist_ins = (mat_dist[i-1][j][0] + 1, i-1, j)
            tup_dist_del = (mat_dist[i][j-1][0] + 1, i, j-1)
            
            cost_sus = 0 if correct_hyp[j-1] == best_hyp[i-1] else 2
            tup_dist_sus = (mat_dist[i-1][j-1][0] + cost_sus, i-1, j-1)

            #Get the transition with minimum cost and the corresponding backpointers
            mat_dist[i][j] = min(tup_dist_ins, tup_dist_del, tup_dist_sus)
    
    #Retrieve the path using the backpointers
    i = len(best_hyp)
    j = len(correct_hyp)
    best_path = [(i,j,0,mat_dist[i][j][1],mat_dist[i][j][2])]

    #General case of the path
    while i > 0 or j > 0:
        (prev_i,prev_j) = (mat_dist[i][j][1], mat_dist[i][j][2])
        cost_op = mat_dist[i][j][0] - mat_dist[prev_i][prev_j][0]
        best_path = [(prev_i,prev_j,cost_op,i,j)] + best_path

        (i,j) = (prev_i,prev_j)
    
    return best_path


## MAIN ##
if len(sys.argv) < 4:
    print("Usage: python align_hypotheses.py <path_best_file> <path_correct_file> <path_output_file> [path_gt_file]")
    print("<path_best_file>: Path to the file with the 1-best hypothesis for each of the lines")
    print("<path_correct_file>: Path to the file with the rescored output (correct tagging)")
    print("<path_output_file>: Path to the output file on which to store the results")
    print("[path_gt_file]: Path to the file with the ground truth transcriptions")
    sys.exit(1)

path_best_file = sys.argv[1]
path_correct_file = sys.argv[2]
path_output_file = sys.argv[3]

gt_dic = dict()

if len(sys.argv) >= 5:
    path_gt_file = sys.argv[4]
    gt_file = open(path_gt_file, 'r')
    
    for l in gt_file.readlines():
        (l_id, transc) = l.split(" ", maxsplit=1)
        gt_dic[l_id] = "".join([" " if c == "<space>" else c for c in transc.split()]).split()

    gt_file.close()


best_file = open(path_best_file, 'r')
correct_file = open(path_correct_file, 'r')
output_file = open(path_output_file, 'w')

#hyp_id_list = [l.split(" ", maxsplit=1)[0] for l in best_file.readlines()]
best_hyp_list = [l.split(" ", maxsplit=1) for l in best_file.readlines()]
correct_hyp_list = [l.split(" ", maxsplit=1) for l in correct_file.readlines()]
best_file.close()
correct_file.close()
aligned_hyp_list = list()
counter = 0

for h_idx in range(len(best_hyp_list)):
    best_hyp = "".join([" " if c == "<space>" else c for c in best_hyp_list[h_idx][1].split()]).split()
    correct_hyp = "".join([" " if c == "<space>" else c for c in correct_hyp_list[h_idx][1].split()]).split()
    counter += 1

    #print("EXAMPLE NR. {}".format(counter))

    best_path = best_wer_path(best_hyp, correct_hyp)

    aligned_hyp = deepcopy(correct_hyp)
    offset_index = -1

    #print("Original best hypothesis: {}".format(" ".join(best_hyp)))
    #print("Original correctly tagged hypothesis: {}".format(" ".join(aligned_hyp)))
    if len(gt_dic) > 0:
        l_id = best_hyp_list[h_idx][0]
        gt_transc = gt_dic.get(l_id, [])
        #print("Ground Truth transcription: {}".format(" ".join(gt_transc)))
    #print("==============")
    
    for t_index in range(0, len(best_path)):
        (prev_i, prev_j, cost_op, i, j) = best_path[t_index]
        delta_i = i - prev_i
        delta_j = j - prev_j

        #print(prev_i, prev_j, cost_op, i, j)

        op_type = "S"
        if delta_j == 0:
            op_type = "I"
        elif delta_i == 0:
            op_type = "D"
        
        word_best_hyp = "" if i == 0 else best_hyp[i-1]
        word_corr_hyp = "" if j == 0 else correct_hyp[j-1]

        if "<" not in word_corr_hyp and "<" not in word_best_hyp: #Normal words, do the OP
            if op_type == "S":
                aligned_hyp[j + offset_index] = word_best_hyp
            
            if op_type == "I":
                aligned_hyp.insert(j + offset_index + 1, word_best_hyp)
                offset_index = offset_index + 1

            if op_type == "D":
                aligned_hyp.pop(j + offset_index)
                offset_index = offset_index - 1

        elif "<" not in word_corr_hyp: #Normal word to ne_tag
            if op_type == "S" or op_type == "D": #Treat both as deletions of word_corr_hyp
                aligned_hyp.pop(j + offset_index)
                offset_index = offset_index - 1  
            else: #Skip insertions of ne_tags from best_hyp
                pass

        elif "<" not in word_best_hyp: #ne_tag to normal_word
            if op_type == "I" or op_type == "S": #Treat both as insertions of word_best_hyp
                #offset_index = offset_index + 1 #Maybe we want to add after the tag
                aligned_hyp.insert(j + offset_index + 1, word_best_hyp)
                offset_index = offset_index + 1

            else: #Keep tags from corr_hyp
                pass
            
        else: #ne_tag to ne_tag
            if op_type == "S" or op_type == "I" or op_type =="D": #Always keep tag at corr_hyp
                pass
        
        #print("prev_i: {}, prev_j: {}, cost_op: {}, i: {}, j: {}, op_type: {}".format(
        #    prev_i, prev_j, cost_op, i, j, op_type
        #))
        #print("word_best_hyp: {}, word_corr_hyp: {}".format(word_best_hyp, word_corr_hyp))
        #print("Partial modified correct hypothesis: {}".format(" ".join(aligned_hyp[:j+offset_index+1])))
        #print("============")


    #print("Original best hypothesis  : {}".format(" ".join(best_hyp)))
    #print("Original correctly tagged : {}".format(" ".join(aligned_hyp)))
    if len(gt_dic) > 0:
        l_id = best_hyp_list[h_idx][0]
        gt_transc = gt_dic.get(l_id, [])
        #print("Ground Truth transcription: {}".format(" ".join(gt_transc)))
    #print("Final modified correct hyp: {}\n\n\n".format(" ".join(aligned_hyp)))
    
    #Needs to be corrected to reconstruct hyp at char level
    aligned_hyp = " ".join("<space>".join(aligned_hyp))
    aligned_hyp = aligned_hyp.split(" ")
    reconstructed_aligned_hyp = []

    inside_special_char = False
    special_char_substr = ""

    for c in aligned_hyp:
        if '<' in c:
            special_char_substr = "<"
            inside_special_char = True
        elif '>' in c:
            special_char_substr += ">"
            reconstructed_aligned_hyp.append(special_char_substr)

            inside_special_char = False
            special_char_substr = ""
        else:
            if inside_special_char:
                special_char_substr += c
            else:
                reconstructed_aligned_hyp.append(c)

    aligned_hyp_list.append(best_hyp_list[h_idx][0] + " " + " ".join(reconstructed_aligned_hyp))

    #if counter >= 10:
    #   sys.exit(0)

for hyp in aligned_hyp_list:
    output_file.write("{}\n".format(hyp))

output_file.close()