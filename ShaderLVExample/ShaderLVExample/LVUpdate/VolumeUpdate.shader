Shader "ShaderLVExample/VolumeUpdate"
{
    Properties
    {
    }

    SubShader
    {
        Name "Update"
        Lighting Off
        Blend One Zero

        Pass
        {
            CGPROGRAM
            #include "UnityCustomRenderTexture.cginc"
            #include "VolumeUpdate.cginc"
            #pragma vertex CustomRenderTextureVertexShader
            #pragma fragment frag
            #pragma target 3.0

            float4 frag(v2f_customrendertexture IN) : COLOR
            {
                float3 uvw = IN.localTexcoord.xyz * RES * float3(3, 1, 1);
                uvw.z += 0.5; // wow
                uint3 uvwInt = floor(uvw);
                uint atlasIndex = uvwInt.x / RES;
                uvwInt.x %= RES;
                return sampleVolume(atlasIndex, uvwInt);
            }
            ENDCG
        }
    }
}
