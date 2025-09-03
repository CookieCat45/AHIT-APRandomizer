class Archipelago_RandomizedItem_BadgePin extends Archipelago_RandomizedItem_Base;

defaultproperties
{
	Begin Object Class=StaticMeshComponent Name=Model2
		StaticMesh = StaticMesh'HatinTime_PrimitiveShapes.TexPropPlane'
		LightEnvironment=m_hLightEnvironment
		MaxDrawDistance = 6000;
		Scale=0.25
		bAcceptsStaticDecals = false;
		bAcceptsDynamicDecals = false;
		Materials(0) = Material'HatInTime_Hud_ItemIcons.Misc.badge_pin_Mat'
	End Object
	Mesh=Model2
	Components.Add(Model2)
	
	CollectParticle = ParticleSystem'HatInTime_Items.ParticleSystems.energybit_collected2'
	CollectParticleColor = (R=255,G=204,B=76,A=255);
	HUDIcon = Texture2D'HatInTime_Hud_ItemIcons.Misc.badge_pin';
}

simulated function bool OnCollected(Actor a)
{
	local Hat_SaveGame save;
	local Hat_Loadout lo;
	lo = Hat_PlayerController(GetALocalPlayerController()).MyLoadout;
	if (WasFromServer())
	{
		save = `SaveManager.GetCurrentSaveData();
		save.MyBadgeSlots = min(2, save.MyBadgeSlots+1);
		
		// make sure to give the player the actual badge pin items or else the game may yeet the slots randomly
		if (save.MyBadgeSlots >= 1 && !lo.BackpackHasInventory(class'Hat_Collectible_BadgeSlot'))
		{
			lo.AddBackpack(lo.MakeBackpackItem(class'Hat_Collectible_BadgeSlot'));
		}

		if (save.MyBadgeSlots >= 2 && !lo.BackpackHasInventory(class'Hat_Collectible_BadgeSlot2'))
		{
			lo.AddBackpack(lo.MakeBackpackItem(class'Hat_Collectible_BadgeSlot2'));
		}
	}
	
	return Super.OnCollected(a);
}