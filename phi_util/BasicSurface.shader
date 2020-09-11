Shader "phi_util/BasicSurface"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        [ToggleOff] _SpecularHighlights("Specular Highlights", Float) = 1.0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "DisableBatching"="True" }
        LOD 200

        CGPROGRAM
        #pragma surface surf Standard fullforwardshadows addshadow vertex:vert
        #pragma target 3.0
        #pragma shader_feature _SPECULARHIGHLIGHTS_OFF

        struct Input {
            float2 texcoord;
            float3 worldPos;
            float3 worldNormal;
            float3 worldRefl;
            float3 viewDir;
        };

        UNITY_INSTANCING_BUFFER_START(Props)
        UNITY_INSTANCING_BUFFER_END(Props)

        void vert(inout appdata_full v, out Input o) {
            UNITY_INITIALIZE_OUTPUT(Input, o);
            o.texcoord = v.texcoord;
        }

        float4 _Color;

        void surf (Input IN, inout SurfaceOutputStandard o) {
            o.Albedo = _Color;
            o.Metallic = 1;
            o.Smoothness = 0.5;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
