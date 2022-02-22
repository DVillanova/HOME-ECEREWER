import sys
import codecs

#PROBLEMA PARTE DE UTF-8 Y PARA PASAR A ASCII PARA QUE PYLAIA NO PETE
#SE PIERDE INFORMACIÓN COMO LAS "ä ö ü" que pasan a: "a o u"


if len(sys.argv) != 3:
    print("Uso: python3 ner_char_splitter.py <fichero_entrada.txt> <fichero_salida.txt>")
    print("<fichero_entrada.txt>: Ruta a fichero con transcripción con separación a nivel de palabra.")
    print("<fichero_salida.txt>: Ruta para guardar el fichero que se generará con separación a nivel de carácter.")

path_in_file = sys.argv[1]
#in_file = codecs.open(path_in_file, 'r', encoding="utf-8")
in_file = codecs.open(path_in_file, 'r')

#path_fich_temp = sys.argv[1]+".tmp"
#fich_temp = codecs.open(path_fich_temp, 'rw', encoding="ascii", errors="ignore")

path_out_file = sys.argv[2]
#out_file = codecs.open(path_out_file, 'w', encoding="ascii", errors="ignore")
out_file = codecs.open(path_out_file, 'w')

content_in_file = in_file.readlines()

for line in content_in_file:
    #Separar por espacios, coger primera palabra que es la ruta del fichero
    split_line = line.split()
    processed_str = split_line[0]

    for i in range(1,len(split_line)):
        word_i = split_line[i]
        #Si la palabra i es un tag
        if word_i[0] == "<":            
            #Mirar si había previamente una etiqueta y printear space en ese caso
            word_i_prev = split_line[i-1]
            if word_i_prev[0] == "<":
                processed_str += " <space>"

            processed_str += " " + word_i

        else:
            #Separar por espacios
            for j in range(len(word_i)):
                processed_str += " " + word_i[j]
            
            #Si no es la última palabra y no tiene delante una etiqueta
            if i != (len(split_line)-1) and split_line[i+1][0] != "<": 
                processed_str += " <space>"
    
    #Escribir la línea procesada
    out_file.write(processed_str+"\n")
