
## Declare the shared list of pipes
## Must be global for every function
## to see the same list

DeclareGlobalVariable( "HOMALG_connection_pipe_list" );

InstallValue( HOMALG_connection_pipe_list,
              [ ] );

ShareLibraryObj( HOMALG_connection_pipe_list );

DeclareGlobalVariable( "HOMALG_connection_pipe_list_semaphore" );

InstallValue( HOMALG_connection_pipe_list_semaphore,
              CreateSemaphore( 0 ) );

Connection := function( input_address, output_address )
  local conn_rec, input_connection, output_connection;
  
  conn_rec := rec( );
  
  input_connection := ZmqPullSocket( );
  
  output_connection := ZmqPushSocket( );
  
  ZmqConnect( input_connection, input_address );
  
  ZmqBind( output_connection, output_address );
  
  conn_rec.input := input_connection;
  
  conn_rec.output := output_connection;
  
  ShareObj( conn_rec );
  
  return conn_rec;
  
end;

initialize_client := function( io_address_list )
  local i;
  
  atomic readwrite HOMALG_connection_pipe_list do
      
      for i in io_address_list do
          
          Add( HOMALG_connection_pipe_list, CallFuncList( Connection, i ) );
          
          SignalSemaphore( HOMALG_connection_pipe_list_semaphore );
          
      od;
      
  od;
  
end;

homalg_send_nonblocking := function( command_string )
  local connection_rec, i;
  
  ## aquire lock on one connection
  
  while not IsBound( connection_rec ) do
      
      atomic readwrite HOMALG_connection_pipe_list do
          
          if Length( HOMALG_connection_pipe_list ) > 0 then
              
              connection_rec := Remove( HOMALG_connection_pipe_list, 1 );
              
          fi;
          
      od;
      
  od;
  
  ## The string doesn't matter
  
  atomic readwrite connection_rec do
      
      ZmqSend( connection_rec.output, [ "nonblock", command_string ] );
      
  od;
  
  atomic readwrite HOMALG_connection_pipe_list do
      
      Add( HOMALG_connection_pipe_list, connection_rec );
      
  od;
  
end;

homalg_send_blocking := function( command_string )
  local connection_rec, i, result;
  
  ## aquire lock on one connection
  
  ## Use semaphore instead.
  
  WaitSemaphore( HOMALG_connection_pipe_list_semaphore );
  
  atomic readwrite HOMALG_connection_pipe_list do
      
      connection_rec := Remove( HOMALG_connection_pipe_list, 1 );
      
  od;
  
  atomic readwrite connection_rec do
      
      ZmqSend( connection_rec.output, [ "block", command_string ] );
      
      result := ZmqReceive( connection_rec.input );
      
  od;
  
  atomic readwrite HOMALG_connection_pipe_list do
      
      Add( HOMALG_connection_pipe_list, connection_rec );
      
      SignalSemaphore( HOMALG_connection_pipe_list_semaphore );
      
  od;
  
  NormalizeWhitespace( result );
  
  return result;
  
end;

initialize_client( [ [ "tcp://127.0.0.1:33338", "tcp://127.0.0.1:33337" ], [ "tcp://127.0.0.1:33340", "tcp://127.0.0.1:33339" ] ] );
