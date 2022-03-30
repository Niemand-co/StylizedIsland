Shader "Demo/Cloud_Shader_"
{
    Properties
    {
        _CloudNoise ("Cloud Noise", 2D) = "" {}
        _CloudSpeedX ("Cloud SpeedX", float) = 0.25
        _CloudSpeedY ("Cloud SpeedY", float) = 0.3
        _PerlinNoise ("Perlin Noise", 2D) = "" {}
        _CloudSpeedSX ("Cloud SpeedSX", float) = 0.3
        _CloudSpeedSY ("Cloud SpeedSY", float) = 0.1
        _CutOff ("Cut Off", float) = 0.0
        _DayCloudColor ("Cloud Color", Color) = (0, 0, 1, 1)
        _NightCloudColor ("Cloud Color", Color) = (0, 0, 1, 1)
        _SSSStrength ("Subsurface Scaterring Strength", float) = 0.0
        _SSSPower ("Subsurface Scaterring Power", float) = 1.0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100
        Cull off

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_instancing

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 WorldPos : TEXCOORD1;
                float Distance : TEXCOORD2;
            };

            sampler2D _CloudNoise;
            sampler2D _PerlinNoise;
            float _CloudSpeedX;
            float _CloudSpeedY;
            float _CloudSpeedSX;
            float _CloudSpeedSY;
            float _Thickness;
            float _MidHeight;
            float _CutOff;
            float4 _DayCloudColor;
            float4 _NightCloudColor;
            float _SSSPower;
            float _SSSStrength;

            v2f vert (appdata v)
            {
                v2f o;
                
                o.uv = v.uv;
                o.WorldPos = mul(UNITY_MATRIX_M, v.vertex);
                // float squareDiffY = pow((_MidHeight - _WorldSpaceCameraPos.y), 2);
                // float far = 500;
                // o.Distance = length(o.WorldPos - _WorldSpaceCameraPos.xyz);
                // float distanceX = sqrt(squareDiffY + pow(o.Distance, 2));
                // float radius = (squareDiffY + far * far) / (2 * (_MidHeight - _WorldSpaceCameraPos.y));
                // float correctionY = radius - sqrt(radius * radius - distanceX * distanceX);
                // o.WorldPos.y = correctionY;
                o.vertex = mul(UNITY_MATRIX_VP, float4(o.WorldPos, 1.0));
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float2 cloudUV = i.uv + float2(_CloudSpeedX, _CloudSpeedY) * _Time.y;
                float2 cloudSUV = i.uv - float2(_CloudSpeedSX, _CloudSpeedSY) * _Time.y;
                float noise = tex2D(_CloudNoise, cloudUV).r;
                float noiseS = tex2D(_PerlinNoise, cloudSUV).r;
                noise *= noiseS;
                clip(noise - 0.22);
                float fallOff = saturate(abs(_MidHeight - i.WorldPos.y) / (_Thickness));
                clip(noise - fallOff - _CutOff);
                fixed4 cloudColor = lerp(_NightCloudColor, _DayCloudColor, saturate(_WorldSpaceLightPos0.y));
                return (cloudColor - saturate(fallOff) * fixed4(0.5, 0.5, 0, 0));
            }
            ENDCG
        }
    }
}
