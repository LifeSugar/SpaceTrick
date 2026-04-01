using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace Rift.Rendering
{
    public class InnerWorldBlitFeature : ScriptableRendererFeature
    {
        [System.Serializable]
        public class Settings
        {
            // public RenderCameraToRT innerWorldCamera;
            public Material blitMaterial;
            public RenderPassEvent renderPassEvent = RenderPassEvent.AfterRenderingTransparents;
        }

        public Settings settings = new Settings();

        private InnerWorldBlitPass m_Pass;
        private Material m_BlitMaterial;
        private RenderTexture m_innerworldSource;

        public override void Create()
        {
            m_BlitMaterial = settings.blitMaterial;
            m_innerworldSource = RenderCameraToRT.RT;
            m_Pass = new InnerWorldBlitPass(settings.renderPassEvent, m_BlitMaterial, m_innerworldSource);
        }

        protected override void Dispose(bool disposing)
        {
            m_Pass?.dispose();
        }

        public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
        {
            if (m_Pass == null) return;

            if (renderingData.cameraData.cameraType == CameraType.Preview ||
                renderingData.cameraData.cameraType == CameraType.Reflection)
                return;

            renderer.EnqueuePass(m_Pass);
        }

        public override void SetupRenderPasses(ScriptableRenderer renderer, in RenderingData renderingData)
        {
            m_Pass?.Setup(renderer.cameraColorTargetHandle, renderer.cameraDepthTargetHandle);
        }
    }
}
