' Billiard ball simulator
' Created by Nelis Franken
' -----------------------------------------------------------
' Sphere (billiard ball) implementation file
' -----------------------------------------------------------


Sub mySphere.resetValuesToZero() 

		weight = 0.0 
		mass = 0.0 
		radius = 0.0 
		fC = 0.0 
		accellSize = 0.0 
		forceSize = 0.0 
		speedSize = 0.0 
		speedDif = 0.0 
		rotation = 0.0 
		speed = Type<vector3>(0.0,0.0,0.0) 
		position = Type<vector3>(0.0,24.9,0.0) 
		accell = Type<vector3>(0.0,0.0,0.0) 
		force = Type<vector3>(0.0,0.0,0.0) 
		reflected = Type<vector3>(0.0,0.0,0.0) 
		collided = FALSE 
		inPlay = TRUE 

End Sub

'Sub mySphere.mySphere() 
'	mySphere.resetValuesToZero() 
'End Sub

Sub mySphere.mySpheres(posX As Single , posY As Single , posZ As Single) 
	resetValuesToZero() 
	position = Type<vector3>(posX, posY, posZ) 
End Sub

Sub mySphere.setDefaults() 

		speedSize = 0.0 
		mass = 0.0001 
		weight = mass * 9.81 
		fC = 0.00004 
		speedDif = 10000.0 
		radius = 1.5 
	
		collided = FALSE 
		inPlay = TRUE 
		force = speed 
		forceSize = Sqr((force.x)*(force.x) + (force.y)*(force.y) + (force.z)*(force.z)) 
	
		if (forceSize <> 0) Then 
			force.x = force.x * ((1.0 / forceSize) * (fC * weight)) 
			force.y = force.y * ((1.0 / forceSize) * (fC * weight)) 
			force.z = force.z * ((1.0 / forceSize) * (fC * weight)) 
		EndIf
	
		accell.x = (force.x * (1.0/mass)) * (-1.0) 
		accell.y = (force.y * (1.0/mass)) * (-1.0) 
		accell.z = (force.z * (1.0/mass)) * (-1.0) 
		
		accellSize = fC * 170.0 
		
		accell.x = accell.x * accellSize 
		accell.y = accell.y * accellSize 
		accell.z = accell.z * accellSize 

End Sub

Sub mySphere.setPos(posX As Single , posY As Single , posZ As Single) 
	position = Type<vector3>(posX, posY, posZ) 
End Sub

Sub mySphere.setSpeed(speedX As Single , speedY As Single , speedZ As Single) 
	speed = Type<vector3>(speedX, speedY, speedZ) 
End Sub

Sub mySphere.updateSpeedSize() 
	speedSize = Sqr((speed.x)*(speed.x) + (speed.y)*(speed.y) + (speed.z)*(speed.z)) 
End Sub

Function mySphere.roll() As BOOL 

	updateSpeedSize() 
	speed.x = speed.x + accell.x 
	speed.y = speed.y + accell.y 
	speed.z = speed.z + accell.z 
	speedDif = speedSize - Sqr((speed.x)*(speed.x) + (speed.y)*(speed.y) + (speed.z)*(speed.z)) 

	if (speedDif >= 0.0000001) Then 
		position.x = position.x + speed.x 
		position.y = position.y + speed.y 
		position.z = position.z + speed.z 
		return TRUE 
	Else
		accell.x = accell.x*0.0 
		accell.y = accell.y*0.0 
		accell.z = accell.z*0.0 
		speedSize = 0.0 
		return FALSE
	EndIf
  
End Function

Function mySphere.getSpeedSize() As Single 
	speedSize = (Sqr((speed.x)*(speed.x) + (speed.y)*(speed.y) + (speed.z)*(speed.z))) 
	return speedSize 
End Function

Function mySphere.determineDistance(testBall As mySphere) As Single 
	return Sqr((position.x - testBall.position.x)*(position.x - testBall.position.x) + _
				  (position.y - testBall.position.y)*(position.y - testBall.position.y) + _
				  (position.z - testBall.position.z)*(position.z - testBall.position.z) )
End Function

Function mySphere.collides(testBall As mySphere) As BOOL 

	Dim As Single distance = determineDistance(testBall) 

	if (distance >= (2.0*radius)) Then 
		return FALSE 
	Else
		   'position = position + (position - testBall.position)*0.1;
		position.x = position.x - (testBall.position.x - position.x)*(2.0*radius - distance) 
		position.y = position.y - (testBall.position.y - position.y)*(2.0*radius - distance) 
		position.z = position.z - (testBall.position.z - position.z)*(2.0*radius - distance) 
		   'position = position - speed*1.4;
		return TRUE 
	EndIf

End Function
