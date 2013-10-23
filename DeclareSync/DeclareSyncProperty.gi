
DeclareGlobalVariable( "HOMALG_SYNC_ATTR_REC" );

InstallValue( HOMALG_SYNC_ATTR_REC,
              rec( ) );

ShareObj( HOMALG_SYNC_ATTR_REC );



BindGlobal( "INSTALL_METHOD_WITHOUT_SYNC_HACK",
              InstallMethod );

MakeImmutable( INSTALL_METHOD_WITHOUT_SYNC_HACK );

BindGlobal( "INSTALL_IMMEDIATE_METHOD_WITHOUT_SYNC_HACK",
              InstallImmediateMethod );

MakeImmutable( INSTALL_IMMEDIATE_METHOD_WITHOUT_SYNC_HACK );


BindGlobal( "HOMALG_SYNC_LOCK",
            ShareInternalObj( [ ] ) );

DeclareSync := function( type, sync_name )

BindGlobal( sync_name,
function( arg )
  local name, async_name;
  
  CallFuncList( type, arg );
  
  name := arg[ 1 ];
  
  MakeReadOnly( name );
  
  async_name := Concatenation( arg[ 1 ], "_async_generated" );
  
  MakeReadOnly( async_name );
  
  ## Remove this
  atomic readwrite HOMALG_SYNC_ATTR_REC do
      
      if not IsBound( HOMALG_SYNC_ATTR_REC.(name) ) then
          
          HOMALG_SYNC_ATTR_REC.(name) := async_name;
          
      fi;
      
  od;
  
  arg[ 1 ] := async_name;
  
  CallFuncList( type, arg );
  
  INSTALL_METHOD_WITHOUT_SYNC_HACK( ValueGlobal( name ),
                 "generated",
                 [ arg[ 2 ] ],
                 
    function( x )
        local is_calculator,
              ret_val, syncvar;
        
        is_calculator := false;
        
        syncvar := Concatenation( name, "_syncvar" );
        
        if not IsBound( x!.( syncvar ) ) then
            
            atomic readwrite HOMALG_SYNC_LOCK do
                
                if not IsBound( x!.( syncvar ) ) then
                    
                    is_calculator := true;
                    
                    x!.( syncvar ):= CreateSyncVar( );
                    
                fi;
                
            od;
            
        fi;
        
        if is_calculator then
            
            ret_val := CallFuncList( ValueGlobal( async_name ), [ x ] );
            
            ## to not confuse the other threads
            Setter( ValueGlobal( name ) )( x, ret_val );
            
            SyncWrite( x!.( syncvar ), ret_val );
            
            return ret_val;
            
        else
            
            return SyncRead( x!.( syncvar ) );
            
        fi;
        
    end );
  
end ); 

end;

DeclareSync( DeclareProperty, "DeclareSyncProperty" );
DeclareSync( DeclareAttribute, "DeclareSyncAttribute" );

ORIG_InstallMethod := InstallMethod;
MakeReadWriteGlobal( "InstallMethod" );
NEW_InstallMethod := function( arg )
  local name;
  
  name := NameFunction( arg[ 1 ] );
  
  atomic readonly HOMALG_SYNC_ATTR_REC do
      
      if IsBound( HOMALG_SYNC_ATTR_REC.(name) ) then
          
          arg[ 1 ] := ValueGlobal( HOMALG_SYNC_ATTR_REC.(name) );
          
      fi;
      
  od;
  
  CallFuncList( ORIG_InstallMethod, arg );
  
end;
InstallMethod := NEW_InstallMethod;
MakeReadOnlyGlobal( "InstallMethod" );

NEW_InstallMethod := function( arg )
  local name, install_different;
  
  name := NameFunction( arg[ 1 ] );
  
  atomic readonly HOMALG_SYNC_ATTR_REC do
      
      if IsBound( HOMALG_SYNC_ATTR_REC.( name ) ) then
          
          install_different := true;
          
      fi;
      
  od;
  
  MakeReadOnly( name );
  
  if install_different then
      
      old_func := arg[ Length( arg ) ];
      
      ## can only take one argument.
      arg[ Length( arg ) ] := function( x )
        local syncvar, sync_name, computes, ret_val;
        
        computes := false;
        
        sync_name := Concatenation( name, "_syncvar" );
        
        if not IsBound( x!.( sync_name ) ) then
            
            atomic readwrite HOMALG_SYNC_LOCK do
                
                if not IsBound( x!.( sync_name ) ) then
                    
                    x!.( sync_name ) := CreateSyncVar( );
                    
                    computes := true;
                    
                fi;
                
            od;
            
        fi;
        
        syncvar := x!.( sync_name );
        
        if computes then
            
            ret_val := old_func( x );
            
            SyncWrite( syncvar );
            
            return ret_val;
            
        fi;
        
        return SyncRead( syncvar );
        
      end;
      
  fi;
  
  CallFuncList( INSTALL_METHOD_WITHOUT_SYNC_HACK, arg );
  
end;

ORIG_InstallImmediateMethod := InstallImmediateMethod;
MakeReadWriteGlobal( "InstallImmediateMethod" );
NEW_InstallImmediateMethod := function( arg )
  local name, install_different, old_func, old_func_index, syncvar;
  
  name := NameFunction( arg[ 1 ] );
  
  install_different := false;
  
  atomic readonly HOMALG_SYNC_ATTR_REC do
      
      if IsBound( HOMALG_SYNC_ATTR_REC.(name) ) then
          
          install_different := true;
          
      fi;
      
  od;
  
  if install_different then
      
      old_func := arg[ Length( arg ) ];
      
      arg[ Length( arg ) ] :=
          
          function( x )
              local syncvar, sync_name, sync_tester, ret_val;
              
              sync_name := Concatenation( name, "_syncvar" );
              
              if not IsBound( x!.( sync_name ) ) then
                  
                  atomic readwrite HOMALG_SYNC_LOCK do
                      
                      if not IsBound( x!.( sync_name ) ) then
                          
                          syncvar := CreateSyncVar( );
                          
                          x!.( sync_name ) := syncvar;
                          
                      fi;
                      
                  od;
                  
              fi;
              
              ret_val := old_func( x );
              
              if IsBound( syncvar ) then
                  
                  SyncWrite( syncvar, ret_val );
                  
              fi;
              
              return ret_val;
              
          end;
          
      CallFuncList( INSTALL_IMMEDIATE_METHOD_WITHOUT_SYNC_HACK, arg );
      
  else
      
      CallFuncList( INSTALL_IMMEDIATE_METHOD_WITHOUT_SYNC_HACK, arg );
      
  fi;
  
end;
InstallImmediateMethod := NEW_InstallImmediateMethod;
MakeReadOnlyGlobal( "InstallImmediateMethod" );


