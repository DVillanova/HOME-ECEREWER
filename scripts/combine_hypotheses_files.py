#Script to combine hypotheses with synctactically correct outputs
#and the result of 1-best decoding to ensure that there is an output
#for each line (rescoring of lattices may produce empty outputs)

import sys

if len(sys.argv) != 4:
    print("Usage: python combine_hypotheses_files.py <path_correct_hyp_file> <path_1best_hyp_file> <path_combined_hyp_file>")
    print("<path_correct_hyp_file>: Path to the file with the rescored output (syntactically correct)")
    print("<path_1best_hyp_file>: Path with the result of 1-best decoding (may have syntactical errors)")
    print("<path_combined_hyp_file>: Path to the output file")
    sys.exit(1)

path_correct_hyp_file = sys.argv[1]
path_1best_hyp_file = sys.argv[2]
path_combined_hyp_file = sys.argv[3]

correct_hyp_file = open(path_correct_hyp_file, 'r')
best_hyp_file = open(path_1best_hyp_file, 'r')
combined_hyp_file = open(path_combined_hyp_file, 'w')

best_lines = dict()
not_modified_lines = set()

for l in best_hyp_file.readlines():
    (doc_id, transc) = l.split(" ", maxsplit=1)
    best_lines[doc_id] = transc

not_modified_lines = set(best_lines.keys())

#Overwrite best_lines with correct_lines
for l in correct_hyp_file.readlines():
    (doc_id, transc) = l.split(" ", maxsplit=1)
    best_lines[doc_id] = transc    
    not_modified_lines.remove(doc_id)

#Modify the lines which are syntactically wrong (TO DO!)
for doc_id in not_modified_lines:
    orig_hyp = best_lines[doc_id]
    print(orig_hyp)

    transc_split = orig_hyp.split(" ")
    
    corrected_hyp = list()
    ne_stack = list()
    last_correct_ind = 0

    #First look at the hypothesis to mark when to start the correction
    for i in range(0, len(transc_split)): 
        c_i = transc_split[i]

        if "<" in c_i and c_i != "<space>": #NE tags
            print(c_i)
            if "/" in c_i: #Closing tag
                matching_opening_tag = c_i.replace("/", "")
                if len(ne_stack) > 0 and ne_stack.pop() == matching_opening_tag: #Closing in correct order
                    pass
                else: #We found an error, stop the analysis
                    break;
            else: #Opening tag
                if c_i not in ne_stack: #Not in stack
                    ne_stack.append(c_i)
                else: #We found an error, stop the analysis
                    break;
        
        #Update last correct index on normal characters or after closing tag
        if len(ne_stack) == 0: 
            last_correct_ind = i

    for i in range(0, last_correct_ind+1): #Copy the transcript until the mark
        corrected_hyp.append(transc_split[i])      

    for i in range(last_correct_ind+1, len(transc_split)): #Copy the transcript removing the tags
        c_i = transc_split[i]
        if not("<" in c_i and c_i != "<space>"):
            corrected_hyp.append(c_i)
    
    str_corrected_hyp = " ".join(corrected_hyp)
    print(str_corrected_hyp)

    best_lines[doc_id] = str_corrected_hyp

for (doc_id, transc) in best_lines.items():
    out_str = doc_id + " " + transc 
    combined_hyp_file.write(out_str)
