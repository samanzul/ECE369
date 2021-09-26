.data
# test 0 For the 4x4 frame size and 2X2 window size
# small size for validation and debugging purpose
# The result should be 0, 2
asize0:  .word    4,  4,  2, 2    #i, j, k, l

frame0:  .word    1,  6,  1,  2, 
         .word    9,  10,  3,  4
         .word    0,  0,  0,  0
         .word    0,  0,  0,  0, 

window0: .word    1,  2, 
         .word    3,  4, 

newline: .asciiz     "\n"

.text
.globl  main

main:
    # a0 = &asize, a1 = &frame, a2 = &window, a3 = index
    # s0 = maxRowFrame, s1 = maxColFrame, s2 = maxRowWindow, s3 = maxColWindow
    la $a0, asize0   # 1st parameter: address of asize1[0]
    la $a1, frame0   # 2nd parameter: address of frame1[0]
    la $a2, window0  # 3rd parameter: address of window1[0] 
    lw $s0, 0($a0)   # s0 = maxRowFrame
    lw $s1, 4($a0)   # s1 = maxColFrame
    lw $s2, 8($a0)   # s2 = maxRowWindow
    lw $s3, 12($a0)  # s3 = maxColWindow
    
    
    li $s5, 0       # i = 0
    vbsme_forloop:
        mul $t0, $s0, $s1   # t0 = maxRowFrame * maxColFrame
        slt $t0, $s6, $t0   # t0 = 1 if i < maxRowFrame * maxColFrame
        beq $t0, $zero, vbsme_forloop_exit  # leave loop if i > maxRowFrame * maxColFrame
        jal increment
        addi $sp, $sp, -4   # adjust stack for one item
        sw $a3, 0($sp)      # save the current index on the stack
        add $a3, $zero, $s7 # a3 = minIndex
        jal SAD
        addi $t8, $v0, 0    # t8 = sum from SAD
        lw $a3, 0($sp)      # restore current index to a3
        addi $sp, $sp, 4    # restore stack
        jal SAD
        addi $t9, $v0, 0    # t9 = sum from SAD
        sgt $t8, $t8, $t9   # t8 = 1 if t8 > t9
        beq $t8, $zero, vbsme_if_exit
        vbsme_if:
            add $s7, $a3, $zero # minIndex = index
        vbsme_if_exit:
        addi $s6, $s6, 1    # i++
        j vbsme_forloop
    vbsme_forloop_exit:

    add $v0, $a3, $zero

    # Printing $v0
    add     $a0, $v0, $zero     # Load $v0 for printing
    li      $v0, 1              # Load the system call numbers
    syscall

    # Print newline.
    la      $a0, newline          # Load value for printing
    li      $v0, 4                # Load the system call numbers
    syscall
   
    # Print newline.
    la      $a0, newline          # Load value for printing
    li      $v0, 4                # Load the system call numbers
    syscall

    j end

.text
.globl increment

increment:
    # s0 = maxRowFrame, s1 = maxColFrame, a3 = index
    # s4 = trajectory s5 = pass
    
    slt $t0, $s1, $s1   # index < maxColFrame
    beq $zero, $t0, INCR_1
    bne $s5, $zero, INCR_1 # && pass == 0

    addi $a3, $a3, 1    # index++
    addi $s5, $zero, 1  # pass = 1
    addi $s4, $zero, 0  # trajectory = 0
    j INCR_END

    INCR_1:
        addi $t0, $s0, -1   # row - 1
        mul $t1, $s1, $t0       # col * (row -1)
        addi $t1, $t1, -1   # (col * (row - 1) - 1)
        slt $t2, $t1, $a3   # (col * (row - 1) - 1) < index
        beq $zero, $t2, INCR_2
        bne $s5, $zero, INCR_2

        addi $a3, $a3, 1    # index++
        addi $s5, $zero, 1  # pass = 1
        addi $s4, $zero, 1  # trajectory = 1
        j INCR_END

    INCR_2:
        div $a3, $s1
        mfhi $t0            # index % col
        bne $t0, $zero, INCR_3
        bne $s5, $zero, INCR_3

        add $a3, $a3, $s1   # index = index + col
        addi $s5, $zero, 1  # pass = 1
        addi $s4, $zero, 1  # trajectory = 1
        j INCR_END

    INCR_3:
        addi $t1, $a3, 1    # index + 1
        div $t1, $s1
        mfhi $t0            # index + 1 % col
        bne $t0, $zero, INCR_ELSE
        bne $s5, $zero, INCR_ELSE

        add $a3, $a3, $s1   # index = index + col
        addi $s5, $zero, 1  # pass = 1
        addi $s4, $zero, 0  # trajectory = 0
        j INCR_END

    INCR_ELSE:
        bne $s4, $zero, INCR_ELSE_2
        add $a3, $a3, $s1   # index = index + col
        addi $a3, $a3, -1   # index + col - 1

    INCR_ELSE_2:
        beq $s4, $zero, INCR_ELSE_3
        sub $a3, $a3, $s1   # index = index - col
        addi $a3, $a3, 1    # index - col + 1

    INCR_ELSE_3:
        addi $s5, $zero, 0 # pass = 0

    INCR_END:
    jr $ra   

