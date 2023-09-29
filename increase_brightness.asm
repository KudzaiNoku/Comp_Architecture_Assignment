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
    li $t9, 10       #constant value to add
    li  $t7, 48 #stores ascii value of zero
    
read_loop:
    li $v0, 14      #read from file
    la $a1, buffer  #buffer to read into
    li $a2, 12292    #number of bytes to read 
    syscall         
    
    beqz $v0, end_of_file #exit loop if read returns zero
    
    # Process each line in the buffer
    la $t0, buffer      #load address of the buffer
    li $t5, 0           #stores current pixel value
    
    #li $t3, 4           #used to ensure first 4 lines are ignored
    #li $t4, 0           # used to indicate once we've passed the fourth line
    
process_line_loop:

    process_num: 
        lb $t1, 0($t0) #load a byte from buffer
        beq $t1, 10, add_ten       #newline character - end of line
        beqz $t1, end_of_file      # null terminator (end of buffer)
        
        sub $t1, $t1, $t7 #subtracting ascii value of zero turns it into an integer
        mul $t5,$t5,$t9             # multiply number by 10
        add $t5, $t5, $t1           # add character to total
        j process_num
        
    add_ten:     
        #Add 10 to value 
        addi $t5, $t5, 10
        
        li $t2, 255                # maximum allowed value
        bgt $t5, $t2, clamp        # branch if value is greater than 255
        sb $t5, 0($t0)             # Store modified character in buffer
        addi $t0, $t0, 1           # move to next char in buffer
        j process_line_loop

clamp:
    li $t5, 255                     # Set $t1 to 255 if it exceeds 255
    
    sb $t5, 0($t0)                  # Store the modified character back to the buffer
    addi $t0, $t0, 1                # move to next char in buffer
    j process_line_loop         # Continue processing
    
    
#ending:
# j process_line_loop         # Perform cleanup for the end of the line
    
end_of_file:
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

