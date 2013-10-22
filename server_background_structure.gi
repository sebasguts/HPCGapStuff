
DeclareGlobalVariable( "HOMALG_SEND_CHANNEL" );

InstallValue( HOMALG_SEND_CHANNEL,
              CreateChannel );


server_background_receiver := function( input_address )
  local input_socket, received, command;
  
  input_socket := ZmqPullSocket( );
  
  ZmqConnect( input_socket, input_address );
  
  while true do
      
      received := ZmqReceiveList( input_socket );
      
      if received[ 1 ] = "break" then
          
          SendChannel( HOMALG_SEND_CHANNEL, "break" );
          
          break;
          
      fi;
      
      command := received[ 2 ];
      
      if command[ Length( command ) ] <> ';' then
          
          Add( command, ';' );
          
      fi;
      
      if received[ 1 ] = "nonblocking" then
          
          RunTask( READ_STREAM_LOOP, command, true );
          
      else
          
          RunTask( launch_command_and_send_back_value, received[ 1 ], received[ 2 ] );
          
      fi;
      
  od;
  
  ZmqClose( input_socket );
  
end;

server_background_sender := function( output_address )
  local output_socket, sending;
  
  output_socket := ZmqPushSocket( );
  
  ZmqBind( output_socket, output_address );
  
  while true do
      
      sending := ReceiveChannel( HOMALG_SEND_CHANNEL );
      
      if sending = "break" then
          
          ZmqSend( output_socket, "break" );
          
          break;
          
      fi;
      
      ZmqSend( output_socket, sending );
      
  od;
  
  ZmqClose( output_socket );
  
end;

launch_command_and_send_back_value := function( return_string, command )
  local input_stream, output_string, output_stream;
  
  input_stream := InputTextString( command );
  
  Print( "gap> ", command, "\n" );
  
  output_string := "";
  
  output_stream := OutputTextString( output_string, false );
  
  SetOutput( output_stream, true );
  
  READ_STREAM_LOOP( input_stream, true );
  
  SetPreviousOutput();
  
  Print( output_string, "\n" );
  
  SendChannel( HOMALG_SEND_CHANNEL, [ return_string, output_string ] );
  
end;

output := `"tcp://127.0.0.1:33337";
 
input := `"tcp://127.0.0.1:33338";

CreateThread( server_background_sender, output );

CreateThread( server_background_receiver, input );