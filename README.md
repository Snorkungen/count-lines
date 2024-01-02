# count-lines

This program counts the number of lines for each file-extension, in a directory.

```sh
alias cunlines="count-lines"

cunlines # counts the lines in the current directory
cunlines --directory / # counts the lines in the root directory
cunlines -d ../ # counts the lines in the parent directory

cunlines [flags] 

# OPTIONS
# --verbose, -v
# --directory , -d [path to directory] 

# --output-type, -t [csv, xml]
# --ext-depth, -e "default is 1"

# --ignore, -i [path, pattern,...]"Name directory or file to ignore"
# --ignore-file, -f "A.K.A. .gitignore"

# --max-file-size [file size in bytes] "file won't be read if file size exceedes the max-file-size"
```
