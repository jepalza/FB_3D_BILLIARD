' Billiard ball simulator
' Created by Nelis Franken
' -----------------------------------------------------------
'  Main implementation file
' -----------------------------------------------------------

' conversion a FreeBasic 1.09 por Joseba Epalza <jepalza_gmail_com> 2022

#Include "crt\stdio.bi" ' Print ), scanf(), fopen(), etc

#Include "billiards.bi"

#Include "mySphere.bas"
#Include "vector3.bas"


' Loads 24-bit bitmap files with 1 plane only.
' (Disclaimer: This function originally obtained from http://nehe.gamedev.net)
Function LoadImagen( filename As string , imagen As IMAGE Ptr) As Integer 

    Dim As FILE Ptr file 
    Dim As ULong size 
    Dim As ULong i 
    Dim As UShort planes 
    Dim As UShort bpp 
    Dim As String*80 finalName
    Dim As byte temp

	finalName= ".\textures\"+filename

	file = fopen(finalName, "rb")
    if file=0 Then 
		Print "File Not Found :";finalName
		return 0 
    EndIf
  

    fseek(file, 18, SEEK_CUR) 
	 i = fread(@imagen->sizeX, 4, 1, file)
    if (i <> 1) Then 
		Print "Error reading width from "; finalName 
		return 0 
    EndIf
  
	 i = fread(@imagen->sizeY, 4, 1, file)
    if (i <> 1) Then 
		Print "Error reading height from "; finalName
		return 0 
    EndIf
  

    size = imagen->sizeX * imagen->sizeY * 3 

    if ((fread(@planes, 2, 1, file)) <> 1) Then 
		Print "Error reading planes from "; finalName
		return 0 
    EndIf
  

    if (planes <> 1) Then 
		Print "Planes from "; finalName;" is not 1: "; planes 
		return 0 
    EndIf
  
  
    i = fread(@bpp, 2, 1, file)
    if (i <> 1) Then 
		Print "Error reading bpp from "; finalName 
		return 0 
    EndIf
  

    if (bpp <> 24) Then 
		Print "Bpp from "; finalName;" is not 24: "; bpp
		Return 0 
    EndIf
  
    fseek(file, 24, SEEK_CUR) 

    imagen->dato = allocate(size)
    if (imagen->dato = NULL) Then 
		Print "Error allocating memory for color-corrected image data"
		return 0 
    EndIf
  
    i = fread(imagen->dato, size, 1, file)
    if (i <> 1) Then 
		Print "Error reading image data from ";finalName
		return 0 
    EndIf
  

    for i=0 To size-1 Step 3     
		temp = imagen->dato[i]
		imagen->dato[i] = imagen->dato[i+2] 
		imagen->dato[i+2] = temp 
    Next


    return 1 
End Function

' Determines the normal from any three points on a plane.
Function getNormal(point1() As GLfloat , point3() As GLfloat , point4() As GLfloat) As vector3 
	Dim As vector3 theNormal = Type<vector3>(0.0,0.0,0.0) 
	theNormal.x = (point1(1) - point4(1))*(point3(2) - point4(2)) - (point3(1) - point4(1))*(point1(2) - point4(2)) 
	theNormal.y = (point3(0) - point4(0))*(point1(2) - point4(2)) - (point1(0) - point4(0))*(point3(2) - point4(2)) 
	theNormal.z = (point1(0) - point4(0))*(point3(1) - point4(1)) - (point3(0) - point4(0))*(point1(1) - point4(1)) 
	return theNormal 
End Function

' Renders the billiard balls to screen (with dynamic shadows)
Sub renderBalls() 
	Dim As Integer i,p

	Dim As GLfloat m(15) 
	for i=0 To 14
		m(i) = 0.0
   Next

	m(0) = 1.0 
	m(5) = 1.0 
	m(10) = 1.0 
	m(7) = (-1.0)/(light0Pos(1) + 2.0) 

	for p=0 To ballCount -1        
		glPushMatrix() 
			glTranslatef(ballList(p).position.x,ballList(p).position.y,ballList(p).position.z) 

			' Determine shadows.
			glPushMatrix() 
				glTranslatef(light0Pos(0), light0Pos(1)+0.65, light0Pos(2)) 
				glMultMatrixf(@m(0)) 
				glTranslatef(-1.0*light0Pos(0), -1.0*light0Pos(1), -1.0*light0Pos(2)) 
				glColor3f(0.0,0.0,0.0) 
				glBindTexture(GL_TEXTURE_2D, @theTexture(BLACK)) 
				gluSphere(ballQuadric, ballList(p).radius, 32, 12) 
			glPopMatrix() 

			Dim As vector3 tempSpeed = Type<vector3>(0.0, 0.0, 0.0) 
			tempSpeed = ballList(p).speed 
			tempSpeed.normalize() 
			Dim As vector3 speedNormal = Type<vector3>(0.0,0.0,0.0) 
			speedNormal.x = tempSpeed.z 
			speedNormal.y = 0.0 
			speedNormal.z = (-1.0)*tempSpeed.x 

			if (ballList(p).rotation > 360.0) Then ballList(p).rotation =  ballList(p).rotation - 360.0 

			ballList(p).rotation += ballList(p).speedSize/ballList(p).radius*(180.0/M_PI) 

			glBindTexture(GL_TEXTURE_2D, @theTexture(p)) 
			glRotatef(ballList(p).rotation, speedNormal.x, speedNormal.y, speedNormal.z) 

			gluSphere(ballQuadric, ballList(p).radius, 32, 32) 
		glPopMatrix() 
	
  Next

End Sub

' Renders a flat surface to screen with predefined width/height, segments and texture
Sub renderSurface(width_ As GLfloat , length As GLfloat , widthSegments As GLfloat , lengthSegments As GLfloat , elevation As GLfloat , texXTile As GLfloat , texYTile As GLfloat , normalX As GLfloat , normalY As GLfloat , normalZ As GLfloat , surfaceTexture As GLuint Ptr) 

	glPushMatrix() 
		glBindTexture(GL_TEXTURE_2D, surfaceTexture) 

		for k As GLfloat=(width_/(-2.0)) To (width_/(2.0)) -.01 Step (width_/widthSegments)       
			for r As GLfloat=(length/(-2.0)) To (length/(2.0)) -.01 Step (length/lengthSegments)       

			glBegin(GL_QUADS) 
				glNormal3f(normalX, normalY, normalZ) 
				glTexCoord2f(0.0, texYTile) 
				glVertex3f(k, elevation, r+length/lengthSegments) 
				glTexCoord2f(texXTile, texYTile) 
				glVertex3f(k+width_/widthSegments, elevation, r+length/lengthSegments) 
				glTexCoord2f(texXTile, 0.0) 
				glVertex3f(k+width_/widthSegments, elevation, r) 
				glTexCoord2f(0.0, 0.0) 
				glVertex3f(k, elevation, r) 
			glEnd() 

         Next
      Next


	glPopMatrix() 
End Sub

' Renders a quad represented by any 4 points to screen.
Sub renderQuad(point1() As GLfloat , point2() As GLfloat , point3() As GLfloat , point4() As GLfloat , orientation As GLfloat , texXTile As GLfloat , texYTile As GLfloat) 

	glBegin(GL_QUADS) 
		Dim As vector3 theNormal = Type<vector3>(0.0, 0.0, 0.0) 
		theNormal = getNormal(point1(), point3(), point4()) 
		theNormal = theNormal*orientation 
		glNormal3f(theNormal.x, theNormal.y, theNormal.z) 
		glTexCoord2f(0.0, texYTile) 
		glVertex3fv(@point1(0)) 
		glNormal3f(theNormal.x, theNormal.y, theNormal.z) 
		glTexCoord2f(texXTile, texYTile) 
		glVertex3fv(@point2(0)) 
		glNormal3f(theNormal.x, theNormal.y, theNormal.z) 
		glTexCoord2f(texXTile, 0.0) 
		glVertex3fv(@point3(0)) 
		glNormal3f(theNormal.x, theNormal.y, theNormal.z) 
		glTexCoord2f(0.0, 0.0) 
		glVertex3fv(@point4(0)) 
	glEnd() 

End Sub

' Renders a curve (partial cylinder of any height and sweep) to screen.
Sub renderCurve(radius As GLfloat , height As GLfloat , sweep As GLfloat , segments As GLuint , orientation As GLfloat , aTexture As GLuint ptr) 

	glPushMatrix() 
		glBindTexture(GL_TEXTURE_2D, aTexture) 

		for t As single=0.0 To sweep-(sweep/segments) Step (sweep/segments)        
			Dim As GLfloat x = 0.0, y = 0.0, z = 0.0 
			Dim As GLfloat point1(3) = {radius*cos(t), height, radius*sin(t)} 
			Dim As GLfloat point2(3) = {radius*cos(t+sweep/segments), height, radius*sin(t+sweep/segments)} 
			Dim As GLfloat point3(3) = {radius*cos(t+sweep/segments), 0.0, radius*sin(t+sweep/segments)} 
			Dim As GLfloat point4(3) = {radius*cos(t), 0.0, radius*sin(t)} 
			renderQuad(point1(), point2(), point3(), point4(), orientation, 1.0, 1.0) 
      Next

	glPopMatrix() 
End Sub

