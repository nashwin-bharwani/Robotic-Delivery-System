; SimpleRobotProgram.asm
; Created by Kevin Johnson
; (no copyright applied; edit freely, no attribution necessary)
; This program:
; 1) performs some basic robot initialization
; 2) waits for the user to enable the motors and
; 3) press KEY3
; 4) moves forward ~2ft and stops
; 5) repeats 3-5


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
	

	
WaitForUser:
	IN      XIO         ; contains KEYs and SAFETY
	AND     StartMask   ; mask with 0x10100 : KEY3 and SAFETY
	XOR     Mask4       ; KEY3 is active low; invert SAFETY to match
	JPOS    WaitForUser ; one of those is not ready, so try again


	
Main:
    LOAD Six
    OUT  LCD
    call wait1

    ;call keepMoving
    

	;fails if it tries to do a different job
	CALL ResetInitConditions
	

	
    
    ;-------------------------------------------------------
    
   ; REMOVE THIS LINE RIGHT HERE
    LOAD ForgetMe
	OUT  UART
	CALL Wait1
    ;---------------------------------------------------------
	

	
	IN Switches
	out LCD
	CALL Wait1
	
	;LOAD TReporting ;THIS LOADS THE NON-RANDOM TEST JOB SET - change for final
	LOAD Reporting
	OUT  UART
	CALL Wait1
	
	;Decides which job to do
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
	LOAD Reqjob1
	CALL doJob
	CALL waitforadjustment
	
		
	Job2:
	LOAD Reqjob2
	CALL doJob
	CALL waitforadjustment
	
	Job3:
	LOAD Reqjob3
	CALL doJob
	CALL waitforadjustment
	
	Job4:
	LOAD Reqjob4
	CALL doJob
	CALL waitforadjustment
	
	Job5:
	LOAD Reqjob5
	CALL doJob
	CALL waitforadjustment
	
	Job6:
	LOAD Reqjob6
	CALL doJob
	CALL waitforadjustment
	
	Job7:
	LOAD Reqjob7
	CALL doJob
	CALL waitforadjustment
	
	Job8:
	LOAD Reqjob8
	CALL doJob
	CALL waitforadjustment
	
	JUMP 	WaitForUser
	
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



keepMoving:
LOAD LRFast
OUT LVELCMD
LOAD RRFast
OUT RVELCMD
jump KeepMoving




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
	CALL Wait1
	CALL StoreJob
	
	LOAD PickY
	OUT  LCD
	CALL Wait1
	LOAD PickX
	OUT  LCD
	CALL Wait1
	LOAD DropY
	OUT  LCD
	CALL Wait1
	LOAD DropX
	OUT  LCD
	
	CALL Wait1
	CALL PickJob
	LOAD Picked1
	OUT  UART
	OUT  LCD
	CALL SignalBeep
	
	CALL DropJob
	LOAD Dropped1
	OUT  LCD
	OUT  UART
	CALL SignalBeep
	CALL ReturnHome
RETURN
	
SonarCheck:
	LOAD Zero
	ADDI &b00001100	
	OUT SONAREN
	IN DIST2
	OUT LCD
	IN DIST3
	OUT SSEG1
	JUMP SonarCheck

Signal:
	CALL Wait1
	LOAD One
	OUT BEEP
	CALL Wait1
	LOAD Zero
	OUT BEEP
	CALL Wait1
	
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
	
	;CALL	Signal
	CALL	Wait1
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
	
	CALL Wait1
	RETURN
	
ReturnHome:	
	LOAD 	One
	STORE 	Ytarget
	STORE	XTarget
	CALL 	CalcDifferences
	CALL MoveX
	
	RETURN
	
WaitForPress: ;THIS NEEDS TO BE TESTED
	IN      XIO         ; contains KEYs and SAFETY
	AND     StartMask   ; mask with 0x10100 : KEY3 and SAFETY
	JPOS    WaitForPress ; one of those is not ready, so try again
	RETURN
	
	
