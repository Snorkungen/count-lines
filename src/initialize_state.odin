package main

import "core:fmt"
import "core:os"
import "core:strconv"
import "core:strings"

OPTION_VERBOSE := PA_FlagName{"verbose", "v"}
OPTION_DIRECTORY := PA_FlagName{"directory", "d"}
OPTION_OUTPUT_TYPE := PA_FlagName{"output-type", "t"}
OPTION_EXT_DEPTH := PA_FlagName{"ext-depth", "e"}
OPTION_IGNORE := PA_FlagName{"ignore", "i"}
OPTION_IGNORE_FILE := PA_FlagName{"ignore-file", "f"}

initialize_state :: proc(state: ^State) -> bool {
	state.output_type = .CSV
	state.ext_depth = 1
	state.root_filepath = os.get_current_directory()

	flagnames := [?]PA_FlagName {
		OPTION_VERBOSE,
		OPTION_DIRECTORY,
		OPTION_OUTPUT_TYPE,
		OPTION_EXT_DEPTH,
		OPTION_IGNORE,
		OPTION_IGNORE_FILE,
	}

	flags := parse_args(os.args, flagnames[:])

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
				continue
			}

			state.root_filepath = fi.fullpath
			break
		}

		if err != os.ERROR_NONE {
			fmt.eprintf("\"%s\": directory doesn't exist\n", path)
			return false
		}

		if !fi.is_dir {
			fmt.eprintf("\"%s\": not a directory\n", fi.fullpath)
			return false
		}
	}

	if flags[OPTION_OUTPUT_TYPE] != nil { 	// use las good value
		output_type_loop: for flag := flags[OPTION_OUTPUT_TYPE]; flag != nil; flag = flag.prev {
			type := flag.value

			switch strings.to_upper(type) {
			case "CSV":
				state.output_type = .CSV;break output_type_loop
			case "XML":
				state.output_type = .XML;break output_type_loop
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
			fmt.eprintf("\"%s\": bad ignore file\n", value)
			return false
		}
	}

	return true
}