.text
.globl   SAD

SAD:
    # a0 = &asize,  a1 = &frame, a2 = &window,a3 = index
    # s0 = maxRowFrame, s1 = maxColFrame, s2 = maxRowWindow, s3 = maxColWindow
    # t0 = sum, t1 = count
    # v0 = SAD
    addi $t0, $zero, 0  # sum = 0
    addi $t1, $zero, 0  # count = 0

    div $a3, $s0        # index / maxRowFrame
    mfhi $t2            # t2 = index % maxRowFrame
    add $t2, $t2, $s2   # t2 = index % maxRowFrame + maxRowWindow
    sgt $t2, $t2, $s0   # t2 = 1 if (index % maxRowFrame + maxRowWindow) > maxRowFrame
    mul $t3, $s0, $s1   # t3 = maxRowFrame * maxColFrame
    mul $t4, $s0, $s3   # t4 = maxRowFrame * maxColWindow
    sub $t3, $t3, $t4   # t3 =  maxRowFrame * maxColFrame) -  maxRowFrame * maxColWindow)
    add $t4, $s3, $a3   # t4 = maxColWindow + index
    slt $t3, $t3, $t4   # t3 = 1 if ( maxRowFrame * maxColFrame) -  maxRowFrame * maxColWindow)) < (maxColWindow + index)
    or $t2, $t2, $t3   # t2 = 1 if t2 and t3 = 1
    beq $t2, $zero, SAD_acceptable # continue through SAD if conditions not met
    addi $v0, $zero, 1000 # return large value if unable to do SAD
    jr $ra               # exit SAD function

    SAD_acceptable: # t2 = i, t3 = k, t5 = window[count], t6 = frame[k + index + maxRowFrame * i]
        add $t2, $zero, $zero   # i = 0
        SAD_firstloop:
            slt $t4, $t2, $s3       # $t4 = 1 if i < maxColWindow
            beq $t4, $zero, SAD_firstloop_exit # leave loop if i >= maxColWindow
            add $t3, $zero, $zero   # k = 0
            SAD_secondloop:
                slt $t4, $t3, $s2   # $t4 = 1 if k < maxRowWindow
                beq $t4, $zero, SAD_secondloop_exit # leave loop if k >= maxRowWindow
                sll $t5, $t1, 2     # t5 = count * 4
                add $t5, $t5, $a2   # t5 = &window[count]
                lw $t5, 0($t5)      # t5 = window[count]
                add $t6, $t3, $a3   # t6 = k + index
                mul $t7, $s0, $t2   # t7 = maxRowFrame * i
                add $t6, $t6, $t7   # t6 = k + index + maxRowFrame * i
                sll $t6, $t6, 2     # t6 = 4 * (k + index + maxRowFrame * i)
                add $t6, $t6, $a1   # t6 = &frame[k + index + maxRowFrame * i]
                lw $t6, 0($t6)      # t6 = frame[k + index + maxRowFrame * i]
                sub $t5, $t5, $t6   # t5 = window[count] - frame[k + index + maxRowFrame * i]
                abs $t5, $t5        # t5 = |window[count] - frame[k + index + maxRowFrame * i]|
                add $t0, $t0, $t5   # sum = sum + |window[count] - frame[k + index + maxRowFrame * i]|
                
                addi $t1, $t1, 1    # count++
                addi $t3, $t3, 1    # k++
                j SAD_secondloop    # loop
            SAD_secondloop_exit:
            addi $t2, $t2, 1    # i++
            j SAD_firstloop     # loop
        SAD_firstloop_exit:
    add $v0, $v0, $t0  # return sum
    jr $ra               # exit SAD function


end:
