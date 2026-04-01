using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace Rift.Rendering
{
    public class GrabInnerDepthFeature : ScriptableRendererFeature
    {
        [System.Serializable]
        public class Settings
        {
            public Shader depthCopyShader;
            public RenderPassEvent renderPassEvent = RenderPassEvent.AfterRenderingOpaques;
        }

        public Settings settings = new Settings();
        private GrabInnerDepthPass m_Pass;
        private Material m_Material;

        public override void Create()
        {
            if (settings.depthCopyShader == null) return;
            m_Material = CoreUtils.CreateEngineMaterial(settings.depthCopyShader);
            m_Pass = new GrabInnerDepthPass(settings.renderPassEvent, m_Material);
        }

        protected override void Dispose(bool disposing)
        {
            m_Pass?.Dispose();
            CoreUtils.Destroy(m_Material);
        }

        public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
        {
            if (m_Pass == null) return;
            renderer.EnqueuePass(m_Pass);
        }

        public override void SetupRenderPasses(ScriptableRenderer renderer, in RenderingData renderingData)
        {
            m_Pass?.Setup(renderer.cameraDepthTargetHandle);
        }
    }
}
