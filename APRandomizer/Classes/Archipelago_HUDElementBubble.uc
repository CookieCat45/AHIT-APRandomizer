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
	if (m_hBubbleTalker == None) return;
    
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
    
    switch (BubbleType)
    {
        case BubbleType_SlotName:
            `AP.ScreenMessage("Please enter slot name");
            break;
        
        case BubbleType_Password:
            `AP.ScreenMessage("Please enter password (if there is none, just left-click)");
            break;
        
        case BubbleType_Connect:
            `AP.ScreenMessage("Please enter IP:Port");
            break;
    }
}

function bool OnClick(HUD H, bool release)
{
    local string ip;
    local string port;
    
    if (!release)
        return false;
    
    Answer = m_hBubbleTalker.InputInstance.Result;
    switch (BubbleType)
    {
        case BubbleType_SlotName:
            if (Answer != "")
                `AP.SlotData.SlotName = Answer;
                m_hBubbleTalker.Destroy();
                `AP.OpenPasswordBubble(0.5);
                CloseHUD(H);

            break;
        
        case BubbleType_Password:
            `AP.SlotData.Password = Answer;
            m_hBubbleTalker.Destroy();
            `AP.OpenConnectBubble(0.5);
            CloseHUD(H);
            break;
        
        // Finally, connect to server
        case BubbleType_Connect:
            if (`AP.Client == None)
            {
                `AP.CreateClient();
            }
            
            port = Split(Answer, ":", true);
            ip = Repl(Answer, ":"$port, "");
            `AP.SlotData.Host = ip;
            `AP.SlotData.Port = int(port);
            `AP.Client.Connect();
            CloseHUD(H);
            break;
    }
    
    return Super.OnClick(H, release);
}

function Timer_OpenInputText(HUD H)
{
    OpenInputText(H, "Archipelago", class'Hat_ConversationType_Internet', 'a', 25);
}

function OnCloseHUD(HUD H)
{
    Super.OnCloseHUD(H);
    if (m_hBubbleTalker != None)
    {
        m_hBubbleTalker.DestroyOnComplete = true;
        m_hBubbleTalker.m_fTime = 0;
        Close();
    }
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