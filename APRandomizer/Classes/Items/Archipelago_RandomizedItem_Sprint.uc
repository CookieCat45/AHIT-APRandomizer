class Archipelago_RandomizedItem_Sprint extends Archipelago_RandomizedItem_Base;

defaultproperties
{
    InventoryClass = class'Hat_Ability_Sprint';
    HUDIcon = Texture2D'HatInTime_Hud_ItemIcons.Hats.sprint_hat'
    Begin Object Class=SkeletalMeshComponent Name=Mesh0
        SkeletalMesh = SkeletalMesh'HatInTime_Costumes.models.sprint_hat_2017'
        PhysicsAsset = PhysicsAsset'HatInTime_Costumes.Physics.sprint_hat_2017_Physics'
		bHasPhysicsAssetInstance = true;
		bNoSkeletonUpdate = false;
    End Object
    Mesh = Mesh0;
    Components.Add(Mesh0);
    RotationComponents.Add(Mesh0);
}