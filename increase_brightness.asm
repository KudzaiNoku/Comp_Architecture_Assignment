.data
buffer:      .space  12292
input_file:  .asciiz "input_file.txt"
output_file: .asciiz "output_file.txt"



.text
main:
    # Open file for reading
    li $v0, 13          # open file
    la $a0, input_file  # load address of input file name
    li $a1, 0           # open for reading (O_RDONLY - open for reading only)
    li $a2, 0           # mode (ignored for O_RDONLY)
    syscall
    
    move $s0, $v0       # save input file descriptor
    
    # Open file for writing 
    li $v0, 13          # syscall: open file
    la $a0, output_file  # load address of output file
    li $a1, 1           # open for writing (O_WRONLY - open for writing only)
    li $a2, 0           # mode
    syscall
    
    move $s1, $v0          # save output file descriptor
    
    # Read from input, modify, write to output
    li $9, 10       #constant value to add

read_loop:
    li $v0, 14      #read from file
    la $a1, buffer  #buffer to read into
    li $a2, 12292    #number of bytes to read 
    syscall         #make system call
    
    beqz $v0, end_of_file #exit loop if read returns zero
    
    # Process each line in the buffer
    la $t0, buffer      #load address of the buffer
    li $t3, 4           #used to ensure first 4 lines are ignored
    
process_line_loop:
    
    lb $t1, 0($t0)  # load a byte from buffer
    beq $t1, 10, end_of_line   # newline character
    beqz $t1, end_of_line      # null terminator (end of buffer)
    
    #Add 10 to value 
    addi $t1, $t1, 10
    
    sb $t1, 0($t0)             #Store modified character in buffer
    addi $t0, $t0, 1           #move to next char in buffer
    
    li $t2, 255                # maximum allowed value
    
    bgt $t1, $t2, clamp        # branch if value is greater than 255
    j process_line_loop

clamp:
    li $t1, 255                     # Set $t1 to 255 if it exceeds 255
    sb $t1, 0($t0)                  # Store the modified character back to the buffer
    j process_line_loop         # Continue processing
    

end_of_file:
    j process_line_loop         # Perform cleanup for the end of the line
    
close_input_file:
    li $v0, 16             # syscall: close file
    move $a0, $s0          # input file descriptor
    syscall               

close_output_file:
    li $v0, 16             # syscall: close file
    move $a0, $s1          # output file descriptor
    syscall                


exit:
    li $v0, 10             # syscall: exit
    syscall                

