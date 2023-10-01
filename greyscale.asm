.data
input_file:  .asciiz "/Users/kudzainyika/Desktop/ArchAssignment/input_file.txt"
output_file: .asciiz "/Users/kudzainyika/Desktop/ArchAssignment/output_file.txt"
buffer:      .space  49165
output_data:  .space  5
stack: .space 1024
first_four_lines: .asciiz "P2\n# Jt2\n64 64\n255\n"
message:     .asciiz "Completed succesfully!"

.text
.globl main
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
        li $a1, 577           # open for writing (write only or create)
        li $a2, 0           # mode
        syscall
        
        move $s1, $v0          # save output file descriptor
     
        li $t9, 10       #used for conversion of ascii to int
        
    read_file_into_buffer:
        li $s3, 10      #ASCII value for newline
        li $v0, 14      
        la $a1, buffer  #buffer to read into
        li $a2, 49165    #number of bytes to read 
        syscall         
        
        beqz $v0, end_of_file #exit loop if read returns zero
        
        la $t0, buffer      #load address of the buffer
        li $t5, 0           #stores current pixel value
    
    populate_first_four_lines:
        li $v0, 15                      
        move $a0, $s1                   # output file descriptor
        la $a1, first_four_lines             # buffer to write
        li $a2, 25                   # number of bytes to write
        syscall
        
        # move 25 spaces forward in buffer
        li $t1, 25      #set loop counter to 25
        loop:
            addi $t0, $t0,1     # Increment buffer pointer to the next byte
            addi $t1, $t1, -1   # Decrement loop counter 
            bnez $t1, loop      # start loop again if counter not zero
            
        addi $t0, $t0,1     # Increment buffer pointer to the next byte
        
        
    initialize:
        li $s2, 3           # number of numbers to be aggregated
        li $t2, 0           # counter
        li $t4, 0           # register to store current number
        li $t3, 0           # register to add total
        
    get_first_three:
        lb $t1, 0($t0)                             # get address of buffer
        beq $t2, $s2, calculate_average            # if counter is 3, branch
        beq $t1, 10, end_of_line                   # newline character 
        beqz $t1, end_of_file     # null terminator (end of buffer)
                  
        convert:
            sub $t1, $t1, '0'           # Convert ASCII to integer
            mul $t4,$t4,$t9             # multiply number by 10
            add $t4, $t4, $t1           # add character to total
            addi $t0, $t0, 1      # move to next character in buffer
            j get_first_three
        
        end_of_line:                                 
            addi $t2, $t2, 1                        #increment counter
            addi $t0, $t0, 1                        #increment address
            add $t3, $t3, $t4                       # add to total
            j get_first_three
            
        calculate_average:
        # method to calculate average and write to file
        # calculate average by dividing total ($t3) by 3 ($s2) 
        
        mtc1 $t3, $f0           #convert values to floating point
        mtc1 $s2, $f1
        
        cvt.d.w $f0, $f0        #convert to double
        cvt.d.w $f1, $f1
        
        div.d $f3, $f0, $f1     #calculate averages
        
        cvt.w.d $f5, $f3        #convert back to a word
        
        mfc1 $t5, $f5 
            
        #turn ascii back to int, while copying into output_data
        
        la $t2, output_data         # where the final string will be stored
        li $t6, 0                   # Counter for number of digits
        li $t9, 10                  # For division to extract digits
        
        la $t7, buffer_reverse      # t7 to store digits in reverse order
        
        # Convert number to ascii and write to output_file
        convert_loop:
            # If the number is zero and we have not processed any digits yet, skip the loop
            beq $t5, $zero, end_of_conversion
            beqz $t6, skip_zero_check
            beq $t5, $zero, copy_string
        
        skip_zero_check:
            # Get remainder    
            rem $t8, $t5, $t9
            
            # Convert to ASCII
            addi $t8, $t8, '0'
            
            # Store it in buffer in reverse
            sb $t8, 0($t7)
            addi $t7, $t7, 1            # Move to next position in buffer_reverse
            addi $t6, $t6, 1            # Increment the digit count
            
            # Remove the last digit from the number
            div $t5, $t5, $t9
            mflo $t5                    # Get quotient
            j convert_loop
            
        copy_string:
            # If no digits processed, the number was 0
            beqz $t6, store_zero
            
            # Copy string from buffer_reverse to output_data in correct order
            addi $t7, $t7, -1
            
        copy_loop:
            lb $t8, 0($t7)
            sb $t8, 0($t2)
            addi $t2, $t2, 1      # Move to the next position in output_data
            addi $t7, $t7, -1     # Move to previous position in buffer_reverse
            addi $t6, $t6, -1
            bnez $t6, copy_loop   # Repeat til all digits are copied
            j end_of_conversion
        store_zero:
            # Store the digit '0' for the number 0
            li $t8, '0'
            sb $t8, 0($t2)
            addi $t2, $t2, 1
            
    finish_string:
        sb $s3, 0($t2)               # save newline char into output string
        
        li $v0, 15                      # write to file
        move $a0, $s1                   # output file descriptor
        la $a1, output_data             # buffer to write
        li $a2, 5                   # number of bytes to write
        syscall
            
        addi $t0, $t0, 1      # increment buffer address ($t0)
        
        li $t2, 0             # reinitialise t2, t3 and t4 
        li $t3, 0
        li $t4, 0
        
        #clear memory of output_data
        la $a0, output_data     # buffer address
        li $t6, 5               # number of bytes
        
        addi $t6, $a0, 5        # calculate the end address
        clear_loop:
            sb $t2, 0($a0)      # Store 0 in specific point in output_data
            addi $a0, $a0, 1    # Move to next byte
            bne $a0, $t6, clear_loop       #repeat till end address is reached 
        
        j get_first_three
        
    end_of_file:
        li $v0, 16             # syscall: close file
        move $a0, $s0          # input file descriptor
        syscall               
    
        li $v0, 16             # syscall: close output file
        move $a0, $s1          # output file descriptor
        syscall   
        
    print_message:
        li $v0, 4
        la $a0, message            # message for old average
        syscall
        
    j exit
    
exit:
    li $v0, 10             # syscall: exit
    syscall                