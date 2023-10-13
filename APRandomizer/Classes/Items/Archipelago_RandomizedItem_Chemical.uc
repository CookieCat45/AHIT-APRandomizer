class Archipelago_RandomizedItem_Chemical extends Archipelago_RandomizedItem_Base;

defaultproperties
{
    InventoryClass = class'Hat_Ability_Chemical';
    HUDIcon = Texture2D'HatInTime_Hud_ItemIcons.Hats.witch_hat'
    Begin Object Class=SkeletalMeshComponent Name=Mesh0
        SkeletalMesh = SkeletalMesh'HatInTime_Costumes.models.hat_witch_hat_2017'
        PhysicsAsset = PhysicsAsset'HatInTime_Costumes.Physics.hat_witch_hat_2017_Physics'
		bHasPhysicsAssetInstance = true;
		bNoSkeletonUpdate = false;
    End Object
    Mesh = Mesh0;
    Components.Add(Mesh0);
    RotationComponents.Add(Mesh0);
}