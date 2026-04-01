using UnityEditor;
using UnityEngine;

/// <summary>
/// Hierarchy right-click  →  GameObject / Create / Rift
/// Instantiates the prefab named "rift" found anywhere in the project.
/// The new instance is placed at world origin, parented to the currently
/// selected object (if any), selected and registered for Undo.
/// </summary>
public static class RiftSpawner
{
    private const string PrefabName = "rift";

    [MenuItem("GameObject/Create/Rift", false, 10)]
    private static void CreateRift(MenuCommand cmd)
    {
        // Search the entire project for a prefab whose file name is "rift"
        string[] guids = AssetDatabase.FindAssets($"t:Prefab {PrefabName}");
        GameObject prefab = null;

        foreach (string guid in guids)
        {
            string path = AssetDatabase.GUIDToAssetPath(guid);
            // Make sure the file name matches exactly (case-insensitive)
            string fileName = System.IO.Path.GetFileNameWithoutExtension(path);
            if (string.Equals(fileName, PrefabName, System.StringComparison.OrdinalIgnoreCase))
            {
                prefab = AssetDatabase.LoadAssetAtPath<GameObject>(path);
                break;
            }
        }

        if (prefab == null)
        {
            EditorUtility.DisplayDialog(
                "Rift Spawner",
                $"Could not find a prefab named \"{PrefabName}\" in the project.\n\n" +
                "Please create a prefab with that exact name (e.g. Assets/Prefabs/rift.prefab).",
                "OK");
            return;
        }

        // Determine parent: use the context object from the right-click, or the
        // first selected object, or null (scene root)
        GameObject parent = cmd?.context as GameObject ?? Selection.activeGameObject;
        Transform parentTransform = parent != null ? parent.transform : null;

        GameObject instance = (GameObject)PrefabUtility.InstantiatePrefab(prefab, parentTransform);
        instance.transform.SetPositionAndRotation(
            parentTransform != null ? parentTransform.position : Vector3.zero,
            Quaternion.identity);

        Undo.RegisterCreatedObjectUndo(instance, $"Create {PrefabName}");
        GameObjectUtility.SetParentAndAlign(instance, parent);
        Selection.activeGameObject = instance;
    }

    [MenuItem("GameObject/Create/Rift", true)]
    private static bool ValidateCreateRift() => true;
}
