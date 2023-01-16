' Billiard ball simulator
' Created by Nelis Franken
' -----------------------------------------------------------
'  Header file for basic vector class
' -----------------------------------------------------------

Type vector3
	 As single x, y, z 
    
    declare Destructor ()
    
    'Declare Constructor ()
    Declare Constructor ( byref _x as Single=0, byref _y as Single=0, ByRef _z as Single=0 )
    declare Constructor ( byref rhs as vector3 )
    Declare Operator Let ( byref rhs as vector3 )
    
    declare Sub normalize()

    Declare Operator *= ( ByVal rhs as vector3 )   
    declare Operator *= ( ByRef rhs as Single  )    
    
    declare Operator -= ( ByVal rhs as vector3 )
    declare Operator -= ( ByVal rhs as Single  )
    
    declare Operator += ( ByVal rhs as vector3 )
    declare Operator += ( ByRef rhs as Single  )
    
    declare Operator /= ( ByVal rhs as vector3 )
    declare Operator /= ( ByVal rhs as Single  )
       
    Declare Operator mod= ( ByVal rhs as vector3 )
    
    ' Return a string containing the vector data.
    Declare Operator Cast() As String
End Type