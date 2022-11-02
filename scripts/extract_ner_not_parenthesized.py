import sys
import os

if len(sys.argv) != 3:
    print("Usage: python extract_ner_not_parenthesized_gw.py <path_input_separatesymbols_file> <path_output_dir>")
    print("<path_input_separatesymbols_file>: Path to fixed_separatesimbols file")
    print("<path_output_dir>: Path to the directory on which to store output files")
    sys.exit(1)
    
input_file = open(sys.argv[1], 'r')
output_dir = sys.argv[2]

if not os.path.isdir(output_dir):
    print("Error: <path_output_dir> is wrong, does the directory exist?")
    sys.exit(1)

for l in input_file.readlines():
    l_id, transc = l.strip().split(" ", maxsplit=1)
    output_file = False
    
    
    for w in transc.split(" "):
        # Version for continuous tagging (with @O or without @O)
        if "@" in w and "@O" not in w:
            if not output_file:
                output_file = open(os.path.join(output_dir, l_id + ".txt"), 'w')
            output_file.write(w + "\n")
            
    if output_file:
        output_file.close()
