#From 2 folders, compute the number of hypotheses which are different
#and print them on screen

import sys
import os

if len(sys.argv) != 3:
    print("Usage: python compare_ner_outputs <path_to_folder_1> <path_to_folder_2>")
    print("<path_to_folder_1>: Path to the first folder containing the ref. hypotheses")
    print("<path_to_folder_2>: Path to the second folder")

path_folder_1 = sys.argv[1]
path_folder_2 = sys.argv[2]

counter_err = 0
list_err = list()
list_err.append("===============")

for f in os.listdir(path_folder_1):
    path_file_1 = os.path.join(path_folder_1, f)
    file_1 = open(path_file_1, 'r')

    path_file_2 = os.path.join(path_folder_2, f)
    file_2 = open(path_file_2, 'r')

    content_file_1 = file_1.readlines()
    content_file_2 = file_2.readlines()

    if content_file_1 != content_file_2:
        counter_err += 1
        list_err.append(str(content_file_1) + "\n----------------\n" + str(content_file_2) + "\n===============")

    file_1.close()
    file_2.close()

print("Number of errors: {}".format(counter_err))
for err in list_err:
    print(err)