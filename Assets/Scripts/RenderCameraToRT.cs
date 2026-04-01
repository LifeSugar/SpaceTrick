using UnityEngine;

[RequireComponent(typeof(Camera))]
public class RenderCameraToRT : MonoBehaviour
{
    /// <summary>全局单例访问点，其他脚本或 RendererFeature 可通过 RenderCameraToRT.RT 获取当前 RT。</summary>
    public static RenderTexture RT { get; private set; }

    [Header("生成的 RenderTexture")]
    public RenderTexture screenSpaceRT;
    
    private Camera targetCamera;

    void Start()
    {
        targetCamera = GetComponent<Camera>();
        ConfigureCameraForTransparentRT();
        CreateAndAssignRT();
    }

    void ConfigureCameraForTransparentRT()
    {
        targetCamera.clearFlags = CameraClearFlags.SolidColor;
        targetCamera.backgroundColor = Color.clear;
    }

    void CreateAndAssignRT()
    {
        int width = Screen.width;
        int height = Screen.height;

        RenderTextureFormat format = targetCamera.allowHDR ? RenderTextureFormat.ARGBHalf : RenderTextureFormat.ARGB32;
        
        RenderTextureDescriptor descriptor = new RenderTextureDescriptor(width, height, format, 32);
        descriptor.sRGB = true; // 确保颜色空间正确
        descriptor.useMipMap = false;
        descriptor.autoGenerateMips = false;

        screenSpaceRT = new RenderTexture(descriptor);
        screenSpaceRT.name = "DynamicScreenSizeRT";
        screenSpaceRT.Create();

        targetCamera.targetTexture = screenSpaceRT;

        // 静态属性 & 全局 Shader Texture 同步更新
        RT = screenSpaceRT;
        Shader.SetGlobalTexture("_InnerWorld", screenSpaceRT);
    }

    void Update()
    {
        // 每帧更新内世界相机的 ZBufferParams，供 blit shader 做深度线性化
        if (targetCamera != null)
        {
            float far = targetCamera.farClipPlane;
            float near = targetCamera.nearClipPlane;
            Vector4 zbp;
            if (SystemInfo.usesReversedZBuffer)
                zbp = new Vector4(-1f + far / near, 1f, (-1f + far / near) / far, 1f / far);
            else
                zbp = new Vector4(1f - far / near, far / near, (1f - far / near) / far, (far / near) / far);
            Shader.SetGlobalVector("_InnerWorldZBufferParams", zbp);
        }

        if (screenSpaceRT != null && (screenSpaceRT.width != Screen.width || screenSpaceRT.height != Screen.height))
        {
            targetCamera.targetTexture = null;
            screenSpaceRT.Release();
            Destroy(screenSpaceRT);
            CreateAndAssignRT();
        }
    }

    void OnDestroy()
    {
        if (screenSpaceRT != null)
        {
            targetCamera.targetTexture = null;
            RT = null;
            Shader.SetGlobalTexture("_InnerWorld", null);
            screenSpaceRT.Release();
            Destroy(screenSpaceRT);
        }
    }
}