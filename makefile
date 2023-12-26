
count-lines:
	mkdir .build -p
	odin build src -out:.build/count-lines

clean: .build/count-lines
	rm -r .build/count-lines