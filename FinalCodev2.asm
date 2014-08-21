; SimpleRobotProgram.asm
; Created by Kevin Johnson
; (no copyright applied; edit freely, no attribution necessary)
; This program:

;ROBOT 65

	ORG     &H000		;Begin program at x000
Init:
	; Always a good idea to make sure the robot
	; stops in the event of a reset.
	LOAD    Zero
	OUT     LVELCMD     ; Stop motors
	OUT     RVELCMD
	OUT     SONAREN     ; Disable sonar (optional)

	CALL    SetupI2C    ; Configure the I2C
	CALL    BattCheck   ; Get battery voltage (and end if too low).
	OUT     SSEG2       ; Display batt voltage on SS

	LOAD    Zero
	ADDI    &H17        ; arbitrary reminder to toggle SW17
	OUT     SSEG1
	
	LOAD Five
	OUT LCD
	
WaitForUser:
	IN      XIO         ; contains KEYs and SAFETY
	AND     StartMask   ; mask with 0x10100 : KEY3 and SAFETY
	XOR     Mask4       ; KEY3 is active low; invert SAFETY to match
	JPOS    WaitForUser ; one of those is not ready, so try again

	
	
	
Main:

	CALL ResetInitConditions

	CALL keepMovingReverse		
	CALL keepMovingForward      
	CALL shortJobDebug			 ; Pick (2,3) Drop (1,3)
 	CALL medJobDebug			 ; Pick (3,3) Drop (1,4)
	CALL longJobDebug			 ; Pick (5,1) Drop (1,5)
		
	
	;Selects jobs based on switches
	IN 	 	Switches
	ADDI 	-1
	JZERO	Job1

	
	IN 	 	Switches
	ADDI 	-2
	JZERO	Job2


	IN 	 	Switches
	ADDI 	-4
	JZERO	Job3

	IN 	 	Switches
	ADDI 	-8
	JZERO	Job4

	
	IN 	 	Switches
	ADDI 	-16
	JZERO	Job5

	
	IN 	 	Switches
	ADDI 	-32
	JZERO	Job6

	
	IN 	 	Switches
	ADDI 	-64
	JZERO	Job7


	IN 	 	Switches
	ADDI 	-128
	JZERO	Job8

	
	LOAD Zero
	ADDI -1
	OUT LCD
	JUMP waitforuser
	
	Job1:
	LOAD ForgetMe
	OUT  UART
	CALL Buffer
	LOAD Reporting
	OUT  UART
	Call Buffer
	LOAD Picked1
	STORE Picktemp
	LOAD Dropped1
	STORE Droptemp
	LOAD Reqjob1
	CALL doJob
	CALL waitforadjustment
	
		
	Job2:
	LOAD Picked2
	STORE Picktemp
	LOAD Dropped2
	STORE Droptemp
	LOAD Reqjob2
	CALL doJob
	CALL waitforadjustment
	
	Job3:
	LOAD Picked3
	STORE Picktemp
	LOAD Dropped3
	STORE Droptemp
	LOAD Reqjob3
	CALL doJob
	CALL waitforadjustment
	
	Job4:
	LOAD Picked4
	STORE Picktemp
	LOAD Dropped4
	STORE Droptemp
	LOAD Reqjob4
	CALL doJob
	CALL waitforadjustment
	
	Job5:
	LOAD Picked5
	STORE Picktemp
	LOAD Dropped5
	STORE Droptemp
	LOAD Reqjob5
	CALL doJob
	CALL waitforadjustment
	
	Job6:
	LOAD Picked6
	STORE Picktemp
	LOAD Dropped6
	STORE Droptemp
	LOAD Reqjob6
	CALL doJob
	CALL waitforadjustment
	
	Job7:
	LOAD Picked7
	STORE Picktemp
	LOAD Dropped7
	STORE Droptemp
	LOAD Reqjob7
	CALL doJob
	CALL waitforadjustment
	
	Job8:
	LOAD Picked8
	STORE Picktemp
	LOAD Dropped8
	STORE Droptemp
	LOAD Reqjob8
	CALL doJob
	CALL CLOCKOUT
	
	JUMP 	WaitForUser
	