PerformJob:
	LOAD 	PickX
	STORE 	XTarget
	LOAD	PickY
	STORE	YTarget
	
	CALL 	CalcDifferences
	CALL	MoveX
	CALL 	Buffer
	CALL	TurnCW90
	CALL	Buffer
	CALL	MoveYHardCode
	CALL 	Buffer
	
	;CALL	Signal
	CALL	Wait1
	
	LOAD 	DropX
	STORE 	XTarget
	LOAD	DropY
	STORE	YTarget
	CALL	CalcDifferences
	
	CALL 	MoveY
	CALL 	Buffer
	CALL	TurnCCW90
	CALL 	Buffer
	CALL 	MoveXHardCode
	
	CALL Wait1
	
	LOAD 	One
	STORE 	Ytarget
	STORE	XTarget
	CALL 	CalcDifferences
	CALL MoveX
	
	RETURN
	
	
	
MoveYHardCode:
	LOAD	yDiff
	JPOS	goDownH
	JNEG	goUpH
	JZERO   endMoveYH
	
goUpH:

	LOAD	yDiff
 	ADDI	1
 	JZERO	u1unit
 	ADDI	1
 	JZERO	u2unit
 	ADDI	1
 	JZERO	u3unit
 	ADDI	1
 	JZERO	u4unit

 u1unit:
 	CALL forward1Unit
	LOAD Zero
	STORE yDiff

	LOAD ycurr
	ADDI -1
	STORE ycurr
	JUMP endMoveYH
 	
u2unit:
 	CALL forward2Unit
	LOAD Zero
	STORE yDiff

	LOAD ycurr
	ADDI -2
	STORE ycurr
	JUMP endMoveYH
	
u3unit:
 	CALL forward3Unit
	LOAD Zero
	STORE yDiff

	LOAD ycurr
	ADDI -3
	STORE ycurr
	JUMP endMoveYH
	
u4unit:
 	CALL forward4Unit
	LOAD Zero
	STORE yDiff

	LOAD ycurr
	ADDI -4
	STORE ycurr
	JUMP endMoveYH
	
	
	
goDownH:

	LOAD	yDiff
 	ADDI	-1
 	JZERO	d1unit
 	ADDI	-1
 	JZERO	d2unit
 	ADDI	-1
 	JZERO	d3unit
 	ADDI	-1
 	JZERO	d4unit

d1unit:
 	CALL backward1Unit
	LOAD Zero
	STORE yDiff

	LOAD ycurr
	ADDI 1
	STORE ycurr
	JUMP endMoveYH
 	
d2unit:
 	CALL backward2Unit
	LOAD Zero
	STORE yDiff

	LOAD ycurr
	ADDI 2
	STORE ycurr
	JUMP endMoveYH
	
d3unit:
 	CALL backward3Unit
	LOAD Zero
	STORE yDiff

	LOAD ycurr
	ADDI 3
	STORE ycurr
	JUMP endMoveYH
	
d4unit:
 	CALL backward4Unit
	LOAD Zero
	STORE yDiff

	LOAD ycurr
	ADDI 4
	STORE ycurr
	JUMP endMoveYH	
	
endMoveYH:
RETURN	
	
	
	
	
	
	
; 
; 	CALL MoveForward
; 	LOAD yCurr
; 	ADDI -1
; 	STORE yCurr
; 	
; 	LOAD yDiff
; 	ADDI 1
; 	STORE yDiff
; 	
; 	JZERO exitMoveY
; 	JUMP goUp
; 
; goDownH:
; 	CALL MoveBackward
; 	LOAD yCurr
; 	ADDI 1
; 	STORE yCurr
; 	
; 	LOAD yDiff
; 	ADDI -1
; 	STORE yDiff
; 	
; 	JZERO exitMoveY
; 	JUMP goDown
; 	
; exitMoveY:
; 	RETURN
	
	
	
	

 MoveXHardCode:
 	LOAD 	xDiff
 	JPOS	goRightH
 	JNEG	goLeftH
 	JZERO	endMoveXH
 	
 goRightH:
 	LOAD	xDiff
 	ADDI	-1
 	JZERO	r1unit
 	ADDI	-1
 	JZERO	r2unit
 	ADDI	-1
 	JZERO	r3unit
 	ADDI	-1
 	JZERO	 r4unit
 	
	r1unit:
	
	CALL backward1Unit
	LOAD Zero
	STORE xDiff

	LOAD xcurr
	ADDI 1
	STORE xcurr
	JUMP endMoveXH
	
	r2unit:
	
	CALL backward2Unit
	LOAD Zero
	STORE xDiff

	LOAD xcurr
	ADDI 2
	STORE xcurr
	JUMP endMoveXH
	
	r3unit:
	
	CALL backward3Unit
	LOAD Zero
	STORE xDiff

	LOAD xcurr
	ADDI 3
	STORE xcurr
	JUMP endMoveXH
	
	r4unit:
	
	CALL backward4Unit
	LOAD Zero
	STORE xDiff
	
	LOAD xcurr
	ADDI 4
	STORE xcurr
	JUMP endMoveXH

	
