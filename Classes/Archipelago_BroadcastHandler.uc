class Archipelago_BroadcastHandler extends BroadcastHandler;

// Remove broadcasting limits
function bool AllowsBroadcast(Actor broadcaster, int inLen)
{
	return true;
}