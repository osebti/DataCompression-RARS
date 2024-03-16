#
# CMPUT 229 Student Submission License
# Version 1.0
# Copyright 2021 Othman Sebti
#
# This software is distributed to students in the course
# CMPUT 229 - Computer Organization and Architecture I at the University of
# Alberta, Canada.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice,
#    this list of conditions and the disclaimer below in the documentation
#    and/or other materials provided with the distribution.
#
# 2. Neither the name of the copyright holder nor the names of its
#    contributors may be used to endorse or promote products derived from this
#    software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
#
#          cmput229@ualberta.ca
#
#---------------------------------------------------------------
# CCID:                 osebti 
# Lecture Section:      3
# Instructor:           Nelson J. Amaral
# Lab Section:          2
# Teaching Assistant:   
#---------------------------------------------------------------
# 

.include "common.s"

#----------------------------------
#        STUDENT SOLUTION
#----------------------------------


#---------------------------------------------------------------------------------------------
# buildTables
#
# Arguments:
#	a0: the address of the contents of a valid input file in memory terminated by the end-of-file sentinel word.
#	a1: the address of pre-allocated memory in which to store the wordTable.
#	a2: the address of pre-allocated memory in which to store the countTable.
#
# Return Values:
#	a0: the number of words in the wordTable (is equivalent to the number of counts in the countTable)
#
# Generates a wordTable alongside a correlated countTable
#
# Function Description: BuildTables will build the wordtable and countables into memory, in order for the encoder subroutine to build a new 
# table enabling the production of encrypted output.
# 
# Register Usage: 
# a0 = index counter (input file) 
# t0 = word table count  
# t1 = word loaded from wordtable
# t2 = search index (when searching for the index of a word in either table by traversing wordtable)
# t3 = word loaded from file input or count value from countable 
# t4 = a1 + 4*offset or a0 + 4* offset
# t5 = a2 + offset
# t6 = 4 (for multiplication purposes)
#---------------------------------------------------------------------------------------------

buildTables: # Nested for loops will be used to build the wordtable and countable during the same iterations. 
	
	addi t6,zero,4 # for calculation of word offset
	mv t0,zero
	
	mv t4,a1 # loading a1 and a2 into t4 and t5, respectively. 
	mv t5,a0
	mv a0,zero
	
	
	# Main loop going through input file
	L1: 
	mv t2,zero # resetting search index to zero
	mul t4,a0,t6 # 4 * offset
	add t4,t4,t5 # address of input file word number i.
	lw t3,(t4) # loading word from input file 
	beq t3,zero,Finish
	addi a0,a0,1 # increment input file index counter
	
	
	# Nested Loop which traverses the wordtable and updates the count in countable 
	L2: 
	beq t0,zero,AddFirstWord
	beq t2,t0,AddWord # if word from input file is not in word table, jump to 'AddWord' block
	mul t4,t2,t6 # 4*offset
	add t4,t4,a1 # finding address of element in wordtable 
	lw t1,(t4) # loading word from address
	beq t1,t3,AddCount # if the word in word table is the same as the one processed from input file, then jump to 'AddCount' block. 
	addi t2,t2,1 # else increment index count
	j L2 # iterate again through loop
	
	
	
	
	
	
	# Block to add new word to the wordtable and updates the count of the word in countable to 1
	AddWord: 
	sw t3,4(t4) # storing new word in wordtable
	add t4,a2,t2 # obtaining its corresponding address in countable
	addi t2,zero,1
	sb t2,(t4) # storing value 1 in countable 
	addi t0,t0,1 # incrementing by 1 number of words in wordtable. 
	j L1
	
	AddFirstWord:
	sw t3,(a1) # storing new word in wordtable
	addi t2,zero,1
	sb t2,(a2) # storing value 1 in countable 
	addi t0,t0,1 # incrementing by 1 number of words in wordtable. 
	j L1
	
	
	
	# Block to increment count by 1
	
	AddCount: 
	add t4,a2,t2 # calculate address of element in countable using byte offset and initial address.
	lb t3,(t4) # loading count value
	addi t3,t3,1 # incrementing by 1
	sb t3,(t4) # storing incremented value back in countable 
	j L1 # jump back to main loop
	
	
	
	
	
	# End of program block, meaning null sentinel has been reached; return to user. a0 has the count of words stored in it. 
	Finish: 
	mv a0,t0 # returning number of words in wordtable
	jr ra 
	   
	


	










