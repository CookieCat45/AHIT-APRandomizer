class Archipelago_RandomizedItem_Dweller extends Archipelago_RandomizedItem_Base;

defaultproperties
{
    InventoryClass = class'Hat_Ability_FoxMask';
    HUDIcon = Texture2D'HatInTime_Hud_Loadout.Item_Icons.itemicon_foxmask';
    Begin Object Class=SkeletalMeshComponent Name=Mesh0
        SkeletalMesh = SkeletalMesh'hatintime_creatures.models.Mask_Fox'
        PhysicsAsset = PhysicsAsset'hatintime_creatures.Physics.Mask_Fox_Physics'
		bNoSkeletonUpdate = true;
    End Object
    Mesh = Mesh0;
    Components.Add(Mesh0);
    RotationComponents.Add(Mesh0);
}