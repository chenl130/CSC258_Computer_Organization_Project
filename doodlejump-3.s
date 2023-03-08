#####################################################################
#
# CSC258H5S Fall 2020 Assembly Final Project
# University of Toronto, St. George
#
# Student: Liang Chen 
# Student Number: 1005735126
#
# Bitmap Display Configuration:
# - Unit width in pixels: 8
# - Unit height in pixels: 8
# - Display width in pixels: 256
# - Display height in pixels: 256
# - Base Address for Display: 0x10008000 ($gp)
#
# Which milestone is reached in this submission?
# (See the assignment handout for descriptions of the milestones)
# - Milestone 1 Done
# - Milestone 2 Done
# - Milestone 3 Done
# - Milestone 4 Done
# - Milestone 5 Done
#
# Which approved additional features have been implemented?
# (See the assignment handout for the list of additional features)
# 1. Milestone 4: Score count and display
# 2. Milestone 4: Game over and restart
# 3. Milestone 4: Different level (five shorter platform)
# 4. Milestone 5: more platform types (1. short normal stable ; 2. short normal moving; 3: short fragile)
# 5. Milestone 5: show wow when reach certain score = 3
# 6. Milestone 5:Player names
#
# Any additional information that the TA needs to know:
# - (write here, if any)######################################################################
#
.data 

	
	#game core information
	
	#screen	
	displayAddress: .word 0x10008000
	enddisplayAddress: .word 0x10008ffc
	screenWidth: .word 32
	screenHeight: .word 32
	numUnit: .word 1024
	
	#colors
	bgdColor:   		.word 0x71C5cf  #background color
	pltColor:   		.word 0xffff00  #normal platform color
	fragilepltColor: 	.word 0xcc6600
	ddlColor:   		.word 0xfec106  #doodle color 
	grayColor: 		.word 0x584b4b  # gray color for drawing GG
	scoreColor: 		.word 0xbc8f8f
	
	# Doodle Settings
	TotalHeight: 	.word	15
	Height: 	.word	15      # the height of doodle can jump in this round
	doodleX:	.word	15      # next x location of doodle to draw
	doodleY:	.word	29	# next y location of doodle to draw
	doodleLX:	.word	15	# current x location of doodle, will be erased later
	doodleLY:	.word	29	# current y location of doodle, will be erased later
	moveup:		.word	1 	# 1 if move up, 0 if move down
	
	# Normal platform Settings (normal platforms' y locations are fixed)
	plt1X:		.word   100
	plt1Y:		.word   31
	plt1LX:		.word   100
	plt1LY:		.word   31
	plt2X:		.word   100
	plt2Y:		.word   21
	plt2LX:		.word   100
	plt2LY:		.word   21
	plt3X:		.word   100
	plt3Y:		.word   11
	plt3LX:		.word   100
	plt3LY:		.word   11
	plt4X:		.word   100
	plt4Y:		.word   26
	plt4LX:		.word   100
	plt4LY:		.word   26
	plt5X:		.word   100
	plt5Y:		.word   16
	plt5LX:		.word   100
	plt5LY:		.word   16
	
	plt4Flag:	.word   1 # means still exist
	plt5Flag:	.word   1 # means still exist
	
	prevCollisionY: .word   33
	
	#socre variable
	score: .word 0
	flag: .word 0
	
	wowFlag: .word 0
	
	#endgame message
	loginMessage: .asciiz "Hello, please enter your name:  "
	usernameInput: .space 20
	loginSuccessfulMessage: .asciiz "Welcome back, "
	StartMessage: .asciiz "Press s to start game"
	lostMessage: .asciiz "Oh no! You died... Your score was: "
	replayMessage: .ascii "Would you like to try again?"
	
	newline: .asciiz "\n"
	
	
	
.text 

main: 
	
	# enter username and show welcome message------------------------------
	jal WelcomeScreen
	
	# draw initla general backgroud color of the screen------------------------------
	lw $t0, displayAddress
	lw $t3, enddisplayAddress # the address of last unit on the screen
	lw $a0, bgdColor

	jal Draw_bgd # draw the general background color
	j Intial_input_check

Intial_input_check: # check whether there is a input from the keyboard
	lw $t8, 0xffff0000
	beq $t8, 1, Start_input
	j Intial_input_check # if no input, wait till the player input "s" to start game
	
	
Start_input: # when there is a input, check what exactly the input is, otherwise do genral location update of doodle
	lw $t7, 0xffff0004
	bne $t7, 0x73, Intial_input_check
	sw $zero, 0xffff0000
	lw $s0, score
	j respond_to_s # input is s, draw initial screen and set up
	

Reset_input: #reset state after each keyboard input
	sw $zero, 0xffff0000
	jr $ra
	
	
Input_check: # check whether there is a input from the keyboard
	lw $t8, 0xffff0000
	beq $t8, 1, Keyboard_input
	jr $ra  # if no input, wait till the player input "s" to start game
	
						
Keyboard_input: # when there is a input, check what exactly the input is, otherwise do genral location update of doodle
	lw $t2, 0xffff0004
	beq $t2, 0x6A , respond_to_j # input is j, move doodle location to left
	beq $t2, 0x6B , respond_to_k # input is s, move doodle location to right
	sw $zero, 0xffff0000
	jr $ra

	

Exit:
li $v0, 10
syscall
	
							
##############################################draw elements functions #########################################									
WelcomeScreen: # ask user to enter name and show welcome text
	li $v0, 4
	la $a0, loginMessage
	syscall
	
	# get text username input
	li $v0, 8 # get prepared for the username input from the keyboard as text message
	la $a0, usernameInput
	li $a1, 20
	syscall
	
	# print welcome message with user's name shown on output screen
	li $v0, 4
	la $a0, loginSuccessfulMessage
	syscall
	
	li $v0, 4
	la $a0, usernameInput
	syscall	
	
	# ask if player want to start to play game
	li $v0, 4
	la $a0, StartMessage
	syscall	
	
	jr $ra
	
					
Draw_bgd: # draw backgroud screen
	# top left corner address of screen is stored at register t0
	# color to draw the screen is stored at register a0
	# bottom right corner address of scrren is stored at register t3
	bgt $t0, $t3, finish_draw_bgd # finish painting the screen
	sw $a0, 0($t0) # paint the unit at current location
	addiu $t0, $t0, 4 # update next unit to draw on the screen
	j Draw_bgd
	
	
finish_draw_bgd: 
	# when finish drawing background, go back to the respond_to_s to draw the following element
	jr $ra

Draw_doodle: # draw the doodle on the screen
	# top left address of doodle block store at register t0
	# color of doodle is stored at register a0
	lw $a0, ddlColor
	sw $a0, 4($t0)
	sw $a0, 128($t0)
	sw $a0, 132($t0)
	sw $a0, 136($t0)
	sw $a0, 256($t0)
	sw $a0, 264($t0)
	jr $ra
	

Delete_doodle: # draw the doodle on the screen
	# top left address of doodle block store at register t0
	# color of doodle is stored at register a0
	lw $a0, bgdColor
	sw $a0, 4($t0)
	sw $a0, 128($t0)
	sw $a0, 132($t0)
	sw $a0, 136($t0)
	sw $a0, 256($t0)
	sw $a0, 264($t0)
	jr $ra

DrawNormalPlatform: # draw a normal platform with length of 8 units
# $t3 is address of platform shown on the bitmap
# Paint the platform ---------------------	
	lw $a0, pltColor
	sw $a0, ($t3)
	sw $a0, 4($t3)
	sw $a0, 8($t3)
	sw $a0, 12($t3)
	sw $a0, 16($t3)
	sw $a0, 20($t3)
	sw $a0, 24($t3)
	sw $a0, 28($t3)
	jr $ra
	
	
DeleteNormalPlatform:
# $t3 is address of platform 
# Erase the normal Platform
	lw $a0, bgdColor
	sw $a0, ($t3)
	sw $a0, 4($t3)
	sw $a0, 8($t3)
	sw $a0, 12($t3)
	sw $a0, 16($t3)
	sw $a0, 20($t3)
	sw $a0, 24($t3)
	sw $a0, 28($t3)
	jr $ra


Draw_initial:
	# redraw general backgroud color of the screen------------------------------
	lw $t0, displayAddress
	lw $t3, enddisplayAddress # the address of last unit on the screen
	lw $a0, bgdColor
	addi $sp, $sp, -4 # store the return address that draw_initial should return to 
	sw $ra, 0($sp)
	jal Draw_bgd # draw the general background color
	lw $ra, 0($sp)
	
	#show level information
	jal draw_levelone 
	lw $ra, 0($sp)
	
	addi $v1, $zero, 1000
	jal Sleep
	lw $ra, 0($sp)
	

	jal delete_levelone 
	lw $ra, 0($sp)

	
	# draw initial doodle on the screen (at middle bottom)---------------------
	lw $t0, displayAddress
	addiu $t0, $t0, 3644
	jal Draw_doodle # draw the general background color
	lw $ra, 0($sp)


	# draw initial normal platforms on the screen (at random position)---------------------
	addi $t2, $zero, 31 #load normal platform 1's y location to $t2
	sw $t2, plt1Y
	sw $t2, plt1LY
	

	jal Random_x_plt_generator# generate a valid x location for platform and store in t1
	lw $ra, 0($sp)
	
	sw $t1, plt1X # save x index of first generated platform in plt1X global variable
	sw $t1, plt1LX 

	lw $t1, plt1X
	lw $t2, plt1Y
	
	jal Calcuate_address
	lw $t0, displayAddress

	add $t3, $t0, $t3
	jal DrawNormalPlatform # draw the first normal platform
	lw $ra, 0($sp)

	
	addi $t2, $zero, 21
	sw $t2, plt2Y
	sw $t2, plt2LY
	jal Random_x_plt_generator
	lw $ra, 0($sp)
	sw $t1, plt2X # save x index of first generated platform in plt1X global variable
	sw $t1, plt2LX
	
	lw $t1, plt2X
	lw $t2, plt2Y
	
	jal Calcuate_address
	lw $t0, displayAddress
	
	add $t3, $t0, $t3
	jal DrawNormalPlatform # draw the first normal platform
	lw $ra, 0($sp)

	addi $t2, $zero, 11
	sw $t2, plt3Y
	sw $t2, plt3LY
	jal Random_x_plt_generator
	lw $ra, 0($sp)
	
	sw $t1, plt3X # save x index of first generated platform in plt1X global variable
	sw $t1, plt3LX
	
	lw $t1, plt3X
	lw $t2, plt3Y
	jal Calcuate_address
	lw $ra, 0($sp)
	
	lw $t0, displayAddress
	
	add $t3, $t0, $t3
	jal DrawNormalPlatform # draw the first normal platform
	lw $ra, 0($sp)
	
	lw $a0, scoreColor
	jal draw_zero
	lw $ra, 0($sp)
	
	j location_update
	

