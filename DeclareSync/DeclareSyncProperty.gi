
DeclareGlobalVariable( "HOMALG_SYNC_ATTR_REC" );

InstallValue( HOMALG_SYNC_ATTR_REC,
              rec( ) );

ShareObj( HOMALG_SYNC_ATTR_REC );



BindGlobal( "INSTALL_METHOD_WITHOUT_HACK",
              InstallMethod );

MakeImmutable( INSTALL_METHOD_WITHOUT_HACK );

DeclareSync := function( type, sync_name )

BindGlobal( sync_name,
function( arg )
  local name, async_name;
  
  CallFuncList( type, arg );
  
  name := arg[ 1 ];
  
  MakeReadOnly( name );
  
  atomic readwrite HOMALG_SYNC_ATTR_REC do
      
      if IsBound( HOMALG_SYNC_ATTR_REC.(name) ) then
          
          async_name := HOMALG_SYNC_ATTR_REC.(name);
          
      else
          
          async_name := Concatenation( arg[ 1 ], "_async_generated" );
          
          MakeReadOnly( async_name );
          
          HOMALG_SYNC_ATTR_REC.(name) := async_name;
          
      fi;
      
  od;
  
  arg[ 1 ] := async_name;
  
  CallFuncList( type, arg );
  
  INSTALL_METHOD_WITHOUT_HACK( ValueGlobal( name ),
                 "generated",
                 [ arg[ 2 ] ],
                 
    function( x )
        local is_calculator, locker, semaphores, semaphore_list, semaphore, i,
              ret_val;
        
        is_calculator := false;
        
        locker := Concatenation( name, "calculating" );
        
        semaphores := Concatenation( name, "semaphores" );
        
        atomic readwrite x do
            
            if not IsBound( x!.( locker ) ) then
                
                x!.( locker ) := true;
                
                is_calculator := true;
                
                x!.( semaphores ):= ShareObj( [ ] );
                
            fi;
            
        od;
        
        if is_calculator then
            
            ret_val := CallFuncList( ValueGlobal( async_name ), [ x ] );
            
            ## to not confuse the other threads
            Setter( ValueGlobal( name ) )( x, ret_val );
            
            atomic readwrite x!.( semaphores ) do
                
                ## this can be done more efficient
                for i in x!.( semaphores ) do
                    
                    SignalSemaphore( i );
                    
                od;
                
                x!.( semaphores ) := false;
                
            od;
            
            Unbind( x!.( locker ) );
            
            return ret_val;
            
        else
            
            
            ## this needs to be here to not hold the lock longer than needed
            semaphore := CreateSemaphore( );
            
            atomic readwrite x!.( semaphores ) do
                
                if x!.( semaphores ) = false then
                    
                    SignalSemaphore( semaphore );
                    
                else
                    
                    Add( x!.( semaphores ), semaphore );
                    
                fi;
                
            od;
            
            WaitSemaphore( semaphore );
            
            ## GAP now knows the value
            return ValueGlobal( async_name )( x );
            
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


