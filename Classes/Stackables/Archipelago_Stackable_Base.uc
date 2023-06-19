class Archipelago_Stackable_Base extends Hat_CarryObject_Stackable
	`RemoveUntilDLC
	abstract;

var Array<Hat_AnimBlendSimple> BlendAnims;

simulated event PostBeginPlay()
{
	Super.PostBeginPlay();
	CanBeThrown = true;
	CanBeDropped = true;
}

function bool CanCarryBeDropped()
{
	return true; // always droppable to avoid messing with other carryables
}

function OnPickUp(Actor p)
{
	Super.OnPickUp(p);
	SetAnim(1);
}

function OnCompleteDelivery()
{
	Super.OnCompleteDelivery();
	SetAnim(0);
}

simulated event PostInitAnimTree(SkeletalMeshComponent SkelComp)
{
	local Hat_AnimBlendSimple hNode;

	Super.PostInitAnimTree(SkelComp);
	if (SkelComp == Mesh)
	{
		foreach SkeletalMeshComponent(Mesh).AllAnimNodes(class'Hat_AnimBlendSimple', hNode)
		{
			BlendAnims[BlendAnims.Length] = hNode;
			hNode.SetIndex(0, true);
		}
	}
}

function SetAnim(int i)
{
	local Hat_AnimBlendSimple n;
	foreach BlendAnims(n)
		n.SetIndex(i);
}

`if(`isdefined(WITH_DLC1))
defaultproperties
{
	Components.Remove(StaticMeshComponent0);
	
   Begin Object Name=m_hLightEnvironment
		bEnabled = true
		bDynamic = true
		bIsCharacterLightEnvironment = false
   End Object

	Begin Object Class=SkeletalMeshComponent Name=SkeletalMeshComponent0
		LightEnvironment=m_hLightEnvironment
		CanBlockCamera=false
		BlockActors=true
		CollideActors=true
		MaxDrawDistance=6000
		BlockZeroExtent=false
		BlockNonZeroExtent=false
		CanBeEdgeGrabbed=false
	End Object
	Components.Add(SkeletalMeshComponent0)
	Mesh = SkeletalMeshComponent0
	CollisionComponent = SkeletalMeshComponent0

	TickManage = false
}
`endif