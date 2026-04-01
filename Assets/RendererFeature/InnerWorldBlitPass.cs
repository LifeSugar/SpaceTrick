using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace Rift.Rendering
{
    public class InnerWorldBlitPass : ScriptableRenderPass
    {
        private Material m_BlitMaterial;
        private RTHandle m_CameraColorTarget;
        private RTHandle m_CameraDepthTarget;
        private RenderTexture m_innerWorldSource;
        private RTHandle m_innerWorldRTHandle;
        private readonly ProfilingSampler m_ProfilingSampler = new ProfilingSampler("InnerWorldBlit");

        public InnerWorldBlitPass(RenderPassEvent evt, Material material, RenderTexture innerWorldRT = null)
        {
            renderPassEvent = evt;
            m_BlitMaterial = material;
            m_innerWorldSource = innerWorldRT;
            ConfigureInput(ScriptableRenderPassInput.Depth);
        }

        public void Setup(RTHandle cameraColorTarget, RTHandle cameraDepthTarget = null)
        {
            m_CameraColorTarget = cameraColorTarget;
            m_CameraDepthTarget = cameraDepthTarget;
        }

        public override void Configure(CommandBuffer cmd, RenderTextureDescriptor cameraTextureDescriptor)
        {
            if (m_CameraDepthTarget != null)
                ConfigureTarget(m_CameraColorTarget, m_CameraDepthTarget);
            else
                ConfigureTarget(m_CameraColorTarget);
            ConfigureClear(ClearFlag.None, Color.clear);
        }

        public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
        {
            if (m_innerWorldSource != null && m_innerWorldSource.IsCreated())
            {
                if (m_innerWorldRTHandle == null || m_innerWorldRTHandle.rt != m_innerWorldSource)
                {
                    // Do not Release() — the underlying RT is owned by RenderCameraToRT
                    m_innerWorldRTHandle = RTHandles.Alloc(m_innerWorldSource);
                }
            }
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            if (m_BlitMaterial == null) return;
            if (m_innerWorldSource == null || !m_innerWorldSource.IsCreated()) return;
            if (m_innerWorldRTHandle == null) return;
            if (m_CameraColorTarget == null) return;

            var cmd = CommandBufferPool.Get();
            using (new ProfilingScope(cmd, m_ProfilingSampler))
            {
                cmd.SetGlobalTexture("_BlitTexture", m_innerWorldRTHandle);
                Blitter.BlitTexture(cmd, m_innerWorldRTHandle, new Vector4(1, 1, 0, 0), m_BlitMaterial, 0);
            }
            context.ExecuteCommandBuffer(cmd);
            CommandBufferPool.Release(cmd);
        }

        public void dispose()
        {
            // Do not Release() — the underlying RT is owned by RenderCameraToRT
            m_innerWorldRTHandle = null;
        }
    }
}
