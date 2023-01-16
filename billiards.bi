' Billiard ball simulator
' Created by Nelis Franken
' -----------------------------------------------------------
'  Main implementation´s header file
' -----------------------------------------------------------

#Undef BOOL
#Define BOOL UByte

#Undef TRUE
#Define TRUE 1

#Undef FALSE
#Define FALSE 0

#Define M_PI 3.14159265359
'#Define PI M_PI

#Include "GL/glut.bi"
#Include "AL/al.bi"
#include "AL/alut.bi"

#include "vector3.bi"
#Include "mySphere.bi"


' Various variable declarations.
' -------------------------------------------------------------------------------------------------

' Define ASCII values for special keystrokes.
#define ESCAPE 27
#define PAGE_UP 73
#define PAGE_DOWN 81
#define UP_ARROW 72
#define DOWN_ARROW 80
#define LEFT_ARROW 75
#define RIGHT_ARROW 77

' Define scene texture indices
' - ball textures remain numbers 0 - 15
' - mini ball icons numbers 16 - 31
' - character portraits 32 - 33
#define CUE 34
#define GREEN_CARPET 35
#define BLACK 36
#define WOOD 37
#define DARK_WOOD 38
#define CHECKER 39
#define RED_CARPET 40
#define BLUE_WALL 41
#define RED_LIGHT 42
#define BEIGE_WALL 43
#define DARKBLUE_MARBLE 44
#define RED_MARBLE 45
#define POWER_BAR 46
#define SEA_VIEW 47
#define SEA_VIEW2 48
#define PAINTING2 49
#define PAINTING1 50
#define ROOF 51

' Constants
Dim Shared As Integer ballCount= 16 
Dim Shared As Integer textureCount= 52 
Dim Shared As Integer playerCount= 2 

' Structures
Type Image 'Field=1
    As ULong sizeX 
    As ULong sizeY 
    As Byte Ptr Dato
End Type 

Type Player 
	As BOOL balls(ballCount-1) 
	As String nombre 
	As Integer noOfShots 
	As Integer side 
	As Integer id 
End Type 

' Various lists
Dim Shared As mySphere ballList(ballCount-1) 
Dim Shared As Image myTextureData(textureCount-1) 
Dim Shared As GLuint theTexture(textureCount-1) 
Dim Shared As Player players(playerCount-1) 
Dim Shared As GLint displayList(4) 


' sound OpenAl
Dim Shared As ALuint soundClip(3) 

' Define sound indices
#define SHOOT 0
#define COLLIDE 1
#define SIDES 2
#define SINK 3



' Camera and lighting positions
Dim Shared As GLdouble   camera(5) = {0.0, 60.0, 70.0, 0.0, 0.0, 0.0} 
Dim Shared As GLfloat light0Pos(3) = { 0.0f, 205.0, 0.0f, 1.0f }  ' Spotlight
Dim Shared As GLfloat light0Dir(2) = { 0.0f, -1.0f, 0.0f } 
Dim Shared As GLfloat light1Pos(3) = { 100.0, 205.0, 100.0, 1.0 }  ' Omni light

' Various essential flags, values and objects.
Dim Shared As ALint ALError 
Dim Shared As GLint mainWindow
Dim Shared As GLUquadricObj Ptr pillarCylinder, ballQuadric 

Dim Shared As GLfloat tableWidth, tableLength, pocketRadius, theta, power, elevationAngle, zoom, _
							 pressedTheta, pressedZoom, pressedElevation, maxX, minX, maxZ, minZ
							
	   tableWidth= 50.0
	   tableLength = 100.0
	   pocketRadius = 1.5
	   theta = M_PI + M_PI/2.0
		power = 3.0
		elevationAngle = 15.0*M_PI/180.0
		zoom = 65.0
		pressedTheta = 0.0
		pressedZoom = zoom
		pressedElevation = 0.0
		maxX = tableWidth /( 2.0) - 2
		minX = tableWidth /(-2.0) + 2
		maxZ = tableLength/( 2.0) - 2
		minZ = tableLength/(-2.0) + 2 



Dim Shared As GLint parentWindowHeight= 600, parentWindowWidth = 800, prevMouseX = 0, prevMouseY = 0, currentPlayer = 0 
Dim Shared As GLint font=GLUT_BITMAP_HELVETICA_12 , largeFont=GLUT_BITMAP_HELVETICA_18 

Dim Shared As BOOL shootMode= FALSE, doAnimation = FALSE, leftMouseButton = FALSE, rightMouseButton = FALSE, _
			 middleMouseButton = FALSE, turnStarting = TRUE, returnWhiteBall = FALSE, rollingBalls = FALSE, _
			 gameover = FALSE, useLazer = TRUE 

Dim Shared As String*20 endGame 


sub fillstring cdecl(s() as string,t as string="",...)
    dim as string ptr p=@s(lbound(s))
    dim as zstring ptr ptr  a=cptr(zstring ptr ptr,@@t)
    var sz=ubound(s)-lbound(s)+1
    for n as long=1 to sz
        p[n-1]=**(a+n)
    next
end Sub

' Texture names list
Dim Shared As String textureFilenames(textureCount-1) 

