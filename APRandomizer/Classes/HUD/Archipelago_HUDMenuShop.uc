class Archipelago_HUDMenuShop extends Hat_HUDMenuShop
    dependson(Archipelago_ItemInfo)
	deprecated;

/*
`include(APRandomizer\Classes\Globals.uci);

function DrawShopWindow(HUD H, float x, float y, float size)
{
	local class<Hat_Collectible_Important> TargetCollectible, IterateCollectible;
	local class<Hat_Ability> AbilityClass;
	local Array<string> s;
	local Surface MyCurrencyIcon;
	local float ItemIconSize, MyPosX, MyPosY, offset, AlphaFocusView, OffsetIndex;
	local int i, j, ItIndex;
	local bool IsSelectedItem, bRenderDescription, bUseCheckoutCart, bIsInCart, IsHovered, HasManyItems;
	`if(`isdefined(WITH_DLC2))
	local string LocalizedComboString, ItemName;
	`endif
	
	bUseCheckoutCart = (ShopInventory != None && ShopInventory.HasCheckoutCart());
	bRenderDescription = (ShopInventory == None || ShopInventory.ShowDescriptions) && !bUseCheckoutCart;
	HasManyItems = ShopInventory.ItemsForSale.Length > 3;
	
	TargetCollectible = (ShopInventory != None && CurrentItemIndex >= 0 && ShopInventory.ItemsForSale.Length > CurrentItemIndex) ? class<Hat_Collectible_Important>(ShopInventory.ItemsForSale[CurrentItemIndex].CollectibleClass) : None;
	
	if (`IsMirrorMode)
	{
		x = H.Canvas.ClipX - x;
	}

	// Background
	H.Canvas.SetDrawColor(255,255,255,255);
	DrawCenter(H, x, y, size, size, ShopBackground[ViewingSpecificItemTransition >= 1.f ? 1 : 0]);
	if (ViewingSpecificItemTransition > 0.f && ViewingSpecificItemTransition < 1.f)
	{
		H.Canvas.SetDrawColor(255,255,255,255*ViewingSpecificItemTransition);
		DrawCenter(H, x, y, size, size, ShopBackground[1]);
	}
	
	`if(`isdefined(WITH_DLC2))
	if (bUseCheckoutCart && HasUndiscoveredCombo)
	{
		LocalizedComboString = "(" $ class'Hat_Localizer'.static.GetMenu("MetroFood", "UndiscoveredCombo") $ ")";
		H.Canvas.SetDrawColor(255,200,24,255);
		H.Canvas.Font = class'Hat_FontInfo'.static.GetDefaultFont(LocalizedComboString);
		class'Hat_HUDMenuLoadout'.static.DrawBorderedText(H.Canvas, LocalizedComboString, x + size * -0.003, y + size * -0.32, size*0.0008, false, TextAlign_Center);
	}
	`endif
	
	H.Canvas.PushMaskRegion(x - size*0.5f*0.9, y-size*0.5f, size*0.9, size);
	
	// Icon
	if (ShopInventory != None && ShopInventory.HasMultipleItems())
	{
		HoveredItemIndex = INDEX_NONE;
		for (i = ShopInventory.ItemsForSale.Length-1; i >= 0; i--)
		{
			for (j = 0; j < 2; j++)
			{
				// We want to render the center item last so it appears front
				if (i == 0 && j > 0) continue;
				if (CurrentItemIndex < 0 && j > 0) continue;
				ItIndex = CurrentItemIndex >= 0 ? CurrentItemIndex+(i*(j==0 ? 1 : -1)) : i;
				if (ItIndex < 0 || ItIndex >= ShopInventory.ItemsForSale.Length) continue;
				
				IsSelectedItem = !IsOnCheckoutButton && ItIndex == CurrentItemIndex;

				IterateCollectible = class<Hat_Collectible_Important>(ShopInventory.ItemsForSale[ItIndex].CollectibleClass);
				if (IterateCollectible != None)
				{
					AbilityClass = class'Hat_HUDMenuLoadout'.static.GetAbilityClass(IterateCollectible);
					
					bIsInCart = bUseCheckoutCart && CheckedOut.Length > ItIndex && CheckedOut[ItIndex];
					AlphaFocusView = 0;
					if (IsSelectedItem)
						AlphaFocusView = ViewingSpecificItemTransition;

					MyPosX = x + size * -0.011;
					if (HasManyItems)
					{
						OffsetIndex = FFloor(CurrentItemIndexInterpolated)+class'Hat_Math'.static.InterpolationEaseInEaseOutJonas(0,1, CurrentItemIndexInterpolated%1.f, 4)-float(ItIndex);
						if (Abs(OffsetIndex) > 1) OffsetIndex = OffsetIndex / Lerp(1, Abs(OffsetIndex), 0.3f);
						offset = size*0.25f*OffsetIndex;
					}
					else
						offset = size*0.25f*(((ShopInventory.ItemsForSale.Length-1)/2.f)-ItIndex);
					MyPosX -= Lerp(offset, 0, AlphaFocusView);

					MyPosY = y + size * -0.151;
					if (!bRenderDescription && !bUseCheckoutCart) MyPosY += size*0.1f;
					`if(`isdefined(WITH_DLC2))
					if (bUseCheckoutCart && HasUndiscoveredCombo) MyPosY += size*0.07f;
					`endif
					
					ItemIconSize = Size*0.447 * 0.5f;
					IsHovered = false;
					if (!IsViewingSpecificItem && HoveredItemIndex == INDEX_NONE && ViewingSpecificItemTransition <= 0.0f && MouseActivated && IsMouseInArea(H, MyPosX, MyPosY, ItemIconSize, ItemIconSize))
					{
						IsHovered = true;
						HoveredItemIndex = ItIndex;
						if (CurrentItemIndex != ItIndex && !HasManyItems)
						{
							CurrentItemIndex = ItIndex;
							OnCurrentItemIndexChange(H);
							PlayOwnerSound(H, ChangeItemSound);
						}
					}

					ItemIconSize *= Lerp(1.0f,1.6f, SelectionFadeIns[ItIndex]);

					if (bIsInCart) H.Canvas.SetDrawColor(64,64,64);
					else H.Canvas.SetDrawColor(255,255,255);
					
					H.Canvas.DrawColor.A = 255.f*(1-ViewingSpecificItemTransition);
					DrawCenter(H, MyPosX, MyPosY + ItemIconSize*0.5f, ItemIconSize, ItemIconSize*0.266, ItemStands[IsSelectedItem ? 1 : 0]);
					
					ItemIconSize *= 1.f + Lerp(Sin(GetWorldInfo().TimeSeconds*7)*0.05f*SelectionFadeIns[ItIndex],0,AlphaFocusView);

					H.Canvas.DrawColor.A = (!IsSelectedItem && ViewingSpecificItemTransition > 0) ? 255.f*(1-ViewingSpecificItemTransition) : 255.f;

					if (AbilityClass != None && AbilityClass.default.IsCrappy)
						class'Hat_HUDMenuLoadout'.static.RenderCrappyBadgeFly(H, self, MyPosX, MyPosY, ItemIconSize, true);
					DrawCenter(H, MyPosX, MyPosY, ItemIconSize, ItemIconSize, IterateCollectible.static.GetHUDIcon());
					if (AbilityClass != None && AbilityClass.default.IsCrappy)
						class'Hat_HUDMenuLoadout'.static.RenderCrappyBadgeFly(H, self, MyPosX, MyPosY, ItemIconSize);
					if (AlreadyBought[ItIndex] || bIsInCart)
					{
						H.Canvas.DrawColor.R = 255;
						H.Canvas.DrawColor.G = 255;
						H.Canvas.DrawColor.B = 255;
						DrawCenter(H, MyPosX, MyPosY, ItemIconSize, ItemIconSize, AlreadyBoughtTexture);
					}
				}
			}
		}
		if (MouseActivated && ViewingSpecificItemTransition <= 0.0f && HoveredItemIndex == INDEX_NONE && !HasManyItems && !IsViewingSpecificItem && CurrentItemIndex != INDEX_NONE)
		{
			CurrentItemIndex = INDEX_NONE;
			OnCurrentItemIndexChange(H);
		}
	}
	else
	{
		if (TargetCollectible != None)
		{
			AbilityClass = class'Hat_HUDMenuLoadout'.static.GetAbilityClass(TargetCollectible);
			ItemIconSize = Size*0.447;
			MyPosX = x + size * -0.011;
			MyPosY = y + size * -0.151 + Sin(GetWorldInfo().RealTimeSeconds*3)*size*0.015;

			H.Canvas.SetDrawColor(255,255,255,255);
			if (AbilityClass != None && AbilityClass.default.IsCrappy)
				class'Hat_HUDMenuLoadout'.static.RenderCrappyBadgeFly(H, self, MyPosX, MyPosY, ItemIconSize, true);
			DrawCenter(H, MyPosX, MyPosY, ItemIconSize, ItemIconSize, TargetCollectible.static.GetHUDIcon());
			if (AbilityClass != None && AbilityClass.default.IsCrappy)
				class'Hat_HUDMenuLoadout'.static.RenderCrappyBadgeFly(H, self, MyPosX, MyPosY, ItemIconSize);
		}
	}
	H.Canvas.PopMaskRegion();
	
	IsHoveringSide = 0;
	if (MouseActivated && ShopInventory.HasMultipleItems() && HasManyItems && CurrentItemIndex != INDEX_NONE && ClosingDown <= 0 && PaymentAnimationState <= 0 && FadeIn >= 0.8f)
	{
		H.Canvas.SetDrawColor(255,255,255,255);
		if (CurrentItemIndex > 0)
		{
			DrawCenter(H, x-size*(0.25f+Sin(H.WorldInfo.TimeSeconds*3.f)*0.01f), y-size*0.08f, size*0.35f*0.18f, size*0.18f, default.SideArrow, 0.5f);
			if (IsMouseInArea(H, x-size*0.3f, y-size*0.15f, size*0.25f, size*0.4f))
				IsHoveringSide = -1;
		}
		if (CurrentItemIndex < ShopInventory.ItemsForSale.Length-1)
		{
			DrawCenter(H, x+size*(0.25f+Sin(H.WorldInfo.TimeSeconds*3.f)*0.01f), y-size*0.08f, size*0.35f*0.18f, size*0.18f, default.SideArrow);
			if (IsHoveringSide == 0 && IsMouseInArea(H, x+size*0.3f, y-size*0.15f, size*0.25f, size*0.4f))
				IsHoveringSide = 1;
		}
		H.Canvas.SetDrawColor(255,255,255,255);
	}
	
	// Title
	H.Canvas.SetDrawColor(0,0,0,200);
	DrawCenter(H, x + size * -0.003, y + size * -0.412, size * 0.919, size * 0.077, DefaultTexture);
	if (TargetCollectible != None)
	{
		H.Canvas.SetDrawColor(255,255,255,255);
		H.Canvas.Font = class'Hat_FontInfo'.static.GetDefaultFont(TargetCollectible.static.GetLocalizedItemName());
		
		if (class<Archipelago_BadgeSalesmanItem_Base>(TargetCollectible) != None)
		{
			if (!class'Archipelago_ItemInfo'.static.GetNativeItemData(
				`AP.GetShopItemID(class<Archipelago_BadgeSalesmanItem_Base>(TargetCollectible)), ItemName))
			{
				ItemName = "AP Item";
			}
		}
		else
		{
			ItemName = "AP Item";
		}
		
		class'Hat_HUDMenuLoadout'.static.DrawBorderedText(H.Canvas, ItemName, x + size * -0.003, y + size * -0.412, size*0.0012, false, TextAlign_Center);
	}
	// Desc 
	if (bRenderDescription)
	{
		H.Canvas.SetDrawColor(0,0,0,200);
		DrawCenter(H, x + size * -0.003, y + size * 0.168, size * 0.919, size * 0.216, DefaultTexture);
		if (TargetCollectible != None)
		{
			s = TargetCollectible.static.GetLocalizedItemDesc();
			if (s.Length > 0 && s[0] != "")
			{
				H.Canvas.SetDrawColor(255,255,255,255);

				if (DescriptionScript.Segments.Length == 0 || DescriptionScript.RawText != s[0])
				{
					DescriptionScript = class'Hat_BubbleTalker_Compiler'.static.Compile(H.PlayerOwner, s[0], 40);
				}
				
				class'Hat_BubbleTalker_Render'.static.Analyze(H.Canvas, DescriptionScript, 66);
				class'Hat_BubbleTalker_Render'.static.Render(H.Canvas, DescriptionScript, vect(1,0,0)*(x + size * -0.003) + vect(0,1,0)*(y + size * 0.16), size*0.0012, MakeColor(255,255,255,255), MakeColor(255,255,255,255), DescriptionTextProgress, TextAlign_Center);
			}
		}
	}
	
	// Total price (for checkout shops)
	if (bUseCheckoutCart)
	{
		MyCurrencyIcon = ShopInventory != None ? ShopInventory.GetCurrencyIcon() : None;
		MyPosX = x-size*0.1f;
		MyPosY = y+size*0.38;
		DrawCenter(H, MyPosX + size * 0.229, MyPosY + size * 0.009, size * 0.094, size * 0.094, MyCurrencyIcon != None ? MyCurrencyIcon : CurrencyIcon);
		DrawCenter(H, MyPosX + size * 0.020, MyPosY + size * 0.009, size * 0.316, size * 0.117, CostBg);
		DrawCostText(H, MyPosX + size * -0.15, MyPosY + size * 0.009, size * 0.057, LocalizedString_TotalCost);
		DrawCostNumber(H, MyPosX + size*0.14, MyPosY, size*0.057, Int(CurrentTotalCount_Visuals));
		
		if (PaymentAnimationState <= 0)
		{
			if (NumCheckedOutItems > 0) H.Canvas.SetDrawColor(64, 255, 64, 255);
			else H.Canvas.SetDrawColor(64, 64, 64, 255);
			
			MyPosX += Size*0.42;
			ItemIconSize = size*0.22f;
			if (MouseActivated && !IsViewingSpecificItem)
			{
				IsHovered = IsMouseInArea(H, MyPosX, MyPosY, ItemIconSize, ItemIconSize);
				if (IsHovered != IsOnCheckoutButton)
				{
					IsOnCheckoutButton = IsHovered;
					if (IsOnCheckoutButton)
						PlayOwnerSound(H, ChangeItemSound);
				}
			}
			
			DrawCheckoutButton(H, MyPosX, MyPosY, ItemIconSize, LocalizedString_Action_Checkout, IsOnCheckoutButton);
		}
	}
	
	// Price
	if (CurrentItemIndex >= 0 && !AlreadyBought[CurrentItemIndex] && (!bUseCheckoutCart || PaymentAnimationState <= 0))
	{
		MyCurrencyIcon = ShopInventory != None ? ShopInventory.GetCurrencyIcon() : None;
		MyPosX = x+size*(bUseCheckoutCart ? -0.15f : 0.f);
		MyPosY = y+size*(bUseCheckoutCart ? 0.2 : 0.38);
		
		if (bUseCheckoutCart)
		{
			H.Canvas.SetDrawColor(0,0,0,200);
			DrawCenter(H, x + size * -0.003, MyPosY + size*0.01, size * 0.919, size * 0.14, DefaultTexture);
		}
		
		H.Canvas.SetDrawColor(255,255,255,255);
		DrawCenter(H, MyPosX + size * 0.229, MyPosY + size * 0.009, size * 0.094, size * 0.094, MyCurrencyIcon != None ? MyCurrencyIcon : CurrencyIcon);
		if (!bUseCheckoutCart)
		{
			DrawCenter(H, MyPosX + size * 0.020, MyPosY + size * 0.009, size * 0.316, size * 0.117, CostBg);
			DrawCostText(H, MyPosX + size * -0.15, MyPosY + size * 0.009, size * 0.057, LocalizedString_ItemCost);
		}
		DrawCostNumber(H, MyPosX + size*0.14, MyPosY, size*0.057, bUseCheckoutCart ? CurrentCostCount : Min(Int(CurrentCostCount_Visuals), CurrentCostCount));
	}
}
*/