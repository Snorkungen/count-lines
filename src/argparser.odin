package main

import "core:fmt"
import "core:mem"

PA_FlagName :: struct {
	name:  string,
	alias: string,
}

PA_FlagValue :: struct {
	prev:  ^PA_FlagValue,
	value: string,
}

PA_Flags :: map[PA_FlagName]^PA_FlagValue

parse_args :: proc(args: []string, flag_names: []PA_FlagName) -> (flags: PA_Flags) {
	arg, name: string

	for i := 1; i < len(args); i += 1 {
		arg = args[i]

		if arg[0] != '-' {
			continue
		}

		name = arg[1] == '-' ? arg[2:] : arg[1:]

		// find PA_FlagName
		fname: PA_FlagName

		for f in flag_names {
			if name == f.name || name == f.alias {
				fname = f
				break
			}
		}

		if fname.name == "" {
			continue
		}


		flagptr := cast(^PA_FlagValue)(mem.alloc(size_of(PA_FlagValue)))
		flagptr.prev = flags[fname]
		flags[fname] = flagptr

		for j := i + 1; j < len(args); j += 1 {
			val := args[j]
			if val[0] == '-' || val == "" {
				i = j - 1 // THIS MIGHT CAUSE PROBLEMS
				break
			}

			if flagptr.value == "" {
				flagptr.value = val
			} else {
				flagptr = cast(^PA_FlagValue)(mem.alloc(size_of(PA_FlagValue)))

				flagptr.prev = flags[fname]
				flagptr.value = val
				flags[fname] = flagptr
			}
		}
	}

	return flags
}

@(private)
free_flag :: proc(flag: ^PA_FlagValue) {
	if flag.prev != nil {
		free_flag(flag.prev)
	}
	mem.free(flag)
}

free_flags :: proc(flags: ^PA_Flags) {
	for flag_name in flags {
		free_flag(flags[flag_name])
	}
}