goLeftH:
	LOAD	xDiff
 	ADDI	1
 	JZERO	l1unit
 	ADDI	1
 	JZERO	l2unit
 	ADDI	1
 	JZERO	l3unit
 	ADDI	1
 	JZERO	l4unit
 	
	l1unit:
	
	CALL forward1Unit
	LOAD Zero
	STORE xDiff

	LOAD xcurr
	ADDI -1
	STORE xcurr
	JUMP endMoveXH
	
	l2unit:
	
	CALL forward2Unit
	LOAD Zero
	STORE xDiff

	LOAD xcurr
	ADDI -2
	STORE xcurr
	JUMP endMoveXH
	
	l3unit:
	
	CALL forward3Unit
	LOAD Zero
	STORE xDiff

	LOAD xcurr
	ADDI -3
	STORE xcurr
	JUMP endMoveXH
	
	l4unit:
	
	CALL forward4Unit
	LOAD Zero
	STORE xDiff
	
	LOAD xcurr
	ADDI -4
	STORE xcurr
	JUMP endMoveXH
	
	
endMoveXH:
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
	ADDI -130		;TURN CONDITION
	JNEG CCW
	
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
	ADDI -160		;TURN CONDITION
	JNEG CW
	
	LOAD Zero
	OUT LVELCMD
	OUT RVELCMD
RETURN
    
Turn180:
		OUT		RESETODO
Spin180: LOAD    RSlow
    	OUT     LVELCMD
    	LOAD    FSlow
    	OUT     RVELCMD
    	IN      THETA
    	OUT     SSEG1
   		ADD    CCW180
    	JNEG    Spin180
    	LOAD    Zero
    	OUT     LVELCMD
    	OUT     RVELCMD    
    	RETURN

MoveForwardPos:
	OUT     RESETODO    ; reset odometry in case wheels moved after programming
Go2ftPos:
	LOAD    FFast       ; Very slow forward movement
	OUT     LVELCMD     ; commmand motors
	OUT     RVELCMD
	
	IN      RPOS        ; get current X position
	SUB     TwoFeetPos     ; check the distance
	OUT 	LCD
	JNEG    Go2ftPos       ; not there yet; keep checking
	
	; at this point, we're past the desired distance
	LOAD    Zero
	OUT     LVELCMD     ; stop
	OUT     RVELCMD
	RETURN
	
	
	
	
Forward1Unit:
	OUT     RESETODO    ; reset odometry in case wheels moved after programming

for1:
	LOAD    FFast       ; Very slow forward movement
	OUT     LVELCMD     ; commmand motors
	OUT     RVELCMD
	; display velocity just as FYI
	IN      LVEL        ; read left velocity
	STORE   Temp        ; save it
	IN      RVEL        ; read right velocity
	ADD     Temp        ; add to left velocity
	SHIFT   -1          ; divide by 2 (average)
	OUT     SSEG1       ; display it
	IN      XPOS        ; get current X position
	SUB     TwoFeet     ; check the distance
	JNEG    for1       ; not there yet; keep checking
	; at this point, we're past the desired distance
	LOAD    Zero
	OUT     LVELCMD     ; stop
	OUT     RVELCMD
	RETURN

Forward2Unit:
	OUT     RESETODO    ; reset odometry in case wheels moved after programming
