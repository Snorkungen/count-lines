package main

import "core:fmt"
import "core:os"
import "core:path/filepath"

Lang :: struct {
	extension: string,
	size:      uint,
	lines:     uint,
	files:     uint,
}

main :: proc() {
	root_dir: string

	// root directory is current directory coz it's simple
	root_dir = os.get_current_directory()

	fd, err := os.open(root_dir)
	if err != os.ERROR_NONE {
		fmt.eprint("Failed to open root error.")
		return
	}
	defer os.close(fd)

	langs := make([dynamic]Lang)


	stat, stat_error := os.fstat(fd)
	if stat_error != os.ERROR_NONE do return

	if count_lines_in_dir(stat, &langs) != os.ERROR_NONE {
		// do some error handling
	}


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

push_file :: proc(langsptr: ^[dynamic]Lang, extension: string, size: uint, lines: uint = 0) {
	for _, i in (langsptr^) {
		if (langsptr^)[i].extension == extension {
			(langsptr^)[i].size += size
			(langsptr^)[i].lines += lines
			(langsptr^)[i].files += 1

			return
		}
	}

	append(langsptr, Lang{extension = extension, size = size, lines = lines, files = 1})
}

count_lines_in_file :: proc(fi: os.File_Info, langsptr: ^[dynamic]Lang) {
	extension := filepath.ext(fi.fullpath)
	if extension == "" {
		extension = fi.name
	}

	data, success := os.read_entire_file_from_filename(fi.fullpath)
	if !success {
		return
	}

	lines: uint = 1

	for char in data {
		if char == byte('\n') do lines += 1
	}

	push_file(langsptr, extension, uint(fi.size), lines)
}

count_lines_in_dir :: proc(fi: os.File_Info, langsptr: ^[dynamic]Lang) -> os.Errno {
	fd: os.Handle
	fis: []os.File_Info
	err: os.Errno

	fd, err = os.open(fi.fullpath)
	fis, err = os.read_dir(fd, 0)
	if err != os.ERROR_NONE {
		return err
	}
	os.close(fd)

	for fi in fis {
		if fi.is_dir {
			count_lines_in_dir(fi, langsptr)
		} else {
			count_lines_in_file(fi, langsptr)
		}
	}

	return os.ERROR_NONE
}
