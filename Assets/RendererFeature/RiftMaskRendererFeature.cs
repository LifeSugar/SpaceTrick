using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;
using System.Collections.Generic;

namespace Rift.Rendering
{
    [System.Serializable]
    public class RiftMaskSettings
    {
        public string passTag = "RiftMask";
        public RenderPassEvent renderPassEvent = RenderPassEvent.AfterRenderingOpaques;
        public Shader overrideShader = null;
        public int overrideShaderPassIndex = 0;
        public LayerMask maskLayer = -1;
        public bool enableDepthWrite = true;
        public CompareFunction depthCompareFunction = CompareFunction.LessEqual;
    }

    public class RiftMaskRendererFeature : ScriptableRendererFeature
    {
        RiftMaskPass riftMaskPass;
        public RiftMaskSettings settings = new RiftMaskSettings();

        public override void Create()
        {
            riftMaskPass?.Dispose();
            riftMaskPass = new RiftMaskPass(
                settings.renderPassEvent,
                settings.passTag,
                null,
                settings.maskLayer
            );
            riftMaskPass.renderPassEvent = settings.renderPassEvent;
            riftMaskPass.overrideShader = settings.overrideShader;
            riftMaskPass.overrideShaderPassIndex = settings.overrideShaderPassIndex;
            riftMaskPass.SetDepthSate(settings.enableDepthWrite, settings.depthCompareFunction);
        }

        protected override void Dispose(bool disposing)
        {
            riftMaskPass?.Dispose();
        }
        public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
        {
            if (renderingData.cameraData.cameraType == CameraType.Preview || 
        renderingData.cameraData.cameraType == CameraType.Reflection)
    {
        return;
    }
            
            renderer.EnqueuePass(riftMaskPass);
        }
        public override void SetupRenderPasses(ScriptableRenderer renderer, in RenderingData renderingData)
        {
            riftMaskPass.ConfigureInput(ScriptableRenderPassInput.Depth);
            riftMaskPass.SetDepthRT(renderer.cameraDepthTargetHandle);
        }

    }
}