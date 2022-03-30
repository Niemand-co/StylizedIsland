Shader "Demo/BasePassOpaque"
{
    Properties
    {
         _MainTex ("Texture", 2D) = "white" {}
         _Roughness ("Roughness", float) = 0.5
    }
    SubShader
    {
        Tags { "LightMode"="BasePass" }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 ClipPos : SV_POSITION;
                float3 WorldPos : TEXCOORD1;
                float3 normal : NORMAL;
                float depth : TEXCOORD2;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _Roughness;

            float4 ComputeScreenPos(float4 pos, float projectionSign)
            {
                float4 o;
                o.xy = float2(pos.x, pos.y * projectionSign) + pos.w;
                o.zw = pos.zw;
                return o;
            }

            v2f vert (appdata v)
            {
                v2f o;
                o.WorldPos = mul(UNITY_MATRIX_M, v.vertex);
                o.ClipPos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.normal = UnityObjectToWorldNormal(v.normal);
                float4 ScreenPos = ComputeScreenPos(o.ClipPos, _ProjectionParams.x);
                o.depth = ScreenPos.z / ScreenPos.w;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed3 col = tex2D(_MainTex, i.uv).rgb;
                float3 normal = i.normal;
                return float4(col, 1.0);
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
}
