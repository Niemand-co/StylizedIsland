Shader "Demo/Sky_Shader_"
{
    Properties
    {
        _SunRadius ("Sun Radius", float) = 1.0
        _SunColor ("Sun Color", Color) = (1, 1, 1, 1)
        _MoonRadius ("Moon Radius", float) = 1.0
        _MoonColor ("Moon Color", Color) = (0.9, 0.9, 0.9, 1.0)

        _DayBottomLight ("Day Bottom Light", Color) = (1, 1, 1, 1)
        _DayTopLight ("Day Top Light", Color) = (1, 1, 1, 1)
        _NightBottomLight ("Night Bottom Light", Color) = (1, 1, 1, 1)
        _NightTopLight ("Night Top Light", Color) = (1, 1, 1, 1)
        _DuskBottomLight ("Dusk Bottom Light", COlor) = (1, 1, 1, 1)
        _DuskTopLight ("Dusk Top Light", COlor) = (1, 1, 1, 1)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 Position : POSITION;
                float3 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 ClipPos : SV_POSITION;
                float3 uv : TEXCOORD0;
            };

            float _SunRadius;
            float4 _SunColor;
            float _MoonRadius;
            float4 _MoonColor;
            float4 _DayBottomLight;
            float4 _DayTopLight;
            float4 _NightBottomLight;
            float4 _NightTopLight;
            float4 _DuskBottomLight;
            float4 _DuskTopLight;

            v2f vert (appdata v)
            {
                v2f o;
                o.ClipPos = UnityObjectToClipPos(v.Position);
                o.uv = v.uv;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                
                float sun = distance(i.uv.xyz, _WorldSpaceLightPos0);
                float sunDisc = 1 - (sun / _SunRadius);
                sunDisc = saturate(sunDisc) + step(0.4, sunDisc);

                float moon = distance(i.uv.xyz, -_WorldSpaceLightPos0);
                float moonDisc = 1 - (moon / _MoonRadius);
                moonDisc = saturate(moonDisc * 3) + step(0.2, moonDisc);

                float4 dayColor = lerp(_DayBottomLight, _DayTopLight, i.uv.y);
                float4 nightColor = lerp(_NightBottomLight, _NightTopLight, i.uv.y);
                float duskColor = lerp(_DuskBottomLight, _DuskTopLight, i.uv.y);
                float factor = _WorldSpaceLightPos0.y * 0.5 + 0.5;
                float4 skyColor = lerp(nightColor, lerp(duskColor, dayColor, saturate((factor - 0.6) * 2.5)), saturate(factor * 2.5));

                return skyColor + (moonDisc * _MoonColor + sunDisc * _SunColor);
            }
            ENDCG
        }
    }
}
