
using UdonSharp;
using UnityEngine;
using VRC.SDKBase;
using VRC.Udon;

namespace Im {

    [UdonBehaviourSyncMode(BehaviourSyncMode.None)]
    public class ParticleUpdate : UdonSharpBehaviour
    {
        public Material update;
        public Material visual;
        public Material debugMat;

        private RenderTexture rt0;
        private RenderTexture rt1;
        private bool outputIs0 = true;

        void Start()
        {
            int N = 256;
            int EW = 2; // width per element
            int EH = 2; // height per element
            int FW = N * EW; // full width
            int FH = N * EH;
            rt0 = new RenderTexture(FW, FH, 0, RenderTextureFormat.ARGBFloat);
            rt0.filterMode = FilterMode.Point;
            rt0.Create();
            rt1 = new RenderTexture(FW, FH, 0, RenderTextureFormat.ARGBFloat);
            rt1.filterMode = FilterMode.Point;
            rt1.Create();
            update.SetFloat("_Init", 1);
        }

        void FixedUpdate()
        {
            if(outputIs0) {
                update.SetTexture("_Store", rt0);
                VRCGraphics.Blit(null, rt1, update);
                visual.SetTexture("_Store", rt1);
                debugMat.SetTexture("_MainTex", rt1);
            } else {
                update.SetTexture("_Store", rt1);
                VRCGraphics.Blit(null, rt0, update);
                visual.SetTexture("_Store", rt0);
                debugMat.SetTexture("_MainTex", rt0);
            }
            update.SetFloat("_Init", 0);
            outputIs0 = !outputIs0;
        }
    }

}
