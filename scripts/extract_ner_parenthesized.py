import sys
import os

if len(sys.argv) != 3:
    print("Usage: python extract_ner_gw.py <path_word_transc_file> <path_output_dir>")
    print("<path_word_transc_file>: Path to the input file with word-level transcription and parenthesized tagging")
    print("<path_output_dir>: Path to the directory on which to store the output files (one per line)")
    sys.exit(1)
    
input_file = open(sys.argv[1], 'r')
output_dir = sys.argv[2]

for l in input_file.readlines():
    try:
        l_id, transc = l.strip().split(" ", maxsplit=1)
    except:
        continue
    #Auxiliary stack to store nested ne state
    stack_ne = list()
    
    out_str = ""
    
    for w in transc.split(" "):
        w = w.strip() #Remove \n from words at end of line
        if "</" in w: #Closing of a NE => Reset to default
            tag = w.replace("</", "").replace(">", "")
            if tag in stack_ne: #If it is a valid closing of NE pop tags until it is reached
                nested_tag = stack_ne.pop()
                while nested_tag != tag:
                    nested_tag = stack_ne.pop()
            
        elif "<" in w: #Opening of NE
            tag = w.replace("<", "").replace(">", "")
            if tag not in stack_ne: #Only add if it is not already in the stack
                stack_ne.append(tag)
                
        else: #Normal word => Insert @tag@tag@tag
            if len(stack_ne) > 0 and len(w) > 0:
                tag_str = ""
                for t in stack_ne:
                    tag_str += "@" + t
                
                out_str += w + tag_str + "\n"
            
    if len(out_str) > 0:    
        output_file = open(os.path.join(output_dir, l_id + ".txt"), 'w')
        output_file.write(out_str + "\n")
        output_file.close()