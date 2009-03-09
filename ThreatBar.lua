--
-- ThreatBar.lua
-- Copyright 2008, 2009 Johannes Rydh
--
-- ThreatBar is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
-- 
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
-- 
-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.
--

ThreatBar = LibStub("AceAddon-3.0"):NewAddon( "ThreatBar", "AceEvent-3.0" );

function ThreatBar:OnInitialize()
	self.db = LibStub("AceDB-3.0"):New( "ThreatBarDB" );
	self:CreateFrame();
end

local maxheight = 300;

function ThreatBar:CreateFrame()
	if self.frame then return; end

	local f = CreateFrame( "Frame", "ThreatBarFrame", UIParent, "SecureFrameTemplate" );
	self.frame = f;
	f:SetAttribute( "unit", "target" );
	RegisterStateDriver( f, "visibility", "[combat,harm,exists,nodead] show; hide" );

	f:SetBackdrop( { bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
		tile = true, tileSize = 16, nil,
		insets = { left = 4, right = 4, top = 4, bottom = 4 } } );
	f:SetBackdropColor( 0, 0, 0, 0.5 );
	f:SetWidth( 61 );
	f:SetHeight( maxheight + 20 );
	f:EnableMouse( true );
	f:SetMovable( true );
	f:RegisterForDrag( "LeftButton" );
	f:SetScript( "OnDragStart", function() if IsAltKeyDown() then f:StartMoving(); end end );
	f:SetScript( "OnDragStop", function() f:StopMovingOrSizing() self:SavePosition(); end );

	if not self.db.profile.position then
		self.frame:SetPoint( "CENTER", UIParent );
		self.db.profile.position = {};
		self:SavePosition();
	else
		local pos = self.db.profile.position;
		self.frame:SetPoint( pos.point, UIParent, pos.relPoint, pos.x, pos.y );
	end

	f.tankbar = f:CreateTexture( nil, "OVERLAY" );
	f.tankbar:SetTexture( "Interface\\AddOns\\ThreatBar\\charcoal" );
	f.tankbar:SetTexCoord( 0, 0, 1, 0, 0, 1, 1, 1 );
	f.tankbar:SetVertexColor( 1, 0, 0 );
	f.tankbar:SetWidth( 10 );
	f.tankbar:SetHeight( maxheight );
	f.tankbar:SetPoint( "BOTTOMLEFT", f, "BOTTOMLEFT", 10, 10 );

	f.playerbar = f:CreateTexture( nil, "OVERLAY" );
	f.playerbar:SetTexture( "Interface\\AddOns\\ThreatBar\\charcoal" );
	f.playerbar:SetTexCoord( 0, 0, 1, 0, 0, 1, 1, 1 );
	f.playerbar:SetWidth( 30 );
	f.playerbar:SetHeight( maxheight );
	f.playerbar:SetPoint( "BOTTOMRIGHT", f, "BOTTOMRIGHT", -10, 10 );
	
	f.pct = f:CreateFontString( nil, "OVERLAY", "GameFontNormalSmall" );
	f.pct:SetWidth( 30 );
	f.pct:SetHeight( 12 );
	f.pct:SetPoint( "BOTTOM", f.playerbar, "BOTTOM", 0, 3 );

	f.deficit = f:CreateFontString( nil, "OVERLAY", "GameFontNormalSmall" );
	f.deficit:SetWidth( 50 );
	f.deficit:SetHeight( 12 );
	f.deficit:SetPoint( "TOP", f, "TOP", 0, -3 );
end

function ThreatBar:SavePosition()
	local point, _, relPoint, x, y = self.frame:GetPoint();
	self.db.profile.position.point = point;
	self.db.profile.position.relPoint = relPoint;
	self.db.profile.position.x = math.floor(x);
	self.db.profile.position.y = math.floor(y);
end

function ThreatBar:OnEnable()
	self:RegisterEvent( "UNIT_THREAT_LIST_UPDATE",
		function( event, unitid ) if unitid == "target" then self:Update(); end end );
	self:RegisterEvent( "PLAYER_TARGET_CHANGED", "Update" );
end

function ThreatBar:OnDisable()
	self:UnregisterEvent( "UNIT_THREAT_LIST_UPDATE" );
	self:UnregisterEvent( "PLAYER_TARGET_CHANGED" );
end

function ThreatBar:Update()
	local isTanking, status, scaledpct, rawpct, threatvalue
		= UnitDetailedThreatSituation( "player", "target" );
		
	if status == nil or rawpct == 0 then	-- not in the mob's aggro list
		self.frame.tankbar:Hide();
		self.frame.playerbar:Hide();
		self.frame.pct:SetText( "0%" );
		self.frame.deficit:SetText( "n/a" );
		return;
	end
	
	self.frame.tankbar:Show();
	self.frame.playerbar:Show();
	
	if isTanking or rawpct > 100 then
		self.frame.tankbar:SetHeight( maxheight );
		self.frame.playerbar:SetHeight( maxheight );
		self.frame.playerbar:SetVertexColor( 1, 0, 0 );
		self.frame.pct:SetText( "***" );
		self.frame.deficit:SetText( "" );
	else
		self.frame.tankbar:SetHeight( floor( maxheight*scaledpct/rawpct ) );
		self.frame.playerbar:SetHeight( floor( maxheight*scaledpct/100 ) );
		self.frame.playerbar:SetVertexColor( scaledpct/100, 1-scaledpct/100, 0 );
		self.frame.pct:SetText( ("%d%%"):format( floor(rawpct) ) );
		
		local deficit = floor( threatvalue * ( 1 - 100/rawpct ) / 100 );
		if deficit < -1000 then
			self.frame.deficit:SetText( string.format( "%2.1fk", deficit/1000 ) );
		else
			self.frame.deficit:SetText( deficit );
		end
	end
end
