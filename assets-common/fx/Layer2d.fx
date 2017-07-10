float4x4 worldToCameraMatrix;
float4x4 projMatrix;

bool hasDepth;
Texture2D txDiffuse;
Texture2D txDepth;
float4 multiplyColor;

SamplerState samLinear
{
    Filter = MIN_MAG_MIP_LINEAR;
    AddressU = Wrap;
    AddressV = Wrap;
};

struct VS_IN
{
    float4 pos : POSITION;
    float2 texCoord : TEXCOORD;
};

struct PS_IN
{
    float4 pos : SV_POSITION;
    float2 texCoord: TEXCOORD0;
};

struct PS_OUTPUT
{
    float4 Color : SV_TARGET;
    float Depth : SV_DEPTH;
};

PS_IN VS( VS_IN input )
{
    PS_IN output = (PS_IN)0;

    output.pos = mul(input.pos, worldToCameraMatrix);
    output.pos = mul(output.pos, projMatrix);
    output.texCoord = input.texCoord;

    return output;
}

PS_OUTPUT PS( PS_IN input )
{
    PS_OUTPUT output = (PS_OUTPUT)0;
    output.Color = txDiffuse.Sample(samLinear, input.texCoord) * multiplyColor;
    output.Color.a = clamp( output.Color.a, 0, 1);
    output.Color.rgb = clamp( output.Color.rgb, 0, 10000);
    if (hasDepth)
        output.Depth = txDepth.Sample(samLinear, input.texCoord);
    else
        output.Depth = input.pos.z;
    return output;
}

technique10 Render
{
    pass P0
    {
        SetGeometryShader( 0 );
        SetVertexShader( CompileShader( vs_4_0, VS() ) );
        SetPixelShader( CompileShader( ps_4_0, PS() ) );
    }
}