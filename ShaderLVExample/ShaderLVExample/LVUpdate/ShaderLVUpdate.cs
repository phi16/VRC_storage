using UdonSharp;
using UnityEngine;
using VRC.SDKBase;
using VRC.Udon;

[UdonBehaviourSyncMode(BehaviourSyncMode.None)]
public class ShaderLVUpdate : UdonSharpBehaviour
{
    const int RES = 32;

    public CustomRenderTexture crt;

    // Original: https://github.com/REDSIM/VRCLightVolumes

    // This is a modified and simplified version of the LightVolumeManager.cs,
    // to inject a custom lighting volume data (CRT), as the LightVolumeAtlas.
    // Original package contains a lot of features not included here,
    // so it is recommended to check the original code for more details.

    // From LightVolumeManager.cs

    private int lightVolumeInvLocalEdgeSmoothID;
    private int lightVolumeInvWorldMatrixID;
    private int lightVolumeUvwID;
    private int lightVolumeColorID;
    private int lightVolumeRotationID;
    private int lightVolumeCountID;
    private int lightVolumeAdditiveCountID;
    private int lightVolumeAdditiveMaxOverdrawID;
    private int lightVolumeEnabledID;
    private int lightVolumeProbesBlendID;
    private int lightVolumeSharpBoundsID;
    private int lightVolumeID;

    private bool initialized = false;

    void Init()
    {
        lightVolumeInvLocalEdgeSmoothID = VRCShader.PropertyToID("_UdonLightVolumeInvLocalEdgeSmooth");
        lightVolumeInvWorldMatrixID = VRCShader.PropertyToID("_UdonLightVolumeInvWorldMatrix");
        lightVolumeUvwID = VRCShader.PropertyToID("_UdonLightVolumeUvw");
        lightVolumeColorID = VRCShader.PropertyToID("_UdonLightVolumeColor");
        lightVolumeRotationID = VRCShader.PropertyToID("_UdonLightVolumeRotation");
        lightVolumeCountID = VRCShader.PropertyToID("_UdonLightVolumeCount");
        lightVolumeAdditiveCountID = VRCShader.PropertyToID("_UdonLightVolumeAdditiveCount");
        lightVolumeAdditiveMaxOverdrawID = VRCShader.PropertyToID("_UdonLightVolumeAdditiveMaxOverdraw");
        lightVolumeEnabledID = VRCShader.PropertyToID("_UdonLightVolumeEnabled");
        lightVolumeProbesBlendID = VRCShader.PropertyToID("_UdonLightVolumeProbesBlend");
        lightVolumeSharpBoundsID = VRCShader.PropertyToID("_UdonLightVolumeSharpBounds");
        lightVolumeID = VRCShader.PropertyToID("_UdonLightVolume");

        // Init with capacity
        VRCShader.SetGlobalVectorArray(lightVolumeInvLocalEdgeSmoothID, new Vector4[32]);
        VRCShader.SetGlobalMatrixArray(lightVolumeInvWorldMatrixID, new Matrix4x4[32]);
        VRCShader.SetGlobalVectorArray(lightVolumeRotationID, new Vector4[64]);
        VRCShader.SetGlobalVectorArray(lightVolumeUvwID, new Vector4[192]);
        VRCShader.SetGlobalVectorArray(lightVolumeColorID, new Vector4[32]);
    }

    void UpdateProps()
    {
        VRCShader.SetGlobalFloat(lightVolumeProbesBlendID, 1);
        VRCShader.SetGlobalFloat(lightVolumeSharpBoundsID, 1);

        Vector4[] invLocalEdgeSmooth = new Vector4[1];
        Vector3 scale = transform.lossyScale;
        invLocalEdgeSmooth[0] = new Vector4(scale.x, scale.y, scale.z, 0) / Mathf.Max(0.25f, 0.00001f); // Default setting
        VRCShader.SetGlobalVectorArray(lightVolumeInvLocalEdgeSmoothID, invLocalEdgeSmooth);

        Matrix4x4[] invWorldMatrix = new Matrix4x4[1];
        invWorldMatrix[0] = transform.worldToLocalMatrix;
        VRCShader.SetGlobalMatrixArray(lightVolumeInvWorldMatrixID, invWorldMatrix);

        Vector4[] boundsUvw = new Vector4[6];
        float smin = 1.0f / RES;
        float smax = 1.0f - smin;
        boundsUvw[0] = new Vector4((smin + 0) / 3, smin, smin, 0);
        boundsUvw[1] = new Vector4((smax + 0) / 3, smax, smax, 0);
        boundsUvw[2] = new Vector4((smin + 1) / 3, smin, smin, 0);
        boundsUvw[3] = new Vector4((smax + 1) / 3, smax, smax, 0);
        boundsUvw[4] = new Vector4((smin + 2) / 3, smin, smin, 0);
        boundsUvw[5] = new Vector4((smax + 2) / 3, smax, smax, 0);
        VRCShader.SetGlobalVectorArray(lightVolumeUvwID, boundsUvw);

        VRCShader.SetGlobalFloat(lightVolumeCountID, 1);
        VRCShader.SetGlobalFloat(lightVolumeAdditiveCountID, 0);
        VRCShader.SetGlobalFloat(lightVolumeAdditiveMaxOverdrawID, 0);
        VRCShader.SetGlobalFloat(lightVolumeEnabledID, 1);

        Vector4[] color = new Vector4[1];
        color[0] = new Vector4(1, 1, 1, 0 /* Not Rotated */);
        VRCShader.SetGlobalVectorArray(lightVolumeColorID, color);

        VRCShader.SetGlobalTexture(lightVolumeID, crt);
    }

    void Update()
    {
        if(!initialized)
        {
            Init();
            UpdateProps();
            initialized = true;
        }
        crt.Update(1);

        // UpdateProps(); // Call this if you update the volume transform
    }

#if !COMPILER_UDONSHARP && UNITY_EDITOR
    private void OnDrawGizmosSelected()
    {
        Gizmos.color = new Color(0.5f, 1.0f, 1.0f, 0.5f);
        Gizmos.matrix = transform.localToWorldMatrix;
        Gizmos.DrawWireCube(Vector3.zero, Vector3.one);
    }
#endif
}
