using System.Collections.Generic;
using System.Linq;
using UnityEditor;
using UnityEngine;

/// <summary>
/// Tool Window: manage which layers appear in the Hierarchy right-click menu.
/// Open via  Tools > Layer Setter > Settings
/// </summary>
public class LayerSetterWindow : EditorWindow
{
    // Persisted as a comma-separated string in EditorPrefs
    private const string PrefsKey = "LayerSetterTool_Layers";

    // Layers shown in this window's list
    internal static List<int> AllowedLayers = new List<int>();

    private Vector2 _scroll;

    [MenuItem("Tools/Layer Setter/Settings")]
    public static void Open()
    {
        var win = GetWindow<LayerSetterWindow>("Layer Setter");
        win.minSize = new Vector2(280, 260);
        win.Show();
    }

    private void OnEnable()
    {
        LoadPrefs();
    }

    private void OnGUI()
    {
        EditorGUILayout.LabelField("Allowed Layers in Hierarchy Menu", EditorStyles.boldLabel);
        EditorGUILayout.HelpBox(
            "Right-click any GameObject in the Hierarchy and choose\n" +
            "\"Set Layer\" to apply one of these layers.",
            MessageType.Info);

        EditorGUILayout.Space(4);

        _scroll = EditorGUILayout.BeginScrollView(_scroll, GUILayout.ExpandHeight(true));

        for (int i = 0; i < AllowedLayers.Count; i++)
        {
            EditorGUILayout.BeginHorizontal();

            // LayerField lets the user pick any layer by name
            int newLayer = EditorGUILayout.LayerField(AllowedLayers[i]);
            if (newLayer != AllowedLayers[i])
            {
                AllowedLayers[i] = newLayer;
                SavePrefs();
            }

            if (GUILayout.Button("✕", GUILayout.Width(24)))
            {
                AllowedLayers.RemoveAt(i);
                SavePrefs();
                break; // list changed, stop iterating
            }

            EditorGUILayout.EndHorizontal();
        }

        EditorGUILayout.EndScrollView();

        EditorGUILayout.Space(4);

        if (GUILayout.Button("+ Add Layer"))
        {
            // Default to "Default" layer (0)
            AllowedLayers.Add(0);
            SavePrefs();
        }
    }

    // ── Persistence ──────────────────────────────────────────────────────────

    private static void LoadPrefs()
    {
        AllowedLayers.Clear();
        string raw = EditorPrefs.GetString(PrefsKey, "");
        if (string.IsNullOrEmpty(raw)) return;

        foreach (string part in raw.Split(','))
        {
            if (int.TryParse(part, out int layer))
                AllowedLayers.Add(layer);
        }
    }

    internal static void SavePrefs()
    {
        EditorPrefs.SetString(PrefsKey, string.Join(",", AllowedLayers));
    }

    // Called from the context menu handler so the list is always up to date
    internal static List<int> GetAllowedLayers()
    {
        LoadPrefs();
        return AllowedLayers;
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared: apply layer with optional children propagation + Undo
// ─────────────────────────────────────────────────────────────────────────────
internal static class LayerSetterHelper
{
    internal static void ApplyLayer(GameObject[] targets, int layer)
    {
        bool applyToChildren = false;
        bool hasChildren = false;
        foreach (var go in targets)
            if (go.transform.childCount > 0) { hasChildren = true; break; }

        if (hasChildren)
        {
            int choice = EditorUtility.DisplayDialogComplex(
                "Set Layer",
                $"Set layer to \"{LayerMask.LayerToName(layer)}\" for child objects as well?",
                "Yes, include children", "No, this object only", "Cancel");
            if (choice == 2) return;
            applyToChildren = (choice == 0);
        }

        Undo.SetCurrentGroupName("Set Layer");
        int group = Undo.GetCurrentGroup();
        foreach (var go in targets)
            SetLayerRecursive(go, layer, applyToChildren);
        Undo.CollapseUndoOperations(group);
    }

    private static void SetLayerRecursive(GameObject go, int layer, bool recursive)
    {
        Undo.RecordObject(go, "Set Layer");
        go.layer = layer;
        if (recursive)
            foreach (Transform child in go.transform)
                SetLayerRecursive(child.gameObject, layer, true);
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hierarchy right-click  →  "Set Layer..."  →  OS dropdown with actual names
// ─────────────────────────────────────────────────────────────────────────────
public static class LayerSetterContextMenu
{
    [MenuItem("GameObject/Set Layer...", false, 20)]
    private static void ShowLayerMenu()
    {
        List<int> layers = LayerSetterWindow.GetAllowedLayers();
        GameObject[] targets = Selection.gameObjects;

        GUIContent[] options = layers
            .Select(l =>
            {
                string n = LayerMask.LayerToName(l);
                return new GUIContent(string.IsNullOrEmpty(n) ? $"Layer {l}" : n);
            })
            .ToArray();

        Vector2 mouse = Event.current != null
            ? GUIUtility.GUIToScreenPoint(Event.current.mousePosition)
            : new Vector2(200f, 200f);

        EditorUtility.DisplayCustomMenu(
            new Rect(mouse.x, mouse.y, 0, 0),
            options,
            -1,
            (userData, opts, selected) => LayerSetterHelper.ApplyLayer(targets, layers[selected]),
            null);
    }

    [MenuItem("GameObject/Set Layer...", true)]
    private static bool ValidateShowLayerMenu()
        => Selection.gameObjects != null
        && Selection.gameObjects.Length > 0
        && LayerSetterWindow.GetAllowedLayers().Count > 0;
}

// ─────────────────────────────────────────────────────────────────────────────
// Scene view overlay  —  top-right panel, visible when ≥1 object is selected
// ─────────────────────────────────────────────────────────────────────────────
[InitializeOnLoad]
public static class LayerSetterSceneOverlay
{
    static LayerSetterSceneOverlay()
        => SceneView.duringSceneGui += OnSceneGUI;

    private static void OnSceneGUI(SceneView sv)
    {
        GameObject[] targets = Selection.gameObjects;
        List<int> layers = LayerSetterWindow.GetAllowedLayers();

        if (targets == null || targets.Length == 0 || layers.Count == 0)
            return;

        const float btnH   = 22f;
        const float panelW = 154f;
        const float titleH = 20f;
        const float gap    = 4f;

        float panelH = titleH + gap + btnH * layers.Count + gap;
        float x = sv.position.width - panelW - 10f;

        Handles.BeginGUI();
        GUILayout.BeginArea(new Rect(x, 30f, panelW, panelH), GUI.skin.box);

        GUILayout.Label("Set Layer", new GUIStyle(EditorStyles.boldLabel)
        {
            alignment   = TextAnchor.MiddleCenter,
            fixedHeight = titleH
        });
        GUILayout.Space(gap);

        foreach (int layer in layers)
        {
            string name  = LayerMask.LayerToName(layer);
            string label = string.IsNullOrEmpty(name) ? $"Layer {layer}" : name;

            if (GUILayout.Button(label, GUILayout.Height(btnH)))
            {
                LayerSetterHelper.ApplyLayer(targets, layer);
                sv.Repaint();
            }
        }

        GUILayout.EndArea();
        Handles.EndGUI();
    }
}
