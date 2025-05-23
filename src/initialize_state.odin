package main

import "core:fmt"
import "core:os"
import "core:strconv"
import "core:strings"

MAX_FILE_SIZE :: 100_000 // 100kB

OPTION_VERBOSE :: PA_FlagName{"verbose", "v"}
OPTION_DIRECTORY :: PA_FlagName{"directory", "d"}
OPTION_OUTPUT_TYPE :: PA_FlagName{"output-type", "t"}
OPTION_EXT_DEPTH :: PA_FlagName{"ext-depth", "e"}
OPTION_IGNORE :: PA_FlagName{"ignore", "i"}
OPTION_IGNORE_FILE :: PA_FlagName{"ignore-file", "f"}
OPTION_MAX_FILE_SIZE :: PA_FlagName{"max-file-size", ""}

OPTION_FLAGNAMES :: []PA_FlagName {
	OPTION_VERBOSE,
	OPTION_DIRECTORY,
	OPTION_OUTPUT_TYPE,
	OPTION_EXT_DEPTH,
	OPTION_IGNORE,
	OPTION_IGNORE_FILE,
	OPTION_MAX_FILE_SIZE,
}

initialize_state :: proc(state: ^State) -> bool {
	state.output_type = .CSV
	state.ext_depth = 1
	state.max_file_size = MAX_FILE_SIZE

	flags := parse_args(os.args, OPTION_FLAGNAMES)
	defer {
		free_flags(&flags)
		delete(flags)
	}

	if flags[OPTION_VERBOSE] != nil {
		state.verbose = true
	}

	if flags[OPTION_DIRECTORY] != nil {
		path: string
		fi: os.File_Info
		err: os.Errno

		for flag := flags[OPTION_DIRECTORY]; flag != nil; flag = flag.prev {
			path = flag.value
			fi, err = os.stat(path)
			if err != os.ERROR_NONE {
				if state.verbose {
					fmt.printf("[WARN] could not find directory: \"%s\"\n", path)
				}

				continue
			}

			state.root_filepath = fi.fullpath
			break
		}

		if err != os.ERROR_NONE {
			fmt.eprintf("[ERROR] could not find the specified directory: \"%s\"\n", path)
			return false
		}

		if !fi.is_dir {
			fmt.eprintf("[ERROR] \"%s\": not a directory\n", fi.fullpath)
			return false
		}
	} else {
		state.root_filepath = os.get_current_directory()
	}

	if flags[OPTION_OUTPUT_TYPE] != nil { 	// use las good value
		output_type_loop: for flag := flags[OPTION_OUTPUT_TYPE]; flag != nil; flag = flag.prev {
			type := flag.value
			switch strings.to_upper(type) {
			case "CSV":
				state.output_type = .CSV;break output_type_loop
			case "XML":
				state.output_type = .XML;break output_type_loop
			case "XML_FP":
				state.output_type = .XML_FP;break output_type_loop
			case "JSON":
				state.output_type = .JSON;break output_type_loop
			}

			if state.verbose {
				fmt.printf("[WARN] could not understand output type: \"%s\"\n", type)
			}
		}
	}

	if flags[OPTION_EXT_DEPTH] != nil {
		depth: int = 1 // The following takes the last good value, due to LIFO
		for flag := flags[OPTION_EXT_DEPTH]; depth <= 1 && flag != nil; flag = flag.prev {
			depth = strconv.atoi(flag.value)
		}

		state.ext_depth = auto_cast depth
	}

	if flags[OPTION_IGNORE] != nil {
		for flag := flags[OPTION_IGNORE]; flag != nil; flag = flag.prev {
			append(&state.ignore_entries, flag.value)
		}
	}

	if flags[OPTION_IGNORE_FILE] != nil {
		data: []u8;success: bool;value: string
		for flag := flags[OPTION_IGNORE_FILE]; flag != nil; flag = flag.prev {
			data, success = os.read_entire_file(flag.value)
			value = flag.value

			if !success {
				if state.verbose {
					fmt.printf("[WARN] could not read ignore file: \"%s\"\n", value)
				}
				continue
			}

			entries, err := strings.split(string(data), "\n")

			if err != nil {
				success = false //  "BUY MORE RAM" 
				continue
			}

			append(&state.ignore_entries, ..entries[:])
			break
		}

		if (!success) {
			fmt.eprintf("[ERROR] failed to read ignore file: \"%s\"\n", value)
			return false
		}
	}

	if flags[OPTION_MAX_FILE_SIZE] != nil {
		max_file_size: i64 // The following takes the last good value, due to LIFO
		for flag := flags[OPTION_MAX_FILE_SIZE]; flag != nil; flag = flag.prev {
			max_file_size = auto_cast strconv.atoi(flag.value)
		}

		if (max_file_size > 0) {
			state.max_file_size = max_file_size
		}
	}

	if flags[PA_FLAG_UNDEFINED] != nil {
		/*
		Iterate through and return false due unrecognized arguments are not allowed
		*/
		for flag := flags[PA_FLAG_UNDEFINED]; flag != nil; flag = flag.prev {
			fmt.eprintf("[ERROR] unrecognized argument \"%s\"\n", flag.value)
			// !TODO: Guess what type of option the user is trying to use
		}

		return false
	}

	return true
}
