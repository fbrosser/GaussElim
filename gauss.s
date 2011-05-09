#
# D-cache :  2way, 16 blocks, 8 words/block, LRU, WB
# I-cache : Direct, LRU, 8 blocks, 8 words/block
# Memory  : 4 First word, 1 Following words, Write buffer 8 words
#
# Budget: 
# I-cache : Direct, LRU, 8 Blocks, 4 Words/block
# D-cache : 2-way, 8 blocks, 8 words/block, LRU, WB
# Memory  : 5 First word, 1 Following Words, Write buffer 1 word
# 
# Gausselimination  EDA331
# Fredrik Brosser
# version 2011-05-06

#include <iregdef.h>

### Text segment
        .text                      
        .globl    main              
main:
        la        $4, matrix_4x4        # a0 = A (base address of matrix)
        li        $5, 4                # a1 = N (number of elements per row)
                                    # <debug>
        jal     print_matrix        # print matrix before elimination
        nop                            # </debug>

################################################################################
## FREDRIKS KOD  
################################################################################

    ## Initialize pivot loop var, k
       add         $s0, $0, $0       # k = 0

    ## Initialize some constants
        sll        $t3, $a1, 2       # t3 = 4*N (number of bytes per row)
        addi       $t4, $t3, 4       # t4 = number of bytes in one row plus one step
        l.s        $f6, const1       # f1 = 1.0 (float constant)
        l.s        $f8, const0       # f0 = 0.0 (float constant)
        add        $s3, $a0, $0      # s3 = A (s3 will hold the address to A[k][k])
		addi	   $s4, $a0, -4		 # s4 = A (s4 will hold 'next line' address)
		
L1:      
    ## Getelem A[k][k]
        l.s     $f0, ($s3)           # f0 = contents of A[k][k]

        div.s   $f2, $f6, $f0        # f2 = 1 / A[k][k], multiplication is cheaper than division!
        #addi    $s2, $s0, 1          # j = k + 1
        addi    $t0, $s3, 4          # t0 = address to A[k][j]...
		add		$s4, $s4, $t3		 # step forward 'next row' address one row (obviously)

L2:  
    ## Getelem A[k][j]
        l.s     $f0, ($t0)           # f0 = contents of A[k][j]

        mul.s   $f0, $f0, $f2        # f0 = A[k][j] * (1 / A[k][k])
        s.s     $f0, ($t0)           # A[k][j] = f2
     
        #addi    $s2, $s2, 1          # j++
        #blt     $s2, $a1, L2         # branch if j < N
		blt		$t0, $s4, L2		 # branch if not on next row (rowerflow!)
        addi    $t0, $t0, 4          # step forward A[k][j] one row

        s.s     $f6, ($s3)           # A[k][k] = 1.0 (pivot element)

        ## Prepare for i loop
        addi    $s1, $s0, 1          # i = k + 1
        add     $t0, $s3, $t3        # t0 = address to A[i][k]

L3:
    ## Getelem A[i][k]
        l.s     $f0, ($t0)           # f0 = contents of A[i][k]

        addi    $t1, $s3, 4          # t1 = address to A[k][j]
        addi    $t2, $t0, 4          # t2 = address to A[i][j]
        addi    $s2, $s0, 1          # j = k + 1
   
L4:
    ## Getelem A[k][j]
        l.s     $f2, ($t1)           # f2 = contents of A[k][j]
    ## Getelem A[i][j]
        l.s     $f4, ($t2)           # f4 = contents of A[i][j]

        mul.s   $f2, $f2, $f0        # f2 = A[k][j] * A[i][k]
        sub.s   $f4, $f4, $f2        # f4 = A[i][j] - (A[i][k] * A[k][j])
        s.s     $f4, ($t2)           # Store away f4 in A[i][j]

        addi    $s2, $s2, 1          # j++
        addi    $t2, $t2, 4          # step forward A[i][j] one column
        blt     $s2, $a1, L4         # branch if j < N
        addi    $t1, $t1, 4          # step forward A[k][j] one column DELAY SLOT
		
        s.s     $f8, ($t0)           # A[i][k] = 0.0                    
	
        addi    $s1, $s1, 1          # i++
        blt     $s1, $a1, L3         # branch if i < N
        add     $t0, $t0, $t3        # step forward A[i][k] one row DELAY SLOT
       
        addi    $s0, $s0, 1          # k++
		blt     $s0, $a1, L1         # branch if k < N
        add     $s3, $s3, $t4        # step forward A[k][k] one row and column DELAY SLOT

################################################################################
## SLUT AV FREDRIKS KOD  
################################################################################

        jal     print_matrix        # print matrix after elimination
        nop                         # </debug>

        li       $2, 10              # specify exit system call
        syscall                      # exit program

