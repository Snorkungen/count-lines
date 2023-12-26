# count-lines

This program count the number of lines in a directory.

```sh
alias cunlines="count-lines"

cunlines # counts the lines in the current directory
cunlines / # counts the lines in the root directory
cunlines ../ # counts the lines in the parent directory

cunlines [flags] [dirctory]

# OPTIONS
# --output-type, -t [csv, xml]

# --file-ext-depth, -e "default is 1"

# --ignore, -i "Name directory or file to ignore"
# --ignore-file, -f "A.K.A. .gitignore"
```
