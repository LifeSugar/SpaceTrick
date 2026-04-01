using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;
using System.Collections.Generic;

namespace Rift.Rendering
{
    public class RiftMaskPass : ScriptableRenderPass
    {
        FilteringSettings m_FilteringSettings;
        string m_ProfilerTag = "RiftMaskPass";
        ProfilingSampler m_ProfilingSampler;
        public Shader overrideShader;
        public int overrideShaderPassIndex = 0;
        List<ShaderTagId> m_ShaderTagIdList = new List<ShaderTagId>();
        RenderStateBlock m_RenderStateBlock;
        RTHandle RiftMaskRT;
        public RTHandle m_CameraDepthRT;

        public RiftMaskPass(
            RenderPassEvent renderPassEvent,
            string profilerTag = "RiftMaskPass",
            string[] shaderTagIds = null,
            int layerMask = -1
        )
        {
            this.renderPassEvent = renderPassEvent;
            m_ProfilerTag = profilerTag;
            m_ProfilingSampler = new ProfilingSampler(profilerTag);
            if (shaderTagIds != null)
            {
                foreach (var shaderTagId in shaderTagIds)
                {
                    m_ShaderTagIdList.Add(new ShaderTagId(shaderTagId));
                }
            }
            else
            {
                m_ShaderTagIdList.Add(new ShaderTagId("SRPDefaultUnlit"));
                m_ShaderTagIdList.Add(new ShaderTagId("UniversalForward"));
                m_ShaderTagIdList.Add(new ShaderTagId("UniversalForwardOnly"));
                m_ShaderTagIdList.Add(new ShaderTagId("DepthOnly"));
            }
            m_FilteringSettings = new FilteringSettings(RenderQueueRange.opaque, layerMask);
        }

        public void SetDepthSate(bool enableDepthTest, CompareFunction depthCompareFunction = CompareFunction.LessEqual)
        {
            m_RenderStateBlock.mask |= RenderStateMask.Depth;
            m_RenderStateBlock.depthState = new DepthState(enableDepthTest, depthCompareFunction);
        }
        public void SetDepthRT(RTHandle depthRT)
        {
            m_CameraDepthRT = depthRT;
        }

        public override void Configure(CommandBuffer cmd, RenderTextureDescriptor cameraTextureDescriptor)
        {
            ConfigureTarget(RiftMaskRT, m_CameraDepthRT);
            ConfigureClear(ClearFlag.Color, Color.black);
        }
        public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
        {
            base.OnCameraSetup(cmd, ref renderingData);
            var discriptor = renderingData.cameraData.cameraTargetDescriptor;
            discriptor.depthBufferBits = 0;
            RenderingUtils.ReAllocateIfNeeded(ref RiftMaskRT, discriptor, name: "RiftMaskRT", filterMode: FilterMode.Point, wrapMode: TextureWrapMode.Clamp);
        }
        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            SortingCriteria sortingCriteria = renderingData.cameraData.defaultOpaqueSortFlags;
            DrawingSettings drawingSettings = CreateDrawingSettings(m_ShaderTagIdList, ref renderingData, sortingCriteria);
            drawingSettings.overrideShader = overrideShader;
            drawingSettings.overrideMaterialPassIndex = overrideShaderPassIndex;

            var cmd = CommandBufferPool.Get(m_ProfilerTag);
            using (new ProfilingScope(cmd, m_ProfilingSampler))
            {
                context.ExecuteCommandBuffer(cmd);
                cmd.Clear();

                context.DrawRenderers(renderingData.cullResults, ref drawingSettings, ref m_FilteringSettings, ref m_RenderStateBlock);

                cmd.SetGlobalTexture("_RiftMaskRT", RiftMaskRT);
            }
            context.ExecuteCommandBuffer(cmd);
            CommandBufferPool.Release(cmd);
        }
        public override void OnCameraCleanup(CommandBuffer cmd)
        {
            base.OnCameraCleanup(cmd);
            m_CameraDepthRT = null;
        }

        public void Dispose()
        {
            RiftMaskRT?.Release();
            RiftMaskRT = null;
        }
    }
}