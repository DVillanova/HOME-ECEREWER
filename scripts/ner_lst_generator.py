import sys
import codecs

if len(sys.argv) != 3:
    print("Uso: python3 ner_lst_generator.py <fichero_lst_base.txt> <fichero_lst_salida.txt>")
    print("<fichero_entrada.txt>: Ruta a fichero .lst con rutas desde carpetas czech_charters o similares.")
    print("<fichero_salida.txt>: Ruta para guardar el .lst únicamente con las IDs de las imágenes.")


path_in_file = sys.argv[1]
in_file = codecs.open(path_in_file, 'r')

path_out_file = sys.argv[2]
out_file = codecs.open(path_out_file, 'w')

content_in_file = in_file.readlines()

for line in content_in_file:
    split_line = line.split("/")
    out_file.write(split_line[-1])