float4x4 objectToWorldMatrix;
float4x4 worldToCameraMatrix;
float4x4 projMatrix;
float4x4 textureMatrix;

float4 color1;
float4 color2;
float4 color3;
float4 color4;
float4 lineColor;
float gridSize;
float lineWeight;
float rotateScale;
float rotateAdd;
float padding;

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
	float4 worldPos: STILL2;
};

PS_IN VS( VS_IN input )
{
    PS_IN output = (PS_IN)0;

    output.worldPos=input.pos = mul(input.pos, objectToWorldMatrix);	
	output.col = input.col;
	

    //float4 d = input.pos - float4( center.x, center.y, 0,1);
    //float distance = length(d);
    //float4 offset=  d * pow(-0.5*cos( clamp(distance/radius,0, 1)  * 2 * 3.141578)+0.5, bias) * strength;
    //float4 offset=  d * pow( smoothstep(1,0, distance/radius),  bias) * strength;

    input.pos = input.pos; // + offset;

    output.pos = mul(input.pos, worldToCameraMatrix);
    output.pos = mul(output.pos, projMatrix);

    

	output.texCoord = input.texCoord;
    return output;
}

float gridSnap( float p, float grid) {
	float p2= p % grid;
	if(p2 < 0) {
		p2 += grid;
	}
	//p2= clamp(p2, 0.1 * grid, 0.9 * grid);			
	return p2;
}

float4 PS( PS_IN input ) : SV_Target
{	
	float4 col;
	float2 pos1 = float2(0.25, 0.25);
	
	float2 refPos = float2(0.5-input.worldPos.x, 0.5-input.worldPos.y);	 // fix flipping and offset for UV coords to match standard plane
	float2 normalizedCellPos= float2( gridSnap(refPos.x, gridSize) / gridSize,
							gridSnap(refPos.y, gridSize) / gridSize);	

	if(		normalizedCellPos.x < 0.5 && normalizedCellPos.y < 0.5 ) {
		col = input.col * color1;	
	}
	else if(normalizedCellPos.x > 0.5 && normalizedCellPos.y < 0.5 ) {
		col = input.col * color2;	
	}
	else if(normalizedCellPos.x < 0.5 && normalizedCellPos.y > 0.5 ) {
		col = input.col * color3;	
	}
	else {
		col = input.col * color4;	
	}
	float halfGrid = 0.5 * gridSize;

	// Sample rotation angle


	float2 gridPosA= float2( refPos.x - gridSnap(refPos.x, halfGrid) + 0.5 * halfGrid ,  
							 refPos.y - gridSnap(refPos.y, halfGrid) + 0.5 * halfGrid  );
	float2 texCoord2A = mul(float4(gridPosA.xy, 0, 1), textureMatrix).xy;	
	float4 sampleColor=txDiffuse.Sample(samLinear, texCoord2A);
	float4 distortColorA=txDiffuse.Sample(samLinear, float2( texCoord2A.x , texCoord2A.y ));

	float2 gridPosB= float2(  refPos.x - gridSnap(refPos.x, halfGrid) + 0.75*halfGrid  ,  
							 refPos.y - gridSnap(refPos.y, halfGrid)  + 0.75*halfGrid  );
	float2 texCoord2B = mul(float4(gridPosB.xy, 0, 1), textureMatrix).xy;	
	float4 distortColorB=txDiffuse.Sample(samLinear, float2( texCoord2B.x , texCoord2B.y ));

	float2 gridPosC= float2( refPos.x - gridSnap(refPos.x, halfGrid) + 0.25*halfGrid  ,  
							 refPos.y - gridSnap(refPos.y, halfGrid) + 0.25*halfGrid  );
	float2 texCoord2C = mul(float4(gridPosC.xy, 0, 1), textureMatrix).xy;	
	float4 distortColorC= txDiffuse.Sample(samLinear, float2( texCoord2C.x , texCoord2C.y ));

	float4 distortColor = (distortColorA + distortColorB + distortColorC) / 3.0;

	// Detect wether insider or out of line through center of subCell
	float2 subCelPos = float2( gridSnap( normalizedCellPos.x, 0.5), gridSnap( normalizedCellPos.y, 0.5));	
	
	if(subCelPos.x < padding || subCelPos.x > 0.5 - padding ||subCelPos.y < padding || subCelPos.y > 0.5 - padding ) {
		return col;
	}
	

	float cx = sin(distortColor.r * rotateScale + rotateAdd) - pos1.x;
	float cy = cos(distortColor.r * rotateScale + rotateAdd) - pos1.y;
	float bx = -cy;
	float by = cx;
    float ex = subCelPos.x - pos1.x;
    float ey = subCelPos.y - pos1.y;
        
    float distanceToLine = (ex*by - ey*bx) / (sqrt(bx*bx + by*by));
	if( abs(distanceToLine) < lineWeight) {
		col=  lineColor;		
		//return lineColor;
	}
	return col;
    //return sampleColor * col;
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