' Renders a disc (cap for a cylinder) of any sweep to screen.
Sub renderCap(inner_radius As GLfloat , outer_radius As GLfloat , inner_sweep As GLfloat , outer_sweep As GLfloat , segments As GLuint , myTexture As GLuint Ptr) 

	glPushMatrix() 

		Dim As GLfloat ciX = 0.0, coX = 0.0, ciZ = 0.0, coZ = 0.0 
		Dim As GLfloat angle = -1.0*outer_sweep/segments 

		glBindTexture(GL_TEXTURE_2D, myTexture) 

		for k As integer=0 To segments -1        

			ciX = inner_radius*cos(angle + inner_sweep/segments) 
			ciZ = inner_radius*sin(angle + inner_sweep/segments) 
			coX = outer_radius*cos(angle + outer_sweep/segments) 
			coZ = outer_radius*sin(angle + outer_sweep/segments) 
			angle += inner_sweep/segments 

			glBegin(GL_QUADS) 
				glNormal3f(0.0,1.0,0.0) 
				glTexCoord2f(coX/(2.0*outer_radius), coZ/(2.0*outer_radius)) 
				glVertex3f(coX, 0.0, coZ) 
				glNormal3f(0.0,1.0,0.0) 
				glTexCoord2f(outer_radius*cos(angle + outer_sweep/segments)/(2.0*outer_radius), outer_radius*sin(angle + outer_sweep/segments)/(2.0*outer_radius)) 
				glVertex3f(outer_radius*cos(angle + outer_sweep/segments), 0.0, outer_radius*sin(angle + outer_sweep/segments)) 
				glNormal3f(0.0,1.0,0.0) 
				glTexCoord2f(inner_radius*cos(angle + inner_sweep/segments)/(2.0*inner_radius), inner_radius*sin(angle + inner_sweep/segments)/(2.0*inner_radius)) 
				glVertex3f(inner_radius*cos(angle + inner_sweep/segments), 0.0, inner_radius*sin(angle + inner_sweep/segments)) 
				glNormal3f(0.0,1.0,0.0) 
				glTexCoord2f(ciX/(2.0*inner_radius), ciZ/(2.0*inner_radius)) 
				glVertex3f(ciX, 0.0, ciZ) 
			glEnd() 
		
      Next


	glPopMatrix() 
End Sub

' Renders a pocket of generic alignment and predefined sweep to screen.
Sub renderPocket(sweep As GLfloat) 

	glPushMatrix() 
		glTranslatef(0.0, -1.55, 0.0) 
		renderCurve(5.5, 2.55, sweep, 16, 1,  @theTexture(DARK_WOOD)) 
		renderCurve(3.0, 2.55, sweep, 16, -1, @theTexture(GREEN_CARPET)) 
		renderCap(0.0001, 5.5, 6.3, 6.3, 16,  @theTexture(BLACK)) 
	glPopMatrix() 
	
	glPushMatrix() 
		glTranslatef(0.0, 1.0, 0.0) 
		renderCap(3.0, 5.5, sweep, sweep, 16, @theTexture(DARK_WOOD)) 
	glPopMatrix() 
	
	glPushMatrix() 
		glTranslatef(0.0, -1.4, 0.0) 
		if (sweep < M_PI+0.001) Then 
 			renderCap(0.0001, 3.0, M_PI, M_PI, 16, @theTexture(BLACK)) 
		else
         renderCap(0.0001, 3.0, 6.3, 6.3, 16, @theTexture(BLACK))
		EndIf
	glPopMatrix() 
End Sub

' Renders the curved table legs to screen.
Sub renderTableLegs() 
	glNewList(displayList(4), GL_COMPILE) 

	glBindTexture(GL_TEXTURE_2D, @theTexture(DARK_WOOD)) 

	glPushMatrix() 

		for k As double=0 To 3.0*M_PI -.01 Step 1.4       
			for g As Double=0 To M_PI*2.0 -0.0001 Step 0.5        
				Dim As GLfloat point1(2) = {3.0*sin((k+1.4)/3.0)*cos(g), k*2, 3.0*sin((k+1.4)/3.0)*sin(g)} 
				Dim As GLfloat point2(2) = {3.0*sin((k+1.4)/3.0)*cos(g+0.5), k*2, 3.0*sin((k+1.4)/3.0)*sin(g+0.5)} 
				Dim As GLfloat point3(2) = {3.0*sin(k/3.0)*cos(g+0.5), k*2 - 2.8, 3.0*sin(k/3.0)*sin(g+0.5)} 
				Dim As GLfloat point4(2) = {3.0*sin(k/3.0)*cos(g), k*2 - 2.8, 3.0*sin(k/3.0)*sin(g)} 
				renderQuad(point1(), point2(), point3(), point4(), 1.0, 1.0, 1.0) 
        Next
      Next

		glRotatef(90.0, 1.0, 0.0 ,0.0) 
		glutSolidTorus(1.0, 1.8, 5, 8) 
		gluCylinder(pillarCylinder, 1.0, 3.0, 4.0, 8, 2) 

	glPopMatrix() 

	glEndList() 
End Sub

' Draws one side of the table (generically aligned)
Sub drawSide() 

	' Wooden side
	glPushMatrix() 
		glTranslatef(0, -0.3, 0) 
		glScalef(1.0, 1.0, 2.0) 
		glRotatef(270.0, 0.0, 1.0, 0.0) 
		glRotatef(45.0, 0.0, 0.0, 1.0) 
		glBindTexture(GL_TEXTURE_2D, @theTexture(WOOD)) 
		gluCylinder(pillarCylinder, 1.7, 1.7, tableWidth - 6, 4, 4) 
	glPopMatrix() 

	' Green carpeted side
	glPushMatrix() 
		glTranslatef(-1.0*tableWidth + 6, 0.0, -2.35) 
		glRotatef(180.0, 0.0, 0.0, 1.0) 
		glRotatef(270.0, 0.0, 1.0, 0.0) 
		glScalef(0.5, 1.0, 1.0) 

		glBindTexture(GL_TEXTURE_2D, @theTexture(GREEN_CARPET)) 
		gluCylinder(pillarCylinder, 1.7, 1.7, tableWidth - 6, 3, 3) 
	glPopMatrix() 
End Sub

' Draws the entire table to screen
Sub renderTable() 
	glNewList(displayList(1), GL_COMPILE) 
	glColor3f(1.0,1.0,1.0) 

	' Table carpeted area
	renderSurface(tableWidth, tableLength, 10.0, 15.0, -1.5, 1.0, 1.0, 0.0, 1.0, 0.0, @theTexture(GREEN_CARPET)) 

	' Anti-aliased game-lines on carpeted area
	glPushMatrix() 
		glDisable(GL_TEXTURE_2D) 
		glDisable(GL_LIGHTING) 
		glEnable(GL_BLEND) 
		glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA) 
		glEnable(GL_LINE_SMOOTH) 
		glColor4f(0.5, 0.5, 0.5, 0.4) 
		glLineWidth(2.5f) 

		' Horisontal line
		glTranslatef(0.0, -1.45, 0.0) 
		glBegin(GL_LINES) 
			glVertex3f(minX - pocketRadius, 0.0, minZ - minZ/3) 
			glVertex3f(maxX + pocketRadius, 0.0, minZ - minZ/3) 
		glEnd() 

		' Half-circle
		glTranslatef(0.0, 0.0, minZ - minZ/3) 
		glRotatef(90.0, 0.0, 1.0, 0.0) 
		glBegin(GL_LINES) 
			for i As GLfloat= 0.0 To M_PI-(M_PI/12.0) -0.1  Step (M_PI/12.0)      
				glVertex3f((maxZ/6.0)*sin(i), 0.0, (maxZ/6.0)*cos(i)) 
				glVertex3f((maxZ/6.0)*sin(i+M_PI/12.0), 0.0, (maxZ/6.0)*cos(i+M_PI/12.0)) 
         Next

		glEnd() 
		glLineWidth(1.0f) 

		' Start-point on line
		glRotatef(90.0, 1.0, 0.0, 0.0) 
		gluDisk(pillarCylinder, 0, 0.3, 9, 1) 

		glDisable(GL_LINE_SMOOTH) 
		glDisable(GL_BLEND) 
		glEnable(GL_LIGHTING) 
		glEnable(GL_TEXTURE_2D) 
	glPopMatrix() 

	' Table sides
	Dim As GLint divCount = -5, angleDirection = 1 
	Dim As GLfloat offA = 2.4, offB = 3.0, offTemp = 0.0, sideAngle = 270.0 

	for f As GLint=1 To -1 Step -1       
		for r As GLfloat=-1.0 To 1.0 Step 2  
			glPushMatrix() 
				glTranslatef(tableWidth/(r*2.0) + (abs(divCount)/divCount)*offA, 0.0, f*tableWidth + r*offB) 
				glRotatef(sideAngle, 0.0, 1.0, 0.0) 
				drawSide() 
			glPopMatrix() 

			divCount += 2 
			if ((f = 0) And (r = -1.0)) Then 
				offA = 2.4: offB = 3.0: offTemp = 0.0 
				sideAngle = 90.0 
				angleDirection = 1 
			Else
				offTemp = offA: offA = offB: offB = offTemp 
				sideAngle = sideAngle + angleDirection*90.0 
				angleDirection *= -1 
			EndIf
      Next
   Next


	' Pockets
	Dim As GLfloat direction = -1.0, angle = 360.0, sweep = M_PI + M_PI/2.0 
	Dim As BOOL sidePocket = FALSE 

	for g As Integer=-1 To 1 Step 2       
		for d As Integer=1 To -1 Step -1  
			glPushMatrix() 
				glTranslatef(g*tableWidth/(2.0), 0.0, d*tableWidth) 
				glRotatef(angle,0.0,1.0,0.0) 
				renderPocket(sweep) 
			glPopMatrix() 

			if (d = 1) Then 
				sweep = M_PI 
				if (g = -1) Then 
					angle = angle + direction*90 
					sidePocket = TRUE 
				End If
			Else
				If (sidePocket = FALSE) Then 
 					angle = angle + direction*90
				Else
        			sidePocket = FALSE
				EndIf
				sweep = M_PI + M_PI/2.0 
			EndIf
			
     Next
		direction = -1*direction 
		angle = 90 
  Next


	' Base
	glBindTexture(GL_TEXTURE_2D, @theTexture(WOOD)) 
	glPushMatrix() 
		glTranslatef(0.0, -1.4, 0.0) 
		glScalef(1.5, 1.0, 2.9) 
		glRotatef(45.0, 0.0, 1.0, 0.0) 
		glRotatef(90.0, 1.0, 0.0, 0.0) 
		gluCylinder(pillarCylinder, tableWidth/2, tableWidth/2 - 2, 5, 4, 2) 
	glPopMatrix() 

	' Legs
	glBindTexture(GL_TEXTURE_2D, @theTexture(DARK_WOOD)) 
	for g As Integer=-1 To 1 Step 2      
		for d As Integer=-1 To 1 Step 2         
			glPushMatrix() 
				glTranslatef(tableWidth/(g*2.0) + g*(-5.0), -20.0, tableLength/(d*2.0) + d*(-5.0)) 
				glCallList(displayList(4)) 
			glPopMatrix() 
     Next
   Next


	glEndList() 