CLOCKOUT:
	LOAD SENDDONE
	OUT  UART
	CALL WAIT1
	RETURN	
	
ResetInitConditions:
OUT Resetodo
LOAD One
STORE xCurr
STORE ycurr
RETURN

SignalBeep:
Call wait1
LOAD Three
OUT BEEP
CALL wait1
LOAD Zero
OUT Beep
CALL wait1
REturn



keepMovingReverse:
LOAD LRFast
OUT LVELCMD
LOAD RRFast
OUT RVELCMD
jump KeepMovingReverse

keepMovingForward:
LOAD LFFast
OUT LVELCMD
LOAD RFFast
OUT RVELCMD
jump KeepMovingForward


WaitForAdjustment:
	LOAD FFAST
	OUT LVELCMD
	OUT RVELCMD
	IN      XIO         ; contains KEYs and SAFETY
	AND     StartMask   ; mask with 0x10100 : KEY3 and SAFETY
	XOR     Mask4       ; KEY3 is active low; invert SAFETY to match
	JPOS    WaitForUser ; one of those is not ready, so try again
RETURN

doJob:
	OUT  UART
	CALL Buffer
	CALL StoreJob

	CALL PickJob
	LOAD Picktemp
	OUT  UART
	OUT  LCD
	CALL SignalBeep
	
	CALL DropJob
	LOAD Droptemp
	OUT  LCD
	OUT  UART
	CALL SignalBeep
	CALL ReturnHome
RETURN
	
StoreJob:
	IN UART
	AND AllSonar
	STORE PickY ;inverted
	CALL Buffer
	IN UART
	AND AllSonar
	STORE PickX
	CALL Buffer
	IN UART 
	AND AllSonar
	STORE DropY
	CALL Buffer
	IN UART 
	AND AllSonar
	STORE DropX
	CALL Buffer
	IN UART
	AND AllSonar
	STORE Checksum
	CALL Buffer
	RETURN
	
PickJob:
	LOAD 	PickX
	STORE 	XTarget
	LOAD	PickY
	STORE	YTarget
	
	CALL 	CalcDifferences
	CALL	MoveX
	CALL 	Buffer
	CALL	TurnCW90
	CALL	Buffer
	CALL	MoveY
	CALL 	Buffer
	
	RETURN
	

	
DropJob:
    LOAD 	DropX
	STORE 	XTarget
	LOAD	DropY
	STORE	YTarget
	CALL	CalcDifferences
	
	CALL 	MoveY
	CALL 	Buffer
	CALL	TurnCCW90
	CALL 	Buffer
	CALL 	MoveX
	
	RETURN
	
ReturnHome:	
	LOAD 	One
	STORE 	Ytarget
	STORE	XTarget
	CALL 	CalcDifferences
	CALL 	MoveX
	
	RETURN
	
	
WaitForPress: ;THIS NEEDS TO BE TESTED
	IN      XIO         ; contains KEYs and SAFETY
	AND     StartMask   ; mask with 0x10100 : KEY3 and SAFETY
	JPOS    WaitForPress ; one of those is not ready, so try again
	RETURN
	
	
	
;_____________________________________________________
MoveX:
	LOAD 	xDiff
	JPOS	goRight
	JNEG	goLeft
	JZERO	exitMoveX
	
	;moves backwards until it reaches the target location
goRight:
	
	CALL MoveBackward
	LOAD xCurr
	ADDI 1
	STORE xCurr
	
	LOAD xDiff
	ADDI -1
	STORE xDiff
	
	JZERO exitMoveX
	JUMP goRight
	
goLeft:		

	CALL MoveForward
	LOAD xCurr
	ADDI -1
	STORE xCurr
	
	LOAD xDiff
	ADDI 1
	STORE xDiff
	
	JZERO exitMoveX
	JUMP goLeft
	
	
exitMoveX:
	RETURN
	
;_____________________________________________________	
	
MoveY:
	LOAD	yDiff
	JPOS	goDown
	JNEG	goUp
	JZERO   exitMoveY
	
goUp:
	CALL MoveForward
	LOAD yCurr
	ADDI -1
	STORE yCurr
	
	LOAD yDiff
	ADDI 1
	STORE yDiff
	
	JZERO exitMoveY
	JUMP goUp