fillstring (textureFilenames(),, _
	"ball_white.bmp",_
	"ball_yellow_solid.bmp",_
	"ball_blue_solid.bmp",_
	"ball_red_solid.bmp",_
	"ball_purple_solid.bmp",_
	"ball_orange_solid.bmp",_
	"ball_green_solid.bmp",_
	"ball_brown_solid.bmp",_
	"ball_black.bmp",_
	"ball_yellow_stripe.bmp",_
	"ball_blue_stripe.bmp",_
	"ball_red_stripe.bmp",_
	"ball_purple_stripe.bmp",_
	"ball_orange_stripe.bmp",_
	"ball_green_stripe.bmp",_
	"ball_brown_stripe.bmp",_
	"mini_white.bmp",_
	"mini_yellow_solid.bmp",_
	"mini_blue_solid.bmp",_
	"mini_red_solid.bmp",_
	"mini_purple_solid.bmp",_
	"mini_orange_solid.bmp",_
	"mini_green_solid.bmp",_
	"mini_brown_solid.bmp",_
	"mini_black.bmp",_
	"mini_yellow_stripe.bmp",_
	"mini_blue_stripe.bmp",_
	"mini_red_stripe.bmp",_
	"mini_purple_stripe.bmp",_
	"mini_orange_stripe.bmp",_
	"mini_green_stripe.bmp",_
	"mini_brown_stripe.bmp",_
	"char1.bmp",_
	"char2.bmp",_
	"cuestick.bmp",_
	"carpet.bmp",_
	"black.bmp",_
	"wood.bmp",_
	"dark_wood.bmp",_
	"checker.bmp",_
	"marble.bmp",_
	"wall_dark2.bmp",_
	"red_light.bmp",_
	"grey_marble.bmp",_
	"darkblue_marble.bmp",_
	"red_marble.bmp",_
	"powerBar.bmp",_
	"view.bmp",_
	"view2.bmp",_
	"painting2.bmp",_
	"painting1.bmp",_
	"roof.bmp" )




' Player names list
Dim Shared As String nameList(playerCount-1)
nameList(0)="Xavier"
nameList(1)="Gabriel"



' Function declerations
' -------------------------------------------------------------------------------------------------

' Vertex generation and drawing tools
Declare Function getNormal(point1() As GLfloat , point3() As GLfloat , point4() As GLfloat) As vector3 
Declare Sub renderQuad(point1() As GLfloat , point2() As GLfloat , point3() As GLfloat , point4() As GLfloat , orientation As GLfloat , texXTile As GLfloat , texYTile As GLfloat) 
Declare Sub renderSurface(width_ As GLfloat , length As GLfloat , widthSegments As GLfloat , lengthSegments As GLfloat , elevation As GLfloat , texXTile As GLfloat , texYTile As GLfloat , normalX As GLfloat , normalY As GLfloat , normalZ As GLfloat , surfaceTexture As GLuint ptr) 
Declare Sub renderCurve(radius As GLfloat , height As GLfloat , sweep As GLfloat , segments As GLuint , orientation As GLfloat , aTexture As GLuint Ptr) 
Declare Sub renderCap(inner_radius As GLfloat , outer_radius As GLfloat , inner_sweep As GLfloat , outer_sweep As GLfloat , segments As GLuint , myTexture As GLuint Ptr) 

' Object rendering functions
Declare Sub renderBalls() 
Declare Sub renderPocket(sweep As GLfloat) 
Declare Sub renderTableLegs() 
Declare Sub renderTable() 
Declare Sub renderStairs(orientation As GLint , stepCount As GLfloat , stepWidth As GLfloat , stepWidthDecrease As GLfloat , totalHeight As GLfloat , myFlatTexture As GLuint ptr, myStepTexture As GLuint Ptr) 
Declare Sub renderBalcony() 
Declare Sub renderRoom() 
Declare Sub renderCueStick() 
Declare Sub drawSide() 
Declare Sub drawGuideLine() 

' Camera functions
Declare Sub updateCamera() 
Declare Sub updateTarget() 

' User interface functions
Declare Sub renderBitmapString(x As Single , y As Single , font As Integer , c As string) 
Declare Sub drawUI() 
Declare Sub drawEndScreen() 

' GLUT implementation functions and basic OpenGL setup (input/window handlers)
Declare Sub changeParentWindow cdecl(ByVal width_ As GLsizei ,ByVal  height As GLsizei) 
Declare Sub renderParentWindow Cdecl() 
Declare Sub keys Cdecl(ByVal key As ubyte,ByVal  x As Integer ,ByVal  y As Integer) 
Declare Sub specialKeyPressed Cdecl(ByVal key As Integer ,ByVal  x As Integer ,ByVal  y As Integer) 
Declare Sub useMouse Cdecl(ByVal button As Integer ,ByVal  state As Integer ,ByVal  x As Integer ,ByVal  y As Integer) 
Declare Sub lookMouse Cdecl(ByVal x As Integer ,ByVal  y As Integer) 
Declare Sub idle Cdecl()
'
Declare Sub switchToOrtho() 
Declare Sub switchFromOrtho() 
Declare Sub initlights() 
Declare Sub initScene()  

' Physics functions
Declare Sub deflectBalls(ballOne As Integer , ballTwo As Integer) 
Declare Sub ballInPocket(ballNr As Integer , pocketNr As Integer) 
Declare Sub initPhysics() 

' Setup functions (initializing display lists, loading sounds and textures, setting up players etc.)
'Declare Function DisplayALError( szText As ALbyte Ptr , errorcode As ALint) As ALvoid 
Declare Function LoadImagen( filename As string,  image As Image Ptr) As Integer 
Declare Sub setupPlayers() 
Declare Sub setupLists() 
Declare Sub resetGame() 
Declare Sub LoadGLTextures() 
Declare Sub loadSound() 
