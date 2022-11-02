##############################################################
# ALTERNATIVE VERSION FOR CONTINUOUS TAGGING WITHOUT @O TAGS #
##############################################################

import sys

if len(sys.argv) != 3:
    print("Usage: python fix_separate_symb_output.py <path_input_separatesymb> <path_output_file>")
    sys.exit(1)

input_file = open(sys.argv[1], 'r')
output_file = open(sys.argv[2], 'w')

set_special_symbols = set()
set_special_symbols.add(".")
set_special_symbols.add(",")
set_special_symbols.add(":")
set_special_symbols.add(";")
set_special_symbols.add("?")
set_special_symbols.add("¿")
set_special_symbols.add("¡")

for l in input_file.readlines():
    try:
        l_id, transc = l.strip().split(" ", maxsplit=1)
    except:
        print("Error in line: {}".format(l))
        continue
    
    transc = transc.split(" ")
    #print(transc)
    out_str = l_id + " "
    
    for i in range(0, len(transc)):
        w_i = transc[i]
        if "@" not in w_i:
            if i < (len(transc)-1):
                next_w = transc[i+1]
                #print(w_i, next_w)                    
                if "@" in next_w and next_w.split("@")[0] in set_special_symbols:
                    next_w_tag = next_w.split("@")[1]
                    out_str += w_i + "@" + next_w_tag + " "
                else:
                    out_str += w_i + " "
            else:
                out_str += w_i + " "
        else:
            out_str += w_i + " "
    
    output_file.write(out_str+"\n")

input_file.close()
output_file.close()   
            