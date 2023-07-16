class Archipelago_CommandHelper extends Hat_PlayerInput;

`include(APRandomizer\Classes\Globals.uci);

exec function ap_set_connection_info(string ip, int port)
{
	if (`AP.Client == None)
	{
		`AP.CreateClient();
	}
	
	`AP.SlotData.Host = ip;
	`AP.SlotData.Port = port;
	`AP.ScreenMessage("Set target host to: "$ip $":" $port);
}

exec function ap_show_connection_info()
{
	if (`AP.Client != None)
	{
		`AP.ScreenMessage("Current target host: "$`AP.SlotData.Host $":" $`AP.SlotData.Port);
	}
}

exec function ap_say(string message)
{
	local JsonObject json;
	
	if (!`AP.IsFullyConnected())
	{
		`AP.ScreenMessage("You are not connected.");
		return;
	}
	
	json = new class'JsonObject';
	json.SetStringValue("cmd", "Say");
	json.SetStringValue("text", message);
	`AP.Client.SendBinaryMessage("[" $class'JsonObject'.static.EncodeJson(json) $"]");
}

exec function ap_connect()
{
	if (`AP.Client == None)
		`AP.CreateClient();
	
	if (`AP.IsFullyConnected())
		return;
	
	`AP.Client.Connect();
}

exec function ap_deathlink()
{
	local bool val;
	local string message;
	
	if (`AP.Client == None || !`AP.IsFullyConnected())
	{
		`AP.ScreenMessage("You are not connected.");
		return;
	}
	
	val = !`AP.SlotData.DeathLink;
	
	if (val)
	{
		message = "[{\"cmd\": \"ConnectUpdate\", \"tags\": [\"DeathLink\"]}]";
		`AP.ScreenMessage("Death Link enabled.");
	}
	else
	{
		message = "[{\"cmd\": \"ConnectUpdate\", \"tags\": []}]";
		`AP.ScreenMessage("Death Link disabled.");
	}
	
	`AP.Client.SendBinaryMessage(message);
	`AP.SlotData.DeathLink = val;
	`AP.SaveGame();
}

// -------------------------------------------- DEBUG COMMANDS -------------------------------------------- \\
exec function ap_teleport(float x, float y, float z)
{
	local Vector loc;
	
	if (!bool(`AP.DebugMode))
		return;
	
	loc.x = x;
	loc.y = y;
	loc.z = z;
	GetPlayerController().Pawn.SetLocation(loc);
}

exec function ap_give_yarn(int count)
{
	if (!bool(`AP.DebugMode) || count <= 0)
		return;
		
	`AP.OnYarnCollected(count);
	`AP.ScreenMessage("Gave " $count $" yarn");
}

exec function ap_complete_act(string id)
{
	if (!bool(`AP.DebugMode))
		return;
		
	`AP.SetAPBits("ActComplete_"$id, 1);
	`AP.ScreenMessage("Completed act: " $id);
}

function Hat_PlayerController GetPlayerController()
{
	local Hat_PlayerController c;

	foreach class'WorldInfo'.static.GetWorldInfo().AllControllers(class'Hat_PlayerController', c)
	{
		if (c.PlayerInput == self)
			return c;
	}
	
	return None;
}