.data
buffer:      .space  49165
input_file:  .asciiz "input_file.ppm"
output_file: .asciiz "output_file.ppm"
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
        
        la $t2, output_data       # points to output_string
        la $t4, stack               # initialize a stack 
        li $t6, 0                   # Stack pointer
            convert_loop:
                div $t5, $t9        # divide $t5 by 10
                mflo $t7            # move quotient to $t7
                mfhi $t8            # move remainder to $t8
                
                addi $t8, $t8, '0'  # Convert remainder to integer
                
                #Push digit onto stack
                sb $t8, 0($t4)
                addi $t4, $t4, 1    #increment stack address
                addi $t6, $t6, 1    #increment stack pointer
                
                bnez $t7, convert_loop # Repeat loop if quotient is not zero
        
        #Pop digits from stack, append to output string
        pop_loop:
            beqz $t6, end_of_conversion     #if stack empty, exit loop
            
            addi $t4, $t4, -1 # move stack pointer back
            lb $t7, 0($t4)    # pop a digit from the stack
            sb $t7, 0($t2)    # store digit in output string
            addi $t2, $t2, 1  # move to next space in output string
            
            addi $t6, $t6, -1 #decrement stack pointer
            j pop_loop
            
        sb $s3, 0($t3)               # save newline char into output string
        
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