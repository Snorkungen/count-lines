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

output_xml_elem :: proc(ext: ExtEntry, fp: bool) {
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
		if fp {
			fmt.printf(
				"\t<File name='%s' fullpath='%s' size='%d' lines='%d' />\n",
				f.name,
				f.fullpath,
				f.size,
				f.lines,
			)
		} else {
			fmt.printf("\t<File name='%s' size='%d' lines='%d' />\n", f.name, f.size, f.lines)
		}
	}

	for subext in ext.extensions {
		output_xml_elem(subext, fp)
	}

	fmt.print("</Extension>\n")
}

output_xml :: proc(extensions: [dynamic]ExtEntry, fp: bool) {
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
			if fp {
				fmt.printf(
					"\t<File name='%s' fullpath='%s' size='%d' lines='%d' />\n",
					f.name,
					f.fullpath,
					f.size,
					f.lines,
				)
			} else {
				fmt.printf("\t<File name='%s' size='%d' lines='%d' />\n", f.name, f.size, f.lines)
			}
		}

		for subext in ext.extensions {
			output_xml_elem(subext, fp)
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

indent :: proc(depth: int) {
	for i in 0 ..< depth {
		fmt.print("\t")
	}
}
output_json_ext :: proc(ext: ExtEntry, depth: int, fp: bool) {
	fe, fcount := compute_extension_file_entry(ext)

	indent(depth);fmt.printfln("\"extension\": \"%s\",", ext.ext)
	indent(depth);fmt.printfln("\"total-size\": %d,", fe.size)
	indent(depth);fmt.printfln("\"total-lines\": %d,", fe.lines)
	indent(depth);fmt.printfln("\"total-files\": %d,", fcount)

	if len(ext.extensions) > 0 {
		indent(depth);fmt.println("\"extensions\": [")
		for subext, i in ext.extensions {
			indent(depth + 1);fmt.println("{")

			output_json_ext(subext, depth + 2, fp)

			if (i < len(ext.extensions) - 1) {
				indent(depth + 1);fmt.println("},")
			} else {
				indent(depth + 1);fmt.println("}")
			}
		}
		indent(depth);fmt.println("],")
	}

	indent(depth);fmt.println("\"files\": [")
	for f, i in ext.files {
		indent(depth + 1);fmt.println("{")

		indent(depth + 2);fmt.printfln("\"name\": \"%s\",", f.name)
		if fp {
			indent(depth + 2);fmt.printfln("\"fullpath\": \"%s\",", f.fullpath)
		}
		indent(depth + 2);fmt.printfln("\"size\": %d,", f.size)
		indent(depth + 2);fmt.printfln("\"lines\": %d", f.lines)

		if i < len(ext.files) - 1 {
			indent(depth + 1);fmt.println("},")
		} else {
			indent(depth + 1);fmt.println("}")
		}
	}
	indent(depth);fmt.println("]")
}
output_json :: proc(extensions: [dynamic]ExtEntry) {
	fmt.println("[")

	depth := 1

	for ext, i in extensions {
		indent(depth);fmt.println("{")

		output_json_ext(ext, depth + 1, false)

		if (i < len(extensions) - 1) {
			indent(depth);fmt.println("},")
		} else {
			indent(depth);fmt.println("}")
		}
	}

	fmt.println("]")
}

output :: proc(state: State) {
	switch (state.output_type) {
	case .CSV:
		{
			output_csv(state.extensions);break
		}
	case .XML, .XML_FP:
		{
			output_xml(state.extensions, state.output_type == .XML_FP);break
		}
	case .JSON:
		{
			output_json(state.extensions);break
		}
	}
}