End Sub

' Computes the stairs using a ton of adjustable settings (will document their use maybe later)
Sub renderStairs(orientation As GLint , stepCount As GLfloat , stepWidth As GLfloat , stepWidthDecrease As GLfloat , totalHeight As GLfloat , myFlatTexture As GLuint ptr, myStepTexture As GLuint ptr) 

	glPushMatrix() 

	Dim As GLfloat t = 0.0, curve = 0.0, nextCurve = 0.0, groundHeight = 0, groundIncrease = totalHeight/stepCount, depth = 70.0, moveRight = 0.0 
	Dim As GLfloat spreadFactor = 0.2, minRange = -1.0*sqr(depth/spreadFactor)+moveRight, maxRange = sqr(depth/spreadFactor)+moveRight 
	Dim As vector3 originVector = Type<vector3>(0.0, 0.0, 0.0) 

	' Half-flight of stairs climbing from right to left
	if (orientation = 0) Then   
		maxRange = 0.0 
	' Half-flight of stairs climbing from left to right
	ElseIf  (orientation = 1) Then
		minRange = 0.0 
		groundHeight = stepCount*groundIncrease + 2.0*groundIncrease 
		stepWidth = stepWidth - stepCount*stepWidthDecrease 
		stepWidthDecrease *= -1.0 
		groundIncrease *= -1.0 
	EndIf
  

	Dim As GLfloat incr = (Sqr((maxRange - minRange)*(maxRange - minRange)))/(stepCount+1) 

	if (orientation = 1) Then   
		maxRange = maxRange - incr 
		minRange = 0.0 - 2.0 *incr 
		minRange = minRange + incr 
	ElseIf  (orientation = 0) Then
		Rem nada
	ElseIf  (orientation = 2) Then
		groundHeight = stepCount*groundIncrease + 2.0*groundIncrease 
		stepWidth = stepWidth - stepCount*stepWidthDecrease 
		stepWidthDecrease *= -1.0 
		groundIncrease *= -1.0 
	EndIf
  

	t = minRange 

	for t=t To maxRange-1 Step incr      

		curve = spreadFactor*((-1.0*(t - moveRight)*(t-moveRight))) + depth 
		nextCurve = spreadFactor*((-1.0*(t + incr - moveRight)*(t + incr -moveRight))) + depth 

		Dim As vector3 stepNormalV = Type<vector3>(0.0,0.0,0.0) 
		stepNormalV.x = curve - (spreadFactor*((-1.0*(t + incr - moveRight)*(t+incr-moveRight))) + depth) 
		stepNormalV.y = 0.0 
		stepNormalV.z = incr 

		Dim As GLfloat length = Sqr( (stepNormalV.x*stepNormalV.x) + (stepNormalV.y*stepNormalV.y) + (stepNormalV.z*stepNormalV.z) ) 
		stepNormalV.x = stepNormalV.x * (1/length) 
		stepNormalV.y = stepNormalV.y * (1/length) 
		stepNormalV.z = stepNormalV.z * (1/length) 
		
		stepNormalV.x = stepNormalV.x * stepWidth 
		stepNormalV.y = stepNormalV.y * stepWidth 
		stepNormalV.z = stepNormalV.z * stepWidth 

		Dim As GLfloat stairs1(2) = {stepNormalV.x + originVector.x, groundHeight + groundIncrease, stepNormalV.z + originVector.z} 
		Dim As GLfloat stairs2(2) = {originVector.x, groundHeight + groundIncrease, originVector.z} 
		Dim As GLfloat stairs3(2) = {originVector.x, groundHeight, originVector.z} 
		Dim As GLfloat stairs4(2) = {stepNormalV.x + originVector.x, groundHeight, stepNormalV.z + originVector.z} 
		Dim As GLfloat stairs6(2) = {t+incr, groundHeight + groundIncrease, nextCurve} 
		Dim As GLfloat stairs7(2) = {t+incr, groundHeight, nextCurve} 

		originVector.x = stairs6(0) 
		originVector.y = stairs6(1) 
		originVector.z = stairs6(2) 

		curve = spreadFactor*((-1.0*(t+incr - moveRight)*(t+incr-moveRight))) + depth 
		nextCurve = spreadFactor*((-1.0*(t + incr+incr - moveRight)*(t +incr+ incr -moveRight))) + depth 
		stepWidth = stepWidth - stepWidthDecrease 

		stepNormalV = Type<vector3>(0.0,0.0,0.0) 
		stepNormalV.x = curve - (spreadFactor*((-1.0*(t+incr + incr - moveRight)*(t+incr+incr-moveRight))) + depth) 
		stepNormalV.y = 0.0 
		stepNormalV.z = incr 
		length = sqr(  (stepNormalV.x*stepNormalV.x) + (stepNormalV.y*stepNormalV.y) + (stepNormalV.z*stepNormalV.z) ) 
		stepNormalV.x = stepNormalV.x * (1/length) 
		stepNormalV.y = stepNormalV.y * (1/length) 
		stepNormalV.z = stepNormalV.z * (1/length) 
		
		stepNormalV.x = stepNormalV.x * stepWidth 
		stepNormalV.y = stepNormalV.y * stepWidth 
		stepNormalV.z = stepNormalV.z * stepWidth 

		Dim As GLfloat stairs5(2) = {stepNormalV.x + originVector.x, groundHeight + groundIncrease, stepNormalV.z + originVector.z} 

		groundHeight = groundHeight + groundIncrease 

		if (t <> minRange) Then 

			glBindTexture(GL_TEXTURE_2D, myStepTexture) 

			if (orientation = 0) Then 
				renderQuad(stairs1(), stairs2(), stairs3(), stairs4(), 1.0, 1.0, 1.0) 
			Else
				renderQuad(stairs1(), stairs2(), stairs3(), stairs4(), -1.0, 1.0, 1.0) 
			EndIf

			if (orientation = 1) And (t > maxRange-incr) Then 
				Rem nada
			Else
				glBindTexture(GL_TEXTURE_2D, myFlatTexture) 
				renderQuad(stairs1(), stairs2(), stairs6(), stairs5(), -1.0, 1.0, 1.0) 
			EndIf
 
		EndIf
  
   Next


	glPopMatrix() 
End Sub

' Renders the balcony (stairs plus red screen) to screen
Sub renderBalcony() 

	glNewList(displayList(3), GL_COMPILE) 

	glPushMatrix() 
		glTranslatef(0.0,0.0,-100.0) 
		glRotatef(145, 0.0, 1.0, 0.0) 
		renderCurve(70.0, 90.0, 1.945, 16, -1, @theTexture(RED_LIGHT)) 
	glPopMatrix() 

	glPushMatrix() 
		glTranslatef(0.0,0.0,-100.0) 
		glRotatef(180.0, 0.0, 1.0, 0.0) 

		glPushMatrix() 
			glTranslatef(-45.0, -3.0, 10.0) 
			renderStairs(0, 15.0, 60.0, 1.5, 60.0, @theTexture(RED_CARPET), @theTexture(BLACK)) 
		glPopMatrix() 

		glPushMatrix() 
			glTranslatef(45.0, 0.0, 0.0) 
			renderStairs(1, 15.0, 60.0, 1.5, 60.0, @theTexture(RED_CARPET), @theTexture(BLACK)) 
		glPopMatrix() 
	glPopMatrix() 

	glEndList() 