################################################################################
# print_matrix
#
# This routine is for debugging purposes only.
# Do not call this routine when timing your code!
#
# print_matrix uses floating point register $f12.
# the value of $f12 is _not_ preserved across calls.
#
# Args:        $4  - base address of matrix (A)
#            $5  - number of elements per row (N)
print_matrix:
        addiu    $29,  $29, -20        # allocate stack frame
        sw        $31,  16($29)
        sw      $18,  12($29)
        sw        $17,  8($29)
        sw        $16,  4($29)
        sw        $4,  0($29)        # done saving registers

        move    $18,  $4            # s2 = a0 (array pointer)
        move    $17,  $0            # s1 = 0  (row index)
loop_s1:
        move    $16,  $0            # s0 = 0  (column index)
loop_s0:
        l.s        $f12, 0($18)        # $f12 = A[s1][s0]
        li        $2,  2                # specify print float system call
         syscall                        # print A[s1][s0]
        la        $4,  spaces
        li        $2,  4                # specify print string system call
        syscall                        # print spaces

        addiu    $18,  $18, 4        # increment pointer by 4

        addiu    $16,  $16, 1        # increment s0
        blt        $16,  $5, loop_s0  # loop while s0 < a1
        nop
        la        $4,  newline
        syscall                        # print newline
        addiu    $17,  $17, 1        # increment s1
        blt        $17,  $5, loop_s1  # loop while s1 < a1
        nop
        la        $4,  newline
        syscall                        # print newline

        lw        $31,  16($29)
        lw        $18,  12($29)
        lw        $17,  8($29)
        lw        $16,  4($29)
        lw        $4,  0($29)        # done restoring registers
        addiu    $29,  $29, 20        # remove stack frame

        jr        $31                    # return from subroutine
        nop                            # this is the delay slot associated with all types of jumps

### End of text segment

### Data segment
        .data
      
### String constants
spaces:
        .asciiz "   "               # spaces to insert between numbers
newline:
        .asciiz "\n"                  # newline

## Input matrix: (4x4) ##
matrix_4x4:  
        .float 57.0
        .float 20.0
        .float 34.0
        .float 59.0
      
        .float 104.0
        .float 19.0
        .float 77.0
        .float 25.0
      
        .float 55.0
        .float 14.0
        .float 10.0
        .float 43.0
      
        .float 31.0
        .float 41.0
        .float 108.0
        .float 59.0

const0:
        .float 0.0
const1:
        .float 1.0

