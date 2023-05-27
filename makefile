
count-lines:
	mkdir .build
	odin build src -out:.build/count-lines

clean: count-lines
	rm count-lines