End Sub

' Renders the rest of the room (minus balcony, floor and table) to screen
Sub renderRoom() 

	glNewList(displayList(2), GL_COMPILE) 

	Dim As GLfloat height= 90.0 

	' Roof
	glPushMatrix() 
		glTranslatef(0.0, 90.0 ,0.0) 
		glRotatef(-90.0, 1.0, 0.0, 0.0) 
		glRotatef(22.5, 0.0, 0.0, 1.0) 
		glBindTexture(GL_TEXTURE_2D, @theTexture(ROOF)) 
		gluCylinder(pillarCylinder, 230.0, 0.0, 50, 8, 1) 
	glPopMatrix() 

	' Windows
	glPushMatrix() 
		glRotatef(292.5, 0.0, 1.0, 0.0) 
		
		' el codigo original solapa un muro con una ventana, y en FB se ven ambas una zobre la otra
		' asi que, hago translacion de un punto de la ventana, para separarla del muro
		glTranslatef(0.0, 0.0, -1.0)
		
		renderCurve(230, height, (M_PI/4.0), 1, -1, @theTexture(SEA_VIEW)) 
		glRotatef(-45, 0.0, 1.0, 0.0) 
		renderCurve(230, height, (M_PI/4.0), 1, -1, @theTexture(SEA_VIEW2)) 
	glPopMatrix() 

	glPushMatrix() 
		glTranslatef(165, 20.0, -25.0) 
		glRotatef(22.5, 0.0, 1.0, 0.0) 
		renderCurve(50, 50, (M_PI/4.0), 1, -1, @theTexture(PAINTING2)) 
		glTranslatef(-20, 0.0, 50.0) 
		renderCurve(50, 50, (M_PI/4.0), 1, -1, @theTexture(PAINTING1)) 
	glPopMatrix() 

	glPushMatrix() 
		glRotatef(202.5, 0.0, 1.0, 0.0) 

		' Walls
		renderCurve(230.0, height, ((2*M_PI) - (M_PI/4.0)), 7, -1, @theTexture(BLUE_WALL)) 

		' Ceiling
		glPushMatrix() 
			glTranslatef(0.0,90.0,0.0) 
			renderCap(135.0, 230.0, M_PI*2.0, M_PI*2.0, 8, @theTexture(BLACK)) 
			renderCurve(135.0, 20.0, M_PI*2.0, 8, -1, @theTexture(RED_MARBLE)) 
		glPopMatrix() 

		glPushMatrix() 
			glTranslatef(0.0,0.5,0.0) 
			renderCap(135.0, 230.0, M_PI*2.0, M_PI*2.0, 8, @theTexture(BLACK)) 
		glPopMatrix() 

		' Pillars
		for t as GLfloat=0.0 To M_PI*2.0 -.01 Step (M_PI*2.0/8.0)     

			glBindTexture(GL_TEXTURE_2D, @theTexture(DARKBLUE_MARBLE)) 

			' Pillars (far)
			glPushMatrix() 
				glTranslatef(223.0*cos(t), height, 223.0*sin(t)) 
				glRotatef(90.0, 1.0, 0.0, 0.0) 
				glutSolidTorus(5.0, 6.0, 8, 12) 
				gluCylinder(pillarCylinder, 7.0, 7.0, height, 16, 1) 
			glPopMatrix() 
			glPushMatrix() 
				glTranslatef(223.0*cos(t), 1.0, 223.0*sin(t)) 
				glRotatef(90.0, 1.0, 0.0, 0.0) 
				glutSolidTorus(5.0, 6.0, 8, 12) 
			glPopMatrix() 

			glBindTexture(GL_TEXTURE_2D, @theTexture(BEIGE_WALL)) 

			' Pillars (near)
			glPushMatrix() 
				glTranslatef(145.0*cos(t), height, 145.0*sin(t)) 
				glRotatef(90.0, 1.0, 0.0, 0.0) 
				glutSolidTorus(1.5, 2.5, 8, 12) 
				gluCylinder(pillarCylinder, 3.0, 3.0, height, 16, 1) 
			glPopMatrix() 
			glPushMatrix() 
				glTranslatef(145.0*cos(t), 1.0, 145.0*sin(t)) 
				glRotatef(90.0, 1.0, 0.0, 0.0) 
				glutSolidTorus(1.5, 2.5, 8, 12) 
			glPopMatrix() 
		
      Next


	glPopMatrix() 

	glEndList() 
End Sub

' Renders the cue stick to screen
Sub renderCueStick() 

	glPushMatrix() 
		updateTarget() 
		updateCamera() 

		glTranslatef(camera(3), camera(4), camera(5)) 
		glRotatef(theta*180.0/M_PI*(-1.0) + 90, 0.0, 1.0 ,0.0) 
		glRotatef(-11.5, 1.0, 0.0 ,0.0) 
		glTranslatef(0.0, 0.0, power) 

		glBindTexture(GL_TEXTURE_2D, @theTexture(CUE)) 
		gluCylinder(ballQuadric, 0.35, 1.0, 50.0, 8, 1) 
	glPopMatrix() 
End Sub

' Draws the guiding/aiming line to screen
Sub drawGuideLine() 
	Dim As GLfloat guideLineLength = -1000 
	Dim As GLfloat targetX = guideLineLength*(cos(theta)) + camera(3) 
	Dim As GLfloat targetZ = guideLineLength*(sin(theta)) + camera(5) 

	if (targetX < minX) Then 
		targetX = minX 
		guideLineLength = (targetX - camera(3)) / cos(theta) 
		targetZ = guideLineLength*(sin(theta)) + camera(5) 
	EndIf
  

	if (targetX > maxX) Then 
		targetX = maxX 
		guideLineLength = (targetX - camera(3)) / cos(theta) 
		targetZ = guideLineLength*(sin(theta)) + camera(5) 
	EndIf
  

	if (targetZ < minZ) Then 
		targetZ = minZ 
		guideLineLength = (targetZ - camera(5)) / sin(theta) 
		targetX = guideLineLength*(cos(theta)) + camera(3)
	EndIf
  

	if (targetZ > maxZ) Then 
		targetZ = maxZ 
		guideLineLength = (targetZ - camera(5)) / sin(theta) 
		targetX = guideLineLength*(cos(theta)) + camera(3) 
	EndIf
  

	glPushMatrix() 
		glDisable(GL_TEXTURE_2D) 
		glDisable(GL_LIGHTING) 
		glEnable(GL_BLEND) 
		glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA) 
		glColor4f(0.61, 0.61, 0.06, 0.75) 
		glBegin(GL_LINES) 
			glVertex3f(camera(3), camera(4), camera(5)) 
			glVertex3f(targetX, camera(4), targetZ) 
		glEnd() 
		glDisable(GL_BLEND) 
		glEnable(GL_LIGHTING) 
		glEnable(GL_TEXTURE_2D) 
	glPopMatrix() 
End Sub

' Draws a text string on screen
Sub renderBitmapString(x As Single , y As Single , font As integer , c As String) 
	glRasterPos2f(x, y) 
	for cc As integer=1 To Len(c)    
		glutBitmapCharacter(font, Asc(Mid(c,cc,1))) 
   Next
End Sub

' Draws the end-of-game screen
Sub drawEndScreen() 

	switchToOrtho() 

	glDisable(GL_TEXTURE_2D) 
	glDisable(GL_LIGHTING) 
	glEnable(GL_BLEND) 
	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA) 

	glColor4f(0.1, 0.1, 0.1, 0.7) 
	glBegin(GL_POLYGON) 
		glVertex2f(0, parentWindowHeight) 
		glVertex2f(parentWindowWidth, parentWindowHeight) 
		glVertex2f(parentWindowWidth, 0) 
		glVertex2f(0, 0) 
	glEnd() 

	glColor4f(1.0, 1.0, 1.0, 1.0) 

	renderBitmapString(parentWindowWidth / 2 - 40, parentWindowHeight/2 - 75,largeFont, endGame) 
	renderBitmapString(parentWindowWidth / 2 - 5,  parentWindowHeight/2 - 60,font, "Game Over") 
	renderBitmapString(parentWindowWidth / 2 - 18, parentWindowHeight/2 - 45,font, "Play again? (Y/N)") 

	glDisable(GL_BLEND) 
	glEnable(GL_LIGHTING) 
	glEnable(GL_TEXTURE_2D) 

	switchFromOrtho() 
End Sub