redraw_screen: 
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	# delete old doodle
	lw $t1, doodleLX
	lw $t2, doodleLY
	jal Calcuate_address
	lw $ra, 0($sp)
	lw $t0, displayAddress
	add $t3, $t0, $t3
	add $t0, $zero, $t3
	jal Delete_doodle
	lw $ra, 0($sp)
	
	# draw updated doodle
	lw $t1, doodleX
	lw $t2, doodleY
	jal Calcuate_address
	lw $ra, 0($sp)
	lw $t0, displayAddress
	add $t3, $t0, $t3
	add $t0, $zero, $t3
	jal Draw_doodle
	lw $ra, 0($sp)
	
	# update current doodle location
	lw $s1, doodleX
	lw $s2, doodleY
	sw $s1, doodleLX
	sw $s2, doodleLY
	
	# delete old platform1
	lw $t1, plt1LX
	lw $t2, plt1LY
	jal Calcuate_address #calculate extra address need to add to origin and store in t3
	lw $ra, 0($sp)
	lw $t0, displayAddress
	add $t3, $t0, $t3 #address of old platform
	jal DeleteNormalPlatform
	lw $ra, 0($sp)
	
	# Draw new platform1
	lw $t1, plt1X
	lw $t2, plt1Y
	jal Calcuate_address
	lw $ra, 0($sp)
	lw $t0, displayAddress
	add $t3, $t0, $t3
	jal DrawNormalPlatform
	lw $ra, 0($sp)
	
	#update current platform1 location
	lw $s1, plt1X
	lw $s2, plt1Y
	sw $s1, plt1LX
	sw $s2, plt1LY
	
	# delete old platform2
	lw $t1, plt2LX
	lw $t2, plt2LY
	jal Calcuate_address
	lw $ra, 0($sp)
	lw $t0, displayAddress
	add $t3, $t0, $t3
	jal DeleteNormalPlatform
	lw $ra, 0($sp)
	
	# Draw new platform2
	lw $t1, plt2X
	lw $t2, plt2Y
	jal Calcuate_address
	lw $ra, 0($sp)
	lw $t0, displayAddress
	add $t3, $t0, $t3
	jal DrawNormalPlatform
	lw $ra, 0($sp)
	
	#update current platform1 location 2
	lw $s1, plt2X
	lw $s2, plt2Y
	sw $s1, plt2LX
	sw $s2, plt2LY
	
	# delete old platform3
	lw $t1, plt3LX
	lw $t2, plt3LY
	jal Calcuate_address
	lw $ra, 0($sp)
	lw $t0, displayAddress
	add $t3, $t0, $t3
	jal DeleteNormalPlatform
	lw $ra, 0($sp)
	
	# Draw new platform1
	lw $t1, plt3X
	lw $t2, plt3Y
	jal Calcuate_address
	lw $ra, 0($sp)
	lw $t0, displayAddress
	add $t3, $t0, $t3
	jal DrawNormalPlatform
	lw $ra, 0($sp)
	
	#update current platform1 location
	lw $s1, plt3X
	lw $s2, plt3Y
	sw $s1, plt3LX
	sw $s2, plt3LY
	
	addi $v1, $zero, 100
	jal Sleep
	lw $ra, 0($sp)
	
	addi $sp, $sp, 4
	
	jr $ra
	

draw_levelone:
	lw $a0, grayColor
	lw $t0, displayAddress
	addi $t0, $t0, 1280
	
	sw $a0, 20($t0)
	sw $a0, 148($t0)
	sw $a0, 276($t0)
	sw $a0, 404($t0)
	sw $a0, 532($t0)
	sw $a0, 536($t0)
	sw $a0, 540($t0)
	
	sw $a0, 36($t0)
	sw $a0, 40($t0)
	sw $a0, 44($t0)
	sw $a0, 164($t0)
	sw $a0, 292($t0)
	sw $a0, 296($t0)
	sw $a0, 300($t0)
	sw $a0, 420($t0)
	sw $a0, 548($t0)
	sw $a0, 552($t0)
	sw $a0, 556($t0)
	
	sw $a0, 52($t0)
	sw $a0, 60($t0)
	sw $a0, 180($t0)
	sw $a0, 188($t0)
	sw $a0, 308($t0)
	sw $a0, 316($t0)
	sw $a0, 436($t0)
	sw $a0, 444($t0)
	sw $a0, 568($t0)
	
	sw $a0, 68($t0)
	sw $a0, 72($t0)
	sw $a0, 76($t0)
	sw $a0, 196($t0)
	sw $a0, 324($t0)
	sw $a0, 328($t0)
	sw $a0, 332($t0)
	sw $a0, 452($t0)
	sw $a0, 580($t0)
	sw $a0, 584($t0)
	sw $a0, 588($t0)
	
	
	sw $a0, 84($t0)
	sw $a0, 212($t0)
	sw $a0, 340($t0)
	sw $a0, 468($t0)
	sw $a0, 596($t0)
	sw $a0, 600($t0)
	sw $a0, 604($t0)
	
	sw $a0, 100($t0)
	sw $a0, 104($t0)
	sw $a0, 232($t0)
	sw $a0, 360($t0)
	sw $a0, 488($t0)
	sw $a0, 612($t0)
	sw $a0, 616($t0)
	sw $a0, 620($t0)
	
	jr $ra
	
	
delete_levelone:
	lw $a0, bgdColor
	lw $t0, displayAddress
		addi $t0, $t0, 1280
	
	sw $a0, 20($t0)
	sw $a0, 148($t0)
	sw $a0, 276($t0)
	sw $a0, 404($t0)
	sw $a0, 532($t0)
	sw $a0, 536($t0)
	sw $a0, 540($t0)
	
	sw $a0, 36($t0)
	sw $a0, 40($t0)
	sw $a0, 44($t0)
	sw $a0, 164($t0)
	sw $a0, 292($t0)
	sw $a0, 296($t0)
	sw $a0, 300($t0)
	sw $a0, 420($t0)
	sw $a0, 548($t0)
	sw $a0, 552($t0)
	sw $a0, 556($t0)
	
	sw $a0, 52($t0)
	sw $a0, 60($t0)
	sw $a0, 180($t0)
	sw $a0, 188($t0)
	sw $a0, 308($t0)
	sw $a0, 316($t0)
	sw $a0, 436($t0)
	sw $a0, 444($t0)
	sw $a0, 568($t0)
	
	sw $a0, 68($t0)
	sw $a0, 72($t0)
	sw $a0, 76($t0)
	sw $a0, 196($t0)
	sw $a0, 324($t0)
	sw $a0, 328($t0)
	sw $a0, 332($t0)
	sw $a0, 452($t0)
	sw $a0, 580($t0)
	sw $a0, 584($t0)
	sw $a0, 588($t0)
	
	
	sw $a0, 84($t0)
	sw $a0, 212($t0)
	sw $a0, 340($t0)
	sw $a0, 468($t0)
	sw $a0, 596($t0)
	sw $a0, 600($t0)
	sw $a0, 604($t0)
	
	sw $a0, 100($t0)
	sw $a0, 104($t0)
	sw $a0, 232($t0)
	sw $a0, 360($t0)
	sw $a0, 488($t0)
	sw $a0, 612($t0)
	sw $a0, 616($t0)
	sw $a0, 620($t0)
	
	jr $ra
	
	
draw_leveltwo:
	lw $a0, grayColor
	lw $t0, displayAddress
	addi $t0, $t0, 1280
	
	sw $a0, 20($t0)
	sw $a0, 148($t0)
	sw $a0, 276($t0)
	sw $a0, 404($t0)
	sw $a0, 532($t0)
	sw $a0, 536($t0)
	sw $a0, 540($t0)
	
	sw $a0, 36($t0)
	sw $a0, 40($t0)
	sw $a0, 44($t0)
	sw $a0, 164($t0)
	sw $a0, 292($t0)
	sw $a0, 296($t0)
	sw $a0, 300($t0)
	sw $a0, 420($t0)
	sw $a0, 548($t0)
	sw $a0, 552($t0)
	sw $a0, 556($t0)
	
	sw $a0, 52($t0)
	sw $a0, 60($t0)
	sw $a0, 180($t0)
	sw $a0, 188($t0)
	sw $a0, 308($t0)
	sw $a0, 316($t0)
	sw $a0, 436($t0)
	sw $a0, 444($t0)
	sw $a0, 568($t0)
	
	sw $a0, 68($t0)
	sw $a0, 72($t0)
	sw $a0, 76($t0)
	sw $a0, 196($t0)
	sw $a0, 324($t0)
	sw $a0, 328($t0)
	sw $a0, 332($t0)
	sw $a0, 452($t0)
	sw $a0, 580($t0)
	sw $a0, 584($t0)
	sw $a0, 588($t0)
	
	
	sw $a0, 84($t0)
	sw $a0, 212($t0)
	sw $a0, 340($t0)
	sw $a0, 468($t0)
	sw $a0, 596($t0)
	sw $a0, 600($t0)
	sw $a0, 604($t0)
	
	sw $a0, 100($t0)
	sw $a0, 104($t0)
	sw $a0, 108($t0)
	sw $a0, 236($t0)
	sw $a0, 356($t0)
	sw $a0, 360($t0)
	sw $a0, 364($t0)
	sw $a0, 484($t0)
	sw $a0, 612($t0)
	sw $a0, 616($t0)
	sw $a0, 620($t0)
	
	jr $ra
	
