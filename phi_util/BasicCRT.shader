Shader "phi_util/BasicCRT"
{
    Properties {
    }
    SubShader
    {
        Cull Off
        ZWrite Off
        ZTest Always
        
        Pass
        {
            Name "Compute"

            CGPROGRAM
            
            #include "UnityCustomRenderTexture.cginc"
            #define TextureSize float2(_CustomRenderTextureWidth,_CustomRenderTextureHeight) 

            #pragma vertex CustomRenderTextureVertexShader
            #pragma fragment frag

            float4 frag (v2f_customrendertexture i) : SV_Target
            {
                float2 uv = i.globalTexcoord;
                int2 p = uv * TextureSize;
                return float4(uv,0,1);
            }
            ENDCG
        }
    }
}
