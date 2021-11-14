local _, addonTable = ...;

--- @type MaxDps
if not MaxDps then
	return
end

local Warrior = addonTable.Warrior;
local MaxDps = MaxDps;
local UnitPower = UnitPower;
local UnitHealth = UnitHealth;
local UnitAura = UnitAura;
local GetSpellDescription = GetSpellDescription;
local UnitHealthMax = UnitHealthMax;
local UnitPowerMax = UnitPowerMax;
local PowerTypeRage = Enum.PowerType.Rage;

local Necrolord = Enum.CovenantType.Necrolord;
local Venthyr = Enum.CovenantType.Venthyr;
local NightFae = Enum.CovenantType.NightFae;
local Kyrian = Enum.CovenantType.Kyrian;


local PR = {
	AncientAftershock = 325886,
	ConquerorsBanner  = 324143,
	SpearOfBastion    = 307865,
	Avatar            = 107574,
	ThunderClap       = 6343,
	UnstoppableForce  = 275336,
	ShieldBlock       = 2565,
	ShieldBlockAura   = 132404,
	ShieldSlam        = 23922,
	LastStand         = 12975,
	Bolster           = 280001,
	IgnorePain        = 190456,
	BoomingVoice      = 202743,
	DemoralizingShout = 1160,
	Ravager           = 228920,
	DragonRoar        = 118000,
	Revenge           = 6572,
	NeverSurrender    = 202561,
	RevengeAura       = 5302,
	Devastate         = 20243,
	Devastator        = 236279,
	Execute	          = 163201,
};

function Warrior:Protection()
	local fd = MaxDps.FrameData;
	local cooldown = fd.cooldown;
	local buff = fd.buff;
	local targets = MaxDps:SmartAoe();
	local targetHp = MaxDps:TargetPercentHealth() * 100;
	local covenantId = fd.covenant.covenantId;
	local talents = fd.talents;
	local rage = UnitPower('player', PowerTypeRage);
	local rageMax = UnitPowerMax('player', PowerTypeRage);
	local rageDeficit = rageMax - rage;
	local curentHP = UnitHealth('player');
	local maxHP = UnitHealthMax('player');
	local healthPerc = (curentHP / maxHP) * 100;

	local inExecutePhase = targetHp < 20 or (targetHp > 80 and covenantId == Venthyr);

	local canExecute = cooldown[PR.Execute].ready and rage >= 20 and inExecutePhase

	fd.rage = rage;
	fd.targetHp = targetHp;
	fd.targets = targets;
	fd.canExecute = canExecute;

	if talents[PR.Avatar] then
		-- avatar,if=cooldown.colossus_smash.remains<8&gcd.remains=0;
		MaxDps:GlowCooldown(
			PR.Avatar,
			cooldown[PR.Avatar].ready and cooldown[PR.ColossusSmash].remains < 8
		);
	end
	
	if covenantId == NightFae then
		MaxDps:GlowCooldown(PR.AncientAftershock, cooldown[PR.AncientAftershock].ready);
	elseif covenantId == Necrolord then
		MaxDps:GlowCooldown(PR.ConquerorsBanner, cooldown[PR.ConquerorsBanner].ready);
	elseif covenantId == Kyrian then
		MaxDps:GlowCooldown(PR.SpearOfBastion, cooldown[PR.SpearOfBastion].ready);
	end

	MaxDps:GlowCooldown(PR.Avatar, cooldown[PR.Avatar].ready);
	MaxDps:GlowCooldown(PR.DemoralizingShout, cooldown[PR.DemoralizingShout].ready);

	if healthPerc <= 80 then
		return Warrior:ProtectionDefense();
	end

	if targets > 1 then
		return Warrior:ProtectionOffenseMulti();
	end

	return Warrior:ProtectionOffenseSingle();
end

function Warrior:ProtectionDefense()
	local fd = MaxDps.FrameData;
	local cooldown = fd.cooldown;
	local buff = fd.buff;
	local talents = fd.talents;
	local rage = UnitPower('player', PowerTypeRage);
	local rageMax = UnitPowerMax('player', PowerTypeRage);
	local rageDeficit = rageMax - rage;
	local target = fd.targets;

	if not buff[PR.ShieldBlockAura].up and rage >=30 and cooldown[PR.ShieldBlock].ready then
		return PR.ShieldBlock;
	end

	if buff[PR.IgnorePain].refreshable and rage >= 40 then
		return PR.IgnorePain;
	end

	-- if not defense available return offensive
	if targets == 1 then
		return Warrior:ProtectionOffenseSingle();
	end

	return Warrior:ProtectionOffenseMulti();
end

function Warrior:ProtectionOffenseSingle()
	local fd = MaxDps.FrameData;
	local cooldown = fd.cooldown;
	local buff = fd.buff;
	local talents = fd.talents;
	local rage = UnitPower('player', PowerTypeRage);
	local rageMax = UnitPowerMax('player', PowerTypeRage);
	local rageDeficit = rageMax - rage;
	local canExecute = fd.canExecute;

	--if cooldown[PR.Avatar].ready then
	--	return PR.Avatar;
	--end

	--if cooldown[PR.DemoralizingShout].ready then
	--	return PR.DemoralizingShout;
	--end

	if cooldown[PR.Ravager].ready then
		return PR.Ravager;
	end

	if talents[PR.DragonRoar] and cooldown[PR.DragonRoar].ready then
		return PR.DragonRoar;
	end

	if canExecute then
		return PR.Execute;
	end

	if cooldown[PR.ShieldSlam].ready then
		return PR.ShieldSlam;
	end

	if cooldown[PR.ThunderClap].ready then
		return PR.ThunderClap;
	end

	if cooldown[PR.Revenge].ready and buff[PR.RevengeAura].up then
		return PR.Revenge;
	end

	if cooldown[PR.Revenge].ready and rage > 75 then
		return PR.Revenge;
	end
	
	if not talents[PR.Devastator] then 
		return PR.Devastate;
	end
end

function Warrior:ProtectionOffenseMulti()
	local fd = MaxDps.FrameData;
	local cooldown = fd.cooldown;
	local buff = fd.buff;
	local talents = fd.talents;
	local rage = UnitPower('player', PowerTypeRage);
	local rageMax = UnitPowerMax('player', PowerTypeRage);
	local rageDeficit = rageMax - rage;
	local canExecute = fd.canExecute;

	-- thunder_clap,if=(talent.unstoppable_force.enabled&buff.avatar.up);
	
	--if cooldown[PR.Avatar].ready then
	--	return PR.Avatar;
	--end

	--if cooldown[PR.DemoralizingShout].ready then
	--	return PR.DemoralizingShout;
	--end

	if cooldown[PR.Ravager].ready then
		return PR.Ravager;
	end

	if talents[PR.DragonRoar] and cooldown[PR.DragonRoar].ready then
		return PR.DragonRoar;
	end

	if cooldown[PR.Revenge].ready and buff[PR.RevengeAura].up then
		return PR.Revenge;
	end

	if cooldown[PR.Revenge].ready and rage >= 20 then
		return PR.Revenge;
	end

	if cooldown[PR.ThunderClap].ready then
		return PR.ThunderClap;
	end

	if canExecute then
		return PR.Execute;
	end

	if cooldown[PR.ShieldSlam].ready then
		return PR.ShieldSlam;
	end

	return PR.Devastate;

end
