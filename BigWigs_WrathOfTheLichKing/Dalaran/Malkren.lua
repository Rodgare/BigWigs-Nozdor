local mod = BigWigs:NewBoss("Hogan Death Herald", 961, 53046)
if not mod then return end
mod:RegisterEnableMob(53046)
mod.toggleOptions = {
    87065,
    87071,
    87137,
    87058,
    87138,
    87051,
    87083,
    87091,
    87067,
    87057,
    87050,
    87052,
    87064,
    87066,
    87059,
    87148,
    87069,
    87087,
    87099,
    87143,
    87144,
    87145,
    87070,
    "berserk"
}
mod.defaultDB = {
    [87017] = false,
}

local L = mod:NewLocale("enUS", true)
if L then
    L[87065] = "Ярость надзирателя"
    L[87071] = "Ритуальный снаряд"
    L[87137] = "Ритуальный разлом"
    L[87058] = "Пламенные цепи"
    L[87138] = "Паника"
    L[87051] = "Кара печати"
    L[87052] = "Кара печати"
    L[87083] = "Защита Кирин-Тора"
    L[87091] = "Жертвоприношение"
    L[87067] = "Жертвоприношение"
    L[87057] = "Призрачный замах"

    L[87050] = "Осадное клеймо"
    L[87052] = "Кара печати"
    L[87064] = "Горящая душа"
    L[87066] = "Осадный барьер"
    L[87059] = "Осадный барьер"
    L[87148] = "Ритуальная защита"
    L[87069] = "Ритуальная защита"

    L[87087] = "Ритуальная защита"
    L[87099] = "Ритуальная защита"
    L[87143] = "Ритуальная защита"
    L[87144] = "Ритуальная защита"
    L[87145] = "Ритуальная защита"

    L[87070] = "Обнаженные цепи"
    L[87069] = "Ритуальная защита"
    L[87069] = "Ритуальная защита"


    

end
L = mod:GetLocale()


function mod:OnBossEnable()
    
end

function mod:OnEngage()

	self:Berserk(567)
end

function mod:PersonalAuraApplied(args)
    if self:Me(args.destGUID) then
        self:PersonalMessage(args.spellId)
        self:PlaySound(args.spellId, "alarm")
    end
end

function mod:MassAuraApplied(args)
    if self:Me(args.destGUID) then
        self:PersonalMessage(args.spellId)
        self:PlaySound(args.spellId, "alarm")
    end
    
    self:TargetMessage(args.spellId, args.destName, "orange", "alert")
end

function mod:CheckPhaseHP(_, unit)
    if unit ~= "boss1" then return end
    local hp = UnitHealth("boss1") / UnitHealthMax("boss1")

    if self.phase == 1 and not self.warned65 and hp <= 0.65 then
        self.warned65 = true
        self:Message("stages", "orange", nil, L.nodes_warn)
        self:PlaySound("stages", "warning")
    end
end