for2:
	LOAD    FFast       ; Very slow forward movement
	OUT     LVELCMD     ; commmand motors
	OUT     RVELCMD
	; display velocity just as FYI
	IN      LVEL        ; read left velocity
	STORE   Temp        ; save it
	IN      RVEL        ; read right velocity
	ADD     Temp        ; add to left velocity
	SHIFT   -1          ; divide by 2 (average)
	OUT     SSEG1       ; display it
	IN      XPOS        ; get current X position
	SUB     FourFeet     ; check the distance
	JNEG    for2       ; not there yet; keep checking
	; at this point, we're past the desired distance
	LOAD    Zero
	OUT     LVELCMD     ; stop
	OUT     RVELCMD
	RETURN		
	
Forward3Unit:
	OUT     RESETODO    ; reset odometry in case wheels moved after programming

for3:
	LOAD    FFast       ; Very slow forward movement
	OUT     LVELCMD     ; commmand motors
	OUT     RVELCMD
	; display velocity just as FYI
	IN      LVEL        ; read left velocity
	STORE   Temp        ; save it
	IN      RVEL        ; read right velocity
	ADD     Temp        ; add to left velocity
	SHIFT   -1          ; divide by 2 (average)
	OUT     SSEG1       ; display it
	IN      XPOS        ; get current X position
	SUB     SixFeet     ; check the distance
	JNEG    for3       ; not there yet; keep checking
	; at this point, we're past the desired distance
	LOAD    Zero
	OUT     LVELCMD     ; stop
	OUT     RVELCMD
	RETURN
	
Forward4Unit:
	OUT     RESETODO    ; reset odometry in case wheels moved after programming

for4:
	LOAD    FFast       ; Very slow forward movement
	OUT     LVELCMD     ; commmand motors
	OUT     RVELCMD
	; display velocity just as FYI
	IN      LVEL        ; read left velocity
	STORE   Temp        ; save it
	IN      RVEL        ; read right velocity
	ADD     Temp        ; add to left velocity
	SHIFT   -1          ; divide by 2 (average)
	OUT     SSEG1       ; display it
	IN      XPOS        ; get current X position
	SUB     EightFeet     ; check the distance
	JNEG    for4       ; not there yet; keep checking
	; at this point, we're past the desired distance
	LOAD    Zero
	OUT     LVELCMD     ; stop
	OUT     RVELCMD
	RETURN	
; 

Backward1Unit:
	OUT     RESETODO    ; reset odometry in case wheels moved after programming

back1:
	LOAD    RFast       ; Very slow forward movement
	OUT     LVELCMD     ; commmand motors
	OUT     RVELCMD
	
	IN      XPOS        ; get current X position
	ADD     TwoFeet     ; check the distance
	OUT 	LCD
	JPOS    back1   ; not there yet; keep checking
	
	; at this point, we're past the desired distance
	LOAD    Zero
	OUT     LVELCMD     ; stop
	OUT     RVELCMD
	RETURN


Backward2Unit:
	OUT     RESETODO    ; reset odometry in case wheels moved after programming

back2:
	LOAD    RFast       ; Very slow forward movement
	OUT     LVELCMD     ; commmand motors
	OUT     RVELCMD
	
	IN      XPOS        ; get current X position
	ADD     FourFeet     ; check the distance
	OUT 	LCD
	JPOS    back2   ; not there yet; keep checking
	
	; at this point, we're past the desired distance
	LOAD    Zero
	OUT     LVELCMD     ; stop
	OUT     RVELCMD
	RETURN
	
	
Backward3Unit:
	OUT     RESETODO    ; reset odometry in case wheels moved after programming

back3:
	LOAD    RFast       ; Very slow forward movement
	OUT     LVELCMD     ; commmand motors
	OUT     RVELCMD
	
	IN      XPOS        ; get current X position
	ADD     sixFeet    ; check the distance
	OUT 	LCD
	JPOS    back3   ; not there yet; keep checking
	
	; at this point, we're past the desired distance
	LOAD    Zero
	OUT     LVELCMD     ; stop
	OUT     RVELCMD
	RETURN
	
	
