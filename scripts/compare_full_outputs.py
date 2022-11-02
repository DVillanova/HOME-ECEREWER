#From 2 folders, compute the number of hypotheses which are different
#and print them on screen

import sys
import os

if len(sys.argv) != 4:
    print("Usage: python compare_full_outputs <path_to_file_1> <path_to_file_2> <path_to_log_file>")
    print("<path_to_file_1>: Path to the first hyp. file")
    print("<path_to_file_2>: Path to the second hyp. file")
    print("<path_to_log_file>: Path to output file on which to log the differences")
    sys.exit(1)

path_file_1 = sys.argv[1]
path_file_2 = sys.argv[2]
path_log_file = sys.argv[3]

file_1 = open(path_file_1, 'r')
file_2 = open(path_file_2, 'r')

counter_err = 0
list_err = list()
list_err.append("===============\n")

content_file_1 = file_1.readlines()
content_file_2 = file_2.readlines()

for i in range(0, len(content_file_1)):
    l_1 = content_file_1[i]
    l_2 = content_file_2[i]

    if l_1 != l_2:
        counter_err += 1
        list_err.append(str(l_1) + "\n----------------\n" + str(l_2) + "\n===============\n")
    

file_1.close()
file_2.close()

log_file = open(path_log_file, 'w')

for err in list_err:
    log_file.write(err)
    
log_file.write("Number of different hypotheses: {}".format(counter_err))
print("Number of different hypotheses: {}".format(counter_err))

log_file.close()