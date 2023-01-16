' Billiard ball simulator
' Created by Nelis Franken
' -----------------------------------------------------------
' Sphere (billiard ball) header file
' -----------------------------------------------------------

Type mySphere 

		As Single weight 
		As Single mass 
		As Single radius 
		As Single fC 
		As Single accellSize 
		As Single forceSize 
		As Single speedSize 
		As Single speedDif 
		As Single rotation 
		As vector3 speed 
		As vector3 position 
		As vector3 accell 
		As vector3 force 
		As vector3 reflected 
		As BOOL collided 
		As BOOL isRolling 
		As BOOL inPlay 

		'Declare Sub mySphere() 
		Declare Sub mySpheres(posX As Single , posY As Single , posZ As Single) 
		Declare Sub resetValuesToZero() 
		Declare Sub setDefaults() 
		Declare Sub setPos(posX As Single , posY As Single , posZ As Single) 
		Declare Sub setSpeed(speedX As Single , speedY As Single , speedZ As Single) 
		Declare Function roll() As BOOL 
		Declare Sub updateSpeedSize() 
		Declare Function getSpeedSize() As Single 
		Declare Function determineDistance(testBall As mySphere) As Single 
		Declare Function collides(testBall As mySphere) As BOOL 

End Type 



