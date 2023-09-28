.data
buffer:      .space  1024

# Open file for reading

li $v0, 13          # open file
la $a0, input_file.txt  # load address of input file name
li $a1, 0           # open for reading (O_RDONLY - open for reading only)
li $a2, 0           # mode (ignored for O_RDONLY)
syscall

# Open file for writing 
li $v0, 13          # syscall: open file
la $a0, ouput_file.txt  # load address of output file
li $a1, 1           # open for writing (O_WRONLY - open for writing only)
li $a2, 0           # mode
syscall

# Read from input, modify, write to output
li $9, 10       #constant value to add

r