delete_leveltwo:
	lw $a0, bgdColor
	lw $t0, displayAddress
	addi $t0, $t0, 1280
	
	sw $a0, 20($t0)
	sw $a0, 148($t0)
	sw $a0, 276($t0)
	sw $a0, 404($t0)
	sw $a0, 532($t0)
	sw $a0, 536($t0)
	sw $a0, 540($t0)
	
	sw $a0, 36($t0)
	sw $a0, 40($t0)
	sw $a0, 44($t0)
	sw $a0, 164($t0)
	sw $a0, 292($t0)
	sw $a0, 296($t0)
	sw $a0, 300($t0)
	sw $a0, 420($t0)
	sw $a0, 548($t0)
	sw $a0, 552($t0)
	sw $a0, 556($t0)
	
	sw $a0, 52($t0)
	sw $a0, 60($t0)
	sw $a0, 180($t0)
	sw $a0, 188($t0)
	sw $a0, 308($t0)
	sw $a0, 316($t0)
	sw $a0, 436($t0)
	sw $a0, 444($t0)
	sw $a0, 568($t0)
	
	sw $a0, 68($t0)
	sw $a0, 72($t0)
	sw $a0, 76($t0)
	sw $a0, 196($t0)
	sw $a0, 324($t0)
	sw $a0, 328($t0)
	sw $a0, 332($t0)
	sw $a0, 452($t0)
	sw $a0, 580($t0)
	sw $a0, 584($t0)
	sw $a0, 588($t0)
	
	
	sw $a0, 84($t0)
	sw $a0, 212($t0)
	sw $a0, 340($t0)
	sw $a0, 468($t0)
	sw $a0, 596($t0)
	sw $a0, 600($t0)
	sw $a0, 604($t0)
	
	sw $a0, 100($t0)
	sw $a0, 104($t0)
	sw $a0, 108($t0)
	sw $a0, 236($t0)
	sw $a0, 356($t0)
	sw $a0, 360($t0)
	sw $a0, 364($t0)
	sw $a0, 484($t0)
	sw $a0, 612($t0)
	sw $a0, 616($t0)
	sw $a0, 620($t0)
	jr $ra
	

##################################################doodle location update by keyboard input	
respond_to_s: # set up start up location of doodle
	
	addi $sp, $sp, -4 # store the return address that respond_to_s should return to
	sw $ra, 0($sp)
	
	add $s0, $zero, $zero
	sw $s0, score

	sw $s0, flag
	
	sw $s0, wowFlag
	
	addi $s0, $zero, 15
	sw $s0, Height
	
	addi $t1, $zero, 15
	addi $t2, $zero, 28
	sw $t1, doodleLX
	sw $t1, doodleX
	sw $t2, doodleLY
	sw $t2, doodleY
	
	# generate initial height to jump
	
	#jal Random_height_generator
	#lw $ra, 0($sp)
	
	#addi $sp, $sp, 4
	
	#sw $t4, Height # assign random height that doodle can jump
	addi $t4, $zero, 15
	sw $t4, Height
	
	# draw initial screen
	j Draw_initial	
	
					
respond_to_j: # update new horizontal location of doodle by move one pixel to left
	# load current x location of doodle
	lw $t1, doodleLX #load current x location of doodle
	bgtz $t1, if_respond_to_j #if not reach left boudary of screen
	addi $t1, $zero, 29 # if reach left boudary of screen and still need to move left
	j update_doodle_x	
	
update_doodle_x:
	sw $t1, doodleX # next x location that doodle will move to
	j Reset_input
	
if_respond_to_j:
	addi $t1, $t1, -1
	j update_doodle_x
	
		
respond_to_k: # respond to k input, update next x location of doodle by move right
	# load current location of doodle
	lw $t1, doodleLX
	blt  $t1, 29, if_respond_to_k # if not reach right boundary of screen
	add $t1, $zero, $zero
	j update_doodle_x
	
if_respond_to_k:
	addi $t1, $t1, 1
	j update_doodle_x	
		
	
	
##################update location of elements that will be drawn on the screen
location_update:
	# if doodle still rise and not reaches the highest platform
	# then all platforms keep original locations
	# only doodle's next location will be changed
	
	
	# if doodle is rise and is higher than the highest platform, all platforms will move downward
	# doodle will not move in y direction
	# all platforms move downward, loop till the curent second plt becomes new first plt
	
	
	# if doodle is falling
	# platforms not need to move
	# doodle's location will be changed
	# need to check collision
	
	lw $s0, Height # load Height varible, to check the status of doodle
	# if Height less or equal to zero, it reaches highest point and fall
	
	blez $s0, location_update_case_one # jump to case 1 when doodle is falling
	
	# doodle is rising
	lw $s1, plt3Y
	lw $s2, doodleY
	bge $s2, $s1, location_update_case_two # jump to case 2 when doodle is rise but not reach highest platform
	
	j location_update_case_three


check_boundary:
	lw $s1, doodleX
	lw $s2, plt1X
	addi $s3, $s2, 7
	blt $s3, $s1, Game_over
	addi $s1, $s1, 2
	bgt $s2, $s1, Game_over
	j resstart_jump
	
l2_check_boundary:
	lw $s1, doodleX
	lw $s2, plt1X
	addi $s3, $s2, 3
	blt $s3, $s1, Game_over
	addi $s1, $s1, 2
	bgt $s2, $s1, Game_over
	j l2_resstart_jump	
			
location_update_case_one:
	# platforms location keep still
	# update doodle's next y location
	lw $s1, doodleY
	beq $s1, 28, check_boundary
	
	lw $s4, doodleY
	addi $s4, $s4, 1
	sw $s4, doodleY
	# update doodle's next x location by checking keyboard input
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	jal Input_check
	lw $ra, 0($sp)
	
	addi $sp, $sp, 4
	
	j check_collision


location_update_case_two:
	#platforms location keep still
	lw $s5, Height
	addi $s5, $s5, -1
	sw $s5, Height
	
	# update doodle's next y location
	lw $s4, doodleY
	addi $s4, $s4, -1
	sw $s4, doodleY
	
	# update doodle's next x location by checking keyboard input
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	
	jal Input_check
	lw $ra, 0($sp)
	
	jal redraw_screen
	lw $ra, 0($sp)
	
	
	
	addi $sp, $sp, 4
	
	j location_update


location_update_case_three: # case that doodle still rising but reach the highest platform
	# want to remove the lowest platform， generate a new top platform， then move the lowest platform to the bottom
	# regenerate a new set of x,y location of three platform
	# doodle will not move in x direction, but it will move together with the platforms
	
	# change direction of doodle
	add $s0, $zero, $zero
	sw $s0, Height
	
	addi $s0, $s0, 1
	sw $s0, flag
	
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	jal rotation_plt
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	
	j plt_downward_loop
	
	
plt_downward_loop:

	lw $s1, plt1Y	
	beq $s1, 31, location_update
	
	#update doodle Y location
	lw $s0, doodleY
	addi $s0, $s0, 1
	sw $s0, doodleY

	#update all three platform locations
	lw $s2, plt1Y
	addi $s2, $s2, 1
	sw $s2, plt1Y
	
	lw $s2, plt2Y
	addi $s2, $s2, 1
	sw $s2, plt2Y
	
	lw $s2, plt3Y
	addi $s2, $s2, 1
	sw $s2, plt3Y
	
	#redraw all elements
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	jal redraw_screen
	lw $ra, 0($sp)
	
	#jump back to check if finished update of platforms
	j plt_downward_loop
	
	
rotation_plt:
	# put current location of plt1 to old location of plt3 so as to erase it
	lw $s5, plt1LY
	lw $s6, plt1LX
	
	# assign location of plt2 to plt1 and update its next location by moving downward
	lw $s1, plt2LY
	lw $s2, plt2Y
	lw $s3, plt2LX
	lw $s4, plt2X
	sw $s1, plt1LY
	addi $s2, $s2, 1
	sw $s2, plt1Y
	sw $s3, plt1LX
	sw $s4, plt1X
	
	# move location of plt3 to plt2
	lw $s1, plt3LY
	lw $s2, plt3Y
	lw $s3, plt3LX
	lw $s4, plt3X
	sw $s1, plt2LY
	addi $s2, $s2, 1
	sw $s2, plt2Y
	sw $s3, plt2LX
	sw $s4, plt2X
	
	# generate a new location for new plt3 with Y location 0 and random X location (assign old location of plt1 to old location of plt3)
	sw $s5, plt3LY
	sw $s6, plt3LX
	add $s1, $zero, $zero
	sw $s1, plt3Y
	
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	jal Random_x_plt_generator
	lw $ra, 0($sp)	
	addi $sp, $sp, 4
	sw $t1, plt3X
	jr $ra
	
	
Calcuate_address:
# $t1 is the x location of the stuff
# $t2 is the y location of the stuff
	sll $t4, $t1, 2
	sll $t5, $t2, 7
	add $t3, $t4, $t5
	jr $ra

check_collision:
	# check if y location of doodle overlap with any platform
	lw $s1, doodleY
	addi $s4, $s1, 2
	beq $s4, 32, Game_over
	
	lw $s1, doodleY
	addi $s1, $s1, 3
	
	lw $s2, plt3Y
	lw $t6, plt3X
	beq $s1, $s2, check_collision_steptwo
	
	lw $s2, plt2Y
	lw $t6, plt2X
	beq $s1, $s2, check_collision_steptwo
	
	lw $s2, plt1Y
	lw $t6, plt1X
	beq $s1, $s2, check_collision_steptwo
	
	# if no collision, directly draw elements
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	jal redraw_screen
	j location_update
	
	
	
check_collision_steptwo: # y location of doodle overlap with one of the platform
	#$s3 stores the location of the potential collision platform
	lw $s1, doodleX
	addi $s4, $s1, 2
	addi $s2, $t6, 0 #lower bound of platform x location
	addi $s3, $t6, 7 #upper bound of platform x location
	blt $s4, $s2, jump_to_redraw # no collision
	bgt $s1, $s3, jump_to_redraw # no collision
	
	lw $s1, doodleY
	addi $s1, $s1, 3
	
	lw $s2, plt3Y
	beq $s1, $s2, check_if_addscore
	
	lw $s2, plt2Y
	beq $s1, $s2, check_if_addscore
	
	lw $s2, plt1Y
	beq $s1, $s2, check_if_addscore

