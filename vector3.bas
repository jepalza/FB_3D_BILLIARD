' Billiard ball simulator
' Created by Nelis Franken
' -----------------------------------------------------------
' Custom vector class implementation file
' -----------------------------------------------------------

Constructor vector3 ( byref rhs as vector3  )
	This=rhs
End Constructor

Destructor vector3()
End Destructor

Constructor vector3(byref _x as Single=0, byref _y as Single=0, ByRef _z as Single=0)
  x=_x
  y=_y
  z=_z
end Constructor

' Allow two vectors to be able to be added together.
'Declare Operator + ( ByRef lhs As vector3, ByRef rhs As vector3 ) As Vector3

' Return the modulus (single) of the vector using the overloaded operator abs().
'Declare Operator Abs (  ByRef rhs As Vector3 ) As Single

Operator vector3.cast () As String
  Return "(" + Str(x) + ", " + Str(y) + ", "+Str(z) + ")"
End Operator

Operator + ( ByRef lhs As vector3, ByRef rhs As vector3 ) As Vector3
  Return Type<Vector3>( lhs.x + rhs.x, lhs.y + rhs.y, lhs.z + rhs.z )
End Operator

Operator + overload( ByRef lhs As vector3, ByRef rhs As Single ) As vector3
  Return Type<Vector3>( lhs.x + rhs, lhs.y + rhs, lhs.z + rhs )
End Operator

#If 0
Operator * ( ByRef lhs As vector3, ByRef rhs As vector3 ) As vector3
	Dim As vector3 resultVector = vector3(0.0, 0.0, 0.0)
		resultVector.x = lhs.y*Rhs.z - lhs.z*Rhs.y
		resultVector.y = -1.0*(lhs.x*Rhs.z - lhs.z*Rhs.x)
		resultVector.z = lhs.x*Rhs.y - lhs.y*Rhs.x
	return resultVector
  'Return Type<Vector3>( lhs.x * rhs.x, lhs.y * rhs.y, lhs.z * rhs.z )
End Operator
#endif

Operator * overload( ByRef lhs As vector3, ByRef rhs As Single ) As vector3
  Return Type<Vector3>( lhs.x * rhs, lhs.y * rhs, lhs.z * rhs )
End Operator

Operator - ( ByRef lhs As vector3, ByRef rhs As vector3 ) As Vector3
  Return Type<Vector3>( lhs.x - rhs.x, lhs.y - rhs.y, lhs.z - rhs.z )
End Operator

Operator - overload( ByRef lhs As vector3, ByRef rhs As Single ) As vector3
  Return Type<Vector3>( lhs.x - rhs, lhs.y - rhs, lhs.z - rhs )
End Operator

Operator / ( ByRef lhs As vector3, ByRef rhs As vector3 ) As Vector3
  Return Type<Vector3>( lhs.x / rhs.x, lhs.y / rhs.y, lhs.z / rhs.z )
End Operator

Operator / overload( ByRef lhs As vector3, ByRef rhs As Single ) As vector3
  Return Type<Vector3>( lhs.x / rhs, lhs.y / rhs, lhs.z / rhs )
End Operator

Operator vector3.Let ( byref rhs as vector3  )
  This.x = rhs.x
  This.y = rhs.y
  This.z = rhs.z
End Operator

Sub vector3.normalize() 
	Dim As Double power = Sqr(x*x + y*y + z*z) 
	x = x / power 
	y = y / power 
	z = z / power 
End Sub

Operator Mod ( ByRef lhs As vector3, ByRef rhs As vector3 ) As Single
	Dim As Single tempAnswer = 0.0 
	tempAnswer = (lhs.x * Rhs.x) + (lhs.y * Rhs.y) + (lhs.z * Rhs.z) 
	Return tempAnswer 
End Operator