#---------------------------------------------------------------------------------------------
# encode
#
# Arguments:
#	a0: the address to the contents of a valid input file in memory.
#	a1: the address of a dictionary table in memory.
#	a2: the number of words in the dictionary.
#	a3: the address of pre-allocated memory in which to store the output.
#
# Return Values:
#	a0: the size of the output in bytes (not including the end-of-file sentinel word at the end).
#
# Compresses the contents of an input file
# Register usage: 
# t4=4 (for multiplication purposes)
# t0 = index (one byte - represented) of current position in output memory
# t1 = address of current pos. in input file 
# t2 = address of current pos. in dictionary when traversing 
# t6 = current pos. in input file, represented as an index 
# t5 = index in dictionary
#---------------------------------------------------------------------------------------------
encode:
	
	
        addi t4,zero,4
        mv t3,a3 # to use when accessing elements in the dict.
        # copying the dictionary to start of the output, followed by null word
        mv t0,zero
	CopyDict: 
	beq t0,a2,AddNull
	mul t1,t4,t0 # calculating offset
	add t1,a1,t1 # getting element address
	lw t1,(t1) #loading word from dict.
	sw t1,(t3) # storing word in output file 
	addi t3,t3,4 # incrementing output file position
	addi t0,t0,1
	j CopyDict
	
	AddNull: 
	sb zero,(t3) # Adding null byte to end of dictionary secuence in output
        addi t0,t0,1
	addi t3,t3,1
	
	
	
	# Compression of input sequence happens here
	Compress: 
	
	mul t0,t0,t4 # setting temp registers to initial value as described above
	mv t6,zero # setting index to zero 
	mv t5,zero
	mv t1,zero
	
	
	
	# Main Loop traversing input file 	
	CL1: 
	addi t5,zero,0 # set dictionary index counter to zero 
	mul t1,t6,t4 # 4 * index = offset
	add t1,t1,a0 # address of input file word number i.
	lw t1,(t1) # loading word from input file        
	beq t1,zero,End
	
	
	
	# Nested Loop which traverses the dictionary table 
	CL2:
	beq t5,a2,StoreBytes # checking if all words in dict. have been processes/iterated through
	mul t2,t4,t5
	add t2,t2,a1
	lw t2,(t2)
	beq t2,t1,StoreRef # store reference if word is in dictionary
	addi t5,t5,1 # increment counter
	j CL2 # iterate again until end of dictionary
	

	# storing bytes from words not found in dict. in reverse order
	StoreBytes:
	
	mul t2,t6,t4
	add t2,t2,a0 # computing address
	
	lb t1,(t2) # storing in reverse order, byte by byte
	sb t1,(t3)
	
	lb t1, 1(t2)
	sb t1,1(t3)
	
	lb t1, 2(t2)
	sb t1,2(t3)
	
	lb t1,3(t2)
	sb t1,3(t3)
	
	addi t3,t3,4 # updating current position in output file 
	addi t0,t0,4
	addi t6,t6,1 # incrementing index of input file 
	j CL1 
	
	
	
	# Storing reference to the dictionary index containing the word which was encoded 
	StoreRef:
	addi t5,t5,128 # placing a one in the 7th bit of reference to indeicate dictionary ref. 
	sb t5,(t3) # storing in output memory
	
	addi t3,t3,1 # incrementing position/index in outputfile
	addi t0,t0,1
	addi t6,t6,1 # incrementing index of input file 
	j CL1
	

        # end of program block that adds null sentinel
        End: 
        sb zero,0(t3) # storing 4 null bytes, byte by byte due to potential misalignment 
        sb zero,1(t3)
        sb zero,2(t3)
        sb zero,3(t3)
        
        mv a0,t0
        jr ra # return to caller









#------------------     end of student solution     ----------------------------------------------------------------------------



#-------------------------------------------------------------------------------------------------------------------------------
# buildDictionary
#
# Arguments:
#	a0: pointer to a wordTable in memory.
#	a1: pointer to a corresponding countTable in memory.
#	a2: the number of elements in either table.
#	a3: pointer to pre-allocated memory in which to store dictionary table.
#
# Return Values:
#	a0: the number of word elements in the dictionary.
#
# Generates a dictionary table.
#-------------------------------------------------------------------------------------------------------------------------------
buildDictionary: # provided to students
	addi sp, sp, -32
	sw ra, 0(sp)	# storing registers
	sw s0, 4(sp) 
	sw s1, 8(sp)
	sw s2, 12(sp)
	sw s3, 16(sp)
	sw s4, 20(sp)
	sw s5, 24(sp)
	sw s6, 28(sp)


	mv s0, a0	# s0 <- address to wordTable
	mv s1, a1	# s1 <- address to countTable
	mv s2, a2	# s2 <- number of elements in wordTable or countTable
	li s3, 0	# s3 <- tableIndex
	mv s4, a3	# s4 <- dictPos
	li s5, 2	# s5 <- threshold
	mv s6, a3	# s6 <- dictStart
	
	tableIteration:
		bge s3, s2, endOfTable	# if reached the end of the tables
		add t0, s1, s3	# t0 <- address of count in countTable at index tableIndex
		lbu t1, 0(t0)	# t1 <- count
		bge t1, s5, addToDict	# if a count is >= threshold, add the corresponding word to the dictionary
		
		addi s3, s3, 1	# updating tableIndex
		
		j tableIteration
		
		addToDict:
			slli t0, s3, 2	# t0 <- s3 * 4 = word offset corresponding to tableIndex
			add t0, s0, t0	# t0 <- address of word in wordTable at index tableIndex
			lw t1, 0(t0)	# t1 <- word
			
			addi s3, s3, 1	# updating tableIndex
			
			sw t1, 0(s4)	# store the word in the dictionary
			addi s4, s4, 4	# update dictPos
			
			j tableIteration
		
	endOfTable:
		
		sub t0, s4, s6	# t0 <- size of dictionary
		srli a0, t0, 2	# a1 <- t0 / 4 = number of words in dictionary
		
		lw ra, 0(sp)	# restoring registers
		lw s0, 4(sp) 
		lw s1, 8(sp)
		lw s2, 12(sp)
		lw s3, 16(sp)
		lw s4, 20(sp)
		lw s5, 24(sp)
		lw s6, 28(sp)
		addi sp, sp, 32
		
		ret


