
count-lines:
	odin build src -out:count-lines

clean: count-lines
	rm count-lines