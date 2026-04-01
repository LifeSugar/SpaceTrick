using System.Collections.Generic;
using UnityEditor;
using UnityEngine;

/// <summary>
/// Converts materials that use Assets/Shader/ASE.shader to Assets/Shader/Standard.shader,
/// mapping properties one-to-one.
///
/// Property mapping:
///   ASE                  →  Standard
///   _Albedo              →  _BaseMap
///   _Normal              →  _NormalMap
///   _MetallicSmoothness  →  _RoughnessMap   (roughness map)
///   _Emission            →  _EmissionMap
///   _Color               →  _BaseColor
///   _EmissionColor       →  _EmissionColor
///   _Metallic            →  _Metallic
///   _SurfaceSmoothness   →  _Roughness      (inverted: roughness = 1 - smoothness)
///   _NormalScale         →  _DetailNormalScale
///   _Tiling (float)      →  _BaseMap_ST     (uniform tiling on x/y)
/// </summary>
public class ASEToStandardConverterWindow : EditorWindow
{
    private const string ASEShaderPath     = "Assets/Shader/ASE.shader";
    private const string TargetShaderPath  = "Assets/Shader/Standard.shader";

    private Vector2 _scroll;
    private List<Material> _candidates = new();
    private bool _searched;

    // -------------------------------------------------------------------------
    // Menu items
    // -------------------------------------------------------------------------

    [MenuItem("Tools/ASE → Standard Converter")]
    public static void OpenWindow()
    {
        GetWindow<ASEToStandardConverterWindow>("ASE → Standard Converter").Show();
    }

    /// <summary>Right-click a material asset in the Project window to convert it.</summary>
    [MenuItem("Assets/Convert ASE Material to Standard", false, 30)]
    private static void ConvertSelected()
    {
        Shader target = AssetDatabase.LoadAssetAtPath<Shader>(TargetShaderPath);
        if (target == null)
        {
            EditorUtility.DisplayDialog("Error",
                $"Target shader not found at: {TargetShaderPath}", "OK");
            return;
        }

        int converted = 0;
        foreach (Object obj in Selection.objects)
        {
            if (obj is Material mat && IsASEMaterial(mat))
            {
                ConvertMaterial(mat, target);
                converted++;
            }
        }

        AssetDatabase.SaveAssets();
        EditorUtility.DisplayDialog("Done",
            converted == 0
                ? "No ASE materials found in selection."
                : $"Converted {converted} material(s).",
            "OK");
    }

    [MenuItem("Assets/Convert ASE Material to Standard", true)]
    private static bool ConvertSelectedValidate()
    {
        foreach (Object obj in Selection.objects)
            if (obj is Material mat && IsASEMaterial(mat))
                return true;
        return false;
    }

    // -------------------------------------------------------------------------
    // Editor Window
    // -------------------------------------------------------------------------

