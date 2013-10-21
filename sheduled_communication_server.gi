server := function( input_address, output_address )
  local input_connection, output_connection, tester,
        list, input_stream, output_stream, output_string;
  
  ## establish connection
  
  atomic readwrite ZmqPullSocket, ZmqPushSocket, input_address, output_address do
  
  input_connection := ZmqPullSocket( );
  
  output_connection := ZmqPushSocket( );
  
  ZmqConnect( input_connection, input_address );
  
  ZmqBind( output_connection, output_address );
  
  od;
  
  ##Start main loop
  while true do
      
      Print( "Command: \n" );
      
      list := ZmqReceiveList( input_connection );
      
      if list[ 1 ] = "kill" then
          
          break;
          
      fi;
      
      if list[ 2 ][ Length( list[ 2 ] ) ] <> ';' then
          
          Add( list[ 2 ], ';' );
          
      fi;
      
      ## control blocking and nonblocking by list 1
      input_stream := InputTextString( list[ 2 ] );
      
      Print( "gap> ", list[ 2 ], "\n" );
      
      output_string := "";
      
      output_stream := OutputTextString( output_string, false );
      
      SetOutput( output_stream, true );
      
      READ_STREAM_LOOP( input_stream, true );
      
      SetPreviousOutput();
      
      Print( output_string, "\n" );
      
      if list[ 1 ] = "block" then
          
          ZmqSend( output_connection, output_string );
          
      fi;
      
      CloseStream( input_stream );
      
      CloseStream( output_stream );
      
  od;
  
  ZmqClose( input_connection );
  
  ZmqClose( output_connection );
  
end;

input1 := "tcp://127.0.0.1:33337";

output1 := "tcp://127.0.0.1:33338";

input2 := "tcp://127.0.0.1:33339";

output2 := "tcp://127.0.0.1:33340";

Perform(  [ input1, output1, input2, output2 ], ShareObj );

server1 := CreateThread( server, input1, output1 );

server2 := CreateThread( server, input2, output2 );