' Renders the user interface to screen
Sub drawUI() 
	Dim As GLfloat displayOffset = parentWindowWidth - 5 
	Dim As String*100 playerBuffer
	Dim As String*20 shotBuffer

	shotBuffer=Str(players(currentPlayer).noOfShots)

	switchToOrtho() 
	glDisable(GL_LIGHTING) 
	glDisable(GL_TEXTURE_2D) 

	glColor3f(1.0,1.0,1.0) 
	renderBitmapString(80, 15, font, "Player: ") 
	renderBitmapString(80, 30, font, "Team  : ") 
	renderBitmapString(80, 45, font, "Shots : ") 

	glColor3f(0.8,0.8,0.8) 
	renderBitmapString(130, 15, font, Str(players(currentPlayer).nombre)) 
	if (players(currentPlayer).side = 0) Then 
		renderBitmapString(130, 30, font, "Solids") 
	ElseIf (players(currentPlayer).side = 1) Then
  		renderBitmapString(130, 30, font, "Stripes") 
	else
      renderBitmapString(130, 30, font, "Undetermined")
	EndIf
  
	renderBitmapString(130, 45, font, shotBuffer) 

	glColor3f(1.0,1.0,1.0) 
	glEnable(GL_TEXTURE_2D) 

	' Render portrait
	glBindTexture(GL_TEXTURE_2D, @theTexture(players(currentPlayer).id + 32)) 
	glBegin(GL_POLYGON) 
		glTexCoord2f(0.0, 1.0) 
		glVertex2f(5, 5) 
		glTexCoord2f(1.0, 1.0) 
		glVertex2f(69, 5) 
		glTexCoord2f(1.0, 0.0) 
		glVertex2f(69, 69) 
		glTexCoord2f(0.0, 0.0) 
		glVertex2f(5, 69) 
	glEnd() 

	' Render power-indicator-bar
	if (shootMode = TRUE) Then 
  
		glBindTexture(GL_TEXTURE_2D, @theTexture(POWER_BAR)) 
		glBegin(GL_POLYGON) 
			glTexCoord2f(0.0, 1.0) 
			glVertex2f(5, 75) 
			glTexCoord2f(power/35, 1.0) 
			glVertex2f(5+power*4, 75) 
			glTexCoord2f(power/35, 0.88) 
			glVertex2f(5+power*4, 90) 
			glTexCoord2f(0.0, 0.88) 
			glVertex2f(5, 90) 
		glEnd() 
		glDisable(GL_TEXTURE_2D) 
		glLineWidth(2.5f) 
		glBegin(GL_LINE_LOOP) 
			glVertex2f(5,75) 
			glVertex2f(145,75) 
			glVertex2f(145,90) 
			glVertex2f(5,90) 
		glEnd() 
		glLineWidth(1.0f) 
		glEnable(GL_TEXTURE_2D) 
	
	EndIf
  

	' Render iconic ball images for balls already sunk.
	for k As integer=0 To ballCount -1        
		if (players(currentPlayer).balls(k) = TRUE ) Then 
  
			glColor3f(1.0, 1.0, 1.0) 
			glBindTexture(GL_TEXTURE_2D, @theTexture(k+16)) 
			glBegin(GL_POLYGON) 
				glTexCoord2f(0.0, 1.0) 
				glVertex2f(displayOffset - 32, 5) 
				glTexCoord2f(1.0, 1.0) 
				glVertex2f(displayOffset, 5) 
				glTexCoord2f(1.0, 0.0) 
				glVertex2f(displayOffset, 37) 
				glTexCoord2f(0.0, 0.0) 
				glVertex2f(displayOffset - 32, 37) 
			glEnd() 

			displayOffset -= 36.0 
		EndIf
   Next


	glEnable(GL_LIGHTING) 
	switchFromOrtho() 
End Sub

' Updates the camera eye coordinates
Sub updateCamera() 
	camera(0) = zoom*(cos(theta)) + camera(3) 
	camera(1) = zoom* Sin(elevationAngle) + camera(4) 
	camera(2) = zoom*(sin(theta)) + camera(5) 
	if (camera(1) < 29) Then camera(1) = 29 
	if (camera(1) > 90) Then camera(1) = 90 
	glutPostRedisplay() 
End Sub

' Updates the camera look-at position
Sub updateTarget() 
	camera(3) = ballList(0).position.x 
	camera(4) = ballList(0).position.y 
	camera(5) = ballList(0).position.z 
	glutPostRedisplay() 
End Sub

' Switches from perspective to orthographic projection.
Sub switchToOrtho() 
	glMatrixMode(GL_PROJECTION) 
	glPushMatrix() 
	glLoadIdentity() 
	gluOrtho2D(0, parentWindowWidth, 0, parentWindowHeight) 
	glScalef(1, -1, 1) 
	glTranslatef(0, -1.0*parentWindowHeight, 0) 
	glMatrixMode(GL_MODELVIEW) 
	glLoadIdentity() 
End Sub

' Switch back from orthographic to perspective projection.
Sub switchFromOrtho() 
	glMatrixMode(GL_PROJECTION) 
	glPopMatrix() 
	glMatrixMode(GL_MODELVIEW) 
End Sub

' The main rendering function
Sub renderParentWindow Cdecl() 

	Dim As Double eq (3) = {0.0f, 1.0f, 0.0f, 0.0f} 
	Dim As Double eqr(3) = {0.0f,-1.0f, 0.0f, 0.0f} 

	glutSetWindow(mainWindow)
	
	glClearColor(0.6, 0.6, 0.6, 1.0) 
	glClear(GL_COLOR_BUFFER_BIT Or GL_DEPTH_BUFFER_BIT Or GL_STENCIL_BUFFER_BIT) 
	glLoadIdentity() 

	If (gameover = FALSE ) Then 
		drawUI() 
	Else
		shootMode = FALSE  
		doAnimation = FALSE  
	EndIf
  

	glLoadIdentity() 
	glPushMatrix() 

		gluLookAt(camera(0),camera(1),camera(2),camera(3),camera(4),camera(5), 0.0, 1.0, 0.0) 

		renderBalls() 
		glCallList(displayList(2)) 
		glCallList(displayList(3)) 

		if (doAnimation = TRUE) Then 
			if (power >= 3.0) Then 
				power -= power/2.0 
			Else
				ballList(0).setDefaults() 
				ballList(0).updateSpeedSize() 
				
				ballList(0).accell.x = (ballList(0).speed.x * -1.0) * (ballList(0).accellSize) * (1 / ballList(0).speedSize) 
				ballList(0).accell.y = (ballList(0).speed.y * -1.0) * (ballList(0).accellSize) * (1 / ballList(0).speedSize) 
				ballList(0).accell.z = (ballList(0).speed.z * -1.0) * (ballList(0).accellSize) * (1 / ballList(0).speedSize) 
				
				power = 3.0 
				doAnimation = FALSE  
				shootMode = FALSE   
				turnStarting = FALSE  
				players(currentPlayer).noOfShots -= 1 

				alSourcePlay(soundClip(SHOOT)) 
				'if ((error_ = alGetError()) <> AL_NO_ERROR) Then 
				'	DisplayALError("alSourcePlay 0 : ", error_)
				'EndIf
				glutIdleFunc(@idle) 
			EndIf
			glutPostRedisplay() 
		EndIf
  

		' The following (rather large) section of code is responsible for the reflection of
		' the table on the floor.
		glDisable(GL_DEPTH_TEST) 
		glColorMask(0,0,0,0) 
		glEnable(GL_STENCIL_TEST) 
		glStencilFunc(GL_ALWAYS, 1, 1) 
		glStencilOp(GL_KEEP, GL_KEEP, GL_REPLACE) 
		glDisable(GL_DEPTH_TEST) 

		glPushMatrix() 
			glTranslatef(0.0f, 25.0, 0.0f) 
			renderSurface(500.0, 500.0, 1.0, 1.0, -24.0, 12.0, 12.0, 0.0, 1.0, 0.0,@theTexture(CHECKER)) 
		glPopMatrix() 

		glEnable(GL_DEPTH_TEST) 
		glColorMask(1,1,1,1) 
		glStencilFunc(GL_EQUAL, 1, 1) 
		glStencilOp(GL_KEEP, GL_KEEP, GL_KEEP) 
		glEnable(GL_CLIP_PLANE0) 
		glClipPlane(GL_CLIP_PLANE0, @eqr(0)) 

		glPushMatrix() 
			glScalef(1.0f, -1.0f, 1.0f) 
			glTranslatef(0.0f, 25.0f, 0.0f) 
			glCallList(displayList(1)) 
		glPopMatrix() 

		glDisable(GL_CLIP_PLANE0) 
		glDisable(GL_STENCIL_TEST) 

		glLightfv(GL_LIGHT0,GL_POSITION,@light0Pos(0)) 
		glLightfv(GL_LIGHT0,GL_SPOT_DIRECTION,@light0Dir(0)) 
		glLightfv(GL_LIGHT1,GL_POSITION,@light1Pos(0)) 

		glEnable(GL_BLEND) 
		glDisable(GL_LIGHTING) 
		glColor4f(1.0f, 1.0f, 1.0f, 0.8f) 
		glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA) 

		glPushMatrix() 
			glTranslatef(0.0f, 25.0f, 0.0f) 
			glRotatef(45.0, 0.0, 1.0, 0.0) 
			renderSurface(500.0, 500.0, 1.0, 1.0, -24.0, 12.0, 12.0, 0.0, 1.0, 0.0, @theTexture(CHECKER)) 
		glPopMatrix() 

		glEnable(GL_LIGHTING) 
		glDisable(GL_BLEND) 
		glEnable(GL_CLIP_PLANE0) 
		glClipPlane(GL_CLIP_PLANE0, @eq(0)) 

		glPushMatrix() 
			glTranslatef(0.0f, 25.0f, 0.0f) 
			glCallList(displayList(1)) 
		glPopMatrix() 

		glDisable(GL_CLIP_PLANE0) 

		if (shootMode = TRUE) Then 
			renderCueStick() 
			if (useLazer = TRUE) Then drawGuideLine()
		EndIf
  
	glPopMatrix() 

	if (gameover = TRUE) Then 
		drawEndScreen() 
	EndIf

	glutSwapBuffers() 
