class Archipelago_BubbleTalker_InputText extends Hat_BubbleTalker_InputText;

`include(APRandomizer\Classes\Globals.uci);

function bool InputKey( int ControllerId, name Key, EInputEvent EventType, float AmountDepressed = 1.f, bool bGamepad = FALSE )
{
	local string s;
	
	if (Key == 'LeftShift' || (!bGamepad && Key == 'Hat_Player_Ability'))
	{
		if (EventType == IE_Released) IsHoldingLeftShift = false;
		else if (EventType == IE_Repeat && !IsHoldingLeftShift) IsHoldingLeftShift = true;
	}
	else if (Key == 'RightShift')
	{
		if (EventType == IE_Released) IsHoldingRightShift = false;
		else if (EventType == IE_Repeat && !IsHoldingRightShift) IsHoldingRightShift = true;
	}
    
    if (EventType == IE_Pressed || EventType == IE_Repeat)
	{
		//if (IsUsingGamepad && !bGamePad)
		//	return false;
		
		if (Key == 'BackSpace')
		{
			return DeleteCharacter();
		}

		s = KeyNameToCharacter(Key);
		if (s != "")
		{
			if (Len(Result) >= CharacterLength)
				return true;

			AddCharacter(s);
			return true;
		}
		else if (Len(Key) == 1)
		{
            if (Len(Result) >= CharacterLength)
				return true;
            
            // lowercase support
            s = Locs(string(Key));
			if (IsHoldingLeftShift || IsHoldingRightShift || bGamePad && `AP.ControllerCapsLock)
            {
                s = Caps(s);
            }
			
			AddCharacter(s);
			return true;
		}
	}

	return false;
}

function bool DeleteCharacter()
{
	local InputText_KilledCharacter kc;
	
	if (Len(Result) <= 0)
		return true;
	
	kc.DisplayText = Mid(Result, Len(Result)-1,1);
	kc.CharacterIndex = Len(Result)-1;
	kc.LifeTime = 8;
	kc.Velocity.X = RandRange(-1.0f,1.0f);
	kc.Velocity.Y = RandRange(2.5f,4.0f);
	KilledCharacters.AddItem(kc);
	Result = Left(Result, Len(Result)-1);
	
	while (CharactersFadeIn.Length > Len(Result))
		CharactersFadeIn.Remove(CharactersFadeIn.Length-1,1);
	
	PlaySoundToPlayerControllers(KeyboardBackspaceSound);
}

function DrawInputText(HUD H, Hat_BubbleTalkerQuestion element, float fTime, float fX, float fY)
{
    local Vector vSize, vOrigin;
    local float fScale, CharacterWidth, CharacterDrawWidth, alpha;
	local int i, j;
	
	if (element != None && element != InElement)
		InElement = element;
    
    vSize = element.GetSize(H, fTime);
    fScale = vSize.X*0.25;
	
	alpha = 1-((1-FadeIn)**3.f);
    
    vOrigin.X = fX + vSize.X * 0.8;
    vOrigin.Y = fY + vSize.Y * Lerp(1.22f, 1.13f, alpha);
    
    H.Canvas.SetDrawColor(255, 255, 255, alpha*255);
    element.DrawCenterRect(H, vOrigin.X + fScale*0.02, vOrigin.Y, fScale * 2.0, fScale*0.92, element.Question01Tex);
	
	CharacterWidth = vSize.X*0.022;
	CharacterWidth *= Lerp(1.f, 0.7f, FClamp((CharacterLength-10)/7.f, 0, 1));
	CharacterDrawWidth = CharacterWidth*0.03;
	
	vOrigin.X -= CharacterWidth*(CharacterLength/2.f);
	
	H.Canvas.SetDrawColor(0,0,0,255);
	H.Canvas.Font = class'Hat_FontInfo'.static.GetDefaultFont("");
	for (i = 0; i < CharacterLength; i++)
	{
		H.Canvas.SetPos(vOrigin.X, vOrigin.Y - CharacterWidth);
		H.Canvas.DrawText("_", false, CharacterDrawWidth, CharacterDrawWidth);
		
		if (Len(Result) > i)
		{
			H.Canvas.SetDrawColor(0,0,0,255*FMin(CharactersFadeIn[i]/0.2f,1.f));
			H.Canvas.SetPos(vOrigin.X, (vOrigin.Y - CharacterWidth)+class'Hat_Math'.static.InterpolationOvershoot(fScale*-0.2f, 0, CharactersFadeIn[i]));
			H.Canvas.DrawText(Mid(Result, i, 1), false, CharacterDrawWidth, CharacterDrawWidth);
		}
		H.Canvas.SetDrawColor(0,0,0,255);
		for (j = 0; j < KilledCharacters.Length; j++)
		{
			if (KilledCharacters[j].CharacterIndex != i) continue;
			H.Canvas.SetPos(vOrigin.X + KilledCharacters[j].Position.X*fScale, vOrigin.Y - CharacterWidth - KilledCharacters[j].Position.Y*fScale);
			H.Canvas.DrawText(KilledCharacters[j].DisplayText, false, CharacterDrawWidth, CharacterDrawWidth);
		}
		
		vOrigin.X += CharacterWidth;
	}
}