    private void OnGUI()
    {
        EditorGUILayout.LabelField("ASE → Standard Material Converter", EditorStyles.boldLabel);
        EditorGUILayout.Space(4);

        EditorGUILayout.HelpBox(
            $"Source shader : {ASEShaderPath}\nTarget shader  : {TargetShaderPath}",
            MessageType.Info);
        EditorGUILayout.Space(6);

        if (GUILayout.Button("Find All ASE Materials in Project"))
        {
            CollectCandidates();
            _searched = true;
        }

        if (_searched)
        {
            EditorGUILayout.Space(4);
            if (_candidates.Count == 0)
            {
                EditorGUILayout.HelpBox("No materials using ASE.shader found.", MessageType.Warning);
            }
            else
            {
                EditorGUILayout.LabelField($"Found {_candidates.Count} material(s):", EditorStyles.boldLabel);

                _scroll = EditorGUILayout.BeginScrollView(_scroll, GUILayout.MaxHeight(300));
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
                        EditorUtility.DisplayDialog("Done",
                            $"Converted {_candidates.Count} material(s).", "OK");
                        CollectCandidates(); // refresh list
                    }
                }
            }
        }
    }

    // -------------------------------------------------------------------------
    // Core helpers
    // -------------------------------------------------------------------------

    private void CollectCandidates()
    {
        _candidates.Clear();
        Shader aseShader = AssetDatabase.LoadAssetAtPath<Shader>(ASEShaderPath);
        if (aseShader == null)
        {
            EditorUtility.DisplayDialog("Error",
                $"ASE shader not found at: {ASEShaderPath}", "OK");
            return;
        }

        string[] guids = AssetDatabase.FindAssets("t:Material");
        foreach (string guid in guids)
        {
            string path = AssetDatabase.GUIDToAssetPath(guid);
            Material mat = AssetDatabase.LoadAssetAtPath<Material>(path);
            if (mat != null && mat.shader == aseShader)
                _candidates.Add(mat);
        }
    }

    private static bool IsASEMaterial(Material mat)
    {
        Shader aseShader = AssetDatabase.LoadAssetAtPath<Shader>(ASEShaderPath);
        return aseShader != null && mat.shader == aseShader;
    }

    private static Shader LoadTargetShader()
    {
        Shader s = AssetDatabase.LoadAssetAtPath<Shader>(TargetShaderPath);
        if (s == null)
            EditorUtility.DisplayDialog("Error",
                $"Target shader not found at: {TargetShaderPath}", "OK");
        return s;
    }

    /// <summary>
    /// Transfers all mapped properties from the ASE material to Standard shader,
    /// then swaps the shader.
    /// </summary>
    private static void ConvertMaterial(Material mat, Shader targetShader)
    {
        Undo.RecordObject(mat, "Convert ASE to Standard");

        // --- Textures ---
        Texture albedo     = mat.GetTexture("_Albedo");
        Texture normal     = mat.GetTexture("_Normal");
        Texture metalSmooth = mat.GetTexture("_MetallicSmoothness");  // → RoughnessMap
        Texture emission   = mat.GetTexture("_Emission");

        // --- Colors ---
        Color baseColor      = mat.GetColor("_Color");
        Color emissionColor  = mat.GetColor("_EmissionColor");

        // --- Floats ---
        float tiling       = mat.GetFloat("_Tiling");
        float normalScale  = mat.GetFloat("_NormalScale");
        float metallic     = mat.GetFloat("_Metallic");
        float smoothness   = mat.GetFloat("_SurfaceSmoothness");

        // Swap shader first so the properties below actually exist
        mat.shader = targetShader;

        // --- Apply textures ---
        if (albedo != null)       mat.SetTexture("_BaseMap", albedo);
        if (normal != null)       mat.SetTexture("_NormalMap", normal);
        if (metalSmooth != null)  mat.SetTexture("_RoughnessMap", metalSmooth);
        if (emission != null)     mat.SetTexture("_EmissionMap", emission);

        // --- Apply colors ---
        mat.SetColor("_BaseColor", baseColor);
        mat.SetColor("_EmissionColor", emissionColor);

        // --- Apply floats ---
        mat.SetFloat("_Metallic", metallic);
        // Smoothness (ASE) → Roughness (Standard): roughness = 1 − smoothness
        mat.SetFloat("_Roughness", Mathf.Clamp01(1f - smoothness));
        mat.SetFloat("_DetailNormalScale", normalScale);

        // --- Apply uniform tiling to _BaseMap_ST (and other maps) ---
        if (!Mathf.Approximately(tiling, 0f))
        {
            Vector2 tileVec = new Vector2(tiling, tiling);
            Vector2 offsetVec = Vector2.zero;

            // Apply to all texture ST properties in Standard shader
            string[] stProps = { "_BaseMap", "_NormalMap", "_RoughnessMap",
                                 "_EmissionMap", "_MetallicMap", "_OcclusionMap" };
            foreach (string prop in stProps)
            {
                mat.SetTextureScale(prop, tileVec);
                mat.SetTextureOffset(prop, offsetVec);
            }
        }

        // Enable emission keyword if emission color is non-black
        if (emissionColor != Color.black)
            mat.EnableKeyword("_EMISSION");

        EditorUtility.SetDirty(mat);
    }
}