Backward4Unit:
	OUT     RESETODO    ; reset odometry in case wheels moved after programming

back4:
	LOAD    RFast       ; Very slow forward movement
	OUT     LVELCMD     ; commmand motors
	OUT     RVELCMD
	
	IN      XPOS        ; get current X position
	ADD     EightFeet     ; check the distance
	OUT 	LCD
	JPOS    back4   ; not there yet; keep checking
	
	; at this point, we're past the desired distance
	LOAD    Zero
	OUT     LVELCMD     ; stop
	OUT     RVELCMD
	RETURN
	
	
	
	
	
	
MoveBackwardPos:
	OUT     RESETODO    ; reset odometry in case wheels moved after programming
Go2ftBackPos:
	LOAD    RFast       ; Very slow forward movement
	OUT     RVELCMD     ; commmand motors
	OUT     LVELCMD
	
	IN      RPOS        ; get current X position
	ADD     TwoFeetPos     ; check the distance
	OUT 	LCD
	JPOS    Go2ftBackPos   ; not there yet; keep checking
	
	; at this point, we're past the desired distance
	LOAD    Zero
	OUT     LVELCMD     ; stop
	OUT     RVELCMD
	RETURN

	
MoveForward:
	OUT     RESETODO    ; reset odometry in case wheels moved after programming
Go2ft:
	LOAD    RFFast       ; Very slow forward movement
	OUT     RVELCMD     ; commmand motors
	LOAD 	LFfast
	OUT     LVELCMD
	
	; display velocity just as FYI
	IN      LVEL        ; read left velocity
	STORE   Temp        ; save it
	IN      RVEL        ; read right velocity
	ADD     Temp        ; add to left velocity
	SHIFT   -1          ; divide by 2 (average)
	OUT     SSEG1       ; display it
	
	IN      XPOS        ; get current X position
	SUB     TwoFeet     ; check the distance
	JNEG    Go2ft       ; not there yet; keep checking
	; at this point, we're past the desired distance
	LOAD    Zero
	OUT     LVELCMD     ; stop
	OUT     RVELCMD
	RETURN

; 	
; MoveForwardBalanced:
; 	OUT     RESETODO    ; reset odometry in case wheels moved after programming
; 	OUT 	TIMER
; 
; ForwardTwoFeetBalanced:
; 	LOAD 	Rforward
; 	OUT		RVELCMD
; 	LOAD	Lforward
; 	OUT		LVELCMD
; 	
; 	IN 		TIMER
; 	JPOS	BalanceSpeedForward
; 
; EndForwardBalancing:
; 	IN      XPOS        ; get current X position
; 	SUB     TwoFeet     ; check the distance
; 	JNEG    ForwardTwoFeetBalanced       ; not there yet; keep checking	
; 	;------
; 	JUMP	ForwardTwoFeetBalanced
; 	;------
; 	JUMP	EndForwardMovement
; 	
; BalanceSpeedForward:
; 	IN		LVEL
; 	STORE	LCurrSpeed
; 	IN		RVEL
; 	STORE	RCurrSpeed
; 	
; 	IN 		LCurrSpeed
; 	SUB		RCurrSpeed
; 	OUT 	LCD
; 	
; 	ADDI	20
; 	JNEG	RtooFast
; 	ADDI	-20
; 	JPOS	LtooFast
; 	
; 	RtooFast:
; 	LOAD	Rforward
; 	ADDI	-1
; 	STORE	Rforward
; 	JUMP	EndForwardBalancing
; 	
; 	LtooFast:
; 	LOAD	Lforward
; 	ADDI	-1
; 	STORE	Lforward
; 	JUMP	EndForwardBalancing
; 	
; EndForwardMovement:	
; 	; at this point, we're past the desired distance
; 	LOAD    Zero
; 	OUT     LVELCMD     ; stop
; 	OUT     RVELCMD
; 	RETURN

BalanceSpeeds:
	OUT RESETODO
	OUT Timer
