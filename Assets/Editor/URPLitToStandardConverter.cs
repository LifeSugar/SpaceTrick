using System.Collections.Generic;
using UnityEditor;
using UnityEngine;

/// <summary>
/// Converts materials using the URP built-in Lit shader
/// ("Universal Render Pipeline/Lit") to Assets/Shader/Standard.shader.
///
/// Property mapping:
///   URP Lit              →  Custom Standard
///   _BaseMap             →  _BaseMap
///   _BaseColor           →  _BaseColor
///   _BumpMap             →  _NormalMap
///   _BumpScale           →  _DetailNormalScale
///   _MetallicGlossMap    →  _MetallicMap
///   _Metallic            →  _Metallic
///   _Smoothness          →  _Roughness   (roughness = 1 − smoothness)
///   _OcclusionMap        →  _OcclusionMap
///   _OcclusionStrength   →  _OcclusionStrength
///   _EmissionMap         →  _EmissionMap
///   _EmissionColor       →  _EmissionColor
///   _BaseMap_ST          →  all texture _ST (tiling / offset)
///
/// Note on smoothness texture:
///   URP Lit packs smoothness into the alpha channel of _MetallicGlossMap
///   (or _BaseMap alpha when _SmoothnessTextureChannel == 1). The custom
///   Standard.shader samples _RoughnessMap separately. The converter assigns
///   _MetallicGlossMap to _MetallicMap only. For accurate per-pixel roughness
///   you will need a dedicated roughness texture extracted from the alpha channel.
/// </summary>
public class URPLitToStandardConverterWindow : EditorWindow
{
    private const string URPLitShaderName  = "Universal Render Pipeline/Lit";
    private const string TargetShaderPath  = "Assets/Shader/Standard.shader";

    private Vector2 _scroll;
    private readonly List<Material> _candidates = new();
    private bool _searched;

    // -------------------------------------------------------------------------
    // Menu items
    // -------------------------------------------------------------------------

    [MenuItem("Tools/URP Lit → Standard Converter")]
    public static void OpenWindow() =>
        GetWindow<URPLitToStandardConverterWindow>("URP Lit → Standard").Show();

    [MenuItem("Assets/Convert URP Lit Material to Standard", false, 31)]
    private static void ConvertSelected()
    {
        Shader target = LoadTargetShader();
        if (target == null) return;

        int converted = 0;
        foreach (Object obj in Selection.objects)
        {
            if (obj is Material mat && IsURPLitMaterial(mat))
            {
                ConvertMaterial(mat, target);
                converted++;
            }
        }

        AssetDatabase.SaveAssets();
        EditorUtility.DisplayDialog("Done",
            converted == 0
                ? "No URP Lit materials found in selection."
                : $"Converted {converted} material(s).",
            "OK");
    }

    [MenuItem("Assets/Convert URP Lit Material to Standard", true)]
    private static bool ConvertSelectedValidate()
    {
        foreach (Object obj in Selection.objects)
            if (obj is Material mat && IsURPLitMaterial(mat))
                return true;
        return false;
    }

    // -------------------------------------------------------------------------
    // Editor Window
    // -------------------------------------------------------------------------

    private void OnGUI()
    {
        EditorGUILayout.LabelField("URP Lit → Custom Standard Converter", EditorStyles.boldLabel);
        EditorGUILayout.Space(4);

        EditorGUILayout.HelpBox(
            $"Source shader : {URPLitShaderName}\nTarget shader  : {TargetShaderPath}\n\n" +
            "Smoothness → Roughness: roughness = 1 − smoothness\n" +
            "_MetallicGlossMap is copied to _MetallicMap.",
            MessageType.Info);
        EditorGUILayout.Space(6);

        if (GUILayout.Button("Find All URP Lit Materials in Project"))
        {
            CollectCandidates();
            _searched = true;
        }

        if (!_searched) return;

        EditorGUILayout.Space(4);
        if (_candidates.Count == 0)
        {
            EditorGUILayout.HelpBox("No materials using URP Lit shader found.", MessageType.Warning);
            return;
        }

        EditorGUILayout.LabelField($"Found {_candidates.Count} material(s):", EditorStyles.boldLabel);

        _scroll = EditorGUILayout.BeginScrollView(_scroll, GUILayout.MaxHeight(320));
        foreach (Material mat in _candidates)
        {
            EditorGUILayout.BeginHorizontal();
            EditorGUILayout.ObjectField(mat, typeof(Material), false);
            if (GUILayout.Button("Convert", GUILayout.Width(70)))
            {
                Shader target = LoadTargetShader();
                if (target != null)
                {
                    ConvertMaterial(mat, target);
                    AssetDatabase.SaveAssets();
                }
            }
            EditorGUILayout.EndHorizontal();
        }
        EditorGUILayout.EndScrollView();

        EditorGUILayout.Space(6);
        if (GUILayout.Button($"Convert All ({_candidates.Count})"))
        {
            Shader target = LoadTargetShader();
            if (target != null)
            {
                foreach (Material mat in _candidates)
                    ConvertMaterial(mat, target);
                AssetDatabase.SaveAssets();
                EditorUtility.DisplayDialog("Done", $"Converted {_candidates.Count} material(s).", "OK");
                CollectCandidates();
            }
        }
    }