jump_to_redraw:	
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	jal redraw_screen
	lw $ra, 0($sp)	
	addi $sp, $sp, 4
	j location_update
			

check_if_addscore:
	lw $s0, flag
	beq $s0, 1, extra_check
	
	# case if jump back to previous platform: no score added
	lw $s1, prevCollisionY
	beq $s1, $s2, resstart_jump
	
	# jump to another platform, score added and update previous Collision platform Y location
	sw $s2, prevCollisionY
	j add_score
	
	
extra_check:
	lw $s1, prevCollisionY
	sw $s2, prevCollisionY
	beq $s1, 31, add_score # add score if previous reach the bottom platform
	j resstart_jump
	
add_score:
	lw $t0, score
	addi $t0, $t0, 1
	sw $t0, score
	
	add $s0, $zero, $zero
	sw $s0, flag
	
	addi $t0, $t0, -1
	beq $t0, 0, delete_zero
	beq $t0, 1, delete_one
	beq $t0, 2, delete_two
	beq $t0, 3, delete_three
	j resstart_jump


resstart_jump:	
	# no change to platforms
	# reassign the height that the doodle can jump 
	# location has been updated
	add $s0, $zero, $zero
	sw $s0, flag
	
	lw $s0, score
	beq $s0, 5, l2_Draw_initial # check if need to update level
	
	beq $s0, 3, check_encourage

	jal Random_height_generator
	lw $ra, 0($sp)
	sw $t4, Height
	jal redraw_screen
	lw $ra, 0($sp)
	addi $sp, $sp, -4
	
	j location_update
	
check_encourage:
	lw $s0, wowFlag
	beq $s0, 0, encourage
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	jal Random_height_generator
	lw $ra, 0($sp)
	sw $t4, Height
	jal redraw_screen
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	j location_update

encourage:
	addi $s0, $zero, 1
	sw $s0, wowFlag
	
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	jal redraw_screen
	lw $ra, 0($sp)
	
	jal draw_wow
	lw $ra, 0($sp)
	
	addi $v1, $zero, 1000
	jal Sleep
	lw $ra, 0($sp)
	
	jal delete_wow
	lw $ra, 0($sp)
	
	# draw old doodle
	lw $t1, doodleLX
	lw $t2, doodleLY
	jal Calcuate_address
	lw $ra, 0($sp)
	lw $t0, displayAddress
	add $t3, $t0, $t3
	add $t0, $zero, $t3
	jal Draw_doodle
	lw $ra, 0($sp)
	
	# delete old platform1
	lw $t1, plt1LX
	lw $t2, plt1LY
	jal Calcuate_address #calculate extra address need to add to origin and store in t3
	lw $ra, 0($sp)
	lw $t0, displayAddress
	add $t3, $t0, $t3 #address of old platform
	jal DrawNormalPlatform
	lw $ra, 0($sp)
	
	# delete old platform2
	lw $t1, plt2LX
	lw $t2, plt2LY
	jal Calcuate_address
	lw $ra, 0($sp)
	lw $t0, displayAddress
	add $t3, $t0, $t3
	jal DrawNormalPlatform
	lw $ra, 0($sp)
	
	# delete old platform3
	lw $t1, plt3LX
	lw $t2, plt3LY
	jal Calcuate_address
	lw $ra, 0($sp)
	lw $t0, displayAddress
	add $t3, $t0, $t3
	jal DrawNormalPlatform
	lw $ra, 0($sp)
	
	addi $s0, $zero, 4
	sw $s0, Height
	
	addi $s0, $zero, 1
	sw $s0, wowFlag
	
	addi $v1, $zero, 1000
	jal Sleep
	lw $ra, 0($sp)
		
	j location_update
	
	
							
Game_over:
	lw $t0, displayAddress
	lw $t3, enddisplayAddress # the address of last unit on the screen
	lw $a0, bgdColor
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	jal Draw_bgd 
	lw $ra, 0($sp)
	
	jal draw_game_over
	lw $ra, 0($sp)
	
	addi $v1, $zero, 500
	jal Sleep
	lw $ra, 0($sp)
	
	jal delete_game_over
	lw $ra, 0($sp)
	
	jal draw_tryagain
	lw $ra, 0($sp)
	
	jal Reset_input
	lw $ra, 0($sp)
	
	addi $sp, $sp, 4
	
	j restart_Intial_input_check
	
	

####################################random value generation######################################################
Random_x_plt_generator: # generate random x index of normal platform in range of [0, 24]
	li $a1, 18 # Here $a1 is the upper bound of the x coordinate of platform (assume length of platform is 4 unit)
	li $a0, 0
	li $v0, 42 # Generate random  coordinate of platform
	syscall
	move $t1, $a0 # $t1 stores the generated random x index to be checked
	addi $t1, $t1, 5
	jr $ra

	
Random_height_generator: # generate random y index of normal platform in range of [0, doodleLY]
	# t5 is the register store the current Y location of doodle which at the platform and will jump
	lw $t2, doodleY
	add $s0, $zero, $t2 # Here $s0 is the upper bound of the y coordinate of platform
	li $a0, 5
	li $v0, 42 # Generate random y coordinate of platform
	syscall
	move $t4, $a0 # $t4 stores the generated random y index to be checked
	addi $t4, $zero, 15
	jr $ra	


Sleep:
	# sleep time is stored in v1
	li $v0, 32 #syscall value for sleep
	add $a0, $zero, $v1 # a0 = number to sleep
	syscall
	jr $ra

			
draw_zero:
	lw $a0, scoreColor
	lw $s0, displayAddress
	addi $s0, $s0, 132
	sw $a0, 0($s0)
	sw $a0, 4($s0)
	sw $a0, 8($s0)
	sw $a0, 128($s0)
	sw $a0, 136($s0)
	sw $a0, 256($s0)
	sw $a0, 264($s0)
	sw $a0, 384($s0)
	sw $a0, 392($s0)
	sw $a0, 512($s0)
	sw $a0, 516($s0)
	sw $a0, 520($s0)
	jr $ra
	
delete_zero:
	lw $a0, bgdColor
	lw $s0, displayAddress
	addi $s0, $s0, 132
	sw $a0, 0($s0)
	sw $a0, 4($s0)
	sw $a0, 8($s0)
	sw $a0, 128($s0)
	sw $a0, 136($s0)
	sw $a0, 256($s0)
	sw $a0, 264($s0)
	sw $a0, 384($s0)
	sw $a0, 392($s0)
	sw $a0, 512($s0)
	sw $a0, 516($s0)
	sw $a0, 520($s0)
	j draw_one
	

draw_one:
	lw $s0, displayAddress
	lw $a0, scoreColor
	addi $s0, $s0, 132
	sw $a0, 0($s0)
	sw $a0, 4($s0)
	sw $a0, 132($s0)
	sw $a0, 260($s0)
	sw $a0, 388($s0)
	sw $a0, 512($s0)
	sw $a0, 516($s0)
	sw $a0, 520($s0)	
	j resstart_jump
	
	
delete_one:
	lw $s0, displayAddress
	lw $a0, bgdColor
	addi $s0, $s0, 132
	sw $a0, 0($s0)
	sw $a0, 4($s0)
	sw $a0, 132($s0)
	sw $a0, 260($s0)
	sw $a0, 388($s0)
	sw $a0, 512($s0)
	sw $a0, 516($s0)
	sw $a0, 520($s0)	
	j draw_two
	
draw_two:
	lw $s0, displayAddress
	lw $a0, scoreColor
	addi $s0, $s0, 132
	sw $a0, 0($s0)
	sw $a0, 4($s0)
	sw $a0, 8($s0)
	sw $a0, 136($s0)
	sw $a0, 256($s0)
	sw $a0, 260($s0)
	sw $a0, 264($s0)
	sw $a0, 384($s0)
	sw $a0, 512($s0)
	sw $a0, 516($s0)
	sw $a0, 520($s0)
	j resstart_jump
	
delete_two:
	lw $s0, displayAddress
	lw $a0, bgdColor
	addi $s0, $s0, 132
	sw $a0, 0($s0)
	sw $a0, 4($s0)
	sw $a0, 8($s0)
	sw $a0, 136($s0)
	sw $a0, 256($s0)
	sw $a0, 260($s0)
	sw $a0, 264($s0)
	sw $a0, 384($s0)
	sw $a0, 512($s0)
	sw $a0, 516($s0)
	sw $a0, 520($s0)
	j draw_three
	
draw_three:
	lw $s0, displayAddress
	lw $a0, scoreColor
	addi $s0, $s0, 132
	sw $a0, 0($s0)
	sw $a0, 4($s0)
	sw $a0, 8($s0)
	sw $a0, 136($s0)
	sw $a0, 256($s0)
	sw $a0, 260($s0)
	sw $a0, 264($s0)
	sw $a0, 392($s0)
	sw $a0, 512($s0)
	sw $a0, 516($s0)
	sw $a0, 520($s0)
	j resstart_jump
	
delete_three:
	lw $s0, displayAddress
	lw $a0, bgdColor
	addi $s0, $s0, 132
	sw $a0, 0($s0)
	sw $a0, 4($s0)
	sw $a0, 8($s0)
	sw $a0, 136($s0)
	sw $a0, 256($s0)
	sw $a0, 260($s0)
	sw $a0, 264($s0)
	sw $a0, 392($s0)
	sw $a0, 512($s0)
	sw $a0, 516($s0)
	sw $a0, 520($s0)
	j draw_four
	
draw_four:
	lw $s0, displayAddress
	lw $a0, scoreColor
	addi $s0, $s0, 132
	sw $a0, 0($s0)
	sw $a0, 8($s0)
	sw $a0, 128($s0)
	sw $a0, 136($s0)
	sw $a0, 256($s0)
	sw $a0, 264($s0)
	sw $a0, 384($s0)
	sw $a0, 388($s0)
	sw $a0, 392($s0)
	sw $a0, 520($s0)
	j resstart_jump
	
