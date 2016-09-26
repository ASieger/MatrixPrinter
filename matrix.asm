#How to make the matrix "fall" faster:
#When update each falling row of the matrix, randomly decide how many characters to update(one column updates 1 character while another updates 3)
#How to decide when a new row falls:
#Implement a random number generation and a percenatage that selects a new row to fall (i.e. a generator makes 0-100, make a new row when it outputs a number <5)
#Each iteration of the matrix should update each column at the appropriate "speed", so store a register with the numbers of the columns in that are in it along with it's speed.
.data
	matrixBuffer: .space 80
	matrixColumn: .space 80	#each column is represented by a one or zero, a zero means that the row is not valid to iterate through, while one is valid
	matrixRowTable: .space 80 #holds the current row each column is on for the iteration loop
	matrixColumnSpeed: .space 80 #holds the "speed" of each column, or how it updates every iteration
.text
li $s0, 0xffff8000	#memory address for the console
li $s1, 0x00002200	#base color for each letter in the matrix
	
addi $t0, $zero, 0 #Counter that keeps track of how many rows that have been printed
addi $s3, $zero, 320
addi $sp, $sp, -8

fileLoop:
beq $t0, 40, fileEnd
mul $s5, $t0, $s3
add $s6, $s5, $s0 #memory address of the base address with its offset for each row
la $a0, matrixBuffer
sw $ra, 0($sp)
sw $t0, 4($sp)
jal _loadMatrixLine
lw $ra, 0($sp)
lw $t0, 4($sp)
la $a0, matrixBuffer
move $a1, $s6
sw $ra, 0($sp)
sw $t0, 4($sp)
jal _printMatrixFileLine
lw $ra, 0($sp)
lw $t0, 4($sp)
addi $t0, $t0, 1
j fileLoop

fileEnd:
addi $sp, $sp, 8
addi $sp, $sp, -4
sw $ra, 0($sp)
j matrixLoop

matrixLoop:
#addi $t0, $zero, 1
#la $a0, matrixColumn
#addi $a0, $a0, 40
#sb $t0, 0($a0)
#la $a1, matrixRowTable
#addi $a1, $a1, 40
#sb $zero, 0($a1)
#addi $t0, $zero, 0
#addi $t1, $zero, 53
#j subLoop

#subLoop:
#beq $t0, $t1, matrixEnd
#la $a0, matrixColumn
#la $a1, matrixRowTable
#jal _iterateColumnTable
#lw $ra, 0($sp)
#addi $t0, $t0, 1
#j subLoop
la $a0, matrixColumn
la $a1, matrixRowTable
la $a2, matrixColumnSpeed
jal _addNewMatrixColumn
lw $ra, 0($sp)
la $a0, matrixColumn
la $a1, matrixRowTable
la $a2, matrixColumnSpeed
jal _iterateColumnTable
lw $ra, 0($sp)
la $a0, matrixColumn
la $a1, matrixRowTable
la $a2, matrixColumnSpeed
jal _cleanMatrixTable
lw $ra, 0($sp)
j matrixLoop


matrixEnd:
addi $sp, $sp, 4
li $v0, 10
syscall

_cleanMatrixTable:
#Removes any rows that are done animating or sets all values of 81 to zero in the table
#$a0 - matrixColumn
#$a1 - matrixRowTabel
addi $s0, $zero, 0
addi $s1, $zero, 80
addi $s2, $zero, 53

checkLoop:
beq $s0, $s1, checkEnd
lb $s3, 0($a0)
bne $s3, $zero, checkForReset
addi $a0, $a0, 1
addi $a1, $a1, 1
addi $a2, $a2, 1
addi $s0, $s0, 1
j checkLoop

checkForReset:
lb $s3, 0($a1)
beq $s3, $s2, resetColumn
addi $a0, $a0, 1
addi $a1, $a1, 1
addi $a2, $a2, 1
addi $s0, $s0, 1
j checkLoop

resetColumn:
sb $zero, 0($a0)
sb $zero, 0($a1)
sb $zero, 0($a2)
addi $a0, $a0, 1
addi $a1, $a1, 1
addi $a2, $a2, 1
addi $s0, $s0, 1
j checkLoop

checkEnd:
jr $ra


_iterateColumnTable:
#This iterates through all the columns in the matrix that are animating right now, if the animation reaches its end, it removes it from the table
#$a0 - matrixColumn
#$a1- matrixRowTable

add $s0, $zero, $zero
addi $s1, $zero, 80
j tableLoop

tableLoop:
beq $s0, $s1, tableLoopEnd
lb $s2, 0($a0)
bne $s2, $zero, validColumn
addi $a0, $a0, 1
addi $a1, $a1, 1
addi $a2, $a2, 1
addi $s0, $s0, 1
j tableLoop

validColumn:
lb $s3, 0($a1)
lb $s4, 0($a2)
addi $s5, $zero, 0
j columnSpeedLoop

columnSpeedLoop:
addi $sp, $sp, -40
sw $ra, 0($sp)
sw $a0, 4($sp)
sw $a1, 8($sp)
sw $s0, 12($sp)
sw $s1, 16($sp)
sw $s2, 20($sp)
sw $a2, 24($sp)
sw $s4, 28($sp)
sw $s5, 32($sp)
sw $a2, 36($sp)


move $a0, $s0
move $a1, $s3
li $a2, 0
jal _iterateColumn

lw $ra, 0($sp)
lw $a0, 4($sp)
lw $a1, 8($sp)
lw $s0, 12($sp)
lw $s1, 16($sp)
lw $s2, 20($sp)
lw $a2, 24($sp)
lw $s4, 28($sp)
lw $s5, 32($sp)
sw $a2, 36($sp)
addi $sp, $sp, 40

