float4x4 worldToCameraMatrix;
float4x4 projMatrix;
float4x4 textureMatrix;

float2 highlightRange;	
float4 colorA;		
float4 colorB;
float4 highColor;
float2 stepsize;

Texture2D txDiffuse;

SamplerState samLinear
{
    Filter = MIN_MAG_MIP_LINEAR;
    AddressU = Wrap;
    AddressV = Wrap;
};

struct VS_IN
{
    float4 pos : POSITION;
    float3 normal: NORMAL;
    float4 col : COLOR;
    float2 texCoord : TEXCOORD;
    float3 tangent: TANGENT;
    float3 binormal: BINORMAL;
};

struct PS_IN
{
    float4 pos : SV_POSITION;
    float4 col : COLOR;
    float2 texCoord: TEXCOORD0;
};

PS_IN VS( VS_IN input )
{
    PS_IN output = (PS_IN)0;

    output.pos = mul(input.pos, worldToCameraMatrix);
    output.pos = mul(output.pos, projMatrix);

    output.col = input.col; 
    output.texCoord = mul(float4(input.texCoord.xy, 0, 1), textureMatrix).xy;

    return output;
}

float4 PS( PS_IN input ) : SV_Target
{
	
	float offset =   length( float2(input.pos.x, input.pos.y) );  
	float t = ((input.pos.w / input.pos.z) + offset * 0.00001 ) % ( stepsize.x + stepsize.y);
	return  t  < stepsize.x 
					  ? colorA
					  : colorB; 					 
	

    //return txDiffuse.Sample(samLinear, input.texCoord) * input.col;
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