delete_four:
	lw $s0, displayAddress
	lw $a0, bgdColor
	addi $s0, $s0, 132
	sw $a0, 0($s0)
	sw $a0, 8($s0)
	sw $a0, 128($s0)
	sw $a0, 136($s0)
	sw $a0, 256($s0)
	sw $a0, 264($s0)
	sw $a0, 384($s0)
	sw $a0, 388($s0)
	sw $a0, 392($s0)
	sw $a0, 520($s0)
	j draw_five
	

draw_five:
	lw $s0, displayAddress
	lw $a0, scoreColor
	addi $s0, $s0, 132
	sw $a0, 0($s0)
	sw $a0, 4($s0)
	sw $a0, 8($s0)
	sw $a0, 128($s0)
	sw $a0, 256($s0)
	sw $a0, 260($s0)
	sw $a0, 264($s0)
	sw $a0, 392($s0)
	sw $a0, 512($s0)
	sw $a0, 516($s0)
	sw $a0, 520($s0)
	jr $ra

delete_five:
	lw $s0, displayAddress
	lw $a0, bgdColor
	addi $s0, $s0, 132
	sw $a0, 0($s0)
	sw $a0, 4($s0)
	sw $a0, 8($s0)
	sw $a0, 128($s0)
	sw $a0, 256($s0)
	sw $a0, 260($s0)
	sw $a0, 264($s0)
	sw $a0, 392($s0)
	sw $a0, 512($s0)
	sw $a0, 516($s0)
	sw $a0, 520($s0)
	j draw_six
		

draw_six:
	lw $s0, displayAddress
	lw $a0, scoreColor
	addi $s0, $s0, 132
	sw $a0, 0($s0)
	sw $a0, 4($s0)
	sw $a0, 8($s0)
	sw $a0, 128($s0)
	sw $a0, 256($s0)
	sw $a0, 260($s0)
	sw $a0, 264($s0)
	sw $a0, 384($s0)
	sw $a0, 392($s0)
	sw $a0, 512($s0)
	sw $a0, 516($s0)
	sw $a0, 520($s0)
	j l2_resstart_jump
	
delete_six:
	lw $s0, displayAddress
	lw $a0, bgdColor
	addi $s0, $s0, 132
	sw $a0, 0($s0)
	sw $a0, 4($s0)
	sw $a0, 8($s0)
	sw $a0, 128($s0)
	sw $a0, 256($s0)
	sw $a0, 260($s0)
	sw $a0, 264($s0)
	sw $a0, 384($s0)
	sw $a0, 392($s0)
	sw $a0, 512($s0)
	sw $a0, 516($s0)
	sw $a0, 520($s0)
	j draw_seven

draw_seven:
	lw $s0, displayAddress
	lw $a0, scoreColor
	addi $s0, $s0, 132
	sw $a0, 0($s0)
	sw $a0, 4($s0)
	sw $a0, 8($s0)
	sw $a0, 136($s0)
	sw $a0, 260($s0)
	sw $a0, 264($s0)
	sw $a0, 388($s0)
	sw $a0, 516($s0)
	j l2_resstart_jump
	
delete_seven:
	lw $s0, displayAddress
	lw $a0, bgdColor
	addi $s0, $s0, 132
	sw $a0, 0($s0)
	sw $a0, 4($s0)
	sw $a0, 8($s0)
	sw $a0, 136($s0)
	sw $a0, 260($s0)
	sw $a0, 264($s0)
	sw $a0, 388($s0)
	sw $a0, 516($s0)
	j draw_eight
	
draw_eight:
	lw $s0, displayAddress
	lw $a0, scoreColor
	addi $s0, $s0, 132
	sw $a0, 0($s0)
	sw $a0, 4($s0)
	sw $a0, 8($s0)
	sw $a0, 128($s0)
	sw $a0, 136($s0)
	sw $a0, 256($s0)
	sw $a0, 260($s0)
	sw $a0, 264($s0)
	sw $a0, 384($s0)
	sw $a0, 392($s0)
	sw $a0, 512($s0)
	sw $a0, 516($s0)
	sw $a0, 520($s0)
	j l2_resstart_jump
	
delete_eight:
	lw $s0, displayAddress
	lw $a0, bgdColor
	addi $s0, $s0, 132
	sw $a0, 0($s0)
	sw $a0, 4($s0)
	sw $a0, 8($s0)
	sw $a0, 128($s0)
	sw $a0, 136($s0)
	sw $a0, 256($s0)
	sw $a0, 260($s0)
	sw $a0, 264($s0)
	sw $a0, 384($s0)
	sw $a0, 392($s0)
	sw $a0, 512($s0)
	sw $a0, 516($s0)
	sw $a0, 520($s0)
	j draw_nine
	

draw_nine:
	lw $s0, displayAddress
	lw $a0, scoreColor
	addi $s0, $s0, 132
	sw $a0, 0($s0)
	sw $a0, 4($s0)
	sw $a0, 8($s0)
	sw $a0, 128($s0)
	sw $a0, 136($s0)
	sw $a0, 256($s0)
	sw $a0, 260($s0)
	sw $a0, 264($s0)
	sw $a0, 392($s0)
	sw $a0, 520($s0)
	j l2_resstart_jump
	
delete_nine:
	lw $s0, displayAddress
	lw $a0, bgdColor
	addi $s0, $s0, 132
	sw $a0, 0($s0)
	sw $a0, 4($s0)
	sw $a0, 8($s0)
	sw $a0, 128($s0)
	sw $a0, 136($s0)
	sw $a0, 256($s0)
	sw $a0, 260($s0)
	sw $a0, 264($s0)
	sw $a0, 392($s0)
	sw $a0, 520($s0)
	j draw_greater_sign
	
draw_greater_sign:
	lw $s0, displayAddress
	lw $a0, scoreColor
	addi $s0, $s0, 132
	sw $a0, 0($s0)
	sw $a0, 132($s0)
	sw $a0, 264($s0)
	sw $a0, 388($s0)
	sw $a0, 512($s0)						
	j l2_resstart_jump
	
	
	
draw_game_over:
	lw $s0, displayAddress
	lw $a0, grayColor
	addi $s0, $s0, 1440
	sw $a0, 4($s0)
	sw $a0, 8($s0)
	sw $a0, 12($s0)
	sw $a0, 16($s0)
	sw $a0, 128($s0)
	sw $a0, 148($s0)
	sw $a0, 256($s0)
	sw $a0, 276($s0)
	sw $a0, 384($s0)
	sw $a0, 512($s0)
	sw $a0, 524($s0)
	sw $a0, 528($s0)
	sw $a0, 644($s0)
	sw $a0, 648($s0)
	sw $a0, 656($s0)
	
	addi $s0, $s0, 40
	sw $a0, 4($s0)
	sw $a0, 8($s0)
	sw $a0, 12($s0)
	sw $a0, 16($s0)
	sw $a0, 128($s0)
	sw $a0, 148($s0)
	sw $a0, 256($s0)
	sw $a0, 276($s0)
	sw $a0, 384($s0)
	sw $a0, 512($s0)
	sw $a0, 524($s0)
	sw $a0, 528($s0)
	sw $a0, 644($s0)
	sw $a0, 648($s0)
	sw $a0, 656($s0)
	
	jr $ra
	
delete_game_over:
	lw $s0, displayAddress
	lw $a0, bgdColor
	addi $s0, $s0, 1440
	sw $a0, 4($s0)
	sw $a0, 8($s0)
	sw $a0, 12($s0)
	sw $a0, 16($s0)
	sw $a0, 128($s0)
	sw $a0, 148($s0)
	sw $a0, 256($s0)
	sw $a0, 276($s0)
	sw $a0, 384($s0)
	sw $a0, 512($s0)
	sw $a0, 524($s0)
	sw $a0, 528($s0)
	sw $a0, 644($s0)
	sw $a0, 648($s0)
	sw $a0, 656($s0)
	
	addi $s0, $s0, 40
	sw $a0, 4($s0)
	sw $a0, 8($s0)
	sw $a0, 12($s0)
	sw $a0, 16($s0)
	sw $a0, 128($s0)
	sw $a0, 148($s0)
	sw $a0, 256($s0)
	sw $a0, 276($s0)
	sw $a0, 384($s0)
	sw $a0, 512($s0)
	sw $a0, 524($s0)
	sw $a0, 528($s0)
	sw $a0, 644($s0)
	sw $a0, 648($s0)
	sw $a0, 656($s0)
	
	jr $ra
	
			
draw_tryagain:
	lw $s0, displayAddress
	lw $a0, grayColor
	addi $s0, $s0, 1412
	sw $a0, 0($s0)
	sw $a0, 4($s0)
	sw $a0, 8($s0)
	sw $a0, 128($s0)
	sw $a0, 136($s0)
	sw $a0, 256($s0)
	sw $a0, 260($s0)
	sw $a0, 264($s0)
	sw $a0, 384($s0)
	sw $a0, 512($s0)
	sw $a0, 516($s0)
	sw $a0, 640($s0)
	sw $a0, 648($s0)
	
	addi $s0, $s0, 20
	sw $a0, 0($s0)
	sw $a0, 4($s0)
	sw $a0, 8($s0)
	sw $a0, 128($s0)
	sw $a0, 256($s0)
	sw $a0, 260($s0)
	sw $a0, 264($s0)
	sw $a0, 384($s0)
	sw $a0, 512($s0)
	sw $a0, 640($s0)
	sw $a0, 644($s0)
	sw $a0, 648($s0)

	addi $s0, $s0, 20
	sw $a0, 0($s0)
	sw $a0, 4($s0)
	sw $a0, 8($s0)
	sw $a0, 132($s0)
	sw $a0, 260($s0)
	sw $a0, 388($s0)
	sw $a0, 516($s0)
	sw $a0, 644($s0)
	
	addi $s0, $s0, 20
	sw $a0, 0($s0)
	sw $a0, 4($s0)
	sw $a0, 8($s0)
	sw $a0, 128($s0)
	sw $a0, 136($s0)
	sw $a0, 256($s0)
	sw $a0, 260($s0)
	sw $a0, 264($s0)
	sw $a0, 384($s0)
	sw $a0, 512($s0)
	sw $a0, 516($s0)
	sw $a0, 640($s0)
	sw $a0, 648($s0)
	
	addi $s0, $s0, 20
	sw $a0, 0($s0)
	sw $a0, 8($s0)
	sw $a0, 128($s0)
	sw $a0, 136($s0)
	sw $a0, 256($s0)
	sw $a0, 260($s0)
	sw $a0, 264($s0)
	sw $a0, 388($s0)
	sw $a0, 516($s0)
	sw $a0, 644($s0)

	addi $s0, $s0, 20
	sw $a0, 0($s0)
	sw $a0, 4($s0)
	sw $a0, 8($s0)
	sw $a0, 12($s0)
	sw $a0, 128($s0)
	sw $a0, 140($s0)
	sw $a0, 264($s0)
	sw $a0, 268($s0)
	sw $a0, 392($s0)
	sw $a0, 648($s0)
	
	jr $ra
	