Move10ft:
	LOAD 	Rforward
	OUT     RVELCMD     ; commmand motors
	LOAD 	Lforward
	OUT     LVELCMD
	
	IN TIMER
	ADDI -10
	CALL Balance
	IN      RPOS        ; get current X position
	ADD     TwoFeetPos     ; check the distance
	OUT 	LCD
	JPOS    Move10ft   ; not there yet; keep checking
	
	; at this point, we're past the desired distance
	LOAD    Zero
	OUT     LVELCMD     ; stop
	OUT     RVELCMD	
	RETURN
	
	
	
	
	
	
	
	Balance:
	JNEG EndBalance
	IN RVEL
	STORE Rcurr
	IN LVEL
	STORE Lcurr
	
	LOAD Rcurr
	SUB Lcurr
	
	JPOS SlowR
	JNEG SlowL
	LOAD One
	OUT BEEP
	JUMP EndBalance
	
	SlowR:
	LOAD Rforward
	ADDI -1
	STORE Rforward
	JUMP EndBalance
	
	SlowL:
	LOAD Lforward
	ADDI -1
	STORE Lforward
	JUMP EndBalance
	
	EndBalance:
	RETURN
	
	 
MoveBackward:
	OUT	RESETODO

Go2ftBack:
	LOAD    LFFast       ; Very slow forward movement
	OUT     LVELCMD     ; commmand motors
	LOAD	RFFAst
	OUT     RVELCMD
	; display velocity just as FYI
	IN      LVEL        ; read left velocity
	STORE   Temp        ; save it
	IN      RVEL        ; read right velocity
	ADD     Temp        ; add to left velocity
	SHIFT   -1          ; divide by 2 (average)
	OUT     SSEG1       ; display it
	
	IN      XPOS        ; get current X position
	ADD     TwoFeet     ; check the distance
	JPOS    Go2ftBack   ; not there yet; keep checking
	; at this point, we're past the desired distance
	LOAD    Zero
	OUT     LVELCMD     ; stop
	OUT     RVELCMD
	RETURN
 
CalibrateSpeed:
	
	LOAD FFast
	STORE LFFast
	STORE RFFast	

cloop:
	LOAD LFFast
	OUT LVELCMD
	LOAD RFFast
	OUT RVELCMD
	OUT Timer
	
	IN      XPOS        ; get current X position
	SUB     4000
	JNEG 	cloop
	
	IN timer
	ADDI -1
	JPos Balancer
	JUMP Cloop
	
	; at this point, we're past the desired distance
	LOAD    Zero
	OUT     LVELCMD     ; stop
	OUT     RVELCMD
RETURN
	
Balancer:
		
	IN RPOS
	STORE temp
	IN LPOS
	
	SUB temp
	
	ADDI 30
	JNEG SlowRight
	
	ADDI -30
	JPOS SlowLeft
	
	JUMP cloop
	
	
	
	SlowRight:
	LOAD RFFast
	ADDI -1
	STORE RFFast
	JUMP Cloop
	
    
	SlowLeft:
	LOAD LFFast
	ADDI -1
	STORE LFFast
	Jump cloop
		
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

LFfast:		DW 476
LRfast:		DW -484

RFfast:		DW 500
RRfast:		DW -500

CW90:	  DW -600		;-526 originally
CCW180:	  DW -350
CCW90:	  DW -195
TurnTolerance: DW 100

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


;Variables are here
Xdiff:	  DW 0
Ydiff:	  DW 0

xCurr:		DW 1
yCurr:		DW 1
THET:		DW 0
LPOSEXIT:	DW 0
RPOSEXIT:	DW 0

Rforward:	DW 0
LForward:	DW 0
Rreverse:	DW 0
Lreverse:	DW 0

LCurrSpeed:	DW 0
RCurrSpeed:	DW 0

Lcurr:		DW 0
Rcurr:		DW 0




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
OneMeter: DW 476        ; one meter in 2.1mm units
HalfMeter: DW 238       ; half meter in 2.1mm units
TwoFeet:  DW 245        ; ~2ft in 2.1mm units
FourFeet: DW 525
SixFeet:	DW 805
EightFeet:	DW 1100

TwoFeetPos:	DW 530
FourFeetPos: DW 1300
SixFeetPos:	DW	1590
EightFeetPos: DW 2120
TenFeetPos:	DW 2650
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