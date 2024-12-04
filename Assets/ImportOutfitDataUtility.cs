using System.Collections.Generic;
using System.IO;
using UnityEditor;
using UnityEngine;

public class ReplaceOutfitDataUtility : Editor
{
	[MenuItem("Assets/Replace Outfit Data")]
	private static void ReplaceOutfitData()
	{
		var selectedObj = Selection.activeObject;
		if (selectedObj == null)
		{
			Debug.LogWarning("No object selected.");
			return;
		}

		// get file path of selected object
		string outfitPath = AssetDatabase.GetAssetPath(selectedObj);

		// Prompt to select the new data JSON file
		string newDataPath = EditorUtility.OpenFilePanel("Select New Data JSON file", "", "json");
		if (string.IsNullOrEmpty(newDataPath))
		{
			Debug.LogWarning("No new data file selected.");
			return;
		}

		string outfitJson = File.ReadAllText(outfitPath);
		string newDataJson = File.ReadAllText(newDataPath);

		OutfitData outfitData;
		List<ImportData> importedItems;

		try
		{
			outfitData = JsonUtility.FromJson<OutfitData>(outfitJson);
			importedItems = JsonUtility.FromJson<ImportWrapper>(WrapJsonArray(newDataJson)).Items;
		}
		catch
		{
			Debug.LogError("Failed to parse JSON. Ensure the files have the correct format.");
			return;
		}

		// Replace Clothing items
		outfitData.Clothing = new List<ClothingItem>();
		foreach (var item in importedItems)
		{
			outfitData.Clothing.Add(new ClothingItem
			{
				Id = item.item_id,
				Color = item.active_palette
			});
		}

		// Save the updated JSON back to the outfit file
		string updatedJson = JsonUtility.ToJson(outfitData, true);
		File.WriteAllText(outfitPath, updatedJson);

		Debug.Log("Outfit data replaced successfully.");
	}

	private static string WrapJsonArray(string json)
	{
		return $"{{\"Items\":{json}}}";
	}

	[System.Serializable]
	private class OutfitData
	{
		public bool IncludeFallbacks;
		public string Skeleton;
		public List<ClothingItem> Clothing;
	}

	[System.Serializable]
	private class ClothingItem
	{
		public string Id;
		public int Color;
	}

	[System.Serializable]
	private class ImportWrapper
	{
		public List<ImportData> Items;
	}

	[System.Serializable]
	private class ImportData
	{
		public string item_id;
		public int active_palette;
		public bool account_bound;
		public object nfi_metadata;
		public object nft_metadata;
		public object remote_render_metadata;
	}
}
