#!/bin/bash
# Proper header for a Bash script.

# to declare a variable read only
declare -r VAR1='Hello world'

# we will get here an error due to previously was declared as read only
VAR1='Good morning Vietnam'

# to read from user input -p flag allows us to specify prompt text without
read -p 'Type your name and press enter: ' NAME
echo "Hello $NAME"

# We can access the length of a string using the hash (#) operator inside parameter expansion before the variable name
echo ${#NAME}

# We can extract a substring using the colon (:) operator inside the parameter expansion, providing the starting position of substring and optionally length of the substring
echo ${NAME:3} # starts at postion 3 of the string until the end of the string
echo ${NAME:0:4} # start at position 0 and goes until position 4

# pattern matching
# * matches any number of characters
# + matches one or more characters
# [abc] – matches only given characters
read -p 'Type your file name and press enter: ' FILENAME

# checks if the extension of the file name is jpg
if [[ ${FILENAME} = *.jpg ]]; then
	echo "is jpg";
else
	echo "is not jpg"
fi

# There’s also an extended matching system called “extended globbing”. It enables us to constraint wildcards to specific patterns
# *(pattern) – matches any number of occurrence of pattern
# ?(pattern) – matches zero or one occurrence of pattern
# +(pattern) – matches one or more occurrence of pattern
# !(pattern) – negates the pattern, matches anything that doesn’t match the pattern

# Extended globbing must be turned on with the shopt command. We can improve the last snippet to also match the .jpeg extension
shopt -s extglob
if [[ ${FILENAME} = *.jp?(e)g ]]; then
	echo "is jpg";
fi

# using regex
# If we need more expressive pattern language we can also use regular expressions with the not-equals (=~) operator
# We can use Extended Regular Expressions here, like when calling grep with the -E flag. If we use the capture groups, they’ll be stored in the BASH_REMATCH array variable and can be accessed later.
if [[ "file.jpg" =~ .*\.jpe?g ]]; then
	echo "is jpg";
fi

# removing matched string
#To do this, we need to match from the end of the string using the percent (%) operator. The singular operator will match the shortest substring, double will match the longest one
declare -r FILENAME="index.component.js"
echo ${FILENAME%.*} # removes js part
# to filter out all the extensions we’d do will return index
echo ${FILENAME%%.*}
# We can also remove filename, leaving only extensions. In that case, we need to start from the beginning using the hash (#) operator
echo ${FILENAME#*.}
# Analogically to the previous example, if we would like to leave only last extension we need to use a double-hash
echo ${FILENAME##*.}


# substituting matched string
# Instead of just removing substring we can substitute it using slash (/) operator.
# The singular operator changes the first match and the double operator changes all matches. Both match the longest possible substring
echo ${FILENAME/*./new_name.} # changes the file name while leaving the extension intact will return new_name.js