## Input matrix: (24x24) ##
matrix_24x24:
        .float     92.00
        .float     43.00
        .float     86.00
        .float     87.00
        .float    100.00
        .float     21.00
        .float     36.00
        .float     84.00
        .float     30.00
        .float     60.00
        .float     52.00
        .float     69.00
        .float     40.00
        .float     56.00
        .float    104.00
        .float    100.00
        .float     69.00
        .float     78.00
        .float     15.00
        .float     66.00
        .float      1.00
        .float     26.00
        .float     15.00
        .float     88.00

        .float     17.00
        .float     44.00
        .float     14.00
        .float     11.00
        .float    109.00
        .float     24.00
        .float     56.00
        .float     92.00
        .float     67.00
        .float     32.00
        .float     70.00
        .float     57.00
        .float     54.00
        .float    107.00
        .float     32.00
        .float     84.00
        .float     57.00
        .float     84.00
        .float     44.00
        .float     98.00
        .float     31.00
        .float     38.00
        .float     88.00
        .float    101.00

        .float      7.00
        .float    104.00
        .float     57.00
        .float      9.00
        .float     21.00
        .float     72.00
        .float     97.00
        .float     38.00
        .float      7.00
        .float      2.00
        .float     50.00
        .float      6.00
        .float     26.00
        .float    106.00
        .float     99.00
        .float     93.00
        .float     29.00
        .float     59.00
        .float     41.00
        .float     83.00
        .float     56.00
        .float     73.00
        .float     58.00
        .float      4.00

        .float     48.00
        .float    102.00
        .float    102.00
        .float     79.00
        .float     31.00
        .float     81.00
        .float     70.00
        .float     38.00
        .float     75.00
        .float     18.00
        .float     48.00
        .float     96.00
        .float     91.00
        .float     36.00
        .float     25.00
        .float     98.00
        .float     38.00
        .float     75.00
        .float    105.00
        .float     64.00
        .float     72.00
        .float     94.00
        .float     48.00
        .float    101.00

        .float     43.00
        .float     89.00
        .float     75.00
        .float    100.00
        .float     53.00
        .float     23.00
        .float    104.00
        .float    101.00
        .float     16.00
        .float     96.00
        .float     70.00
        .float     47.00
        .float     68.00
        .float     30.00
        .float     86.00
        .float     33.00
        .float     49.00
        .float     24.00
        .float     20.00
        .float     30.00
        .float     61.00
        .float     45.00
        .float     18.00
        .float     99.00

        .float     11.00
        .float     13.00
        .float     54.00
        .float     83.00
        .float    108.00
        .float    102.00
        .float     75.00
        .float     42.00
        .float     82.00
        .float     40.00
        .float     32.00
        .float     25.00
        .float     64.00
        .float     26.00
        .float     16.00
        .float     80.00
        .float     13.00
        .float     87.00
        .float     18.00
        .float     81.00
        .float      8.00
        .float    104.00
        .float      5.00
        .float     57.00

        .float     19.00
        .float     26.00
        .float     87.00
        .float     80.00
        .float     72.00
        .float    106.00
        .float     70.00
        .float     83.00
        .float     10.00
        .float     14.00
        .float     57.00
        .float      8.00
        .float      7.00
        .float     22.00
        .float     50.00
        .float     90.00
        .float     63.00
        .float     83.00
        .float      5.00
        .float     17.00
        .float    109.00
        .float     22.00
        .float     97.00
        .float     13.00

        .float    109.00
        .float      5.00
        .float     95.00
        .float      7.00
        .float      0.00
        .float    101.00
        .float     65.00
        .float     19.00
        .float     17.00
        .float     43.00
        .float    100.00
        .float     90.00
        .float     39.00
        .float     60.00
        .float     63.00
        .float     49.00
        .float     75.00
        .float     10.00
        .float     58.00
        .float     83.00
        .float     33.00
        .float    109.00
        .float     63.00
        .float     96.00

        .float     82.00
        .float     69.00
        .float      3.00
        .float     82.00
        .float     91.00
        .float    101.00
        .float     96.00
        .float     91.00
        .float    107.00
        .float     81.00
        .float     99.00
        .float    108.00
        .float     73.00
        .float     54.00
        .float     18.00
        .float     91.00
        .float     97.00
        .float      8.00
        .float     71.00
        .float     27.00
        .float     69.00
        .float     25.00
        .float     77.00
        .float     34.00

        .float     36.00
        .float     25.00
        .float      8.00
        .float     69.00
        .float     24.00
        .float     71.00
        .float     56.00
        .float    106.00
        .float     30.00
        .float     60.00
        .float     79.00
        .float     12.00
        .float     51.00
        .float     65.00
        .float    103.00
        .float     49.00
        .float     36.00
        .float     93.00
        .float     47.00
        .float      0.00
        .float     37.00
        .float     65.00
        .float     91.00
        .float     25.00

        .float     74.00
        .float     53.00
        .float     53.00
        .float     33.00
        .float     78.00
        .float     20.00
        .float     68.00
        .float      4.00
        .float     45.00
        .float     76.00
        .float     74.00
        .float     70.00
        .float     38.00
        .float     20.00
        .float     67.00
        .float     68.00
        .float     80.00
        .float     36.00
        .float     81.00
        .float     22.00
        .float    101.00
        .float     75.00
        .float     71.00
        .float     28.00

        .float     58.00
        .float      9.00
        .float     28.00
        .float     96.00
        .float     75.00
        .float     10.00
        .float     12.00
        .float     39.00
        .float     63.00
        .float     65.00
        .float     73.00
        .float     31.00
        .float     85.00
        .float     31.00
        .float     36.00
        .float     20.00
        .float    108.00
        .float      0.00
        .float     91.00
        .float     36.00
        .float     20.00
        .float     48.00
        .float    105.00
        .float    101.00

        .float     84.00
        .float     76.00
        .float     13.00
        .float     75.00
        .float     42.00
        .float     85.00
        .float    103.00
        .float    100.00
        .float     94.00
        .float     22.00
        .float     87.00
        .float     60.00
        .float     32.00
        .float     99.00
        .float    100.00
        .float     96.00
        .float     54.00
        .float     63.00
        .float     17.00
        .float     30.00
        .float     95.00
        .float     54.00
        .float     51.00
        .float     93.00

        .float     54.00
        .float     32.00
        .float     19.00
        .float     75.00
        .float     80.00
        .float     15.00
        .float     66.00
        .float     54.00
        .float     92.00
        .float     79.00
        .float     19.00
        .float     24.00
        .float     54.00
        .float     13.00
        .float     15.00
        .float     39.00
        .float     35.00
        .float    102.00
        .float     99.00
        .float     68.00
        .float     92.00
        .float     89.00
        .float     54.00
        .float     36.00

        .float     43.00
        .float     72.00
        .float     66.00
        .float     28.00
        .float     16.00
        .float      7.00
        .float     11.00
        .float     71.00
        .float     39.00
        .float     31.00
        .float     36.00
        .float     10.00
        .float     47.00
        .float    102.00
        .float     64.00
        .float     29.00
        .float     72.00
        .float     83.00
        .float     53.00
        .float     17.00
        .float     97.00
        .float     68.00
        .float     56.00
        .float     22.00

        .float     61.00
        .float     46.00
        .float     91.00
        .float     43.00
        .float     26.00
        .float     35.00
        .float     80.00
        .float     70.00
        .float    108.00
        .float     37.00
        .float     98.00
        .float     14.00
        .float     45.00
        .float      0.00
        .float     86.00
        .float     85.00
        .float     32.00
        .float     12.00
        .float     95.00
        .float     79.00
        .float      5.00
        .float     49.00
        .float    108.00
        .float     77.00

        .float     23.00
        .float     52.00
        .float     95.00
        .float     10.00
        .float     10.00
        .float     42.00
        .float     33.00
        .float     72.00
        .float     89.00
        .float     14.00
        .float      5.00
        .float      5.00
        .float     50.00
        .float     85.00
        .float     76.00
        .float     48.00
        .float     13.00
        .float     64.00
        .float     63.00
        .float     58.00
        .float     65.00
        .float     39.00
        .float     33.00
        .float     97.00

        .float     52.00
        .float     18.00
        .float     67.00
        .float     57.00
        .float     68.00
        .float     65.00
        .float     25.00
        .float     91.00
        .float      7.00
        .float     10.00
        .float    101.00
        .float     18.00
        .float     52.00
        .float     24.00
        .float     90.00
        .float     31.00
        .float     39.00
        .float     96.00
        .float     37.00
        .float     89.00
        .float     72.00
        .float      3.00
        .float     28.00
        .float     85.00

        .float     68.00
        .float     91.00
        .float     33.00
        .float     24.00
        .float     21.00
        .float     67.00
        .float     12.00
        .float     74.00
        .float     86.00
        .float     79.00
        .float     22.00
        .float     44.00
        .float     34.00
        .float     47.00
        .float     25.00
        .float     42.00
        .float     58.00
        .float     17.00
        .float     61.00
        .float      1.00
        .float     41.00
        .float     42.00
        .float     33.00
        .float     81.00

        .float     28.00
        .float     71.00
        .float     60.00
        .float    101.00
        .float     75.00
        .float     89.00
        .float     76.00
        .float     34.00
        .float     71.00
        .float      0.00
        .float     58.00
        .float     92.00
        .float     68.00
        .float     70.00
        .float     57.00
        .float     44.00
        .float     39.00
        .float     79.00
        .float     88.00
        .float     74.00
        .float     16.00
        .float      3.00
        .float      6.00
        .float     75.00

        .float     20.00
        .float     68.00
        .float     77.00
        .float     62.00
        .float      0.00
        .float      0.00
        .float     33.00
        .float     28.00
        .float     72.00
        .float     94.00
        .float     19.00
        .float     37.00
        .float     73.00
        .float     96.00
        .float     71.00
        .float     34.00
        .float     97.00
        .float     20.00
        .float     17.00
        .float     55.00
        .float     91.00
        .float     74.00
        .float     99.00
        .float     21.00

        .float     43.00
        .float     77.00
        .float     95.00
        .float     60.00
        .float     81.00
        .float    102.00
        .float     25.00
        .float    101.00
        .float     60.00
        .float    102.00
        .float     54.00
        .float     60.00
        .float    103.00
        .float     87.00
        .float     89.00
        .float     65.00
        .float     72.00
        .float    109.00
        .float    102.00
        .float     35.00
        .float     96.00
        .float     64.00
        .float     70.00
        .float     83.00

        .float     85.00
        .float     87.00
        .float     28.00
        .float     66.00
        .float     51.00
        .float     18.00
        .float     87.00
        .float     95.00
        .float     96.00
        .float     73.00
        .float     45.00
        .float     67.00
        .float     65.00
        .float     71.00
        .float     59.00
        .float     16.00
        .float     63.00
        .float      3.00
        .float     77.00
        .float     56.00
        .float     91.00
        .float     56.00
        .float     12.00
        .float     53.00

        .float     56.00
        .float      5.00
        .float     89.00
        .float     42.00
        .float     70.00
        .float     49.00
        .float     15.00
        .float     45.00
        .float     27.00
        .float     44.00
        .float      1.00
        .float     78.00
        .float     63.00
        .float     89.00
        .float     64.00
        .float     49.00
        .float     52.00
        .float    109.00
        .float      6.00
        .float      8.00
        .float     70.00
        .float     65.00
        .float     24.00
        .float     24.00

### End of data segment
