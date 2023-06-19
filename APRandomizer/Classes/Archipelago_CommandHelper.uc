class Archipelago_CommandHelper extends Hat_PlayerInput;

`include(APRandomizer\Classes\Globals.uci);

exec function ap_set_connection_info(string ip, int port)
{
	if (`AP.Client != None)
	{
		`AP.Client.TargetHost = ip;
		`AP.Client.TargetPort = port;
		
		`AP.ScreenMessage("Set target host to: "$ip $":" $port);
	}
}

exec function ap_show_connection_info()
{
	if (`AP.Client != None)
	{
		`AP.ScreenMessage("Current target host: "$`AP.Client.TargetHost $":" $`AP.Client.TargetPort);
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
	if (`AP.Client != None)
		`AP.Client.Connect();
}

exec function ap_deathlink(int num)
{
	local string message;
	local bool enabled;

	if (!`AP.IsFullyConnected())
	{
		`AP.ScreenMessage("You are not connected.");
		return;
	}
	
	enabled = bool(num);
	`AP.SlotData.DeathLink = enabled;
	if (enabled)
	{
		message = "[{\"cmd\":\"ConnectUpdate\", \"tags\":[\"DeathLink\"]}]";
		`AP.ScreenMessage("Death Link enabled");
	}
	else
	{
		message = "[{\"cmd\":\"ConnectUpdate\", \"tags\":[]}]";
		`AP.ScreenMessage("Death Link disabled");
	}
	
	`AP.Client.SendBinaryMessage(message);
}

// -------------------------------------------- DEBUG COMMANDS -------------------------------------------- \\
exec function ap_debug()
{
	if (!`AP.DebugMode)
	{
		`AP.DebugMode = true;
		`AP.ScreenMessage("Debug mode ON");
	}
	else
	{
		`AP.DebugMode = false;
		`AP.ScreenMessage("Debug mode OFF");
	}
}

exec function ap_teleport(float x, float y, float z)
{
	local Vector loc;
	
	if (!`AP.DebugMode)
		return;
	
	loc.x = x;
	loc.y = y;
	loc.z = z;
	GetPlayerController().Pawn.SetLocation(loc);
}

exec function ap_disable_item_collision()
{
	local Hat_Collectible_Inventory item;
	
	if (!`AP.DebugMode)
		return;
	
	foreach class'WorldInfo'.static.GetWorldInfo().DynamicActors(class'Hat_Collectible_Inventory', item)
	{
		item.SetCollision(false, false);
	}
	
	`AP.ScreenMessage("Disabled item collision");
}

exec function ap_enable_item_collision()
{
	local Hat_Collectible_Inventory item;
	if (!`AP.DebugMode)
		return;
	
	foreach class'WorldInfo'.static.GetWorldInfo().DynamicActors(class'Hat_Collectible_Inventory', item)
	{
		item.SetCollision(true, true);
	}
	
	`AP.ScreenMessage("Enabled item collision");
}

exec function ap_give_yarn(int count)
{
	if (!`AP.DebugMode || count <= 0)
		return;
		
	`AP.OnYarnCollected(count);
	`AP.ScreenMessage("Gave " $count $" yarn");
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