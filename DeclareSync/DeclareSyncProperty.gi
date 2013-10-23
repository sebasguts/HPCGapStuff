
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
  
  name := arg[ 1 ];
  
  atomic readwrite HOMALG_SYNC_ATTR_REC do
      
      if not IsBound( HOMALG_SYNC_ATTR_REC.( name ) ) then
          
          HOMALG_SYNC_ATTR_REC.( name ) := true;
          
      fi;
      
  od;
  
  CallFuncList( type, arg );
  
end );

end;

DeclareSync( DeclareProperty, "DeclareSyncProperty" );
DeclareSync( DeclareAttribute, "DeclareSyncAttribute" );

ORIG_InstallMethod := InstallMethod;
MakeReadWriteGlobal( "InstallMethod" );
NEW_InstallMethod := function( arg )
  local name, install_different, old_func;
  
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
            
            SyncTryWrite( syncvar );
            
            return ret_val;
            
        fi;
        
        return SyncRead( syncvar );
        
      end;
      
  fi;
  
  CallFuncList( INSTALL_METHOD_WITHOUT_SYNC_HACK, arg );
  
end;
InstallMethod := NEW_InstallMethod;
MakeReadOnlyGlobal( "InstallMethod" );



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
          
          ## can we make sure here or better above that no one has
          ## written to the variable before? Maybe some atomic
          ## Flush/Write command?
          SyncTryWrite( x!.( sync_name ), ret_val );
          
          return ret_val;
          
      end;
      
  fi;
  
  CallFuncList( INSTALL_IMMEDIATE_METHOD_WITHOUT_SYNC_HACK, arg );
  
end;
InstallImmediateMethod := NEW_InstallImmediateMethod;
MakeReadOnlyGlobal( "InstallImmediateMethod" );