End Sub

' The idle function, handles collision detection and response for the table (and various other things like ball animation)
Sub idle cdecl() 

	' Check for and handle collisions between balls
	for s As Integer=0 To  (ballCount-1) -1        
		for t As Integer=(s+1) To ballCount-1         
			if ((ballList(s).collides(ballList(t)) = TRUE) And (ballList(s).collided = FALSE) _
				And (ballList(t).collided = FALSE) And (ballList(s).inPlay = TRUE)_
				And (ballList(t).inPlay = TRUE)) Then 
					deflectBalls(s, t) 
			EndIf
      Next
   Next


	' Check for and handle collisions between balls and table sides
	for t As Integer=0 To ballCount-1         

		if(ballList(t).inPlay = TRUE) Then 
  
			' Determine if the ball was sunk into a pocket
			if (ballList(t).position.z > (maxZ - pocketRadius) ) Then   
				if (ballList(t).position.x < (minX + pocketRadius)) Then
  					ballInPocket(t, 1) 
				ElseIf  (ballList(t).position.x > (maxX - pocketRadius)) Then
  					ballInPocket(t, 2) 
				EndIf
			ElseIf (ballList(t).position.z < (minZ + pocketRadius) ) Then
				if (ballList(t).position.x < (minX + pocketRadius)) Then
 					 ballInPocket(t, 3) 
				ElseIf  (ballList(t).position.x > (maxX - pocketRadius)) Then
  					ballInPocket(t, 4) 
				EndIf
			ElseIf ((ballList(t).position.z < (pocketRadius)) And (ballList(t).position.z > (-1.0*pocketRadius))) Then
				if (ballList(t).position.x < (minX + pocketRadius)) Then  
					ballInPocket(t, 5) 
				ElseIf  (ballList(t).position.x > (maxX - pocketRadius)) Then
					ballInPocket(t, 6) 
				EndIf
			EndIf
  
			if ((ballList(t).position.x > maxX) Or (ballList(t).position.x < minX)) Then 
				ballList(t).position.x = ballList(t).position.x - ballList(t).speed.x*1.3 
				ballList(t).position.z = ballList(t).position.z - ballList(t).speed.z*1.3 
				ballList(t).speed.x    = ballList(t).speed.x*(-0.8) 
				ballList(t).speed.z    = ballList(t).speed.z*(0.8) 
				ballList(t).accell.x   = ballList(t).accell.x*(-1.0) 

				alSourcePlay(soundClip(SIDES)) 
				'if ((error = alGetError()) <> AL_NO_ERROR) Then
				'	DisplayALError("alSourcePlay SIDES : ", error)
				'EndIf
			EndIf
  

			if ((ballList(t).position.z > maxZ) Or (ballList(t).position.z < minZ)) Then 
				ballList(t).position.x = ballList(t).position.x - ballList(t).speed.x*1.3 
				ballList(t).position.z = ballList(t).position.z - ballList(t).speed.z*1.3 
				ballList(t).speed.z    = ballList(t).speed.z*(-0.8) 
				ballList(t).speed.x    = ballList(t).speed.x*(0.8) 
				ballList(t).accell.z   = ballList(t).accell.z*(-1.0) 

				alSourcePlay(soundClip(SIDES)) 
				'if ((error = alGetError()) <> AL_NO_ERROR) Then 
				'	DisplayALError("alSourcePlay SIDES : ", error)
				'EndIf
			EndIf
		EndIf
   Next

	rollingBalls = FALSE 

	' Let the balls roll on
	for p As Integer =0 To ballCount-1         
		if (ballList(p).inPlay = TRUE) Then 
			rollingBalls = rollingBalls Or ballList(p).roll() 
		Else
			rollingBalls = rollingBalls Or FALSE 
		EndIf
		ballList(p).collided = FALSE 
   Next

	if (rollingBalls = FALSE) Then 
		if (returnWhiteBall = TRUE) Then 
			ballList(0).mySpheres(0.0, 24.9 , minZ - minZ/3) 
			ballList(0).setDefaults() 
			returnWhiteBall = FALSE
		EndIf
  
		if (turnStarting = FALSE) Then 
			if (players(currentPlayer).noOfShots <= 0) Then 
				turnStarting = TRUE 
				players(currentPlayer).noOfShots = 0 
				currentPlayer = (currentPlayer + 1) Mod playerCount 
				players(currentPlayer).noOfShots += 1 
			Else
				turnStarting = TRUE
			EndIf
		EndIf
	EndIf
  
	if (turnStarting = TRUE) Then 
		glutIdleFunc(NULL) 
	EndIf
  

	glutPostRedisplay() 
End Sub

' Handles normal (non-keypad) key input.
Sub keys cdecl(byval key As UByte,byval x As Integer ,ByVal y As Integer) 

	if (key = 27) Then End

	' Rotate left
	If (key = Asc("a"))  Then 
  
		theta = theta - 0.05 
		camera(0) = 65.0*(cos(theta)) + camera(3) 
		camera(2) = 65.0*(sin(theta)) + camera(5) 
		updateCamera() 
	
	EndIf
  

	' Rotate right
	if(key = Asc("d")) Then 
  
		theta = theta + 0.05 
		camera(0) = 65.0*(cos(theta)) + camera(3) 
	   camera(2) = 65.0*(sin(theta)) + camera(5) 
	   updateCamera() 
    
	EndIf
  

	' Move forward
	if(key = Asc("w")) Then 
  
		zoom -= 1.0 
		if (zoom < 10) Then zoom = 10 
		updateCamera() 
 	
	EndIf
  

	' Move backward
	if(key = Asc("s")) Then 
  
		zoom += 1.0 
		if (zoom > 100) Then zoom = 100 
		updateCamera() 
	
	EndIf
  

	' Ascend
	if(key = Asc("z")) Then 
  
		camera(1) = camera(1) + 1.0 
		if (camera(1) > 90.0) Then camera(1) = 90.0 
		updateCamera() 
	
	EndIf
  

	' Descend
	if(key = Asc("x")) Then 
  
		camera(1) = camera(1) - 1.0 
		if (camera(1) < 24.9) Then camera(1) = 24.9 
		updateCamera() 
	
	EndIf
  

	' Increase power of shot
	if(key = Asc("g")) Then 
  
		power += 2.0 
		if (power >= 35.0) Then power = 35.0 
	
	EndIf
  

	' Decrease power of shot
	if (key = Asc("f")) Then 
  
		power -= 2.0 
		if (power <= 3.0) Then power = 3.0 
	
	EndIf
  

	' Shoot
	if (key = Asc("t")) Then 
  
		Dim As GLfloat powX = power*(cos(theta)) 
	   Dim As GLfloat powZ = power*(sin(theta)) 
		ballList(0).speed.x = powX*(-0.1) 
		ballList(0).speed.z = powZ*(-0.1) 
		doAnimation = TRUE 
	
	EndIf
  

	' Toggle shootmode
	if (key = Asc(" ")) Then 
  
		shootMode = Not shootMode 
	
	EndIf
  

	' Handle choice at end of game
	if (gameover = TRUE) Then 
  
		if (key = Asc("y")) Then resetGame() 
		if (key = Asc("n")) Then End 
	
	EndIf
  

	' Toggle lazer guided aiming
	if (key = Asc("l")) Then 
  
		useLazer = Not useLazer 
	
	EndIf
  
	glutSetWindow(mainWindow) 
	glutPostRedisplay() 
End Sub

' Handles all special (keypad) key input.
Sub specialKeyPressed cdecl(ByVal key As Integer ,byval x As Integer ,ByVal y As Integer) 
    Select Case (key)  
    	case GLUT_KEY_PAGE_UP  		
    		keys(Asc("z"),0,0) 
    	case GLUT_KEY_PAGE_DOWN  	
    		keys(Asc("x"),0,0)
    	case GLUT_KEY_UP  			
    		keys(Asc("w"),0,0) 
    	case GLUT_KEY_DOWN  		
    		keys(Asc("s"),0,0) 
    	case GLUT_KEY_LEFT 			
    		keys(Asc("a"),0,0) 
    	case GLUT_KEY_RIGHT 		
    		keys(Asc("d"),0,0) 
    End Select
End Sub

