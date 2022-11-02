import os
import sys
import re

if len(sys.argv) != 3:
    print("Usage: python extract_ner_not_nested <path_input_file> <path_output_folder>")
    print("<path_input_file>: File with ID and transcription for each line")
    print("<path_output_folder>: Folder where for each line a file will be generated with its NE")

path_input_file = sys.argv[1]
input_file = open(path_input_file, 'r')

path_output_folder = sys.argv[2]

for l in input_file.readlines():
    (out_filename, transc) = l.split(sep = " ", maxsplit = 1)
    out_filename = out_filename + ".txt"


    #Add additional spaces for split
    transc = transc.replace("<", " <")
    transc = transc.replace(">", "> ").strip()

    split_transc = re.split("\s+", transc)
    
    named_entity = ""
    named_entity_tag = ""
    for w in split_transc:
        #Closing the named entity that was opened
        if "</" in w:
            if named_entity_tag != "" and named_entity_tag in w:
                named_entity = named_entity + " " + w + "\n"
                
                #Reset control variable
                named_entity_tag = ""

        #Opening a named entity (forgo nested NEs)
        elif "<" in w:
            if named_entity_tag == "":
                named_entity = named_entity + w
                named_entity_tag = w[1:-1]

        #Normal words inside a named entity
        elif named_entity_tag != "":
            named_entity = named_entity + " " + w

        #Normal words outside named entities (discard)
        else:
            pass
    
    #Cerrar named entities que se hayan quedado abiertas
    if named_entity_tag != "":
        named_entity = named_entity + " </" + named_entity_tag + ">\n"
    
    if named_entity != "":
        out_file = open(os.path.join(path_output_folder, out_filename), 'w')
        out_file.write(named_entity)
        out_file.close()


input_file.close()
