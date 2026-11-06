-- SentinelMentor database: single root table.
-- classes[token][level][spellID] = {cost, rank, requires, faction, race}
-- warlockPets[pet][level][spellID] / hunterPet[level][spellID]
-- professions[name].skills[skillReq][spellID] = {icon, cost}
-- professions[name].recipes[skillReq][spellID] = {icon, source, sourceLocations}
-- trainers.{class,pet,portal,profession,spec} = per-token npc/location lists
-- weaponSkills / hunterBeasts = lookup tables
SentinelMentorDB = {
    version = 2,
    classes = {},
    warlockPets = {},
    hunterPet = {},
    professions = {},
    trainers = {},
    weaponSkills = {},
    hunterBeasts = {},
}
