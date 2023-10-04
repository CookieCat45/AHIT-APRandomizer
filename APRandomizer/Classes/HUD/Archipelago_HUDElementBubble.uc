class Archipelago_HUDElementBubble extends Hat_HUDElementBubble;

`include(APRandomizer\Classes\Globals.uci);

var string Answer;
var Texture2D QuestionBubbleOverride;

function OpenInputText(HUD H, string strText, class<Hat_ConversationType_Base> ConvType, Name InVariableName, int CharacterLength)
{
	SpawnBubbleTalker(H);
    
    // Wider note so text doesn't cut off
    if (QuestionBubbleOverride != None)
    {
        m_hBubbleTalker.Question01Tex = QuestionBubbleOverride;
    }
    
    m_hBubbleTalker.ClearAnswers();
    m_hBubbleTalker.SetBubbleType(ConvType);
    m_hBubbleTalker.InputInstance = new class'Archipelago_BubbleTalker_InputText';
	m_hBubbleTalker.InputInstance.AddToInteractions(H.PlayerOwner, InVariableName, CharacterLength);
    m_hBubbleTalker.Open(H.PlayerOwner, strText);
}

function bool OnClick(HUD H, bool release)
{
    if (!release || Hat_HUD(H).IsGamepad())
        return false;
    
    OnEnter(H);
    return Super.OnClick(H, release);
}

function bool Tick(HUD H, float d)
{
    local Hat_HUDMenuControllerKeyboardInput kb;
    
    if (m_hBubbleTalker != None)
    {
        // IsClosed being true means user pressed accept button
        kb = Hat_HUDMenuControllerKeyboardInput(Hat_HUD(H).GetHUD(class'Hat_HUDMenuControllerKeyboardInput'));
        if (kb != None && (kb.IsClosed || !Hat_HUD(H).IsGamepad()))
        {
            if (kb.IsClosed)
                OnEnter(H);
                
            kb.CloseHUD(H);
        }
    }
    
    return Super.Tick(H, d);
}

function bool OnXClick(HUD H, bool release)
{
    // caps lock for controllers
    `AP.ControllerCapsLock = !`AP.ControllerCapsLock;
    return true;
}

function bool OnYClick(HUD H, bool release)
{
    if (!release)
        return false;
    
    OnEnter(H);
    return true;
}

function OnEnter(HUD H)
{
    local string ip, port;
    
    Answer = m_hBubbleTalker.InputInstance.Result;
    if (Answer == "")
        return;

    if (`AP.Client == None)
    {
        `AP.CreateClient();
    }
    
    if (InStr(Answer, ":") != -1)
    {
        port = Split(Answer, ":", true);
        ip = Repl(Answer, ":"$port, "");
    }
    else if (InStr(Answer, "-") != -1)
    {
        port = Split(Answer, "-", true);
        ip = Repl(Answer, "-"$port, "");
    }
    else
    {
        `AP.ScreenMessage("You must use : or - between the IP and Port.");
        `AP.OpenConnectBubble(1.0);
        CloseHUD(H);
        return;
    }
    
    `AP.SlotData.Host = ip;
    `AP.SlotData.Port = int(port);
    if (`AP.Client == None)
        `AP.CreateClient();
    
    `AP.Client.Connect();
    `AP.SaveGame();
    CloseHUD(H);
    return;
}

function OnCloseHUD(HUD H)
{
    local Hat_HUDMenuControllerKeyboardInput kb;

    if (m_hBubbleTalker != None)
    {
        m_hBubbleTalker.InputInstance.Detach(H.PlayerOwner);
        m_hBubbleTalker.Destroy();
    }
    
    kb = Hat_HUDMenuControllerKeyboardInput(Hat_HUD(H).GetHUD(class'Hat_HUDMenuControllerKeyboardInput'));
    if (kb != None)
        kb.CloseHUD(H);
    
    Super.OnCloseHUD(H);
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
    QuestionBubbleOverride = Texture2D'APRandomizer_content.speech_bubble_question_wider';
}