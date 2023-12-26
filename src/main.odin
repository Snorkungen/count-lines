package main

import "core:fmt"
import "core:os"
import "core:path/filepath"
import "core:strconv"
import "core:strings"
import "core:time"

FileEntry :: struct {
	name:     string, // name without extension
	fullpath: string,
	size:     uint,
	lines:    uint,
}

ExtEntry :: struct {
	// There should maybe be a hashmap involved instead of "linear search"
	ext:        string,
	extensions: [dynamic]ExtEntry,
	files:      [dynamic]FileEntry,
}

StateOutputType :: enum {
	CSV,
	XML,
}

State :: struct {
	root_filepath:  string,
	output_type:    StateOutputType,
	ext_depth:      uint, // Default 1 the allowed "." in an extensinon
	ignore_entries: [dynamic]string,
	extensions:     [dynamic]ExtEntry,
}

initialize_state :: proc(state: ^State) -> bool {
	state.root_filepath = os.get_current_directory()
	state.output_type = .CSV
	state.ext_depth = 1

	// !TODO parse arguments and configure option properly

	for i := 1; i < len(os.args); i += 1 {
		arg := os.args[i]

		if arg[0] == '-' {
			switch arg {
			case "--output-type", "-t":
				{
					// read next value
					next := os.args[i + 1]
					if next[0] == '-' {
						continue
					}

					switch strings.to_lower(next) {
					case "csv":
						state.output_type = .CSV
					case "xml":
						{
							state.output_type = .XML
						}
					}

					i += 1
				}
			case "--ext-depth", "-d":
				{
					// read next value
					next := os.args[i + 1]
					if next[0] == '-' {
						continue
					}

					depth := strconv.atoi(next)

					if depth < 1 {
						continue
					}

					state.ext_depth = uint(depth)

					i += 1
				}
			case "--ignore", "-i":
				{
					// read next value
					next := os.args[i + 1]
					if next[0] == '-' {
						continue
					}

					append(&state.ignore_entries, next)
					i += 1
				}
			case "--ignore-file", "-f":
				{
					// read next value
					next := os.args[i + 1]
					if next[0] == '-' {
						continue
					}

					// Read ignore file and the entries to the ignore list

					data, success := os.read_entire_file(next)

					if !success {
						continue
					}

					entries, err := strings.split(string(data), "\n")

					if err != nil {
						continue
					}

					append(&state.ignore_entries, ..entries[:])
					i += 1
				}
			}
		}

		// this is not the best but i feel that it is a  hacky solution
		fi, err := os.stat(arg)
		if err != os.ERROR_NONE || fi.is_dir {
			continue
		}

		state.root_filepath = fi.fullpath
	}

	return true
}


main :: proc() {
	state: State

	if (!initialize_state(&state)) {
		return
	}

	if (walk(&state, state.root_filepath) != os.ERROR_NONE) {
		return
	}

	output(state)
}

get_file_exts :: proc(
	state: ^State,
	path: string,
) -> (
	name: string,
	exts: []string,
	ext_count: uint,
) {
	count: uint
	end := len(path)
	exts = make([]string, state.ext_depth)

	for i := len(path) - 1; i >= 0 && !filepath.is_separator(path[i]); i -= 1 {
		if path[i] == '.' {
			exts[count] = path[i:(end)]
			count += 1
			end = i

			if count >= state.ext_depth {
				break
			}
		}
	}

	name = path

	if end > 0 {
		name = path[:end]
	}

	return name, exts, count
}

@(private = "file")
rel_offset := len(os.get_current_directory()) + 1

/*
Ignore file based upon git ignore and other options maybe
*/
ignore_entry :: proc(state: State, fullpath: string) -> bool {
	rel_offset := len(state.root_filepath) + 1

	relative_file_path := fullpath[rel_offset:]

	for entry in state.ignore_entries {
		matched, _ := filepath.match(entry, filepath.base(fullpath))
		if matched {
			return true
		}
		matched, _ = filepath.match(entry, relative_file_path)
		if matched {
			return true
		}
	}

	return false
}

NEWLINE_BYTE :: byte('\n')

walk :: proc(state: ^State, path: string) -> os.Errno {
	// start by walking the tree tree

	fd: os.Handle
	fi: []os.File_Info
	err: os.Errno


	fd, err = os.open(path)
	if err != os.ERROR_NONE {
		return err
	}
	defer os.close(fd)

	fi, err = os.read_dir(fd, 0)
	if err != os.ERROR_NONE {
		return err
	}

	for info in fi {
		if ignore_entry(state^, info.fullpath) {
			continue
		}

		if info.is_dir {
			walk(state, info.fullpath)
			continue
		}

		data, success := os.read_entire_file_from_filename(info.fullpath)
		if !success {
			continue
		}

		file_entry := FileEntry{}
		_, exts, count := get_file_exts(state, info.name)

		file_entry.name = info.name
		file_entry.fullpath = info.fullpath
		file_entry.size = uint(info.size)
		file_entry.lines = 1

		for char in data {
			if char == NEWLINE_BYTE do file_entry.lines += 1
		}

		// // now place the FileEntry into my data structure
		insert_file_entry(&state.extensions, file_entry, exts, 0)
	}

	return os.ERROR_NONE
}

insert_file_entry :: proc(
	extensions: ^[dynamic]ExtEntry,
	file_entry: FileEntry,
	exts: []string,
	idx: int,
) -> bool {
	for ext, _ in extensions {
		if ext.ext != exts[idx] {
			continue
		}

		if idx < len(exts) - 1 && exts[idx + 1] != "" {
			return insert_file_entry(&ext.extensions, file_entry, exts, idx + 1)
		}

		append(&ext.files, file_entry)
		return true
	}

	// create new ext entry
	ext_entry := ExtEntry{}
	ext_entry.ext = exts[idx]

	if idx < len(exts) - 1 && exts[idx + 1] != "" {
		insert_file_entry(&ext_entry.extensions, file_entry, exts, idx + 1)
	} else {
		append(&ext_entry.files, file_entry)
	}

	append(extensions, ext_entry)

	return true
}
