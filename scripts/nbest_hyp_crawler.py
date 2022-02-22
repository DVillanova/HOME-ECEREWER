#Obtains the best hypothesis for each line that complies with the NE syntax
#Input: n-best hypothesis (word level)
#Out: best compliant hypothesis

import sys, os

if len(sys.argv) < 3 or len(sys.argv) > 5:
    print("Usage: python3 nbest_hyp_crawler.py <path_to_nbest_hyp_input> <path_to_hyp_output> [path_to_histogram_output] [path_to_log_output]")
    print("path_to_nbest_hyp_input: Path to a file with the n-best transcriptions for each line. Format: [<id_line> <transcription>]")
    print("path_to_hyp_output: Path to the output file, which will contain only 1 transcription for each line. Format: [<id_line> <transcription>]")
    print("path_to_histogram_output: Path to the output histogram file, which will contain for each index i the number of times that the i-best hypothesis has been considered valid")
    print("path_to_log_output: Path to a verbose file. If none is specified then no logging will occur.")
    sys.exit(1)

path_nbest_hyp = sys.argv[1]
hyp_file = open(path_nbest_hyp, 'r')

path_output = sys.argv[2]
out_file = open(path_output, 'w')

histogram_file = False
if len(sys.argv) >= 4:
    path_histogram = sys.argv[3]
    histogram_file = open(path_histogram, 'w')

log_file = False
if len(sys.argv) == 5:
    path_log_output = sys.argv[4]
    log_file = open(path_log_output, 'w')


line_id = ""
best_hyp = ""
index_best_hyp = 0
index_current_hyp = 0 
found_correct_transcription = True

histogram = dict()

while True:
    

    curr_hyp = hyp_file.readline()
    
    if curr_hyp == "":
        break

    curr_hyp = curr_hyp.strip()

    try:
        (curr_hyp_id, curr_transcription) = curr_hyp.split(maxsplit=1)
    except ValueError:
        #print(curr_hyp)
        curr_hyp_id = curr_hyp
        curr_transcription = ""

    #Remove the -N from the tail of the hyp_id to reveal the line id
    sep = "-"
    curr_line_id = sep.join(curr_hyp_id.split("-")[:-1]) 

    #If we are starting to look at a new line
    if curr_line_id != line_id:
        #If we did not find a transcription that satisfied the constraints
        if not found_correct_transcription:
            out_str = line_id + " " + best_hyp + "\n"
            out_file.write(out_str)

            #ADD INDEX TO THE DICTIONARY FOR A LATER HISTOGRAM PRINT
            val_hist = histogram.get(0, 0)
            histogram[0] = val_hist + 1


        #print(curr_hyp_id.split("-")[-1]) # Sanity check: should give always 1

        #Start to analyze the N-best hypothesis of a new line
        line_id = curr_line_id
        best_hyp = curr_transcription
        found_correct_transcription = False

        #Reset hyp index
        index_current_hyp = 0
    
    #Update index for current hypothesis
    index_current_hyp += 1
    
    
    #Analyze the transcription only if we haven't found a compliant transcription
    if not found_correct_transcription:
        ne_stack = list()

        curr_transcription_copy = "" + curr_transcription
        curr_transcription_copy = curr_transcription_copy.replace("<", " <")
        curr_transcription_copy = curr_transcription_copy.replace(">", "> ")
        curr_transcription_copy = curr_transcription_copy.replace(",", " , ")
        curr_transcription_copy = curr_transcription_copy.replace(".", " . ")
        curr_transcription_copy = curr_transcription_copy.replace(";", " ; ")

        curr_transcription_copy = curr_transcription_copy.split()

        detected_mistakes = False

        #Read the transcription until we observe a mistake
        for w in curr_transcription_copy:
            if "</" in w:
                if len(ne_stack) == 0:
                    #ERROR DETECTED: CLOSING A NE WHEN NO NEs WERE OPEN
                    detected_mistakes = True

                    if log_file:
                        log_file.write("ERROR: CLOSING A NE WHEN NO NEs WERE OPEN\n")
                        log_file.write(curr_transcription + "\n")

                    break
                
                matching_open_ne = w.replace("/", "")
                ne_head = ne_stack.pop()
                if ne_head != matching_open_ne:
                    #ERROR DETECTED: THE NEs AREN'T BEING CLOSED IN THE CORRECT ORDER
                    detected_mistakes = True

                    if log_file:
                        log_file.write("ERROR: THE NEs AREN'T BEING CLOSED IN THE CORRECT ORDER\n")
                        log_file.write(curr_transcription + "\n")

                    break

            elif "<" in w:
                if w in ne_stack:
                    #ERROR DETECTED: OPENING OF A NE WHICH IS ALREADY IN THE STACK
                    detected_mistakes = True

                    if log_file:
                        log_file.write("ERROR: OPENING OF A NE WHICH IS ALREADY IN THE STACK\n")
                        log_file.write(curr_transcription + "\n")

                    break

                else:
                    ne_stack.append(w)

            elif "." == w:
                if len(ne_stack) != 0:
                    #ERROR DETECTED: SOME NEs REMAIN OPEN BEFORE READING A DOT
                    detected_mistakes = True

                    if log_file:
                        log_file.write("ERROR: SOME NEs REMAIN OPEN BEFORE READING A DOT\n")
                        log_file.write(curr_transcription + "\n")

                    break
        
        if len(ne_stack) == 0 and not detected_mistakes:
            #No mistakes were found during the parsing and all the NEs were closed
            #Print the current transcription
            found_correct_transcription = True
            out_str = line_id + " " + curr_transcription + "\n"
            out_file.write(out_str)

            #print("EL CRAWLER HA ENCONTRADO UNA HIPÓTESIS VÁLIDA EN LAS N-BEST", line_id)
            
            #ADD INDEX TO THE DICTIONARY FOR A LATER HISTOGRAM PRINT
            val_hist = histogram.get(index_current_hyp, 0)
            histogram[index_current_hyp] = val_hist + 1


        elif not detected_mistakes:
            if log_file:
                log_file.write("ERROR: SOME NEs REMAIN OPEN UPON LINE ENDING\n")
                log_file.write(curr_transcription + "\n")

    
#HISTOGRAM OUTPUT
if histogram_file:
    indexes = histogram.keys()
    max_index = max(indexes)
    for i in range(0, max_index + 1):
        val_hist = histogram.get(i, 0)
        histogram_file.write(str(val_hist) + "\n")