    // -------------------------------------------------------------------------
    // Core helpers
    // -------------------------------------------------------------------------

    private void CollectCandidates()
    {
        _candidates.Clear();
        string[] guids = AssetDatabase.FindAssets("t:Material");
        foreach (string guid in guids)
        {
            string path = AssetDatabase.GUIDToAssetPath(guid);
            Material mat = AssetDatabase.LoadAssetAtPath<Material>(path);
            if (mat != null && IsURPLitMaterial(mat))
                _candidates.Add(mat);
        }
    }

    private static bool IsURPLitMaterial(Material mat) =>
        mat.shader != null && mat.shader.name == URPLitShaderName;

    private static Shader LoadTargetShader()
    {
        Shader s = AssetDatabase.LoadAssetAtPath<Shader>(TargetShaderPath);
        if (s == null)
            EditorUtility.DisplayDialog("Error",
                $"Target shader not found at: {TargetShaderPath}", "OK");
        return s;
    }

    private static void ConvertMaterial(Material src, Shader targetShader)
    {
        Undo.RecordObject(src, "Convert URP Lit to Standard");

        // ---- Read all values before swapping the shader ----

        // Textures
        Texture baseMap      = src.GetTexture("_BaseMap");
        Texture normalMap    = src.GetTexture("_BumpMap");
        Texture metallicMap  = src.GetTexture("_MetallicGlossMap");  // R=metallic, A=smoothness
        Texture occlusionMap = src.GetTexture("_OcclusionMap");
        Texture emissionMap  = src.GetTexture("_EmissionMap");

        // Texture ST (tiling / offset) — URP Lit uses _BaseMap_ST for all maps
        Vector2 tilingBase  = src.GetTextureScale("_BaseMap");
        Vector2 offsetBase  = src.GetTextureOffset("_BaseMap");

        // Colors
        Color baseColor     = src.GetColor("_BaseColor");
        Color emissionColor = src.GetColor("_EmissionColor");

        // Floats
        float metallic        = src.GetFloat("_Metallic");
        float smoothness      = src.GetFloat("_Smoothness");
        float normalScale     = src.HasFloat("_BumpScale") ? src.GetFloat("_BumpScale") : 1f;
        float occlusionStrength = src.HasFloat("_OcclusionStrength") ? src.GetFloat("_OcclusionStrength") : 1f;

        // ---- Swap shader ----
        src.shader = targetShader;

        // ---- Textures ----
        if (baseMap != null)      src.SetTexture("_BaseMap",      baseMap);
        if (normalMap != null)    src.SetTexture("_NormalMap",    normalMap);
        if (metallicMap != null)  src.SetTexture("_MetallicMap",  metallicMap);
        if (occlusionMap != null) src.SetTexture("_OcclusionMap", occlusionMap);
        if (emissionMap != null)  src.SetTexture("_EmissionMap",  emissionMap);

        // Apply tiling / offset to all texture slots
        string[] texProps = { "_BaseMap", "_NormalMap", "_MetallicMap", "_RoughnessMap",
                              "_OcclusionMap", "_EmissionMap" };
        foreach (string prop in texProps)
        {
            src.SetTextureScale(prop, tilingBase);
            src.SetTextureOffset(prop, offsetBase);
        }

        // ---- Colors ----
        src.SetColor("_BaseColor",     baseColor);
        src.SetColor("_EmissionColor", emissionColor);

        // ---- Floats ----
        src.SetFloat("_Metallic",          metallic);
        src.SetFloat("_Roughness",         Mathf.Clamp01(1f - smoothness)); // key conversion
        src.SetFloat("_DetailNormalScale", normalScale);
        src.SetFloat("_OcclusionStrength", occlusionStrength);

        // ---- Keywords ----
        if (emissionColor != Color.black || emissionMap != null)
            src.EnableKeyword("_EMISSION");

        EditorUtility.SetDirty(src);
        Debug.Log($"[URPLit→Standard] Converted: {AssetDatabase.GetAssetPath(src)}  " +
                  $"smoothness={smoothness:F3} → roughness={Mathf.Clamp01(1f - smoothness):F3}");
    }
}