goDown:
	CALL MoveBackward
	LOAD yCurr
	ADDI 1
	STORE yCurr
	
	LOAD yDiff
	ADDI -1
	STORE yDiff
	
	JZERO exitMoveY
	JUMP goDown
	
exitMoveY:
	RETURN

;______________________________________________________
;Calculates the differences in the current x and y coordinates from their target location

calcDifferences:
	LOAD 	XTarget
	SUB		xCurr
	STORE   xDiff
	
	LOAD 	YTarget
	SUB		yCurr
	STORE	yDiff
	
	RETURN
	
;____________________________________________________
	
TurnCCW90:
	OUT		RESETODO
CCW:
	LOAD	RFast
	OUT		LVELCMD
	LOAD	FFast
	OUT		RVELCMD
	IN RPOS
	ADDI 51			;SHIFT SO THAT THE STARTING POSITION IS 50, OFFSET BY THIS MUCH
	SUB CCWcond		;TURN CONDITION
	JNEG CCW
	
LOAD Fslow
OUT LVELCMD
OUT RVELCMD
LOAD Zero
OUT LVELCMD
OUT RVELCMD

RETURN

TurnCW90:
	OUT RESETODO
CW:
	LOAD	RFast
	OUT		RVELCMD
	LOAD	FFast
	OUT		LVELCMD
	IN LPOS
	ADDI 51			;SHIFT SO THAT THE STARTING POSITION IS 50, OFFSET BY THIS MUCH
	SUB CWcond		;TURN CONDITION
	
	JNEG CW
	
	LOAD Fslow
	OUT LVELCMD
	OUT RVELCMD
	LOAD Zero
	OUT LVELCMD
	OUT RVELCMD
RETURN

	

	
MoveForward:
	OUT     RESETODO    ; reset odometry in case wheels moved after programming
Go2ft:
	LOAD    RFFast       ; Very slow forward movement
	OUT     RVELCMD     ; commmand motors
	LOAD 	LFfast
	OUT     LVELCMD

	
	IN      XPOS        ; get current X position
	SUB     TwoFeet     ; check the distance
	JNEG    Go2ft       ; not there yet; keep checking
	; at this point, we're past the desired distance
	LOAD    Zero
	OUT     LVELCMD     ; stop
	OUT     RVELCMD
	RETURN

	
	
	
MoveBackward:
	OUT	RESETODO

Go2ftBack:
	LOAD    LRFast       ; Very slow forward movement
	OUT     LVELCMD     ; commmand motors
	LOAD	RRFast
	OUT     RVELCMD

	
	IN      XPOS        ; get current X position
	ADD     TwoFeet     ; check the distance
	JPOS    Go2ftBack   ; not there yet; keep checking
	; at this point, we're past the desired distance
	LOAD    Zero
	OUT     LVELCMD     ; stop
	OUT     RVELCMD
	RETURN
 
	
;***** SUBROUTINES

Buffer:
	OUT     TIMER
Bloop:
	IN      TIMER
	ADDI    -3
	JNEG    Wloop
	RETURN

; Subroutine to wait (block) for 1 second
Wait1:
	OUT     TIMER
Wloop:
	IN      TIMER
	OUT     LEDS
	ADDI    -10
	JNEG    Wloop
	RETURN

	
; This subroutine will get the battery voltage,
; and stop program execution if it is too low.
; SetupI2C must be executed prior to this.
BattCheck:
	CALL    GetBattLvl 
	SUB     MinBatt
	JNEG    DeadBatt
	ADD     MinBatt     ; get original value back
	RETURN
; If the battery is too low, we want to make
; sure that the user realizes it...
DeadBatt:
	LOAD    Four
	OUT     BEEP        ; start beep sound
	CALL    GetBattLvl  ; get the battery level
	OUT     SSEG1       ; display it everywhere
	OUT     SSEG2
	OUT     LCD
	LOAD    Zero
	ADDI    -1          ; 0xFFFF
	OUT     LEDS        ; all LEDs on
	OUT     GLEDS
	CALL    Wait1       ; 1 second
	Load    Zero
	OUT     BEEP        ; stop beeping
	LOAD    Zero
	OUT     LEDS        ; LEDs off
	OUT     GLEDS
	CALL    Wait1       ; 1 second
	JUMP    DeadBatt    ; repeat forever
	
