#!/bin/bash
# DevOps Assignment 1 - Task 2: Shell Scripting

# Prints the current date and time
echo "Current date and time:"
date

# Prints the hostname
echo "Hostname: $(hostname)"

# Prints the username
echo "Username: $(whoami)"

# Prints the disk usage
echo "Disk usage:"
df -h

# Prints the running processes
echo "Current processes:"
ps

# Uses a variable to store and print data
variable="Hello, World!"
echo "$variable"

# Takes user input using read -p
read -p "Enter your name: " name
read -p "Enter your roll no: " roll_no
echo "My name is $name"
echo "My roll no is $roll_no"

# Creates a directory using mkdir
mkdir -p hello

# Creates a file using touch
touch process.log

# Stores the running process information in the file using > output redirection
echo "Process information:" > process.log
ps >> process.log

echo "Saved process information to process.log"
