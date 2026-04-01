using UnityEngine;

public class RiftThickness : MonoBehaviour
{
    [Range(0f, 1f)]
    public float framethick = 0.06f;

    void Update()
    {
        Shader.SetGlobalFloat("_framethick", framethick);
    }
}
