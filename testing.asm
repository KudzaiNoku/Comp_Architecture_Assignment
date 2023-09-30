.data
number: .asciiz "255\n"
message1: .asciiz "Ascii Version of number:\n"
message2: .asciiz "Integer version of number:\n"
newline: .asciiz "\n
output_data: .space 1024
stack: .space 1024
.text
.globl main

main:
    la $t0, number  #load address of number
    li $t5, 0
    li $t3, 10
    li $s3, 10
change_to_ascii:
    loop:
        lb $t1, 0($t0)
        beq $t1, $s3, print_ascii
        sub $t1,  $t1, '0'
        mul $t5, $t5, $t3
        add $t5, $t5, $t1
        addi $t0, $t0, 1
        j loop
        
print_ascii: 
    la $t8, message1
    li $v0, 4
    move $a0, $t8
    syscall
    
    li $v0, 1
    move $a0, $t5
    syscall
    
    li $v0, 4
    la $a0, newline
    syscall
    
change_back_toInt:
        #turn ascii back to int, while copying into output_data
        addi $t5, $t5, 10           # add 10 to t5
        la $t1, output_data         # points to output_data
        la $t4, stack               # initialize a stack 
        li $t6, 0                   # Stack pointer
            convert_loop:
                div $t5, $t3        # divide $t5 by 10
                mflo $t7            # move quotient to $t7
                mfhi $t8            # move remainder to $t8
                
                addi $t8, $t8, '0'  # Convert remainder to integer
                
                #Push digit onto stack
                sb $t8, 0($t4)
                addi $t4, $t4, 1
                addi $t6, $t6, 1
                
                bnez $t7, convert_loop # Repeat loop if quotient is not zero
        
        #Pop digits from stack, append to output string
        pop_loop:
            beqz $t6, print_int     #if stack empty, exit loop
            
            addi $t4, $t4, -1 # move stack pointer back
            lb $t2, 0($t4)    # pop a digit from the stack
            sb $t2, 0($t1)    # store digit in output string
            addi $t1, $t1, 1  # move to next space in output string
            addi $t6, $t6, -1 #decrement stack pointer
            j pop_loop
            
print_int:   
    sb $s3, 0($t1)               # save newline char into output string
    li $v0, 4
    la $a0, message2
    syscall
    
    li $v0, 4
    la $a0, output_data
    syscall
    
exit:
    li $v0, 10
    syscall
    