delete_tryagain:
	lw $s0, displayAddress
	lw $a0, bgdColor
	addi $s0, $s0, 1412
	sw $a0, 0($s0)
	sw $a0, 4($s0)
	sw $a0, 8($s0)
	sw $a0, 128($s0)
	sw $a0, 136($s0)
	sw $a0, 256($s0)
	sw $a0, 260($s0)
	sw $a0, 264($s0)
	sw $a0, 384($s0)
	sw $a0, 512($s0)
	sw $a0, 516($s0)
	sw $a0, 640($s0)
	sw $a0, 648($s0)
	
	addi $s0, $s0, 20
	sw $a0, 0($s0)
	sw $a0, 4($s0)
	sw $a0, 8($s0)
	sw $a0, 128($s0)
	sw $a0, 256($s0)
	sw $a0, 260($s0)
	sw $a0, 264($s0)
	sw $a0, 384($s0)
	sw $a0, 512($s0)
	sw $a0, 640($s0)
	sw $a0, 644($s0)
	sw $a0, 648($s0)

	addi $s0, $s0, 20
	sw $a0, 0($s0)
	sw $a0, 4($s0)
	sw $a0, 8($s0)
	sw $a0, 132($s0)
	sw $a0, 260($s0)
	sw $a0, 388($s0)
	sw $a0, 516($s0)
	sw $a0, 644($s0)
	
	addi $s0, $s0, 20
	sw $a0, 0($s0)
	sw $a0, 4($s0)
	sw $a0, 8($s0)
	sw $a0, 128($s0)
	sw $a0, 136($s0)
	sw $a0, 256($s0)
	sw $a0, 260($s0)
	sw $a0, 264($s0)
	sw $a0, 384($s0)
	sw $a0, 512($s0)
	sw $a0, 516($s0)
	sw $a0, 640($s0)
	sw $a0, 648($s0)
	
	addi $s0, $s0, 20
	sw $a0, 0($s0)
	sw $a0, 8($s0)
	sw $a0, 128($s0)
	sw $a0, 136($s0)
	sw $a0, 256($s0)
	sw $a0, 260($s0)
	sw $a0, 264($s0)
	sw $a0, 388($s0)
	sw $a0, 516($s0)
	sw $a0, 644($s0)

	addi $s0, $s0, 20
	sw $a0, 0($s0)
	sw $a0, 4($s0)
	sw $a0, 8($s0)
	sw $a0, 12($s0)
	sw $a0, 128($s0)
	sw $a0, 140($s0)
	sw $a0, 264($s0)
	sw $a0, 268($s0)
	sw $a0, 392($s0)
	sw $a0, 648($s0)
	
	jr $ra
	
restart_Intial_input_check:
	lw $t8, 0xffff0000
	beq $t8, 1, Restart_input
	j restart_Intial_input_check # if no input, wait till the player input "s" to start game
	
	
Restart_input: # when there is a input, check what exactly the input is, otherwise do genral location update of doodle
	lw $t7, 0xffff0004
	bne $t7, 0x73, Exit
	sw $zero, 0xffff0000
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	jal delete_tryagain
	j respond_to_s
	

#######################################################################################
l2_DrawNormalPlatform: # draw a normal platform with length of 8 units
# $t3 is address of platform shown on the bitmap
# Paint the platform ---------------------	
	lw $a0, pltColor
	sw $a0, 0($t3)
	sw $a0, 4($t3)
	sw $a0, 8($t3)
	sw $a0, 12($t3)
	jr $ra
	
	
l2_DeletePlatform:
# $t3 is address of platform 
# Erase the normal Platform
	lw $a0, bgdColor
	sw $a0, 0($t3)
	sw $a0, 4($t3)
	sw $a0, 8($t3)
	sw $a0, 12($t3)
	jr $ra

l2_DrawFragilePlatform: # draw a normal platform with length of 8 units
# $t3 is address of platform shown on the bitmap
# Paint the platform ---------------------	
	lw $a0, fragilepltColor
	sw $a0, 0($t3)
	sw $a0, 4($t3)
	sw $a0, 8($t3)
	sw $a0, 12($t3)
	jr $ra
	

l2_Draw_initial:
	# redraw general backgroud color of the screen------------------------------
	
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	jal redraw_screen
	lw $ra, 0($sp)
	
	jal delete_four
	lw $ra, 0($sp)
	
	
	addi $v1, $zero, 1000
	jal Sleep
	lw $ra, 0($sp)
	
	
	lw $t0, displayAddress
	lw $t3, enddisplayAddress # the address of last unit on the screen
	lw $a0, bgdColor
	addi $sp, $sp, -4 # store the return address that draw_initial should return to 
	sw $ra, 0($sp)
	jal Draw_bgd # draw the general background color
	lw $ra, 0($sp)
	
	#show level information
	jal draw_leveltwo 
	lw $ra, 0($sp)
	
	addi $v1, $zero, 1000
	jal Sleep
	lw $ra, 0($sp)
	

	jal delete_leveltwo
	lw $ra, 0($sp)

	add $s0, $zero, $zero
	sw $s0, flag
	
	addi $s0, $zero, 15
	sw $s0, Height
	
	addi $t1, $zero, 15
	addi $t2, $zero, 28
	sw $t1, doodleLX
	sw $t1, doodleX
	sw $t2, doodleLY
	sw $t2, doodleY
	
	# draw initial doodle on the screen (at middle bottom)---------------------
	lw $t0, displayAddress
	addiu $t0, $t0, 3644
	jal Draw_doodle # draw the general background color
	lw $ra, 0($sp)


	# draw initial normal platforms on the screen (at random position)---------------------
	addi $t2, $zero, 31 #load normal platform 1's y location to $t2
	sw $t2, plt1Y
	sw $t2, plt1LY
	jal l2_Random_x_plt_generator# generate a valid x location for platform and store in t1
	lw $ra, 0($sp)
	sw $t1, plt1X # save x index of first generated platform in plt1X global variable
	sw $t1, plt1LX 
	lw $t1, plt1X
	lw $t2, plt1Y
	jal Calcuate_address
	lw $t0, displayAddress
	add $t3, $t0, $t3
	jal l2_DrawNormalPlatform # draw the first normal platform
	lw $ra, 0($sp)

	
	addi $t2, $zero, 21
	sw $t2, plt2Y
	sw $t2, plt2LY
	jal l2_Random_x_plt_generator
	lw $ra, 0($sp)
	sw $t1, plt2X # save x index of first generated platform in plt1X global variable
	sw $t1, plt2LX
	lw $t1, plt2X
	lw $t2, plt2Y
	jal Calcuate_address
	lw $t0, displayAddress
	add $t3, $t0, $t3
	jal l2_DrawNormalPlatform # draw the first normal platform
	lw $ra, 0($sp)

	addi $t2, $zero, 11
	sw $t2, plt3Y
	sw $t2, plt3LY
	jal l2_Random_x_plt_generator
	lw $ra, 0($sp)
	sw $t1, plt3X # save x index of first generated platform in plt1X global variable
	sw $t1, plt3LX
	lw $t1, plt3X
	lw $t2, plt3Y
	jal Calcuate_address
	lw $ra, 0($sp)
	lw $t0, displayAddress
	add $t3, $t0, $t3
	jal l2_DrawNormalPlatform # draw the first normal platform
	lw $ra, 0($sp)
	
	addi $t2, $zero, 26
	sw $t2, plt4Y
	sw $t2, plt4LY
	jal l2_Random_x_plt_generator
	lw $ra, 0($sp)
	sw $t1, plt4X # save x index of first generated platform in plt1X global variable
	sw $t1, plt4LX
	lw $t1, plt4X
	lw $t2, plt4Y
	jal Calcuate_address
	lw $ra, 0($sp)
	lw $t0, displayAddress
	add $t3, $t0, $t3
	jal l2_DrawFragilePlatform # draw the first normal platform
	lw $ra, 0($sp)
	
	addi $t2, $zero, 16
	sw $t2, plt5Y
	sw $t2, plt5LY
	jal l2_Random_x_plt_generator
	lw $ra, 0($sp)
	sw $t1, plt5X # save x index of first generated platform in plt1X global variable
	sw $t1, plt5LX
	lw $t1, plt5X
	lw $t2, plt5Y
	jal Calcuate_address
	lw $ra, 0($sp)
	lw $t0, displayAddress
	add $t3, $t0, $t3
	jal l2_DrawFragilePlatform # draw the first normal platform
	lw $ra, 0($sp)
	
	
	lw $a0, scoreColor
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	jal draw_five
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	j l2_location_update
	
l2_Random_x_plt_generator: # generate random x index of normal platform in range of [0, 24]
	li $a1, 22 # Here $a1 is the upper bound of the x coordinate of platform (assume length of platform is 4 unit)
	li $a0, 0
	li $v0, 42 # Generate random  coordinate of platform
	syscall
	move $t1, $a0 # $t1 stores the generated random x index to be checked
	addi $t1, $t1, 5
	jr $ra


