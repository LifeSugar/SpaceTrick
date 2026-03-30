using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class WriteStencilFeature : ScriptableRendererFeature
{
    [System.Serializable]
    public class Settings
    {
        // 建议放在渲染不透明物体之前
        public RenderPassEvent passEvent = RenderPassEvent.BeforeRenderingOpaques;
        public Material stencilMaterial;
    }

    public Settings settings = new Settings();
    private WriteStencilPass stencilPass;

    class WriteStencilPass : ScriptableRenderPass
    {
        private Material material;
        private RTHandle tempColor;
        public RTHandle m_CameraDepthRT;

        public WriteStencilPass(Material mat, RenderPassEvent evt)
        {
            this.material = mat;
            this.renderPassEvent = evt;
        }
        public void SetDepthRT(RTHandle depthRT)
        {
            m_CameraDepthRT = depthRT;
        }

        public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
        {
            var cameraTargetDescriptor = renderingData.cameraData.cameraTargetDescriptor;
            cameraTargetDescriptor.depthBufferBits = 0; // 不需要深度缓冲
            tempColor = RTHandles.Alloc(cameraTargetDescriptor, name: "WriteStencilTempColor");
        }
        public override void Configure(CommandBuffer cmd, RenderTextureDescriptor cameraTextureDescriptor)
        {
            ConfigureTarget(tempColor, m_CameraDepthRT);
            ConfigureClear(ClearFlag.Color, Color.black);
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            if (material == null) return;

            CommandBuffer cmd = CommandBufferPool.Get("WriteStencil_RiftMask");

            if (tempColor != null && m_CameraDepthRT != null)
            {
                Blitter.BlitTexture(cmd, tempColor, new Vector4(1, 1, 0, 0), material, 0);
            }

            context.ExecuteCommandBuffer(cmd);
            CommandBufferPool.Release(cmd);
        }
    }

    public override void Create()
    {
        stencilPass = new WriteStencilPass(settings.stencilMaterial, settings.passEvent);
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        // 只有当材质被赋值，且不是在渲染反射探针等特殊摄像机时才添加 Pass
        if (settings.stencilMaterial != null && renderingData.cameraData.cameraType != CameraType.Reflection)
        {
            renderer.EnqueuePass(stencilPass);
        }
    }
    public override void SetupRenderPasses(ScriptableRenderer renderer, in RenderingData renderingData)
    {
        stencilPass.SetDepthRT(renderer.cameraDepthTargetHandle);
    }
}