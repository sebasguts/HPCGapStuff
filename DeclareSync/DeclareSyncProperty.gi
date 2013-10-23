
DeclareGlobalVariable( "HOMALG_SYNC_ATTR_REC" );

InstallValue( HOMALG_SYNC_ATTR_REC,
              rec( ) );

ShareObj( HOMALG_SYNC_ATTR_REC );



BindGlobal( "INSTALL_METHOD_WITHOUT_SYNC_HACK",
              InstallMethod );

MakeImmutable( INSTALL_METHOD_WITHOUT_SYNC_HACK );


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
        local is_calculator, locker, semaphores, semaphore_list, semaphore, i,
              ret_val, syncvar;
        
        is_calculator := false;
        
        syncvar := Concatenation( async_name, "_syncvar" );
        
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


