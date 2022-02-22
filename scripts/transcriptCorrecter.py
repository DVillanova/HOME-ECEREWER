import sys, os

#Open system hypothesis, remove \n
hyp_lines = list()
with open('../TMP/decode/wordtest.txt', 'r') as fich_hyp:
    hyp_lines = list(map(lambda x: x.strip(), fich_hyp.readlines()))

#Open new file to save the complete corrected hypothesis
fich_correct = open('../TMP/decode/corrected_wordtest.txt', 'w')
#New file to save the lines which needed correction
fich_corrected_lines = open('../TMP/decode/lines_corrected_test.txt', 'w')


for line in hyp_lines:
    needed_correction = False

    #Save first part of the string (line id)
    id_line = line.split()[0]
    
    #Save a copy of the original line for later usage
    line_copy = line

    #We work with the transcription, remove the line id and have everything separated with a space
    sep = " "

    #Separate ID from Transcription
    line = line.split(maxsplit=1)
    if len(line) == 1:
        #Special case where the line doesn't have a transcription
        fich_correct.write(id_line + " \n")
        continue

    line = line[1]

    #Fix some common spacing mistakes
    #And add additional spaces to '.', ',', ';'
    line = line.replace("<", " <")
    line = line.replace(">", "> ")
    line = line.replace(",", " , ")
    line = line.replace(".", " . ")
    line = line.replace(";", " ; ")

    line = line.split()

    ne_stack = list()
    last_correct_ind = 0
    correct_hyp = list()

    #Read each "word" in the transcription
    for i in range(0, len(line)):
        w = line[i]
        #NE is closed
        if "</" in w:
            matching_open_ne = w.replace("/", "")
            #Check if the closed NE was in the stack (might need correction to close NEs in order)
            if matching_open_ne in ne_stack:
                #Close other NEs in order
                while ne_stack[-1] != matching_open_ne:
                    ne_head = ne_stack.pop()
                    closed_ne = ne_head.replace("<", "</")
                    correct_hyp.append(closed_ne)
                    needed_correction = True

                #Close the head of the stack
                ne_head = ne_stack.pop()
                closed_ne = ne_head.replace("<", "</")
                correct_hyp.append(closed_ne)
                
                #Save a checkpoint for inserting NE opening tags
                last_correct_ind = len(correct_hyp)

            #If it was not, we have to append a NE opener beforehand
            else:
                needed_correction = True

                #ACT AS IF THE CLOSING TAG WAS NOT THERE
                #correct_hyp.insert(last_correct_ind, matching_open_ne)
                #Also append the closing tag. No need to work with the stack
                #correct_hyp.append(w)

                #Save a checkpoint for future use
                #last_correct_ind = len(correct_hyp)

        #NE is opened
        elif "<" in w:
            #Check if there is an opened NE of the same type in the stack
            if w in ne_stack:
                #In that case, try to fix the situation by closing the stacked NEs in order
                while ne_stack[-1] != w:
                    ne_head = ne_stack.pop()
                    closed_ne = ne_head.replace("<", "</")
                    correct_hyp.append(closed_ne)
                
                #Close the head of the stack which is equal to the opened NE
                ne_head = ne_stack.pop()
                closed_ne = ne_head.replace("<", "</")
                correct_hyp.append(closed_ne)
                
                #Append the new NE to the stack and the hypothesis
                correct_hyp.append(w)
                ne_stack.append(w)

                needed_correction = True

                #Save a checkpoint for future use
                last_correct_ind = len(correct_hyp)

            #In the other case, just append the NE to the stack and the hypothesis
            else:
                correct_hyp.append(w)
                ne_stack.append(w)
                
                #Save a checkpoint for future use
                last_correct_ind = len(correct_hyp)
            
        #End of a sentence, empty the stack
        elif w == ".":
            while len(ne_stack) > 0:
                ne_head = ne_stack.pop()
                closed_ne = ne_head.replace("<", "</")
                correct_hyp.append(closed_ne)
                needed_correction = True

            correct_hyp.append(w)
            
            #Save a checkpoint for future use
            last_correct_ind = len(correct_hyp)
        #A normal word
        else:
            correct_hyp.append(w)
        
    #The stack was not empty upon line ending, we have to deplete it
    while len(ne_stack) > 0:
        ne_head = ne_stack.pop()
        closed_ne = ne_head.replace("<", "</")
        correct_hyp.append(closed_ne)
        needed_correction = True


    str_correct_hyp = sep.join(correct_hyp)
    #str_correct_hyp = str_correct_hyp.replace(" <", "<")
    #str_correct_hyp = str_correct_hyp.replace("> ", ">")
    str_correct_hyp = str_correct_hyp.replace(" .", ".")
    str_correct_hyp = str_correct_hyp.replace(" ,", ",")
    str_correct_hyp = str_correct_hyp.replace(",<", ", <")
    str_correct_hyp = str_correct_hyp.replace(".<", ". <")
    str_correct_hyp = str_correct_hyp.replace(">,", "> ,")
    str_correct_hyp = str_correct_hyp.replace(">.", "> .")
    correct_line = id_line + " " + str_correct_hyp
    fich_correct.write(correct_line + "\n")

    if needed_correction:
        fich_corrected_lines.write(id_line + "\n")
        fich_corrected_lines.write(line_copy + "\n")
        fich_corrected_lines.write(correct_line + "\n")