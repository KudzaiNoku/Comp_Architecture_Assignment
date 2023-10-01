.data
input_file:  .asciiz "/Users/kudzainyika/Desktop/ArchAssignment/input_file.txt"
output_file: .asciiz "/Users/kudzainyika/Desktop/ArchAssignment/output_file.txt"
message1: .asciiz "Average pixel value of original image:\n"
message2: .asciiz "Average pixel value of new image:\n"
buffer:      .space  49165
output_data:  .space  100
stack: .space 100
totalOriginalPixels:  .word 0     # value of original pixels added up
totalNewPixels: .word 0           # value of new pixels added up
totalToDivideBy: .word 3133440    # 64 x 64 x 3 x 255
old_average: .double 0.0
new_average: .double 0.0
first_four_lines: .asciiz "P3\n# Jet\n64 64\n255\n"
newline: .asciiz "\n"
buffer_reverse: .space 100

.text
.globl main
main: 
    #loading totals into $s registers
        la $s4, totalOriginalPixels
        la $s5, totalNewPixels
        la $s6, totalToDivideBy
        li $s3, 10 # ASCII value for newline
        
        # Open file for reading
        li $v0, 13          # open file
        la $a0, input_file  # load address of input file name
        li $a1, 0           # open for reading (O_RDONLY - open for reading only)     
        syscall
        move $s0, $v0       # save input file descriptor
        
        
        #read file into buffer
        li $v0, 14              # read_file syscall code = 14
        move $a0,$s0            # file descriptor
        la $a1, buffer       # buffer that holds the string of the WHOLE file
        la $a2, 49165            # hardcoded buffer length
        syscall     
        
        #open output file
        li $v0, 13              # open_file syscall code = 13
        la $a0, output_file        # get the file name
        li $a1, 1               # file flag = write (1)
        syscall
        move $s1, $v0           #save file descriptor. $s0 = file
     
        li $t9, 10       #used for conversion of ascii to int
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
        li $t6, 10
        add $t5, $t5, $t6               # Add 10 to number
        add $s5, $s5, $t5               # Add to totalNew
        
        bgt $t5, 255, clamp        # branch if value is greater than 255
        j end_of_line         
        
    clamp:
        li $t5, 255                     # Set $t1 to 255 if it exceeds 255
        j end_of_line
    
    end_of_line: 
        la $t3, output_data         # where the final string will be stored
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
            sb $t8, 0($t3)
            addi $t3, $t3, 1      # Move to the next position in output_data
            addi $t7, $t7, -1     # Move to previous position in buffer_reverse
            addi $t6, $t6, -1
            bnez $t6, copy_loop   # Repeat til all digits are copied
            j end_of_conversion
        store_zero:
            # Store the digit '0' for the number 0
            li $t8, '0'
            sb $t8, 0($t3)
            addi $t3, $t3, 1
        
    end_of_conversion:
        # Append newline character
        sb $s3, 0($t3)               # save newline char into output string
        
        li $v0, 15                      # write to file
        move $a0, $s1                   # output file descriptor
        la $a1, output_data             # buffer to write
        li $a2, 100                   # number of bytes to write
        syscall
        
        addi $t0, $t0, 1      # move to next number
        
        li $t5, 0             #make $t5 zero again
        
        #clear memory of output_data
        la $a0, output_data     # buffer address
        li $t6, 100               # number of bytes
        
        addi $t6, $a0, 100        # calculate the end address
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
        mtc1 $s4, $f2
        mtc1 $s5, $f4
        mtc1 $s6, $f6
        
        #convert to double
        cvt.d.w $f2, $f2
        cvt.d.w $f4, $f4
        cvt.d.w $f6, $f6
        
        #calculate averages
        div.d $f8, $f2, $f6
        div.d $f10, $f4, $f6
        
        #store back into memory
        sdc1 $f8, old_average
        sdc1 $f10, new_average
    
    print_averages:
        li $v0, 4
        la $a0, message1            # message for old average
        syscall
        
        li $v0, 3
        ldc1 $f12, old_average      # message showing old average value
        syscall
        
        # New line
        li $v0,4
        la $a0, newline    
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