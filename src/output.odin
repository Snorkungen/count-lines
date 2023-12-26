package main

import "core:fmt"
import "core:strings"

compute_extension_file_entry :: proc(ext: ExtEntry) -> (file_entry: FileEntry, file_count: uint) {
	for subext in ext.extensions {
		fe, count := compute_extension_file_entry(subext)
		file_entry.size += fe.size
		file_entry.lines += fe.lines

		file_count += count
	}

	for fe in ext.files {
		file_entry.size += fe.size
		file_entry.lines += fe.lines

		file_count += 1
	}

	return file_entry, file_count
}

output_xml_elem :: proc(ext: ExtEntry) {
	fe, fcount := compute_extension_file_entry(ext)
	fmt.printf(
		"<Extension extension='%s' total-size='%d' total-lines='%d' total-files='%d'>\n",
		ext.ext,
		fe.size,
		fe.lines,
		fcount,
	)

	// Output files
	for f in ext.files {
		fmt.printf("\t<File name='%s' size='%d' lines='%d' />\n", f.name, f.size, f.lines)
	}

	for subext in ext.extensions {
		output_xml_elem(subext)
	}

	fmt.print("</Extension>\n")
}

output_xml :: proc(extensions: [dynamic]ExtEntry) {
	fmt.println(`<?xml version="1.0" encoding="UTF-8"?>`)
	fmt.println(`<CountLines>`)
	
	for ext in extensions {
		fe, fcount := compute_extension_file_entry(ext)
		fmt.printf(
			"<Extension extension='%s' total-size='%d' total-lines='%d' total-files='%d'>\n",
			ext.ext,
			fe.size,
			fe.lines,
			fcount,
		)
		
		// Output files
		for f in ext.files {
			fmt.printf("\t<File name='%s' size='%d' lines='%d' />\n", f.name, f.size, f.lines)
		}
		
		for subext in ext.extensions {
			output_xml_elem(subext)
		}
		
		fmt.print("</Extension>\n")
	}
	fmt.println(`</CountLines>`)
}


output_csv_row :: proc(ext: ExtEntry, parent_ext: string = "") {
	ext_name := strings.concatenate({ext.ext, parent_ext})

	for subext in ext.extensions {
		output_csv_row(subext, ext_name)
	}

	fe, fcount := compute_extension_file_entry(ext)
	fmt.printf("%s,%d,%d,%d\n", ext_name, fe.size, fe.lines, fcount)
}

output_csv :: proc(extensions: [dynamic]ExtEntry) {
	fmt.print("extension,total_size,total_lines,total_files\n")

	for ext in extensions {
		output_csv_row(ext)
	}
}


output :: proc(state: State) {
	switch (state.output_type) {
	case .CSV:
		{
			output_csv(state.extensions);break
		}
	case .XML:
		{
			output_xml(state.extensions);break
		}
	}

}
