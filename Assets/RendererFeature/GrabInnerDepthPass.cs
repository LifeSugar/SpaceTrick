using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace Rift.Rendering
{
    public class GrabInnerDepthPass : ScriptableRenderPass
    {
        private Material m_Material;
        private RTHandle m_DepthCopyRT;
        private RTHandle m_CameraDepthTarget;
        private readonly ProfilingSampler m_ProfilingSampler = new ProfilingSampler("GrabInnerDepth");

        public GrabInnerDepthPass(RenderPassEvent evt, Material material)
        {
            renderPassEvent = evt;
            m_Material = material;
        }

        public void Setup(RTHandle cameraDepthTarget)
        {
            m_CameraDepthTarget = cameraDepthTarget;
        }

        public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
        {
            var desc = renderingData.cameraData.cameraTargetDescriptor;
            desc.colorFormat = RenderTextureFormat.RFloat;
            desc.depthBufferBits = 0;
            desc.msaaSamples = 1;
            RenderingUtils.ReAllocateIfNeeded(ref m_DepthCopyRT, desc, name: "_InnerWorldDepth");
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            if (m_Material == null || m_CameraDepthTarget == null) return;

            var cmd = CommandBufferPool.Get();
            using (new ProfilingScope(cmd, m_ProfilingSampler))
            {
                CoreUtils.SetRenderTarget(cmd, m_DepthCopyRT);
                cmd.SetGlobalTexture("_CameraDepthAttachment", m_CameraDepthTarget);
                Blitter.BlitTexture(cmd, m_CameraDepthTarget, new Vector4(1, 1, 0, 0), m_Material, 0);
            }
            cmd.SetGlobalTexture("_InnerWorldDepth", m_DepthCopyRT);
            context.ExecuteCommandBuffer(cmd);
            CommandBufferPool.Release(cmd);
        }

        public void Dispose()
        {
            m_DepthCopyRT?.Release();
        }
    }
}
