#Generation of Named Entity FSA to impose syntactical constraints on the lattice.

from contextlib import closing
import itertools
import sys

if len(sys.argv) != 3:
    print("Usage: python generate_categorical_sfsa.py <symbols_file_path> <output_file_path>")
    print("<symbols_file_path>: Path to the symb.txt file")
    print("<output_file_path>: Path on which to store the output Categorical.fst")
    sys.exit(1)

normal_symbols = list()
ne_symbols = list()

symbols_file_path = sys.argv[1]
output_file_path = sys.argv[2]

with open(symbols_file_path, 'r') as symbols_file:
    for l in symbols_file.readlines():
        (symbol, int_map) = l.split()
        if "<" in symbol:
            if symbol == "<eps>" or symbol == "<space>" or symbol == "<s>" or symbol == "</s>" or symbol == "<DUMMY>":
                normal_symbols.append(symbol)
            elif "/" not in symbol:
                ne_symbols.append(symbol)
            
        else:
            normal_symbols.append(symbol)

#Add additional symbols for Kaldi
# normal_symbols.append("<eps>")
# normal_symbols.append("#0")
# normal_symbols.append("<DUMMY>")
# normal_symbols.append("<s>")
#normal_symbols.append("</s>")

ne_set = set()
for ne in ne_symbols:
    ne_set.add(ne[1:-1])

try:
    output_file = open(output_file_path, 'w')
except:
    print("Error when opening output file")
    sys.exit(1)


dict_states = dict()
dict_states["()"] = 0
counter_state = 1

#Transitions from initial state to itself
for symbol in normal_symbols:
    out_str = "0 0 {} {} 1\n".format(symbol, symbol)
    output_file.write(out_str)

for r in range(1,len(ne_set)):
    perm = itertools.permutations(ne_set,r)
    for state in perm:
        #Assign a new ID for this new state
        dict_states[str(state)] = counter_state
        state_id = counter_state
        counter_state += 1

        #Get the previous state
        prev_state = state[:-1]
        prev_state_id = dict_states[str(prev_state)]

        #Named Entity to transit from prev_state to state
        trans_ne = "<" + state[-1] + ">"
        closing_trans_ne = "</" + state[-1] + ">"

        #Transitions from prev_state to state and state to prev_state
        out_str = "{} {} {} {} 1\n".format(prev_state_id, state_id, trans_ne, trans_ne)
        output_file.write(out_str)

        out_str = "{} {} {} {} 1\n".format(state_id, prev_state_id, closing_trans_ne, closing_trans_ne)
        output_file.write(out_str)

        #Transitions with normal symbols
        for symbol in normal_symbols:
            out_str = "{} {} {} {} 1\n".format(state_id, state_id, symbol, symbol)
            output_file.write(out_str)

       
#Add initial state as final state
out_str = "0 1\n"
output_file.write(out_str)
