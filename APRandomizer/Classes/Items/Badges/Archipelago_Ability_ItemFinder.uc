class Archipelago_Ability_ItemFinder extends Hat_Ability_Automatic;

defaultproperties
{
    Begin Object Name=Mesh2
		Materials(0) = MaterialInstanceConstant'HatInTime_Items.Materials.Badges.badge_relicfinder'
    End Object
	
	HUDIcon = Texture2D'HatInTime_Hud_ItemIcons.Badges.badge_relicfinder'
	CosmeticItemName="CompassBadgeName"
    Description(0) = "CompassBadgeDesc0";
}

function GivenTo( Pawn thisPawn, optional bool bDoNotActivate )
{
	if (thisPawn != None && thisPawn.Controller != None && PlayerController(thisPawn.Controller) != None && PlayerController(thisPawn.Controller).MyHUD != None)
		Hat_HUD(PlayerController(thisPawn.Controller).MyHUD).OpenHUD(class'Archipelago_HUDElementItemFinder');
	SetTimer(2.f, false, NameOf(GivenToTimer));
	Super.GivenTo(thisPawn, bDoNotActivate);
}

function GivenToTimer()
{
	if (Instigator != None && Instigator.Controller != None)
		Hat_HUD(PlayerController(Instigator.Controller).MyHUD).OpenHUD(class'Archipelago_HUDElementItemFinder');
}

function ItemRemovedFromInvManager()
{
	ClearTimer(NameOf(GivenToTimer));
	if (Instigator != None && Instigator.Controller != None)
		Hat_HUD(PlayerController(Instigator.Controller).MyHUD).CloseHUD(class'Archipelago_HUDElementItemFinder');
	Super.ItemRemovedFromInvManager();
}