class Archipelago_HUDElementLocationBanner_Metro extends Hat_HUDElementLocationBanner_Metro;

`include(APRandomizer\Classes\Globals.uci);

function RefreshIcons(HUD H, Name InLocationName)
{
	local Hat_ChapterInfo ci;
	local int i, NumClaimedTP, NumUnclaimedTP, NumUnclaimedManholeTP;
	local Array<class<object>> MetroTickets;
	local Hat_Loadout MyLoadout;
	
	Icons.Length = 0;
	
	if (IsInFinaleEscape)
	{
		Icons.AddItem(EscapeIcon);
		return;
	}
	
	ci = `GameManager.GetChapterInfo();
	if (ci != None && InLocationName != '')
	{
		ci.ConditionalUpdateActList();
		for (i = 0; i < ci.ChapterActInfo.Length; i++)
		{
			if (ci.ChapterActInfo[i].Hourglass == "") continue;
			if (ci.ChapterActInfo[i].InDevelopment) continue;
			if (ci.ChapterActInfo[i].LocationName != InLocationName) continue;
			
			if (`AP.IsActReallyCompleted(ci.ChapterActInfo[i])) NumClaimedTP++;
			else if (IsManhole(ci.ChapterActInfo[i])) NumUnclaimedManholeTP++;
			else NumUnclaimedTP++;
		}
		
		for (i = 0; i < NumClaimedTP; i++) Icons.AddItem(TimePieceIcon[0]);
		for (i = 0; i < NumUnclaimedTP; i++) Icons.AddItem(TimePieceIcon[1]);
		for (i = 0; i < NumUnclaimedManholeTP; i++) Icons.AddItem(TimePieceIcon[2]);
		
		MetroTickets = class'Hat_ClassHelper'.static.GetAllScriptClasses("Hat_Collectible_MetroTicket_Base");
		MyLoadout = Hat_PlayerController(H.PlayerOwner).GetLoadout();
		for (i = 0; i < MetroTickets.Length; i++)
		{
			if (class<Hat_Collectible_MetroTicket_Base>(MetroTickets[i]).default.LocationName != InLocationName) continue;
			Icons.AddItem((MyLoadout != None && MyLoadout.HasCollectible(MetroTickets[i], 1)) ? class<Hat_Collectible_MetroTicket_Base>(MetroTickets[i]).static.GetHUDIcon() : MetroTicketIcon);
		}
	}
}