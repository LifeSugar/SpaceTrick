using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;
using System.Collections.Generic;

namespace Rift.Rendering
{
    public class RiftStencilCopyFeature : ScriptableRendererFeature
    {
        RiftStencilCopyPass riftStencilCopyPass;
        public Material material;
        public override void Create()
        {
            riftStencilCopyPass = new RiftStencilCopyPass(RenderPassEvent.AfterRenderingOpaques);
        }
        public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
        {
            if (renderingData.cameraData.cameraType == CameraType.Preview ||
        renderingData.cameraData.cameraType == CameraType.Reflection)
            {
                return;
            }

            renderer.EnqueuePass(riftStencilCopyPass);
        }
        public override void SetupRenderPasses(ScriptableRenderer renderer, in RenderingData renderingData)
        {
            riftStencilCopyPass.ConfigureInput(ScriptableRenderPassInput.Depth);
        }
    }

    public class RiftStencilCopyPass : ScriptableRenderPass
    {
        RTHandle RiftMaskStencilRT;
        public RiftStencilCopyPass(RenderPassEvent renderPassEvent)
        {
            this.renderPassEvent = renderPassEvent;
        }
        public override void Configure(CommandBuffer cmd, RenderTextureDescriptor cameraTextureDescriptor)
        {
            base.Configure(cmd, cameraTextureDescriptor);
        }

        public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
        {
            RenderTextureDescriptor depthDesc = renderingData.cameraData.cameraTargetDescriptor;
            depthDesc.graphicsFormat = UnityEngine.Experimental.Rendering.GraphicsFormat.None;
            depthDesc.depthStencilFormat = UnityEngine.Experimental.Rendering.GraphicsFormat.D24_UNorm_S8_UInt;

            RenderingUtils.ReAllocateIfNeeded(ref RiftMaskStencilRT, depthDesc, FilterMode.Point, TextureWrapMode.Clamp, name: "_RiftMaskStencilRT");
        }
        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            
        }
    }
}

