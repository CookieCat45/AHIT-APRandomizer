class Archipelago_BroadcastHandler extends BroadcastHandler;

// Remove broadcasting limits
function bool AllowsBroadcast(Actor broadcaster, int inLen)
{
	return true;
}

function BroadcastText( PlayerReplicationInfo SenderPRI, PlayerController Receiver, coerce string Msg, optional name Type )
{
	Receiver.TeamMessage(SenderPRI, Msg, Type, 7.0); // and extend message lifetime
}