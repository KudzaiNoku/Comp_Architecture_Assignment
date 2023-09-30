.data
message1: .asciiz "Average pixel value of original image:\n"
message2: .asciiz "Average pixel value of new image:\n"
buffer:      .space  49165
input_file:  .asciiz "input_file.ppm"
output_file: .asciiz "output_file.ppm"
output_data:  .space  5
stack: .space 10
totalOriginalPixels:  .word 0     # value of original pixels added up
totalNewPixels: .word 0           # value of new pixels added up
totalToDivideBy: .word 3133440    # 64 x 64 x 3 x 255
old_average: .double 0.0
new_average: .double 0.0
first_four_lines: .asciiz "P3\n# Jet\n64 64\n255\n"

.text
.globl main
main: 
    #loading totals into $s registers
        lw $s4, totalOriginalPixels
        lw $s5, totalNewPixels
        lw $s6, totalToDivideBy
        
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
     
        li $t9, 10       #used for conversion of ascii to int
        
    read_file_into_buffer:
        li $s3, 10 # ASCII value for newline
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
        
        #move 25 spaces forward in buffer
        li $t1, 25      #set loop counter to 25
        loop:
            addi $t0, $t0,1     # Increment buffer pointer to the next byte
            addi $t1, $t1, -1   # Decrement loop counter 
            bnez $t1, loop      # start loop again if counter not zero
            
        addi $t0, $t0,1     # Increment buffer pointer to the next byte
    process_line_loop:
        lb $t1, 0($t0)              # load a byte from buffer
        beq $t1, 10, add_ten   # newline character
        beqz $t1, end_of_file      # null terminator (end of buffer)
        
        sub $t1, $t1, '0'           # Convert ASCII to integer
        mul $t5,$t5,$t9             # multiply number by 10
        add $t5, $t5, $t1           # add character to total
        addi $t0, $t0, 1      # move to next character in buffer
        j process_line_loop
    
    add_ten:
        add $s4, $s4, $t5               # Add to totalOriginal
        addi $t5, $t5, 10               # Add 10 to number
        add $s5, $s5, $t5               # Add to totalNew
        
        bgt $t5, 255, clamp        # branch if value is greater than 255
        j end_of_line         
        
    clamp:
        li $t5, 255                     # Set $t1 to 255 if it exceeds 255
        j end_of_line
    
    end_of_line: 
        #turn ascii back to int, while copying into output_data
        
        move $t3, output_data       # points to output_string
        la $t4, stack               # initialize a stack 
        li $t6, 0                   # Stack pointer
            convert_loop:
                div $t5, $t9        # divide $t5 by 10
                mflo $t7            # move quotient to $t7
                mfhi $t8            # move remainder to $t8
                
                addi $t8, $t8, '0'  # Convert remainder to integer
                
                #Push digit onto stack
                sb $t8, 0($t4)
                addi $t4, $t4, 1
                addi $t6, &t6, 1
                
                bnez $t7, convert_loop # Repeat loop if quotient is not zero
        
        #Pop digits from stack, append to output string
        pop_loop:
            beqz $t6, end_of_conversion     #if stack empty, exit loop
            
            addi $t4, $t4, -1 # move stack pointer back
            lb $t2, 0($t4)    # pop a digit from the stack
            sb $t2, 0($t3)    # store digit in output string
            addi $t3, $t3, 1  # move to next space in output string
            
            addi $t6, $t6, -1 #decrement stack pointer
            j pop_loop
        
    end_of_conversion:
        # Append newline character
        sb $s3, 0($t3)               # save newline char into output string
        
        li $v0, 15                      # write to file
        move $a0, $s1                   # output file descriptor
        la $a1, output_data             # buffer to write
        li $a2, 5                   # number of bytes to write
        syscall
        
        addi $t0, $t0, 1      # move to next number
        
        move $t5, $zero             #make $t5 zero again
        
        #clear memory of output_data
        la $a0, output_data     # buffer address
        li $t6, 5               # number of bytes
        
        addi $t6, $a0, 5        # calculate the end address
        clear_loop:
            sb $t5, 0($a0)      # Store 0 in specific point in output_data
            addi $a0, $a0, 1    # Move to next byte
            bne $a0, $t6, clear_loop       #repeat till end address is reached 
            
        j process_line_loop         #go to next line
    
    
    end_of_file:
        li $v0, 16             # syscall: close file
        move $a0, $s0          # input file descriptor
        syscall               
    
    close_output_file:
        li $v0, 16             # syscall: close file
        move $a0, $s1          # output file descriptor
        syscall                
    
    
    calculations:
        la $t0, old_average     #address of old average
        la $t1, new_average     #address of new average
        
        #convert values to floating point
        mtc1 $s4, $f0
        mtc1 $s5, $f1
        mtc1 $s6, $f2
        
        #convert to double
        cvt.d.w $f0, $f0
        cvt.d.w $f1, $f1
        cvt.d.w $f2, $f2
        
        #calculate averages
        div.d $f3, $f0, $f2
        div.d $f4, $f1, $f2
        
        #store back into memory
        sdc1 $f3, old_average
        sdc1 $f4, new_average
    
    print_averages:
    
        li $v0, 4
        la $a0, message1            # message for old average
        syscall
        
        li $v0, 3
        ldc1 $f12, old_average      # message showing old average value
        syscall
        
        # New line
        li $v0,4
        la $a0, "\n"    
        syscall
    
        li $v0, 4
        la $a0, message2            # message for new average
        syscall
        
        li $v0, 3
        ldc1 $f12, new_average      # message showing new average value
        syscall
        
exit:
    li $v0, 10             # syscall: exit
    syscall                