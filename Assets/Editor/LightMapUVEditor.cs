using System.Collections.Generic;
using UnityEditor;
using UnityEngine;

 public class LightMapUVEditor : EditorWindow
{
     [MenuItem("Tools/Generate Lightmap UV for Selected")]
     private static void Run()
     {
         var selection = Selection.gameObjects;
        if (selection == null || selection.Length == 0)
        {
            EditorUtility.DisplayDialog("Generate Lightmap UV", "No GameObject selected.", "OK");
            return;
        }

        var processedPaths = new HashSet<string>();
        int count = 0;

        foreach (var root in selection)
        {
            var renderers = root.GetComponentsInChildren<MeshRenderer>(true);
            foreach (var renderer in renderers)
            {
                // 检查是否勾选了 Contribute Global Illumination
                if ((GameObjectUtility.GetStaticEditorFlags(renderer.gameObject) & StaticEditorFlags.ContributeGI) == 0)
                    continue;

                var meshFilter = renderer.GetComponent<MeshFilter>();
                if (meshFilter == null || meshFilter.sharedMesh == null)
                    continue;

                string assetPath = AssetDatabase.GetAssetPath(meshFilter.sharedMesh);
                if (string.IsNullOrEmpty(assetPath))
                    continue;

                // 只处理 FBX（ModelImporter）
                var importer = AssetImporter.GetAtPath(assetPath) as ModelImporter;
                if (importer == null)
                    continue;

                if (processedPaths.Contains(assetPath))
                    continue;

                processedPaths.Add(assetPath);

                if (!importer.generateSecondaryUV)
                {
                    importer.generateSecondaryUV = true;
                    importer.SaveAndReimport();
                    count++;
                    Debug.Log($"[LightmapUV] Enabled Generate Lightmap UVs: {assetPath}");
                }
            }
        }

        EditorUtility.DisplayDialog("Generate Lightmap UV",
            count > 0 ? $"已为 {count} 个 FBX 开启 Generate Lightmap UVs。" : "没有需要修改的 FBX（已全部开启或无 ContributeGI 网格）。",
            "OK");
    }
}
/// 