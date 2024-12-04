--!Type(Module)

export type ClothingData = {
    id: string,
    color: number
}

function DeserializeClothingDataToOutfit(clothingDataList : {ClothingData}) : CharacterOutfit
    local outfitIds = {}
    for _, clothingData in ipairs(clothingDataList) do
        table.insert(outfitIds, clothingData.id)
    end
    local outfit = DeserializeDataToOutfit(outfitIds)
    for i = 1 , #outfit.clothing do
        outfit.clothing[i].color = clothingDataList[i].color
    end
    return outfit
end

function DeserializeDataToOutfit(outfitIds : {string}) : CharacterOutfit
    return CharacterOutfit.CreateInstance(outfitIds, nil)
end

function SerializeOutfitToData(outfit : CharacterOutfit) : {ClothingData}
    local clothingList = {}
    for _, clothing in ipairs(outfit.clothing) do
        table.insert(clothingList, {id = clothing.id, color = clothing.color})
    end
    return clothingList
end

function SerializeOutfitToOutfitSaveData(outfit : CharacterOutfit) : OutfitSaveData
    local clothingDataList = SerializeOutfitToData(outfit)
    local saveData = {
        Ids = {},
        Colors = {}
    }
    for _, clothingData in ipairs(clothingDataList) do
        saveData.Ids[#saveData.Ids + 1] = clothingData.id
        saveData.Colors[#saveData.Colors + 1] = clothingData.color
    end
    return saveData
end

function DeserializeOutfitSaveDataToOutfit(saveData : OutfitSaveData) : CharacterOutfit
    local clothingDataList = {}
    for i = 1, #saveData.Ids do
        table.insert(clothingDataList, {id = saveData.Ids[i], color = saveData.Colors[i]})
    end
    return DeserializeClothingDataToOutfit(clothingDataList)
end