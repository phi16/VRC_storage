
using UdonSharp;
using UnityEngine;
using VRC.SDKBase;
using VRC.Udon;

namespace Im {

    [UdonBehaviourSyncMode(BehaviourSyncMode.None)]
    public class ExtendBounds : UdonSharpBehaviour
    {
        public float size;

        void Start()
        {
            MeshFilter mf = GetComponent<MeshFilter>();
            mf.sharedMesh.bounds = new Bounds(Vector3.zero, Vector3.one * size);
        }
    }

}