; Subroutine to configure the I2C for reading batt voltage
; Only needs to be done once after each reset.
SetupI2C:
	LOAD    I2CWCmd     ; 0x1190 (write 1B, read 1B, addr 0x90)
	OUT     I2C_CMD     ; to I2C_CMD register
	LOAD    Zero        ; 0x0000 (A/D port 0, no increment)
	OUT     I2C_DATA    ; to I2C_DATA register
	OUT     I2C_RDY     ; start the communication
	CALL    BlockI2C    ; wait for it to finish
	RETURN
	
; Subroutine to read the A/D (battery voltage)
; Assumes that SetupI2C has been run
GetBattLvl:
	LOAD    I2CRCmd     ; 0x0190 (write 0B, read 1B, addr 0x90)
	OUT     I2C_CMD     ; to I2C_CMD
	OUT     I2C_RDY     ; start the communication
	CALL    BlockI2C    ; wait for it to finish
	IN      I2C_DATA    ; get the returned data
	RETURN

; Subroutine to block until I2C device is idle
BlockI2C:
	IN      I2C_RDY;   ; Read busy signal
	JPOS    BlockI2C    ; If not 0, try again
	RETURN              ; Else return

ShortJobDebug:

	LOAD pickXshort
	STORE pickX
	LOAD pickYshort
	STORE pickY
	
	LOAD dropXShort
	STORE dropX
	LOAD dropYShort
	STORE dropY
	
MedJobDebug:

	LOAD pickXMed
	STORE pickX
	LOAD pickYMed
	STORE pickY
	
	LOAD dropXMed
	STORE dropX
	LOAD dropYMed
	STORE dropY
	
LongJobDebug:	

	LOAD pickXLong
	STORE pickX
	LOAD pickYLong
	STORE pickY
	
	LOAD dropXLong
	STORE dropX
	LOAD dropYLong
	STORE dropY
	
	
doJobDebug:
	CALL PickJob
	CALL SignalBeep
	CALL DropJob
	CALL SignalBeep
	CALL ReturnHome
	JUMP waitForUser
RETURN


	
	
	
; This is a good place to put variables
Temp:     DW 0 ; "Temp" is not a great name, but can be helpful

; Having some constants can be very useful
Zero:     DW 0
One:      DW 1
Two:      DW 2
Three:    DW 3
Four:     DW 4
Five:     DW 5
Six:      DW 6
Seven:    DW 7
Eight:    DW 8
Nine:     DW 9
Ten:      DW 10
FSlow:    DW 100       ; 100 is about the lowest value that will move at all
RSlow:    DW -100
FFast:    DW 500       ; 500 is a fair clip (511 is max)
RFast:    DW -500



; Constants for UART communication
Hello:          DW &H01
TReporting:     DW &H80
Reporting:      DW &H10
Reqjob1:        DW &H21
Reqjob2:        DW &H22
Reqjob3:        DW &H23
Reqjob4:        DW &H24
Reqjob5:        DW &H25
Reqjob6:        DW &H26
Reqjob7:        DW &H27
Reqjob8:        DW &H28
Picked1:        DW &H31
Picked2:        DW &H32
Picked3:        DW &H33
Picked4:        DW &H34
Picked5:        DW &H35
Picked6:        DW &H36
Picked7:        DW &H37
Picked8:        DW &H38
Dropped1:       DW &H41
Dropped2:       DW &H42
Dropped3:       DW &H43
Dropped4:       DW &H44
Dropped5:       DW &H45
Dropped6:       DW &H46
Dropped7:       DW &H47
Dropped8:       DW &H48
Timeleft:       DW &H50
SendDone:       DW &H60
Testjobs:       DW &H80
ForgetMe:       DW &H90
ImAlive:        DW &H00
Picktemp:       DW &H00
Droptemp:       DW &H00

;Variables are here
Xdiff:	  DW 0
Ydiff:	  DW 0

xCurr:		DW 1
yCurr:		DW 1
THET:		DW 0
LPOSEXIT:	DW 0
RPOSEXIT:	DW 0