l2_redraw_screen: 
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	# delete old doodle
	lw $t1, doodleLX
	lw $t2, doodleLY
	jal Calcuate_address
	lw $ra, 0($sp)
	lw $t0, displayAddress
	add $t3, $t0, $t3
	add $t0, $zero, $t3
	jal Delete_doodle
	lw $ra, 0($sp)
	
	# draw updated doodle
	lw $t1, doodleX
	lw $t2, doodleY
	jal Calcuate_address
	lw $ra, 0($sp)
	lw $t0, displayAddress
	add $t3, $t0, $t3
	add $t0, $zero, $t3
	jal Draw_doodle
	lw $ra, 0($sp)
	
	# update current doodle location
	lw $s1, doodleX
	lw $s2, doodleY
	sw $s1, doodleLX
	sw $s2, doodleLY
	
	# delete old platform1
	lw $t1, plt1LX
	lw $t2, plt1LY
	jal Calcuate_address #calculate extra address need to add to origin and store in t3
	lw $ra, 0($sp)
	lw $t0, displayAddress
	add $t3, $t0, $t3 #address of old platform
	jal l2_DeletePlatform
	lw $ra, 0($sp)
	
	# Draw new platform1
	lw $t1, plt1X
	lw $t2, plt1Y
	jal Calcuate_address
	lw $ra, 0($sp)
	lw $t0, displayAddress
	add $t3, $t0, $t3
	jal l2_DrawNormalPlatform
	lw $ra, 0($sp)
	
	#update current platform1 location
	lw $s1, plt1X
	lw $s2, plt1Y
	sw $s1, plt1LX
	sw $s2, plt1LY
	
	# delete old platform2
	lw $t1, plt2LX
	lw $t2, plt2LY
	jal Calcuate_address
	lw $ra, 0($sp)
	lw $t0, displayAddress
	add $t3, $t0, $t3
	jal l2_DeletePlatform
	lw $ra, 0($sp)
	
	# Draw new platform2
	lw $t1, plt2X
	lw $t2, plt2Y
	jal Calcuate_address
	lw $ra, 0($sp)
	lw $t0, displayAddress
	add $t3, $t0, $t3
	jal l2_DrawNormalPlatform
	lw $ra, 0($sp)
	
	#update current platform1 location 2
	lw $s1, plt2X
	lw $s2, plt2Y
	sw $s1, plt2LX
	sw $s2, plt2LY
	
	# delete old platform3
	lw $t1, plt3LX
	lw $t2, plt3LY
	jal Calcuate_address
	lw $ra, 0($sp)
	lw $t0, displayAddress
	add $t3, $t0, $t3
	jal l2_DeletePlatform
	lw $ra, 0($sp)
	
	# Draw new platform1
	lw $t1, plt3X
	lw $t2, plt3Y
	jal Calcuate_address
	lw $ra, 0($sp)
	lw $t0, displayAddress
	add $t3, $t0, $t3
	jal l2_DrawNormalPlatform
	lw $ra, 0($sp)
	
	#update current platform1 location
	lw $s1, plt3X
	lw $s2, plt3Y
	sw $s1, plt3LX
	sw $s2, plt3LY
	
	j l2_redraw_case1
	
l2_redraw_case1: # if no plt4 temporarily
	lw $s0, plt4Flag
	
	lw $s1, plt4X
	lw $s2, plt4Y
	
	beq $s0, 0, l2_redraw_case2
	lw $t1, plt4LX
	lw $t2, plt4LY	
	jal Calcuate_address
	lw $ra, 0($sp)
	lw $t0, displayAddress
	add $t3, $t0, $t3
	jal l2_DeletePlatform
	lw $ra, 0($sp)
	
	# Draw new platform4
	lw $t1, plt4X
	lw $t2, plt4Y
	jal Calcuate_address
	lw $ra, 0($sp)
	lw $t0, displayAddress
	add $t3, $t0, $t3
	jal l2_DrawFragilePlatform
	lw $ra, 0($sp)
	
	#update current platform1 location
	j l2_redraw_case2
	

l2_redraw_case2: # if no plt5 temporarily
	lw $s0, plt5Flag
	
	lw $s3, plt5X
	lw $s4, plt5Y
	
	beq $s0, 0, l2_redraw_case3
		
	lw $t1, plt5LX
	lw $t2, plt5LY
	jal Calcuate_address
	lw $ra, 0($sp)
	lw $t0, displayAddress
	add $t3, $t0, $t3
	jal l2_DeletePlatform
	lw $ra, 0($sp)
	
	# Draw new platform5
	lw $t1, plt5X
	lw $t2, plt5Y
	jal Calcuate_address
	lw $ra, 0($sp)
	lw $t0, displayAddress
	add $t3, $t0, $t3
	jal l2_DrawFragilePlatform
	lw $ra, 0($sp)
	
	#update current platform1 location
	j l2_redraw_case3


l2_redraw_case3:
	sw $s1, plt4LX
	sw $s2, plt4LY
	sw $s3, plt5LX
	sw $s4, plt5LY

	addi $v1, $zero, 100
	jal Sleep
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
	
	
##################update location of elements that will be drawn on the screen
l2_location_update:
	
	lw $s0, Height # load Height varible, to check the status of doodle
	# if Height less or equal to zero, it reaches highest point and fall
	
	blez  $s0, l2_location_update_case_one # jump to case 1 when doodle is falling
	
	# doodle is rising
	lw $s1, plt3Y
	lw $s2, doodleY
	bge $s2, $s1, l2_location_update_case_two # jump to case 2 when doodle is rise but not reach highest platform
	
	j l2_location_update_case_three

	
			
l2_location_update_case_one:
	# platforms location keep still
	# update doodle's next y location
	lw $s1, doodleY
	beq $s1, 28, l2_check_boundary
	
	lw $s4, doodleY
	addi $s4, $s4, 1
	sw $s4, doodleY
	# update doodle's next x location by checking keyboard input
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	jal Input_check
	lw $ra, 0($sp)
	
	addi $sp, $sp, 4
	
	j l2_check_collision


l2_location_update_case_two:
	#platforms location keep still
	lw $s5, Height
	addi $s5, $s5, -1
	sw $s5, Height
	
	# update doodle's next y location
	lw $s4, doodleY
	addi $s4, $s4, -1
	sw $s4, doodleY
	
	# update doodle's next x location by checking keyboard input
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	jal Input_check
	lw $ra, 0($sp)
	
	beq $s5,5 move_board1
	
	jal l2_redraw_screen
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	j l2_location_update
	
move_board1:
	lw $s0, plt1X
	addi $s0, $s0, 4
	bgt $s0, 28, circle_x1
	sw $s0, plt1X
	j move_board3

circle_x1:
	addi $s0, $zero, 5
	sw $s0, plt1X
	j move_board3
	
move_board3:
	lw $ra, 0($sp)
	lw $s0, plt3X
	sw $s0, plt3LX
	addi $s0, $s0, -4
	blt $s0, 5, circle_x3
	sw $s0, plt3X
	j move_board4

circle_x3:
	addi $s0, $zero, 27
	sw $s0, plt3X
	j move_board4
	
	
move_board4:
	lw $s0, plt4X
	sw $s0, plt4LX
	addi $s0, $s0, -4
	blt $s0, 5, circle_x4
	sw $s0, plt4X
	j move_board5

circle_x4:
	addi $s0, $zero, 27
	sw $s0, plt4X
	j move_board5
	
move_board5:
	lw $s0, plt5X
	sw $s0, plt5LX
	addi $s0, $s0, 4
	bgt $s0, 28, circle_x5
	sw $s0, plt5X
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	jal l2_redraw_screen
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	j l2_location_update

circle_x5:
	addi $s0, $zero, 5
	sw $s0, plt5X
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	jal l2_redraw_screen
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	j l2_location_update
	

l2_location_update_case_three: # case that doodle still rising but reach the highest platform
	# want to remove the lowest platform， generate a new top platform， then move the lowest platform to the bottom
	# regenerate a new set of x,y location of three platform
	# doodle will not move in x direction, but it will move together with the platforms
	
	# change direction of doodle
	add $s0, $zero, $zero
	sw $s0, Height
	
	addi $s0, $zero, 1 # change flag to value 1  showing screen rotate
	sw $s0, flag
	
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	jal l2_rotation_plt
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	j l2_plt_downward_loop
	
	
l2_plt_downward_loop:

	lw $s1, plt1Y	
	beq $s1, 31, l2_location_update
	
	#redraw all elements
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	jal l2_redraw_screen
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	#update doodle Y location
	lw $s0, doodleY
	addi $s0, $s0, 1
	sw $s0, doodleY

	#update all five platform locations
	lw $s2, plt1Y
	addi $s2, $s2, 1
	sw $s2, plt1Y
	
	lw $s2, plt2Y
	addi $s2, $s2, 1
	sw $s2, plt2Y
	
	lw $s2, plt3Y
	addi $s2, $s2, 1
	sw $s2, plt3Y
	
	lw $s2, plt4Y
	addi $s2, $s2, 1
	sw $s2, plt4Y
	
	lw $s2, plt5Y
	addi $s2, $s2, 1
	sw $s2, plt5Y
	
	#jump back to check if finished update of platforms
	j l2_plt_downward_loop
	
	
l2_rotation_plt:
	# put current location of plt1 to old location of plt3 so as to erase it
	lw $s5, plt1LY
	lw $s6, plt1LX
	
	# assign location of plt2 to plt1 and update its next location by moving downward
	lw $s1, plt2LY
	lw $s2, plt2Y
	lw $s3, plt2LX
	lw $s4, plt2X
	sw $s1, plt1LY
	addi $s2, $s2, 1
	sw $s2, plt1Y
	sw $s3, plt1LX
	sw $s4, plt1X
	
	# move location of plt3 to plt2
	lw $s1, plt3LY
	lw $s2, plt3Y
	lw $s3, plt3LX
	lw $s4, plt3X
	sw $s1, plt2LY
	addi $s2, $s2, 1
	sw $s2, plt2Y
	sw $s3, plt2LX
	sw $s4, plt2X
	
	# generate a new location for new plt3 with Y location 0 and random X location (assign old location of plt1 to old location of plt3)
	sw $s5, plt3LY
	sw $s6, plt3LX
	addi $s1, $zero, 1
	sw $s1, plt3Y
	
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	jal l2_Random_x_plt_generator
	lw $ra, 0($sp)	
	addi $sp, $sp, 4
	sw $t1, plt3X
	
	# assign information of plt5 to plt4
	# put current location of plt4 to old location of plt5 so as to erase it
	lw $s5, plt4LY
	lw $s6, plt4LX

	# move location of plt5 to plt4
	lw $s1, plt5LY
	lw $s2, plt5Y
	lw $s3, plt5LX
	lw $s4, plt5X
	lw $s0, plt5Flag
	sw $s1, plt4LY
	addi $s2, $s2, 1
	sw $s2, plt4Y
	sw $s3, plt4LX
	sw $s4, plt4X
	sw $s0, plt4Flag
	
	# generate a new location for new plt5 with Y location 0 and random X location (assign old location of plt1 to old location of plt3)
	addi $s1, $zero, 6
	sw $s1, plt5Y
	
	addi $s1, $zero, 1
	sw $s1, plt5Flag
	
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	jal l2_Random_x_plt_generator
	lw $ra, 0($sp)	
	addi $sp, $sp, 4
	sw $t1, plt5X
	sw $s5, plt5LY
	sw $s6, plt5LX
	jr $ra
	

