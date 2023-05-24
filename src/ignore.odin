package main

import "core:os"
import "core:fmt"
import "core:strings"
import "core:path/filepath"

gitignore_entries: []string

init_gitignore :: proc() {
	gitignore_path := filepath.join([]string{os.get_current_directory(), ".gitignore"})
	data, success := os.read_entire_file(gitignore_path)

	if !success {
		return
	}

	entries, err := strings.split(string(data), "\n")

	if err != nil {
		return
	}

	gitignore_entries = entries
}


@(private = "file")
rel_offset := len(os.get_current_directory()) + 1

/*
Ignore file based upon git ignore and other options maybe
*/
ignore_entry :: proc(fi: os.File_Info) -> bool {

	// ignore .git folders
	if fi.is_dir && fi.name == ".git" {
		return true
	}

	relative_file_path := fi.fullpath[rel_offset:]

	for entry in gitignore_entries {
		matched, _ := filepath.match(entry, fi.name)
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