' Handles any mouse input from the user.
Sub useMouse cdecl(ByVal button As Integer ,byval state As Integer ,byval x As Integer ,ByVal y As Integer) 

	prevMouseX = x 
	prevMouseY = y 

	if (turnStarting = TRUE) Then updateTarget() 

	if ((button = GLUT_LEFT_BUTTON) And (state = GLUT_DOWN)) Then 
		pressedTheta = theta 
		pressedElevation = elevationAngle 
		leftMouseButton = TRUE 
	EndIf
  

	if ((button = GLUT_LEFT_BUTTON) And (state = GLUT_UP)) Then 
		leftMouseButton = FALSE 
	EndIf
  

	if (rollingBalls = FALSE) Then 
		if ((button = GLUT_RIGHT_BUTTON) And (state = GLUT_DOWN)) Then 
			pressedTheta = theta 
			shootMode = TRUE 
			rightMouseButton = TRUE 
		EndIf

		if ((button = GLUT_RIGHT_BUTTON) And (state = GLUT_UP)) Then 
			rightMouseButton = FALSE 

			Dim As GLfloat powX = power*(cos(theta)) 
	   	Dim As GLfloat powZ = power*(sin(theta)) 

			ballList(0).speed.x = powX*(-0.1) 
			ballList(0).speed.z = powZ*(-0.1) 

			doAnimation = TRUE 
		EndIf
	EndIf

	if ((button = GLUT_MIDDLE_BUTTON) And (state = GLUT_DOWN)) Then 
		middleMouseButton = TRUE 
		pressedZoom = zoom
	EndIf
  

	if ((button = GLUT_MIDDLE_BUTTON) And (state = GLUT_UP)) Then 
		middleMouseButton = FALSE
	EndIf

	glutPostRedisplay() 
End Sub

' Determines what happens when the mouse is moved.
Sub lookMouse cdecl(ByVal x As Integer ,ByVal y As Integer) 

	if (leftMouseButton = TRUE) Then 
		theta = pressedTheta + (x - prevMouseX)*0.005 
		elevationAngle = pressedElevation + (y - prevMouseY)*0.005 
	EndIf

	if (rightMouseButton = TRUE) Then 
		theta = pressedTheta + (x - prevMouseX)*0.005 
		power = 3.0 + (y - prevMouseY)*0.5 
		if (power >= 35.0) Then power = 35.0 
		if (power <= 3.0) Then power = 3.0 
	EndIf
  

	if (middleMouseButton = TRUE) Then 
		zoom = pressedZoom + (y - prevMouseY)*1.0 
		if (zoom < 10) Then zoom = 10 
		if (zoom > 100) Then zoom = 100 
	EndIf

	updateCamera() 
	glutPostRedisplay() 
End Sub

' Handles the collision of two balls on the table.
Sub deflectBalls(ballOne As Integer , ballTwo As Integer) 

	Dim As vector3 midPointConnectV = Type<vector3>(0.0, 0.0, 0.0) 
	Dim As vector3 relative = Type<vector3>(0.0, 0.0, 0.0) 
	Dim As Single impulse = 0.0, e = 0.8 

	midPointConnectV = ballList(ballOne).position - ballList(ballTwo).position 
	relative = ballList(ballOne).speed - ballList(ballTwo).speed 
	impulse = ((-1.0)*(1.0 + e)*(relative Mod midPointConnectV)) / (midPointConnectV Mod (midPointConnectV * (2.0 / ballList(ballOne).mass))) 

	ballList(ballOne).collided = TRUE 
	ballList(ballOne).speed = ballList(ballOne).speed + ((midPointConnectV)*(impulse / ballList(ballOne).mass)) 
	ballList(ballOne).updateSpeedSize() 
	if (ballList(ballOne).speedSize = 0) Then ballList(ballOne).speedSize = 0.000001 
	ballList(ballOne).accell = (ballList(ballOne).speed * -1.0) * (ballList(ballOne).accellSize) * (1 / ballList(ballOne).speedSize) 

	ballList(ballTwo).collided = TRUE 
	ballList(ballTwo).speed = ballList(ballTwo).speed - ((midPointConnectV)*(impulse / ballList(ballTwo).mass)) 
	ballList(ballTwo).updateSpeedSize() 
	if (ballList(ballTwo).speedSize = 0) Then ballList(ballTwo).speedSize = 0.000001 
	ballList(ballTwo).accell = (ballList(ballTwo).speed * -1.0) * (ballList(ballTwo).accellSize) * (1 / ballList(ballTwo).speedSize) 

	alSourcePlay(soundClip(COLLIDE)) 
	'if ((error = alGetError()) <> AL_NO_ERROR) Then 
	'	DisplayALError("alSourcePlay COLLIDE : ", error)
	'EndIf
  
End Sub

' Determines what happens when a ball is hit into a pocket.
Sub ballInPocket(ballNr As Integer , pocketNr As Integer) 

	ballList(ballNr).setPos(-1000.0, 2000, -1000) 

	if ((ballNr <> 0) And (ballList(ballNr).inPlay = TRUE)) Then 
		' No team
		if (players(currentPlayer).side = -1) Then 
			if (ballNr > 8) Then   
				players(currentPlayer).side = 1 
				players((currentPlayer+1) Mod playerCount).side = 0 
			ElseIf  (ballNr < 8) Then
				players(currentPlayer).side = 0 
				players((currentPlayer+1) Mod playerCount).side = 1 
			EndIf
			if (ballNr <> 8) Then 
				players(currentPlayer).noOfShots += 1 
				players(currentPlayer).balls(ballNr) = TRUE  ' Has team
			EndIf
		Else
			' Check that the correct team ball was hit
			if (players(currentPlayer).side = 0) Then   
				if (ballNr < 8) Then
					players(currentPlayer).noOfShots += 1
					players(currentPlayer).balls(ballNr) = TRUE 
				ElseIf  (ballNr > 8) Then 
					players(currentPlayer).noOfShots = 0 
					players((currentPlayer+1) Mod playerCount).noOfShots += 1 
					players((currentPlayer+1) Mod playerCount).balls(ballNr) = TRUE 
				EndIf
			ElseIf  (players(currentPlayer).side = 1) Then 
  
				if (ballNr > 8) Then   
					players(currentPlayer).noOfShots += 1 
					players(currentPlayer).balls(ballNr) = TRUE 
				ElseIf  (ballNr < 8) Then
					players(currentPlayer).noOfShots = 0 
					players((currentPlayer+1) Mod playerCount).noOfShots += 1 
					players((currentPlayer+1) Mod playerCount).balls(ballNr) = TRUE 
				EndIf
			EndIf
		EndIf
  

		' Eight-ball has been sunk (end of game), determine winner (if any).
		if (ballNr = 8) Then 
			if (players(currentPlayer).side <> -1) Then 
				Dim As Integer completeList = 0 
				for k As Integer =1 To 7        
					if (players(currentPlayer).balls(players(currentPlayer).side*8 + k) = TRUE) Then 
						completeList+=1 
					EndIf
            Next

				if (completeList = 7) Then 
					endGame+= "Player "
					endGame+= players(currentPlayer).nombre
					endGame+= " wins! "
				EndIf
  
			EndIf
 
			gameover = TRUE 
			glutPostRedisplay()

		Else
         
		returnWhiteBall = TRUE
		EndIf
  
		players((currentPlayer+1) Mod playerCount).noOfShots += 1 
		players(currentPlayer).noOfShots = 0 
	
	EndIf
  

	ballList(ballNr).inPlay = FALSE 

	alSourcePlay(soundClip(SINK)) 
	'if ((error = alGetError()) <> AL_NO_ERROR) Then 
	'	DisplayALError("alSourcePlay 0 : ", error)
	'EndIf
  
End Sub

' Instantiates the physics objects and reset them to predefined states.
Sub initPhysics() 

	' Setup balls´ positions on table
	ballList(0).mySpheres(0.0, 24.9 , minZ - minZ/3) 

	' Closely packed triangle (may cause some problems for collision detection/response)
	ballList(15).mySpheres(7.0, 24.9 , 27.0) 
	ballList(1).mySpheres(3.5, 24.9 , 27.0) 
	ballList(14).mySpheres(0.0, 24.9 , 27.0) 
	ballList(13).mySpheres(-3.5, 24.9 , 27.0) 
	ballList(2).mySpheres(-7.0, 24.9 , 27.0) 

	ballList(3).mySpheres(5.25, 24.9 , 23.5) 
	ballList(12).mySpheres(1.75, 24.9 , 23.5) 
	ballList(4).mySpheres(-1.75, 24.9 , 23.5) 
	ballList(11).mySpheres(-5.25, 24.9 , 23.5) 

	ballList(10).mySpheres(3.5, 24.9 , 20.0) 
	ballList(8).mySpheres(0.0, 24.9 , 20.0) 
	ballList(5).mySpheres(-3.5, 24.9 , 20.0) 

	ballList(6).mySpheres(1.75, 24.9 , 16.5) 
	ballList(7).mySpheres(-1.75, 24.9 , 16.5) 

	ballList(9).mySpheres(0.0, 24.9 , 13.0) 

	' Initialize physics properties for balls
	for r As Integer=0 To ballCount-1         
		ballList(r).setDefaults() 
   Next

End Sub

' Resets the game parameters and camera
Sub resetGame() 
	initPhysics() 
	setupPlayers() 
	gameover = FALSE 
	theta = M_PI + M_PI/2.0 
	updateTarget() 
	updateCamera() 
	endGame = "" 
End Sub

' Sets up the list of players
Sub setupPlayers() 

	for p As Integer=0 To playerCount-1         
		for i As Integer = 0 To ballCount-1
			players(p).balls(i) = FALSE
      Next
		players(p).nombre = nameList(p) 
		players(p).noOfShots = 0 
		players(p).side = -1 
		players(p).id = p 
   Next

	' First player in list starts the game
	players(0).noOfShots = 1 
	currentPlayer = 0 
End Sub

