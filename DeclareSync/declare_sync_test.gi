Read( "DeclareSyncProperty.gi" );

DeclareRepresentation( "IsMyObject",
                       IsObject and IsAttributeStoringRep,
                       [ ]
                     );

BindGlobal( "TheFamilyOfMyType",
        NewFamily( "TheFamilyOfMyType" , IsMyObject ) );

BindGlobal( "TheTypeOfMyObj",
        NewType( TheFamilyOfMyType,
                IsMyObject ) );

DeclareSyncProperty( "TestProp",
                     IsMyObject );

InstallMethod( TestProp,
               [ IsMyObject ],
               
  function( x )
    
    ## my favorite!!
    Factorial( x!.count );
    
    return true;
    
end );

a := rec( count := 50 );

b := rec( count := 100000000 );

Objectify( TheTypeOfMyObj, a );

Objectify( TheTypeOfMyObj, b );

InstallImmediateMethod( TestProp,
                        IsMyObject,
                        0,
                        
  function( x )
    
    Factorial( x!.count );
    
    return true;
    
end );

c := rec( count := 100000000 );