lb $s3, 0($a1)
addi $s3, $s3, 1	#increases the row number of the current valid counter by one
sb $s3, 0($a1)

addi $s5, $s5, 1

bne $s5, $s4, columnSpeedLoop

addi $a0, $a0, 1
addi $a1, $a1, 1
addi $a2, $a2, 1
addi $s0, $s0, 1
j tableLoop

tableLoopEnd:
jr $ra







_iterateColumn:
#This iterates a column one time by calling itself recursively
#$a0 - column number
#$a1 - current row number
#$a2 - number of times called

add $s0, $zero, $zero
addi $s1, $zero, 25
j waitLoop
waitLoop:	#this delays the start of the next iteration to make the animation slower
beq $s0, $s1, start
addi $s0, $s0, 1
j waitLoop


start:
li $s0, 0x00001100	
li $s1, 0x0000ff00 #brightest color
li $s2, 0xffff8000
li $s5, 0xffffb200

addi $s3, $zero, 14
slt $s3, $a2, $s3
beq $s3, $zero, iterateEnd

beq $a2, $zero, increaseColor
bne $a2, $zero, decreaseColor

increaseColor:
addi $s3, $zero, 40	#This checks if the current row is valid
slt $s3, $s3, $a1
bne $s3, $zero, notValidRow
add $s3, $zero, $zero
slt $s3, $a1, $zero
bne $s3, $zero, notValidRow

addi $s3, $zero, 320
mul $s3, $s3, $a1
mul $s4, $a0, 4
add $s3, $s3, $s4
add $s2, $s2, $s3	#This adds the offset to the base address

beq $s2, $s5, notValidRow

lw $s4, 0($s2)

srl $s4, $s4, 24
sll $s4, $s4, 24
or $s4, $s4, $s1

sw $s4, 0($s2)

addi $sp, $sp, -4
sw $ra, 0($sp)
addi $a1, $a1, -1
addi $a2, $a2, 1
jal _iterateColumn
lw $ra, 0($sp)
addi $sp, $sp, 4
j iterateEnd

decreaseColor:
addi $s3, $zero, 40	#This checks if the current row is valid
slt $s3, $s3, $a1
bne $s3, $zero, notValidRow
add $s3, $zero, $zero
slt $s3, $a1, $zero
bne $s3, $zero, notValidRow

addi $s3, $zero, 320
mul $s3, $s3, $a1
mul $s4, $a0, 4
add $s3, $s3, $s4
add $s2, $s2, $s3	#This adds the offset to the base address

beq $s2, $s5, notValidRow

lw $s4, 0($s2)

sub $s4, $s4, $s0
sw $s4, 0($s2)

addi $sp, $sp, -4
sw $ra, 0($sp)
addi $a1, $a1, -1
addi $a2, $a2, 1
jal _iterateColumn
lw $ra, 0($sp)
addi $sp, $sp, 4
j iterateEnd

notValidRow:
addi $sp, $sp, -4
sw $ra, 0($sp)
addi $a1, $a1, -1
addi $a2, $a2, 1
jal _iterateColumn
lw $ra, 0($sp)
addi $sp, $sp, 4
j iterateEnd

iterateEnd:
jr $ra







_addNewMatrixColumn:
#This functions runs a random number generator to see if a new column is added to the matrix
#The chance that a new column is added every iteration is two percent
#If the 2% passes, it creates a random column number to add to the matrixColumn table with a random speed between (1-5)
#$a0 - matrixColumn table
#$a1 - matrixRowTable
#$a2 - matrixColumnSpeed

move $s0, $a0	#These hold the iterated values of the tables
move $s1, $a1

move $s4, $a0	#These hold the base address of the table
move $s5, $a1
move $s7, $a2

li $v0, 42
li $a1, 99
syscall
addi $s2, $zero, 25

slt $s3, $a0, $s2
bne $s3, $zero, addColumn
beq $s3, $zero, addEnd

addColumn:
j getRandomNumber

getRandomNumber:
move $s0, $s4
move $s1, $s5
li $v0, 42
li $a1, 79
syscall
j checkNumber

checkNumber:
add $s0, $a0, $s0
lb $s6, 0($s0)
beq $s6, $zero, setValidColumn
bne $s6, $zero, getRandomNumber

setValidColumn:
add $s1, $s1, $a0
addi $s6, $zero, 1
sb $s6, 0($s0)
sb $zero, 0($s1)
add $s7, $s7, $a0

li $v0, 42
li $a1, 3
syscall
addi $a0, $a0, 1

sb $a0, 0($s7)

j addEnd

addEnd:
jr $ra



_loadMatrixLine: 
#This function fills the buffer with one row of 80 characters for the console
#$a0 - intput buffer
addi $t0, $a0, 0 #sets the input buffer to $t0
li $v0, 42
li $a1, 93
addi $t1, $zero, 0
j readLoop

readLoop:
beq $t1, 80, readEnd

syscall
addi $a0, $a0, 33

sb $a0, 0($t0)
addi $t0, $t0, 1
addi $t1, $t1, 1
j readLoop

readEnd:
jr $ra

_printMatrixFileLine:
#This function sets each character of the input buffer to the correct color
#$a0 - input buffer
#$a1 - console address

addi $t0, $zero, 0
li $t1, 0x00002200

printLineLoop:
beq $t0, 80, printLineEnd
lb $t2, 0($a0)
sll $t2, $t2, 24
or $t2, $t2, $t1
sw $t2, 0($a1)
addi $a0, $a0, 1
addi $a1, $a1, 4
addi $t0, $t0, 1
j printLineLoop

printLineEnd:
jr $ra



