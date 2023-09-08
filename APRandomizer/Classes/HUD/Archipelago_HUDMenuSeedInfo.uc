class Archipelago_HUDMenuSeedInfo extends Hat_HUDMenu
    dependson(Archipelago_GameMod);

`include(APRandomizer\Classes\Globals.uci);

var Archipelago_GameMod mod;
var Texture2D BoxTexture;
var Texture2D YellowPainting;
var Texture2D BluePainting;
var Texture2D GreenPainting;

function OnOpenHUD(HUD H, optional String command)
{
    Super.OnOpenHUD(H, command);
    mod = `AP;
}

function bool Render(HUD H)
{
    local int i, index;
    local float x, y, scale, offsetX, offsetY;
    local string text;
    local Hat_Loadout lo;
    local Hat_SaveGame save;
    local EZiplineType zipline;
    
    if (!Super.Render(H))
        return false;
    
    lo = Hat_PlayerController(H.PlayerOwner).MyLoadout;
    save = `SaveManager.GetCurrentSaveData();
    
    H.Canvas.SetDrawColor(255, 255, 255, 255);
    scale = FMin(H.Canvas.ClipX, H.Canvas.ClipY);
    DrawCenter(H, H.Canvas.ClipX*0.5, H.Canvas.ClipY*0.5, scale, scale*0.8, BoxTexture);
    
    x = H.Canvas.ClipX * 0.25f;
    y = H.Canvas.ClipY * 0.1f;
    H.Canvas.Font = class'Hat_FontInfo'.static.GetDefaultFont("abcdefghijkmnlopqrstuvwxyzABCDEFGHIJKMNLOPQRSTUVWXYZ"); 
    
    if (mod == None || !mod.SlotData.Initialized)
    {
        H.Canvas.SetDrawColor(125, 125, 125, 255);
        DrawBorderedText(H.Canvas, "No seed data! Connect at least once first.", x, y, 0.7, true);
        return true;
    }
    
    y *= 1.6;
    index = mod.GetAPBits("HatCraftIndex", 1);
    if (index > 5)
    {
        text = "All Hats Unlocked!";
    }
    else
    {
        text = "Yarn: " $mod.GetAPBits("TotalYarnCollected") $"/" $mod.GetHatYarnCost(mod.GetNextHat());
    }
    
    DrawBorderedText(H.Canvas, text, x, y, 0.7, true);
    
    offsetY += H.Canvas.ClipY * 0.1;
    for (i = 1; i <= 5; i++)
    {
        if (i > 1)
            offsetX += H.Canvas.ClipX * 0.08;
        else
            offsetX += H.Canvas.ClipX * 0.02;
        
        if (index > i)
        {
            H.Canvas.SetDrawColor(255, 255, 255, 255);
            DrawCenter(H, x+offsetX, y+offsetY, scale*0.1, scale*0.1, mod.GetHatByIndex(i).default.HUDIcon);
        }
        else
        {
            H.Canvas.SetDrawColor(100, 100, 100, 255);
            DrawBorderedText(H.Canvas, "?", x+offsetX, y+offsetY, 0.7, true);
        }
    }
    
    offsetX = 0;
    offsetY += H.Canvas.ClipY * 0.15;
    mod.SlotData.ShuffleSubconPaintings ? H.Canvas.SetDrawColor(255, 255, 255, 255) : H.Canvas.SetDrawColor(25, 25, 25, 255);
    DrawBorderedText(H.Canvas, "Painting Unlocks:", x, y+offsetY, 0.7, true);
    
    for (i = 1; i <= 3; i++)
    {
        offsetX += H.Canvas.ClipX * 0.05;
        
        if (mod.SlotData.ShuffleSubconPaintings && mod.GetPaintingUnlocks() >= i)
        {
            H.Canvas.SetDrawColor(255, 255, 255);
        }
        else
        {
            H.Canvas.SetDrawColor(10, 10, 10);
        }
        
        DrawCenter(H, (x*1.7)+offsetX, y+offsetY, scale*0.1, scale*0.1, GetPaintingIcon(i));
    }
    
    offsetX = 0;
    offsetY += H.Canvas.ClipY * 0.1;
    mod.SlotData.ShuffleZiplines ? H.Canvas.SetDrawColor(255, 255, 255, 255) : H.Canvas.SetDrawColor(25, 25, 25, 255);
    DrawBorderedText(H.Canvas, "Zipline Unlocks:", x, y+offsetY, 0.7, true);
    for (i = 0; i <= 3; i++)
    {
        switch (i)
        {
            case 0:
                text = "BH";
                zipline = Zipline_Birdhouse;
                break;
            
            case 1:
                text = "LC";
                zipline = Zipline_LavaCake;
                break;
            
            case 2:
                text = "WM";
                zipline = Zipline_Windmill;
                break;
            
            case 3:
                text = "TB";
                zipline = Zipline_Bell;
                break;
        }
        
        if (mod.SlotData.ShuffleZiplines && mod.HasZipline(zipline))
        {
            H.Canvas.SetDrawColor(255, 255, 255);
        }
        else
        {
            H.Canvas.SetDrawColor(10, 10, 10);
        }
        
        DrawBorderedText(H.Canvas, text, (x*1.7)+offsetX, y+offsetY, 0.5, true);
        offsetX += H.Canvas.ClipX * 0.05;
    }
    
    offsetX = 0;
    offsetY += H.Canvas.ClipY * 0.1;
    H.Canvas.SetDrawColor(255, 255, 255);
    DrawBorderedText(H.Canvas, "Relics:", x, y+offsetY, 0.7, true);
    
    for (i = 0; i < save.MyBackpack2017.Collectibles.Length; i++)
    {
        if (class<Hat_Collectible_Decoration>(save.MyBackpack2017.Collectibles[i].BackpackClass) != None)
        {
            DrawCenter(H, (x*1.35)+offsetX, y+offsetY, scale*0.05, scale*0.05, 
                class<Hat_Collectible_Decoration>(save.MyBackpack2017.Collectibles[i].BackpackClass).default.HUDIcon);
            
            offsetX += H.Canvas.ClipX * 0.025;
        }
    }
    
    offsetX = 0;
    offsetY += H.Canvas.ClipY * 0.1;
    
    if (mod.SlotData.DLC2)
    {
        H.Canvas.SetDrawColor(255, 255, 255);
    }
    else
    {
        H.Canvas.SetDrawColor(25, 25, 25);
    }
    
    DrawBorderedText(H.Canvas, "Metro Tickets:", x, y+offsetY, 0.7, true);
    
    offsetX += H.Canvas.ClipX * 0.05;
    if (lo.HasCollectible(class'Hat_Collectible_MetroTicket_RouteA'))
    {
        H.Canvas.SetDrawColor(255, 255, 255);
    }
    else
    {
        H.Canvas.SetDrawColor(10, 10, 10);
    }
    
    DrawCenter(H, (x*1.7)+offsetX, y+offsetY, scale*0.1, scale*0.1, class'Hat_Collectible_MetroTicket_RouteA'.default.HUDIcon);
    
    offsetX += H.Canvas.ClipX * 0.05;
    if (lo.HasCollectible(class'Hat_Collectible_MetroTicket_RouteB'))
    {
        H.Canvas.SetDrawColor(255, 255, 255);
    }
    else
    {
        H.Canvas.SetDrawColor(10, 10, 10);
    }
    
    DrawCenter(H, (x*1.7)+offsetX, y+offsetY, scale*0.1, scale*0.1, class'Hat_Collectible_MetroTicket_RouteB'.default.HUDIcon);
    
    offsetX += H.Canvas.ClipX * 0.05;
    if (lo.HasCollectible(class'Hat_Collectible_MetroTicket_RouteC'))
    {
        H.Canvas.SetDrawColor(255, 255, 255);
    }
    else
    {
        H.Canvas.SetDrawColor(10, 10, 10);
    }
    
    DrawCenter(H, (x*1.7)+offsetX, y+offsetY, scale*0.1, scale*0.1, class'Hat_Collectible_MetroTicket_RouteC'.default.HUDIcon);

    offsetX += H.Canvas.ClipX * 0.05;
    if (lo.HasCollectible(class'Hat_Collectible_MetroTicket_RouteD'))
    {
        H.Canvas.SetDrawColor(255, 255, 255);
    }
    else
    {
        H.Canvas.SetDrawColor(10, 10, 10);
    }
    
    DrawCenter(H, (x*1.7)+offsetX, y+offsetY, scale*0.1, scale*0.1, class'Hat_Collectible_MetroTicket_RouteD'.default.HUDIcon);
    H.Canvas.SetDrawColor(255, 255, 255);
    
    offsetY += H.Canvas.ClipY * 0.1;
    switch (mod.SlotData.Goal)
    {
        case 1:
            text = "GOAL: Beat Mustache Girl";
            break;
        
        case 2:
            text = "GOAL: Clear Rush Hour";
            break;
        
        case 3:
            text = "GOAL: Complete Seal the Deal";
            break;
        
        default:
            text = "GOAL: ???";
            break;
    }

    H.Canvas.SetDrawColor(25, 255, 25, 255);
    DrawBorderedText(H.Canvas, text, x, y+offsetY, 0.7, true);
    
    return true;
}

function Texture2D GetPaintingIcon(int index)
{
    switch (index)
    {
        case 1: return YellowPainting;
        case 2: return BluePainting;
        case 3: return GreenPainting;
    }
    
    return None;
}

function OnCloseHUD(HUD H)
{
    Super.OnCloseHUD(H);
    if (IsPauseMenuActive(H))
    {
        Hat_HUD(H).OpenHUD(class'Archipelago_HUDElementInfoButton');
    }
}

function bool IsPauseMenuActive(HUD H)
{
    local Hat_HUDMenuLoadout lo;
    lo = Hat_HUDMenuLoadout(Hat_HUD(H).GetHUD(class'Hat_HUDMenuLoadout', true));
    return (lo != None && !lo.IsClosing(H));
}

function bool OnStartButton(HUD H)
{
    CloseHUD(H, class);
    return true;
}

function bool OnAltClick(HUD H, bool release)
{
    CloseHUD(H, class);
    return true;
}

function bool DisablePause(HUD H)
{
    return true;
}

function bool DisablesMovement(HUD H)
{
    return true;
}

function bool DisablesCameraMovement(HUD H)
{
    return true;
}

defaultproperties
{
    BoxTexture = Texture2D'HatInTime_Hud_Loadout.PopUp.popupmenu'
    YellowPainting = Texture2D'HatInTime_Hud_ItemIcons.Paintings.bonfire_painting_yellow';
    BluePainting = Texture2D'HatInTime_Hud_ItemIcons.Paintings.bonfire_painting_blue';
    GreenPainting = Texture2D'HatInTime_Hud_ItemIcons.Paintings.bonfire_painting_green';
    RealTime = true;
    RenderIndex = 1;
}