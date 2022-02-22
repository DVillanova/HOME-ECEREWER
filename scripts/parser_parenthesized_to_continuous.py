import sys

if len(sys.argv) != 3:
    print("Usage: python parser_parenthesized_to_continuous.py <path_index_input_file> <path_index_output_file>")
    print("path_index_input_file: path to the input file with Named Entities in the Ground Truth with parenthesized notation")
    print("path_index_output_file: path to the output file which will contain the Ground Truth with continuous notation for the Named Entiites")

path_index_input_file = sys.argv[1]
index_input_file = open(path_index_input_file, 'r')

path_index_output_file = sys.argv[2]
index_output_file = open(path_index_output_file, 'w')

#Read line-by-line the input file
for line in index_input_file.readlines():

    try:
        (id_line, text_line) = line.split(maxsplit=1)
    except ValueError:
        #print(curr_hyp)
        id_line = line
        text_line = ""

    #Add extra spaces to ensure correct split
    text_line = text_line.replace("<", " <")
    text_line = text_line.replace(">", "> ")

    text_line_split = text_line.split()
    stack_opened_ne = list()
    transformed_text_line = ""
    added_tags = False

    for w in text_line_split:
        #Closing NE
        if "</" in w:
            matching_ne = w[2:-1]
            
            #Debug
            if stack_opened_ne[-1] != matching_ne:
                print("ERROR EN LA LÍNEA ", id_line, " - SE CIERRA NE EN ORDEN INCORRECTO")
                print(text_line_split)
            else:
                stack_opened_ne.pop()
            

        #Start of NE
        elif "<" in w:
            if w != "<persName/>":
                #Include at the top of the stack
                stack_opened_ne.append(w[1:-1])

        #Any other word / symbol
        else:
            tags = " ".join(["@"+tag_ne for tag_ne in reversed(stack_opened_ne)])

            if tags != "":
                tags = tags + " "
                added_tags = True
            else:
                added_tags = False
                
            transformed_text_line = transformed_text_line + w + " " + tags
    

    if transformed_text_line == "":
        transformed_text_line = " "

    output_line = id_line + " " + transformed_text_line
    index_output_file.write(output_line + "\n")