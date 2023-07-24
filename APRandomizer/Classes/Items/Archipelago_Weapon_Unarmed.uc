class Archipelago_Weapon_Unarmed extends Hat_Weapon_Unarmed;

simulated function bool ProcessInstantHit2(ImpactInfo Impact, optional int NumHits, optional class<DamageType> dmg, optional float amount = 1.0, optional bool dead = false)
{
    return false;
}