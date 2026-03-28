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
        public bool enableDepthTest = true;
        public CompareFunction depthCompareFunction = CompareFunction.LessEqual;
    }

    public class RiftMaskRendererFeature : ScriptableRendererFeature
    {
        RiftMaskPass riftMaskPass;
        public RiftMaskSettings settings = new RiftMaskSettings();

        public override void Create()
        {
            throw new System.NotImplementedException();
        }
        public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
        {
            if (riftMaskPass == null)
            {
                riftMaskPass = new RiftMaskPass(settings.renderPassEvent,
                    settings.passTag,
                    null,
                    settings.maskLayer
                );
                riftMaskPass.SetDepthSate(settings.enableDepthTest, settings.depthCompareFunction);
                riftMaskPass.renderPassEvent = settings.renderPassEvent;
            }
            renderer.EnqueuePass(riftMaskPass);
        }
        public override void SetupRenderPasses(ScriptableRenderer renderer, in RenderingData renderingData)
        {
            riftMaskPass.ConfigureInput(ScriptableRenderPassInput.Depth);
        }

    }
}