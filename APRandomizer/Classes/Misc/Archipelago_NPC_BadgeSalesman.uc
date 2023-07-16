/**
 *
 * Copyright 2012-2015 Gears for Breakfast ApS. All Rights Reserved.
 */

class Archipelago_NPC_BadgeSalesman extends Hat_NPC
    placeable;

`include(APRandomizer\Classes\Globals.uci);

var() Array<class<Archipelago_ShopItem_Base>> AllSoldItems;
var() Array<class<Archipelago_ShopItem_Base>> SoldItems;
var() Array<int> TimePieceThreshold_AppearInSpaceship;
var transient Hat_ShopInventory ShopInventory;
var(Conversations) Hat_ConversationTree SoldOutConversationTree;
var(Conversations) Hat_ConversationTree InitialConversationTree;
var transient Hat_ConversationTree DefaultConversationTree;
var transient bool SoldOut;
var transient bool IsInitialSlotPurchase;
var(Music) SoundCue Music;
var transient Hat_MusicNodeBlend_Dynamic DynamicMusicNode;
var transient Array<class<Archipelago_ShopItem_Base>> CurrentItemsToSell;
var(Lights) SpotlightComponent Spotlight;
var(Particles) ParticleSystemComponent GlitchyParticle;

simulated event PostBeginPlay()
{
	DefaultConversationTree = ConversationTree;
    Super.PostBeginPlay();
}

static function int ShouldAppearInHUB(Hat_GameManager gm)
{
	return -1;
}

simulated function bool OnInteractedWith(Actor a)
{
	SoldOut = !HasAnythingNewToSell(Pawn(a).Controller);
	
	if (SoldOut)
	{
		ConversationTree = SoldOutConversationTree;
	}
	else if (!class'Hat_SaveBitHelper'.static.HasLevelBit("BadgeSellerIntro", 1, "hub_spaceship"))
	{
		ConversationTree = InitialConversationTree;
	}
	else
	{
		ConversationTree = DefaultConversationTree;
	}
	
	if (ConversationTreeInstance != None)
		ConversationTreeInstance.Destroy();
	
	ConversationTreeInstance = None;

	if (!Super.OnInteractedWith(a)) 
		return false;
		
	if (ConversationTreeInstance != None)
	{
		if (DynamicMusicNode == None)
		{
			DynamicMusicNode = new class'Hat_MusicNodeBlend_Dynamic';
			DynamicMusicNode.Music = Music;
			DynamicMusicNode.BlendTimes[0] = 1.0f; // 1.0s fade out
			DynamicMusicNode.BlendTimes[1] = 0.3f; // 0.3s fade in
			DynamicMusicNode.Priority = 40;
			`PushMusicNode(DynamicMusicNode);
		}
		
		Hat_PlayerController(Pawn(a).Controller).TalkManager.PushCompleteDelegate(self.OnTalkMessageComplete);
	}

    return true;
}

delegate OnTalkMessageComplete(Controller c, int answer)
{
	if (SoldOut)
	{
		if (DynamicMusicNode != None)
		{
			DynamicMusicNode.Stop();
			DynamicMusicNode = None;
		}

		return;
	}

	class'Hat_SaveBitHelper'.static.AddLevelBit("BadgeSellerIntro", 1, "hub_spaceship");
	OpenShop(c);
}

