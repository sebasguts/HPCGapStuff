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

DeclareFilter( "IsSomething" );

InstallImmediateMethod( TestProp,
                        IsMyObject and IsSomething,
                        0,
                        
  function( x )
    
    return true;
    
end );
