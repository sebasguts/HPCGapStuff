## Establish connections

Connection := function( input_address, output_address )
  local conn_rec, input_connection, output_connection;
  
  conn_rec := rec( );
  
  input_connection := ZmqPullSocket( );
  
  output_connection := ZmqPushSocket( );
  
  ZmqConnect( input_connection, input_address );
  
  ZmqBind( output_connection, output_address );
  
  conn_rec.input_connection := input_connection;
  
  conn_rec.output_connection := output_connection;
  
  MakeReadOnlyObj( conn_rec.input_connection );
  
  MakeReadOnlyObj( conn_rec.output_connection );
  
  MakeReadOnlyObj( conn_rec );
  
  return conn_rec;
  
end;

SendBlocking := function( connection, command_string )
  local string;
  
  ZmqSend( connection.output_connection, [ "block", command_string ] );
  
  string := ZmqReceive( connection.input_connection );
  
  NormalizeWhitespace( string );
  
  return string;
  
end;

SendNonBlocking := function( connection, command_string )
  
  ZmqSend( connection.output_connection, [ "nonblock", command_string ] );
  
end;

KillServer := function( connection )
  
  ZmqSend( connection.output_connection, [ "kill", "bla" ] );
  
end;

connection1 := Connection( "tcp://127.0.0.1:33338", "tcp://127.0.0.1:33337" );

connection2 := Connection( "tcp://127.0.0.1:33340", "tcp://127.0.0.1:33339" );