function OpenShop(Controller c)
{
	local int i;
	local array<int> shopLocationList;
	local Hat_HUDMenuShop shop;
	local HUD MyHUD;
	local ShopItemInfo shopInfo;
	
	MyHUD = PlayerController(c).MyHUD;
	
	shop = Hat_HUDMenuShop(Hat_HUD(MyHUD).OpenHUD(class'Hat_HUDMenuShop'));
	if (shop == None) 
		return;
	
	shop.MerchantActor = self;
	shop.SetShopInventory(MyHUD, GetShopInventory(Hat_PlayerController(c)));
	shop.PurchaseDelegates.AddItem(self.OnPurchase);
	TalkingTo = c.Pawn;
	
	for (i = 0; i < CurrentItemsToSell.Length; i++)
	{
		if (!`AP.GetShopItemInfo(CurrentItemsToSell[i], shopInfo))
			continue;
		
		// Only hint progression
		if (shopInfo.ItemFlags != ItemFlag_Important && shopInfo.ItemFlags != ItemFlag_ImportantSkipBalancing)
			continue;
		
		shopLocationList.AddItem(shopInfo.ItemClass.default.LocationID);
	}
	
	if (shopLocationList.Length > 0)
	{
		`AP.SendMultipleLocationChecks(shopLocationList, true, true);
	}
}

function bool HasAnythingNewToSell(Controller pc)
{
	local Hat_PlayerController hpc;
	hpc = Hat_PlayerController(pc);
	CalculateIndicesToSell(hpc);
	return !GetShopInventory(hpc).IsSoldOut(hpc);
}

function int CompareSellingBadges(int A, int B)
{
	if (SoldItems[A] == class'Hat_Collectible_BadgeSlot' || SoldItems[A] == class'Hat_Collectible_BadgeSlot2') return -1;
	if (SoldItems[B] == class'Hat_Collectible_BadgeSlot' || SoldItems[B] == class'Hat_Collectible_BadgeSlot2') return 1;
	
	if (SoldItems[B].default.BadgeSeller_EnergyBitCost == SoldItems[A].default.BadgeSeller_EnergyBitCost) return (Rand(2)*2) -1;
	
	return SoldItems[B].default.BadgeSeller_EnergyBitCost - SoldItems[A].default.BadgeSeller_EnergyBitCost;
}

function CalculateIndicesToSell(Hat_PlayerController pc)
{
	local int i;
	if (SoldItems.Length == 0)
	{
		for (i = 0; i < AllSoldItems.Length; i++)
		{
			SoldItems.AddItem(AllSoldItems[i]);
		}
	}
	
	if (CurrentItemsToSell.Length == 0 && SoldItems.Length > 0)
	{
		//TimePieces = Hat_GameManager(Worldinfo.Game).GetTimeObjects();
		
		for (i = 0; i < SoldItems.Length; i++)
		{
			CurrentItemsToSell.AddItem(SoldItems[i]);
		}
	}
}

function Hat_ShopInventory GetShopInventory(Hat_PlayerController pc)
{
	local Hat_ShopInventory s;
	local ShopItemInfo shopInfo;
	local int i;
	
	if (ShopInventory != None) return ShopInventory;
	
	CalculateIndicesToSell(pc);
	s = new class'Hat_ShopInventory';
	s.Currency = class'Hat_Collectible_EnergyBit';
	IsInitialSlotPurchase = false;
	
	s.ItemsForSale.Add(CurrentItemsToSell.Length);
	for (i = 0; i < CurrentItemsToSell.Length; i++)
	{
		`AP.GetShopItemInfo(CurrentItemsToSell[i], shopInfo);
		s.ItemsForSale[i].CollectibleClass = CurrentItemsToSell[i];
		s.ItemsForSale[i].ItemCost = shopInfo.PonCost;
		s.ItemsForSale[i].PreventRePurchase = true;
	}
	
	ShopInventory = s;
	return ShopInventory;
}

simulated event Destroyed()
{
	ShopInventory = None;
	Super.Destroyed();
}

delegate OnPurchase(PlayerController pc, bool MadePurchase)
{
	if (MadePurchase)
	{
		if (ConversationTreeInstance != None)
			ConversationTreeInstance.Destroy();
		ConversationTreeInstance = None;
		
		if (SoldOutConversationTree != None)
			ConversationTree = SoldOutConversationTree;
		
		if (IsInitialSlotPurchase)
		{
			IsInitialSlotPurchase = false;
			ShopInventory = None;
		}
		
		SoldOut = !HasAnythingNewToSell(pc);
	}
	
	if (!MadePurchase && DynamicMusicNode != None)
	{
		DynamicMusicNode.Stop();
		DynamicMusicNode = None;
	}
}

defaultproperties
{
	Begin Object Name=SkeletalMeshComponent0
		SkeletalMesh=SkeletalMesh'HatinTime_Characters_BadgeS.models.BadgeS_Base'
		AnimSets(0)=AnimSet'HatinTime_Characters_BadgeS.AnimSet.BadgeS_Anims'
		AnimTreeTemplate=AnimTree'HatinTime_Characters_BadgeS.AnimTree.BadgeS_AnimTree'
		Animations = None;
		PhysicsAsset=PhysicsAsset'HatinTime_Characters_BadgeS.Physics.BadgeS_Base_Physics'
		Scale = 1.4
		Translation=(Z=-80);
		BlockActors=false
		BlockZeroExtent=false
		BlockNonZeroExtent=false
		CollideActors=false
		BlockRigidBody=false
	End Object
   
   Begin Object Class=CylinderComponent Name=CollisionCylinder
		CollisionRadius=40
		CollisionHeight=80
        CanBlockCamera = false
		
		BlockActors=true
		BlockZeroExtent=true
		BlockNonZeroExtent=true
		CollideActors=true
		BlockRigidBody=true
		CanBeEdgeGrabbed=false
		CanBeWallSlid=false
   End Object
	CollisionComponent=CollisionCylinder
	Components.Add(CollisionCylinder)
	
   Begin Object Class=SpotLightComponent Name=SpotLight0
		InnerConeAngle = 5
		OuterConeAngle = 25
		Radius = 1500
		Brightness = 1.23
		LightColor = (B=255,G=255,R=255,A=255)
        Translation=(X=130,Y=14,Z=240)
		Rotation=(Pitch=-11146,Yaw=-31392)
	    LightAffectsClassification=LAC_STATIC_AFFECTING
		CastShadows=TRUE
		CastStaticShadows=TRUE
		CastDynamicShadows=FALSE
		bForceDynamicLight=FALSE
		UseDirectLightMap=TRUE
		CullDistance=5000
		LightingChannels=(BSP=TRUE,Static=TRUE,Dynamic=FALSE,bInitialized=TRUE)
   End Object
   Components.Add(SpotLight0);
   SpotLight = SpotLight0;
   
    Begin Object Class=ParticleSystemComponent Name=GlitchyParticle0
        Template = ParticleSystem'HatinTime_Characters_BadgeS.Particles.BadgeS_Ambient_FX'
		bAutoActivate=true
		MaxDrawDistance = 6000;
    End Object 
    Components.Add(GlitchyParticle0)
    GlitchyParticle = GlitchyParticle0;
	
	TimePieceThreshold_AppearInSpaceship(0) = 7;
	TimePieceThreshold_AppearInSpaceship(1) = 11;
	TimePieceThreshold_AppearInSpaceship(2) = 15;
	TimePieceThreshold_AppearInSpaceship(3) = 20;
	
	AllSoldItems[0] = class'Archipelago_BadgeSalesmanItem_1';
	AllSoldItems[1] = class'Archipelago_BadgeSalesmanItem_2';
	AllSoldItems[2] = class'Archipelago_BadgeSalesmanItem_3';
	AllSoldItems[3] = class'Archipelago_BadgeSalesmanItem_4';
	AllSoldItems[4] = class'Archipelago_BadgeSalesmanItem_5';
	AllSoldItems[5] = class'Archipelago_BadgeSalesmanItem_6';
	AllSoldItems[6] = class'Archipelago_BadgeSalesmanItem_7';
	AllSoldItems[7] = class'Archipelago_BadgeSalesmanItem_8';
	AllSoldItems[8] = class'Archipelago_BadgeSalesmanItem_9';
	AllSoldItems[9] = class'Archipelago_BadgeSalesmanItem_10';
	
	ConversationTree = Hat_ConversationTree'HatinTime_Conv_BadgeSalesman.spaceship.SellIntro2'
	SoldOutConversationTree = Hat_ConversationTree'HatinTime_Conv_BadgeSalesman.spaceship.All_Out'
	InitialConversationTree = Hat_ConversationTree'HatinTime_Conv_BadgeSalesman.spaceship.SellIntro'
	Music = SoundCue'HatinTime_Music_General2.Badge_Salesman_Music_Loop_cue'
}