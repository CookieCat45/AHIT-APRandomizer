class Archipelago_HUDElementInfoButton extends Hat_HUDElement;

var Texture2D APIcon;
var Texture2D APIconGamepad;
var float ClickPosX;
var float ClickPosY;
var bool Hovered;
var SoundCue HoverSound;

function bool Render(HUD H)
{
    local float scale;
    local Vector2D mousePos;
    local bool isSelected;
    
    if (!IsPauseMenuActive(H))
    {
        CloseHUD(H);
        return false;
    }
    
    if (!Super.Render(H))
        return false;
    
    ClickPosX = H.Canvas.ClipX*0.8;
    ClickPosY = H.Canvas.ClipY*0.85;
    scale = FMin(H.Canvas.ClipX, H.Canvas.ClipY)*0.15;
    mousePos = GetMousePos(H);
    isSelected = Abs(mousePos.x - ClickPosX) <= 50.0 && Abs(mousePos.y - ClickPosY) <= 50.0;
    
    if (isSelected)
    {
        if (!Hovered)
            PlaySound(H, HoverSound);
        
        H.Canvas.SetDrawColor(25, 255, 25);
    }
    else
    {
        H.Canvas.SetDrawColor(255, 255, 255);
    }
    
    Hovered = isSelected;
    IsGamepad(H) ? DrawCenter(H, ClickPosX, ClickPosY, scale, scale, APIconGamepad) : DrawCenter(H, ClickPosX, ClickPosY, scale, scale, APIcon);
    return true;
}

function bool OnClick(HUD H, bool release)
{
    if (IsGamepad(H))
        return false;
    
    if (Hovered)
    {
        OpenSeedInfo(H);
        return true;
    }
    
    return false;
}

function bool OnYClick(HUD H, bool release)
{
    OpenSeedInfo(H);
    return true;
}

function OpenSeedInfo(HUD H)
{
    if (!IsPauseMenuActive(H))
        return;
    
    Hat_PlayerController(H.PlayerOwner).SetPause(false);
    Hat_HUD(H).OpenHUD(class'Archipelago_HUDMenuSeedInfo', , true);
    CloseHUD(H);
}

function bool IsPauseMenuActive(HUD H)
{
    return H.PlayerOwner.WorldInfo.Pauser != None;
}

function bool IsGamepad(HUD H)
{
    return Hat_PlayerController(H.PlayerOwner).IsGamepad();
}

defaultproperties
{
    APIcon = Texture2D'APRandomizer_contentNew.logo_new';
    APIconGamepad = Texture2D'APRandomizer_contentNew.logo_new_y';
    HoverSound = SoundCue'HatInTime_Hud.SoundCues.CursorMove';
    RealTime = true;
}