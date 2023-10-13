class Archipelago_RandomizedItem_Ice extends Archipelago_RandomizedItem_Base;

defaultproperties
{
    InventoryClass = class'Hat_Ability_StatueFall';
    HUDIcon = Texture2D'HatInTime_Hud_ItemIcons.Hats.ice_statue_hat';
    Begin Object Class=SkeletalMeshComponent Name=Mesh0
        SkeletalMesh = SkeletalMesh'HatInTime_Costumes.models.ice_hat_2017'
        PhysicsAsset = PhysicsAsset'HatInTime_Costumes.Physics.ice_hat_2017_Physics'
		bHasPhysicsAssetInstance = true;
    End Object
    Mesh = Mesh0;
    Components.Add(Mesh0);
    RotationComponents.Add(Mesh0);
}