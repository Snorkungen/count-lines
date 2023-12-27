# count-lines

This program count the number of lines in a directory.

```sh
alias cunlines="count-lines"

cunlines # counts the lines in the current directory
cunlines --directory / # counts the lines in the root directory
cunlines --directory ../ # counts the lines in the parent directory

cunlines [flags] 

# OPTIONS
# --verbose, -v
# --directory , -d [path to directory] 

# --output-type, -t [csv, xml]
# --ext-depth, -e "default is 1"

# --ignore, -i [path, pattern,...]"Name directory or file to ignore"
# --ignore-file, -f "A.K.A. .gitignore"
```
