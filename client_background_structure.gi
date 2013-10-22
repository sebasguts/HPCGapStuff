
# DeclareGlobalVariable( "HOMALG_SEND_CHANNEL" );
# 
# InstallValue( HOMALG_SEND_CHANNEL,
#               CreateChannel( ) );

BindGlobal( "HOMALG_SEND_CHANNEL", CreateChannel( ) );

DeclareGlobalVariable( "HOMALG_RECEIVE_CHANNEL_LIST" );

InstallValue( HOMALG_RECEIVE_CHANNEL_LIST,
              [ ] );

ShareObj( HOMALG_RECEIVE_CHANNEL_LIST );

DeclareGlobalVariable( "HOMALG_RECEIVE_CHANNEL_LIST_IN_USE" );

InstallValue( HOMALG_RECEIVE_CHANNEL_LIST_IN_USE,
              [ ] );

ShareObj( HOMALG_RECEIVE_CHANNEL_LIST_IN_USE );



sender_client := function( output_address )
  local socket, sending_list;
  
  socket := ZmqPushSocket( );
  
  ZmqBind( socket, output_address );
  
  while true do
      
      sending_list := ReceiveChannel( HOMALG_SEND_CHANNEL );
      
      if IsString( sending_list ) and sending_list = "break" then
          
          ZmqSend( socket, [ "break" ] );
          
          break;
          
      fi;
      
      ZmqSend( socket, sending_list );
      
  od;
  
  ZmqClose( socket );
  
end;

receiver_client := function( input_address )
  local socket, received, channel, channel_number;
  
  socket := ZmqPullSocket( );
  
  ZmqConnect( socket, input_address );
  
  while true do
      
      received := ZmqReceiveList( socket );
      
      if received[ 1 ] = "break" then
          
          break;
          
      fi;
      
      channel_number := Int( received[ 1 ] );
      
      atomic readwrite HOMALG_RECEIVE_CHANNEL_LIST_IN_USE do
          
          channel := HOMALG_RECEIVE_CHANNEL_LIST_IN_USE[ channel_number ];
          
          Unbind( HOMALG_RECEIVE_CHANNEL_LIST_IN_USE[ channel_number ] );
          
      od;
      
      SendChannel( channel, received[ 2 ] );
      
      atomic readwrite HOMALG_RECEIVE_CHANNEL_LIST do
          
          Add( HOMALG_RECEIVE_CHANNEL_LIST, channel );
          
      od;
      
  od;
  
  ZmqClose( socket );
  
end;


push_to_server_with_return := function( command )
  local channel_number, channel, message, ret_val;
  
  atomic HOMALG_RECEIVE_CHANNEL_LIST do
      
      if Length( HOMALG_RECEIVE_CHANNEL_LIST ) > 0 then
          
          channel := Remove( HOMALG_RECEIVE_CHANNEL_LIST, 1 );
          
      else
          
          channel := CreateChannel( );
          
      fi;
      
  od;
  
  atomic HOMALG_RECEIVE_CHANNEL_LIST_IN_USE do
      
      channel_number := Length( HOMALG_RECEIVE_CHANNEL_LIST_IN_USE ) + 1;
      
      Add( HOMALG_RECEIVE_CHANNEL_LIST_IN_USE, channel );
      
  od;
  
  message := [ String( channel_number ), command ];
  
  SendChannel( HOMALG_SEND_CHANNEL, message );
  
  ret_val := ReceiveChannel( channel );
  
  NormalizeWhitespace( ret_val );
  
  return ret_val;
  
end;

push_to_server_without_return := function( command )
  local message;
  
  message := [ "nonblocking", command ];
  
  SendChannel( HOMALG_SEND_CHANNEL, message );
  
end;

input1 := `"tcp://127.0.0.1:33337";
 
output1 := `"tcp://127.0.0.1:33338";

CreateThread( sender_client, output1 );

CreateThread( receiver_client, input1 );


