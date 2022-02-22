import sys

if len(sys.argv) != 3:
    print("Usage: python char_transcript_extractor.py <path_word_file> <path_char_file>")
    print("path_word_file: path to the input file with the hypotheses at word level")
    print("path_char_file: path to the output file which will contain the hypotheses at character level")

path_word_file = sys.argv[1]
word_file = open(path_word_file, 'r')

path_char_file = sys.argv[2]
char_file = open(path_char_file, 'w')


hyp_line = word_file.readline()
while hyp_line != "":
    hyp_line = hyp_line.strip()
    hyp_line = hyp_line.replace("<", " <")
    hyp_line = hyp_line.replace(">", "> ")
    hyp_line = hyp_line.split()
    line_id = hyp_line[0]
    line_transcription = hyp_line[1:]

    char_str = str(line_id) + " "
    add_space = False

    for w in line_transcription:
        #Case in which there is an opening / closing tag
        if w[0] == "<":
            char_str = char_str + w + " "
            add_space = False
        #Normal word -> split characters and add "<space>" if previous word was not a tag
        else:
            if add_space:
                char_str = char_str + "<space> "
            
            #Split
            split_w = list(w)

            for c in split_w:
                char_str = char_str + c + " "

            add_space = True

    #Write the reconstructed line
    char_file.write(char_str + "\n")
    
    #Read the next line
    hyp_line = word_file.readline()