#!/bin/sh
#####################################################
# RANDOM VALUES
generate_random_word() {
	shuf -n1 /usr/share/dict/words
}
export -f generate_random_word