;Temporary constants for checking locations
PickX:	DW	5
PickY:	DW  5
DropX:	DW	5
DropY:	DW	5
Checksum:   DW 0
XTarget:	DW 0
YTarget:	DW 0



; Masks of multiple bits can be constructed by, for example,
; LOAD Mask0; OR Mask2; OR Mask4, etc.
Mask0:    DW &B00000001
Mask1:    DW &B00000010
Mask2:    DW &B00000100
Mask3:    DW &B00001000
Mask4:    DW &B00010000
Mask5:    DW &B00100000
Mask6:    DW &B01000000
Mask7:    DW &B10000000
StartMask: DW &B10100
AllSonar: DW &B11111111



MinBatt:  DW 110        ; 11V - minimum safe battery voltage
I2CWCmd:  DW &H1190     ; write one byte, read one byte, addr 0x90
I2CRCmd:  DW &H0190     ; write nothing, read one byte, addr 0x90

; IO address space map
SWITCHES: EQU &H00  ; slide switches
LEDS:     EQU &H01  ; red LEDs
TIMER:    EQU &H02  ; timer, usually running at 10 Hz
XIO:      EQU &H03  ; pushbuttons and some misc. inputs
SSEG1:    EQU &H04  ; seven-segment display (4-digits only)
SSEG2:    EQU &H05  ; seven-segment display (4-digits only)
LCD:      EQU &H06  ; primitive 4-digit LCD display
GLEDS:    EQU &H07  ; Green LEDs (and Red LED16+17)
BEEP:     EQU &H0A  ; Control the beep
LPOS:     EQU &H80  ; left wheel encoder position (read only)
LVEL:     EQU &H82  ; current left wheel velocity (read only)
LVELCMD:  EQU &H83  ; left wheel velocity command (write only)
RPOS:     EQU &H88  ; same values for right wheel...
RVEL:     EQU &H8A  ; ...
RVELCMD:  EQU &H8B  ; ...
I2C_CMD:  EQU &H90  ; I2C module's CMD register,
I2C_DATA: EQU &H91  ; ... DATA register,
I2C_RDY:  EQU &H92  ; ... and BUSY register
UART:     EQU &H98  ; The basic UART interface provided
; 0x98-0x9F are reserved for any additional UART functions you create
SONAR:    EQU &HA0  ; base address for more than 16 registers....
DIST0:    EQU &HA8  ; the eight sonar distance readings
DIST1:    EQU &HA9  ; ...
DIST2:    EQU &HAA  ; ...
DIST3:    EQU &HAB  ; ...
DIST4:    EQU &HAC  ; ...
DIST5:    EQU &HAD  ; ...
DIST6:    EQU &HAE  ; ...
DIST7:    EQU &HAF  ; ...
SONAREN:  EQU &HB2  ; register to control which sonars are enabled
XPOS:     EQU &HC0  ; Current X-position (read only)
YPOS:     EQU &HC1  ; Y-position
THETA:    EQU &HC2  ; Current rotational position of robot (0-701)
RESETODO: EQU &HC3  ; reset odometry to 0



;DEBUG COMMANDS
PickXShort: DW 2
PickYShort: DW 3
DropXShort: DW 1
DropYShort: DW 3

PickXMed:	DW 3
PickYMed:	DW 3
DropXMed:	DW 1
DropYMed:	DW 4

PickXLong:	DW 5
PickYLong:	DW 1
DropXLong:	DW 1
DropYLong:  DW 5




;Left Wheel:			Increasing absolute value makes it go faster
LFfast:		DW 483
LRfast:		DW -489

;Right Wheel:			DO NOT CHANGE THIS, ADJUST ONLY THE LEFT MOTOR
RFfast:		DW 500
RRfast:		DW -500

;Distance:		Choose a compromise, it will not work for all points, but 255 is a good compromise for longer jobs, only really fails on the short movements
TwoFeet:  	DW 255       ; ~2ft in 2.1mm units

;Turn Values, Increasing this makes it turn more
CCWcond: 	DW 123		; Increasing makes it turn more
CWcond:		DW 148	; Increasing makes it turn more -- previously 140