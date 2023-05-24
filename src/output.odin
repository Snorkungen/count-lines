package main

import "core:fmt"

output_html :: proc(langs: [dynamic]Lang) {

	fmt.print("<!DOCTYPE html>")
	fmt.print("<html>")
	fmt.print("<body>")

	for lang in langs {
		fmt.print("<article>")
		fmt.printf("<p>Extension \"%s\"</p>", lang.extension)
		fmt.printf("<p>Total Size %dB</p>", lang.size)
		fmt.printf("<p>Total Lines %d</p>", lang.lines)
		fmt.printf("<p>Total Files %d</p>", lang.files)
		fmt.print("</article>")
	}

	fmt.print("</body>")
	fmt.print("</html>")

}