' Rendered window´s reshape function (manages changes to size of the window).
Sub changeParentWindow cdecl(ByVal width_ As GLsizei , ByVal height As GLsizei) 
	if height = 0 Then height = 100
	glViewport(0, 0, width_, height) 
   glMatrixMode(GL_PROJECTION) 
   glLoadIdentity() 
	gluPerspective(45.0, Cast(GLfloat,Width_/height), 0.1, 5000.0) 
   glMatrixMode(GL_MODELVIEW) 
   glLoadIdentity() 
End Sub

' Initializes the OpenGL display lists
Sub setupLists() 

	Dim As GLint listCount = 5 
	displayList(0) = glGenLists(listCount-1) 

	for k as GLint=1 To listCount-1         
		displayList(k) = displayList(0) + k 
   Next

	renderTableLegs() 
	renderTable()
	renderRoom() 
	renderBalcony()
End Sub


' Loads .WAV sound files using OpenAL (opensource multi-platform audio libraries)
Sub loadSound() 
	Dim As ALfloat listenerPos(2)={0.0,0.0,0.0} 
	Dim As ALfloat listenerVel(2)={0.0,0.0,0.0} 
	Dim As ALfloat listenerOri(5)={0.0,0.0,-1.0,  0.0,1.0,0.0}  ' "at", then "up"
	Dim As ALsizei _size,_freq 
	Dim As ALenum	_format
	Dim As ALvoid	Ptr _data
	Dim As ALboolean _loop
	Dim As ALuint NUM_BUFFERS = 4 
	
	Dim As String audioFiles(NUM_BUFFERS-1)
		audioFiles(0)="audio\shoot.wav"
		audioFiles(1)="audio\hit.wav"
		audioFiles(2)="audio\side.wav"
		audioFiles(3)="audio\sunk.wav"
	
	'Dim As ALuint g_Buffers(NUM_BUFFERS-1) 
	Dim As ALuint g_Buffers(NUM_BUFFERS-1) 

	' Initialize OpenAL
	alutInit(NULL,0) 
	alGetError() 

	' Generate Buffers
	alGenBuffers(NUM_BUFFERS, @g_Buffers(0)) 
	for k As ALuint=0 To NUM_BUFFERS-1         
		alutLoadWAVFile(StrPtr(audioFiles(k)),@_format,@_data,@_size,@_freq,@_loop) 
		alBufferData(g_Buffers(k),_format,_data,_size,_freq) 
		alutUnloadWAV(_format,_data,_size,_freq) 
   Next


	' Generate Sources
	alGenSources(NUM_BUFFERS, @soundClip(0)) 
	for r As ALuint=0 To NUM_BUFFERS-1         
		alSourcei(soundClip(r), AL_BUFFER, g_Buffers(r)) 
   Next


	' Set Listener Position ...
	alListenerfv(AL_POSITION,@listenerPos(0)) 
	ALError = alGetError()
	if ALError <> AL_NO_ERROR Then 
		Print "alListenerfv POSITION : "; Hex(ALError),ALError
		Sleep:end 
	EndIf
  

	' Set Listener Velocity ...
	alListenerfv(AL_VELOCITY,@listenerVel(0)) 
	ALError = alGetError()
	if ALError <> AL_NO_ERROR Then 
		Print "alListenerfv VELOCITY : "; ALError 
		Sleep:end  
	EndIf
  

	' Set Listener Orientation ...
	alListenerfv(AL_ORIENTATION,@listenerOri(0)) 
	ALError = alGetError()
	if ALError <> AL_NO_ERROR Then 
		Print "alListenerfv ORIENTATION : "; ALError 
		sleep:end  
	EndIf
	
	alSourcePlay(soundClip(SHOOT)) 
	alSourcePlay(soundClip(COLLIDE)) 
	alSourcePlay(soundClip(SIDES)) 
	alSourcePlay(soundClip(SINK)) 

End Sub



' Initializes basic lighting parameters for use in the final rendered scene.
Sub initlights() 

	' Global parameters / settings
	Dim As GLfloat lmodel_ambient(...) = { 0.5, 0.5, 0.5, 1.0 } 
	glLightModelfv(GL_LIGHT_MODEL_AMBIENT, @lmodel_ambient(0)) 
	glLightModeli(GL_LIGHT_MODEL_LOCAL_VIEWER, GL_TRUE) 
	Dim As GLfloat ambient(...) = { 0.8, 0.8, 0.8, 1.0 } 
	Dim As GLfloat specular(...) = { 1.0f, 1.0f, 1.0f, 1.0f} 

	' Table spotlight (0)
	glLightfv(GL_LIGHT0,GL_SPECULAR, @specular(0)) 
	glLightfv(GL_LIGHT0,GL_POSITION, @light0Pos(0)) 
	glLightf (GL_LIGHT0,GL_SPOT_CUTOFF,45.0f) 
	glLightf (GL_LIGHT0,GL_SPOT_EXPONENT,100.0f) 

	' Global Ambient light (1)
	glLightfv(GL_LIGHT1, GL_AMBIENT, @ambient(0)) 
	glLightfv(GL_LIGHT1, GL_DIFFUSE, @ambient(0)) 
   glLightfv(GL_LIGHT1, GL_POSITION, @light1Pos(0)) 

	' Material settings
   Dim As GLfloat mat_diffuse(...) = { 0.5, 0.5, 0.5, 1.0 } 
   Dim As GLfloat mat_specular(...) = { 1.0, 1.0, 1.0, 1.0 } 
   Dim As GLfloat mat_shininess(...) = { 80.0 } 
	glColorMaterial(GL_FRONT, GL_AMBIENT_AND_DIFFUSE) 
	glMaterialfv(GL_FRONT, GL_DIFFUSE, @mat_diffuse(0)) 
	glMaterialfv(GL_FRONT, GL_SPECULAR, @mat_specular(0)) 
	glMaterialfv(GL_FRONT, GL_SHININESS, @mat_shininess(0)) 

	' Enable lighting
	glEnable(GL_LIGHTING) 
	glEnable(GL_LIGHT0) 
	glEnable(GL_LIGHT1) 
End Sub

' Load Bitmaps And Convert To Textures
Sub LoadGLTextures() 

	glPixelStorei(GL_UNPACK_ALIGNMENT, 1) 

	for k As Integer=0 To textureCount-1         
		if ( LoadImagen(textureFilenames(k), @myTextureData(k))=0) Then Print "error cargando textura ";textureFilenames(k):Sleep:End

		' Various texture specific parameters, including wrapping/tiling and filtering.
		glGenTextures(1, @theTexture(k)) 
	    glBindTexture(GL_TEXTURE_2D, @theTexture(k)) 
	   	glTexParameterf(GL_TEXTURE_2D,GL_TEXTURE_WRAP_S,GL_REPEAT) 
	   	glTexParameterf(GL_TEXTURE_2D,GL_TEXTURE_WRAP_T,GL_REPEAT) 
	   	glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR) 
		glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR_MIPMAP_NEAREST) 
	   gluBuild2DMipmaps(GL_TEXTURE_2D, 3,myTextureData(k).sizeX, myTextureData(k).sizeY, GL_RGB, GL_UNSIGNED_BYTE, myTextureData(k).dato) 
	
   Next

End Sub

' Sets up some global OpenGL parameters..
Sub initScene() 

	LoadGLTextures() 
	loadSound() 

	glShadeModel(GL_SMOOTH) 
	glClearStencil(0) 
	glClearDepth(1.0f) 
	glEnable(GL_DEPTH_TEST) 
	glDepthFunc(GL_LEQUAL) 
	glHint(GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST) 
	glEnable(GL_TEXTURE_2D) 

	' Instantiates the quadric object used to render the pillars and table sides (etc.).
	pillarCylinder=gluNewQuadric() 
	gluQuadricNormals(pillarCylinder, GLU_FLAT) 
	gluQuadricOrientation(pillarCylinder, GLU_OUTSIDE) 
	gluQuadricTexture(pillarCylinder, GL_TRUE) 

	' Instantiates the quadric object used to render the billiard balls.
	ballQuadric=gluNewQuadric() 
	gluQuadricNormals(ballQuadric, GLU_SMOOTH) 
	gluQuadricOrientation(ballQuadric, GLU_OUTSIDE) 
	gluQuadricTexture(ballQuadric, GL_TRUE) 
	
End Sub



' -----------------------------------------------------------------------------
' The main function, sets up the window and links up the OpenGL GLUT functions.


	glutInit ( 1, strptr(" ")) 
	glutInitDisplayMode(GLUT_DEPTH Or GLUT_DOUBLE Or GLUT_RGBA Or GLUT_STENCIL) 
	glutInitWindowPosition(100,100) 
	glutInitWindowSize(parentWindowWidth,parentWindowHeight) 

	mainWindow = glutCreateWindow("The Blue Room")

	glutReshapeFunc(@changeParentWindow) 
	glutDisplayFunc(@renderParentWindow) 
	glutKeyboardFunc(@keys) 
	glutSpecialFunc(@specialKeyPressed) 
	glutMouseFunc(@useMouse) 
	glutMotionFunc(@lookMouse) 
	glutSetCursor(GLUT_CURSOR_CROSSHAIR) 
	glutIdleFunc(@idle) 
	'glutFullScreen() 

	initScene() 
	initlights() 
	setupLists() 
	resetGame() 
	
	
	glutMainLoop() 
