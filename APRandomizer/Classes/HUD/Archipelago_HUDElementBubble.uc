class Archipelago_HUDElementBubble extends Hat_HUDElementBubble;

`include(APRandomizer\Classes\Globals.uci);

enum EBubbleType
{
    BubbleType_SlotName,
    BubbleType_Password,
    BubbleType_Connect,
};

var string Answer;
var EBubbleType BubbleType;
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
    
    if (Hat_HUD(H).IsGamepad() && m_hBubbleTalker != None)
    {
        // IsClosed being true means user pressed accept button
        kb = Hat_HUDMenuControllerKeyboardInput(Hat_HUD(H).GetHUD(class'Hat_HUDMenuControllerKeyboardInput'));
        if (kb != None && kb.IsClosed)
        {
            kb.CloseHUD(H);
            OnEnter(H);
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

// The controller keyboard input will not allow you to click accept button if text is empty, so this is needed for the password entry.
// But this also serves as a shortcut.
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
    switch (BubbleType)
    {
        case BubbleType_SlotName:
            if (Answer != "")
            {
                `AP.SlotData.SlotName = Answer;
                `AP.OpenPasswordBubble(0.5);
                CloseHUD(H);
            }
            
            break;
        
        case BubbleType_Password:
            `AP.SlotData.Password = Answer;
            `AP.OpenConnectBubble(0.5);
            CloseHUD(H);
            break;
        
        // Finally, connect to server
        case BubbleType_Connect:
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
                break;
            }
            
            `AP.SlotData.Host = ip;
            `AP.SlotData.Port = int(port);
            if (`AP.Client == None)
                `AP.CreateClient();
            
            `AP.Client.Connect();
            CloseHUD(H);
            break;
    }
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