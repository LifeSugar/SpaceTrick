using UnityEngine;

/// <summary>
/// 挂载到任意带 Trigger Collider 的物体上。
/// 鼠标按下该 Trigger 时，可在摄像机平面（保持原始深度）上拖拽移动该物体。
/// </summary>
public class DragOnCameraPlane : MonoBehaviour
{
    [Tooltip("拖拽使用的摄像机，留空则自动取 Camera.main")]
    public Camera dragCamera;

    private bool _isDragging;
    private float _planeDistance;   // 物体到摄像机的初始深度
    private Vector3 _dragOffset;    // 鼠标射线命中点与物体 pivot 的偏移

    void Start()
    {
        if (dragCamera == null)
            dragCamera = Camera.main;
    }

    void OnMouseDown()
    {
        if (dragCamera == null) return;

        _isDragging = true;

        // 计算并锁定当前深度（物体在摄像机空间中的 Z 值）
        Vector3 screenPos = dragCamera.WorldToScreenPoint(transform.position);
        _planeDistance = screenPos.z;

        // 计算点击命中点与物体 pivot 的世界空间偏移，防止物体跳到鼠标中心
        Vector3 hitWorld = dragCamera.ScreenToWorldPoint(
            new Vector3(Input.mousePosition.x, Input.mousePosition.y, _planeDistance));
        _dragOffset = transform.position - hitWorld;
    }

    void OnMouseDrag()
    {
        if (!_isDragging || dragCamera == null) return;

        Vector3 mouseWorld = dragCamera.ScreenToWorldPoint(
            new Vector3(Input.mousePosition.x, Input.mousePosition.y, _planeDistance));
        transform.position = mouseWorld + _dragOffset;
    }

    void OnMouseUp()
    {
        _isDragging = false;
    }
}