l2_check_collision:
	# check if y location of doodle overlap with any platform
	lw $s1, doodleY
	addi $s4, $s1, 2
	beq $s4, 32, Game_over
	
	lw $s1, doodleY
	addi $s1, $s1, 3
	
	lw $s2, plt4Y
	lw $t6, plt4X
	beq $s1, $s2, l2_check_fragile4_steptwo
	
	lw $s2, plt5Y
	lw $t6, plt5X
	beq $s1, $s2, l2_check_fragile5_steptwo
	
	lw $s2, plt3Y
	lw $t6, plt3X
	beq $s1, $s2, l2_check_collision_steptwo
	
	lw $s2, plt2Y
	lw $t6, plt2X
	beq $s1, $s2, l2_check_collision_steptwo
	
	lw $t6, plt1X
	lw $s2, plt1Y
	beq $s1, $s2, l2_check_collision_steptwo
	
	# if no collision, directly draw elements
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	jal l2_redraw_screen
	lw $ra, 0($sp)
	j l2_location_update


l2_check_fragile4_steptwo:
	lw $s1, doodleX
	addi $s4, $s1, 2
	addi $s2, $t6, 0 #lower bound of platform x location
	addi $s3, $t6, 3 #upper bound of platform x location
	blt $s4, $s2, l2_check_stepthree # no collision
	bgt $s1, $s3, l2_check_stepthree # no collision
	
	add $s0, $zero, $zero
	sw $s0, plt4Flag
	lw $t1, plt4X
	lw $t2, plt4Y
	j l2_touch_fragileplt
	
	
l2_check_stepthree:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	jal l2_redraw_screen
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	j l2_location_update
		
	
l2_check_fragile5_steptwo:
	lw $s1, doodleX
	addi $s4, $s1, 2
	addi $s2, $t6, 0 #lower bound of platform x location
	addi $s3, $t6, 3 #upper bound of platform x location
	blt $s4, $s2,  l2_check_stepthree# no collision
	bgt $s1, $s3, l2_check_stepthree # no collision
	
	add $s0, $zero, $zero
	sw $s0, plt5Flag
	lw $t1, plt5X
	lw $t2, plt5Y
	j l2_touch_fragileplt
			
l2_touch_fragileplt:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	jal Calcuate_address #calculate extra address need to add to origin and store in t3
	lw $ra, 0($sp)
	lw $t0, displayAddress
	add $t3, $t0, $t3
	jal l2_DeletePlatform
	lw $ra, 0($sp)
	

	#move the doodle downward first
	lw $t1, doodleLX
	lw $t2, doodleLY
	jal Calcuate_address
	lw $ra, 0($sp)
	lw $t0, displayAddress
	add $t3, $t0, $t3
	add $t0, $zero, $t3
	jal Delete_doodle
	lw $ra, 0($sp)
	
	lw $t1, doodleX
	lw $t2, doodleY
	jal Calcuate_address
	lw $ra, 0($sp)
	lw $t0, displayAddress
	add $t3, $t0, $t3
	add $t0, $zero, $t3
	jal Draw_doodle
	lw $ra, 0($sp)
	
	lw $s1, doodleX
	lw $s2, doodleY
	sw $s1, doodleLX
	sw $s2, doodleLY
	
	
	addi $sp, $sp, 4
	
	j l2_location_update
	
			
	
l2_check_collision_steptwo: # y location of doodle overlap with one of the platform
	#$s3 stores the location of the potential collision platform
	lw $s1, doodleX
	addi $s4, $s1, 2
	addi $s2, $t6, 0 #lower bound of platform x location
	addi $s3, $t6, 3 #upper bound of platform x location
	blt $s4, $s2, l2_check_stepthree # no collision
	bgt $s1, $s3, l2_check_stepthree # no collision
	
	lw $s1, doodleY
	addi $s1, $s1, 3
	
	lw $s2, plt3Y
	beq $s1, $s2, l2_check_if_addscore
	
	lw $s2, plt2Y
	beq $s1, $s2, l2_check_if_addscore
	
	lw $s2, plt1Y
	beq $s1, $s2, l2_check_if_addscore
	

l2_check_if_addscore:
	lw $s0, flag
	beq $s0, 1, l2_extra_check
	
	
	# case if jump back to previous platform: no score added
	lw $s1, prevCollisionY
	beq $s1, $s2, l2_resstart_jump
	
	# jump to another platform, score added and update previous Collision platform Y location
	sw $s2, prevCollisionY
	j l2_add_score
	
	
l2_extra_check:
	lw $s1, prevCollisionY
	sw $s2, prevCollisionY
	beq $s1, 31, l2_add_score # add score if previous reach the bottom platform
	j l2_resstart_jump
	
l2_add_score:
	lw $t0, score
	addi $t0, $t0, 1
	sw $t0, score
	
	add $s0, $zero, $zero
	sw $s0, flag
	
	addi $t0, $t0, -1
	beq $t0, 5, delete_five
	beq $t0, 6, delete_six
	beq $t0, 7, delete_seven
	beq $t0, 8, delete_eight
	beq $t0, 9, delete_nine
	j l2_resstart_jump


l2_resstart_jump:	
	# no change to platforms
	# reassign the height that the doodle can jump 
	# location has been updated
	add $s0, $zero, $zero
	sw $s0, flag
	
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	jal Random_height_generator
	lw $ra, 0($sp)
	sw $t4, Height
	jal l2_redraw_screen
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	j l2_location_update
	
	
draw_wow:
	lw $s0, displayAddress
	lw $a0, grayColor
	addi $s0, $s0, 1440
	sw $a0, 0($s0)
	sw $a0, 12($s0)
	sw $a0, 128($s0)
	sw $a0, 136($s0)
	sw $a0, 256($s0)
	sw $a0, 264($s0)
	sw $a0, 384($s0)
	sw $a0, 392($s0)
	sw $a0, 516($s0)

	addi $s0, $s0, 16
	sw $a0, 8($s0)
	sw $a0, 128($s0)
	sw $a0, 136($s0)
	sw $a0, 256($s0)
	sw $a0, 264($s0)
	sw $a0, 384($s0)
	sw $a0, 392($s0)
	sw $a0, 516($s0)
	
	addi $s0, $s0, 16
	sw $a0, 0($s0)
	sw $a0, 4($s0)
	sw $a0, 8($s0)
	sw $a0, 12($s0)
	sw $a0, 128($s0)
	sw $a0, 140($s0)
	sw $a0, 256($s0)
	sw $a0, 268($s0)
	sw $a0, 384($s0)
	sw $a0, 396($s0)
	sw $a0, 512($s0)
	sw $a0, 516($s0)
	sw $a0, 520($s0)
	sw $a0, 524($s0)
	
	addi $s0, $s0, 20
	sw $a0, 0($s0)
	sw $a0, 12($s0)
	sw $a0, 128($s0)
	sw $a0, 136($s0)
	sw $a0, 256($s0)
	sw $a0, 264($s0)
	sw $a0, 384($s0)
	sw $a0, 392($s0)
	sw $a0, 516($s0)

	addi $s0, $s0, 16
	sw $a0, 8($s0)
	sw $a0, 128($s0)
	sw $a0, 136($s0)
	sw $a0, 256($s0)
	sw $a0, 264($s0)
	sw $a0, 384($s0)
	sw $a0, 392($s0)
	sw $a0, 516($s0)

	jr $ra
	
	
delete_wow:
	lw $s0, displayAddress
	lw $a0, bgdColor
		addi $s0, $s0, 1440
	sw $a0, 0($s0)
	sw $a0, 12($s0)
	sw $a0, 128($s0)
	sw $a0, 136($s0)
	sw $a0, 256($s0)
	sw $a0, 264($s0)
	sw $a0, 384($s0)
	sw $a0, 392($s0)
	sw $a0, 516($s0)

	addi $s0, $s0, 16
	sw $a0, 8($s0)
	sw $a0, 128($s0)
	sw $a0, 136($s0)
	sw $a0, 256($s0)
	sw $a0, 264($s0)
	sw $a0, 384($s0)
	sw $a0, 392($s0)
	sw $a0, 516($s0)
	
	addi $s0, $s0, 16
	sw $a0, 0($s0)
	sw $a0, 4($s0)
	sw $a0, 8($s0)
	sw $a0, 12($s0)
	sw $a0, 128($s0)
	sw $a0, 140($s0)
	sw $a0, 256($s0)
	sw $a0, 268($s0)
	sw $a0, 384($s0)
	sw $a0, 396($s0)
	sw $a0, 512($s0)
	sw $a0, 516($s0)
	sw $a0, 520($s0)
	sw $a0, 524($s0)
	
	addi $s0, $s0, 20
	sw $a0, 0($s0)
	sw $a0, 12($s0)
	sw $a0, 128($s0)
	sw $a0, 136($s0)
	sw $a0, 256($s0)
	sw $a0, 264($s0)
	sw $a0, 384($s0)
	sw $a0, 392($s0)
	sw $a0, 516($s0)

	addi $s0, $s0, 16
	sw $a0, 8($s0)
	sw $a0, 128($s0)
	sw $a0, 136($s0)
	sw $a0, 256($s0)
	sw $a0, 264($s0)
	sw $a0, 384($s0)
	sw $a0, 392($s0)
	sw $a0, 516($s0)

	jr $ra

####################################random value generation######################################################

	

