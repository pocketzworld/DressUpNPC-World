using System.Collections.Generic;
using UnityEditor;
using UnityEngine;

public class OutfitEditorWindow : EditorWindow
{
	private string idInput = "";
	private ScriptableObject targetScriptableObject;

	[MenuItem("Assets/Edit Outfit Items", true)]
	private static bool ValidateEditOutfitItems()
	{
		return Selection.activeObject is ScriptableObject;
	}

	[MenuItem("Assets/Edit Outfit Items")]
	private static void OpenOutfitEditorWindow()
	{
		if (Selection.activeObject is ScriptableObject selectedObject)
		{
			OutfitEditorWindow window = GetWindow<OutfitEditorWindow>("Edit Outfit Items");
			window.targetScriptableObject = selectedObject;
		}
		else
		{
			Debug.LogError("Selected object is not a ScriptableObject.");
		}
	}

	private void OnGUI()
	{
		EditorGUILayout.LabelField("Add Items to Outfit", EditorStyles.boldLabel);
		EditorGUILayout.Space();

		if (targetScriptableObject == null)
		{
			EditorGUILayout.LabelField("No ScriptableObject selected.", EditorStyles.wordWrappedLabel);
			return;
		}

		EditorGUILayout.LabelField("ScriptableObject:", targetScriptableObject.name);
		EditorGUILayout.Space();

		EditorGUILayout.LabelField("Paste comma-separated IDs:");
		idInput = EditorGUILayout.TextArea(idInput, GUILayout.Height(50));

		if (GUILayout.Button("Add Items"))
		{
			AddItemsToAsset();
		}
	}

	private void AddItemsToAsset()
	{
		if (targetScriptableObject == null)
		{
			Debug.LogError("No ScriptableObject loaded.");
			return;
		}

		if (string.IsNullOrEmpty(idInput))
		{
			Debug.LogWarning("No IDs entered.");
			return;
		}

		string[] ids = idInput.Split(',');
		for (int i = 0; i < ids.Length; i++)
		{
			ids[i] = ids[i].Trim();
		}

		SerializedObject serializedObject = new SerializedObject(targetScriptableObject);
		SerializedProperty itemsProperty = serializedObject.FindProperty("_items");

		if (itemsProperty == null || !itemsProperty.isArray)
		{
			Debug.LogError("Failed to find '_items' array in the ScriptableObject.");
			return;
		}

		// Clear the existing items
		itemsProperty.ClearArray();

		// Add new items
		foreach (string id in ids)
		{
			if (!string.IsNullOrEmpty(id))
			{
				itemsProperty.InsertArrayElementAtIndex(itemsProperty.arraySize);
				SerializedProperty newItem = itemsProperty.GetArrayElementAtIndex(itemsProperty.arraySize - 1);
				newItem.FindPropertyRelative("_descriptorId").stringValue = id;
				newItem.FindPropertyRelative("_paletteId").intValue = -1;
			}
		}

		// Apply changes to the asset
		serializedObject.ApplyModifiedProperties();
		EditorUtility.SetDirty(targetScriptableObject);
		AssetDatabase.SaveAssets();
		AssetDatabase.Refresh();

		Debug.Log("Items replaced successfully in the ScriptableObject.");
		Close();
	}
}
