unit g_res_textures;

interface

uses
  SysUtils, Classes, m_texmng_class, g_resources, g_loader_ocf, dglOpenGL;

type
  TTextureResource = class(TAbstractResource)
    protected
      fTexture: TTexture;
    public
      property Texture: TTexture read fTexture;
      class function Get(ResourceName: String): TTextureResource;
      constructor Create(ResourceName: String);
      procedure FileLoaded(Data: TOCFFile);
      procedure Free;
    end;

implementation

uses
  u_graphics, u_events;

class function TTextureResource.Get(ResourceName: String): TTextureResource;
begin
  Result := TTextureResource(ResourceManager.Resources[ResourceName]);
  if Result = nil then
    Result := TTextureResource.Create(ResourceName)
  else
    ResourceManager.AddFinishedResource(Result);
end;

constructor TTextureResource.Create(ResourceName: String);
begin
  inherited Create(ResourceName, @FileLoaded);
end;

procedure TTextureResource.FileLoaded(Data: TOCFFile);
var
  A: TTexImage;
  CompressedTexFormat, TexFormat: GLEnum;
begin
  with Data.ResourceByName(SubResourceName) do
    begin
    A := TexFromStream(Data.Bin[Section].Stream, '.' + Format);
    TexFormat := GL_RGB;
    CompressedTexFormat := GL_COMPRESSED_RGB;
    if A.BPP = 32 then
      begin
      TexFormat := GL_RGBA;
      CompressedTexFormat := GL_COMPRESSED_RGBA;
      end;
    fTexture := TTexture.Create;
    fTexture.CreateNew(A.Width, A.Height, TexFormat);
    fTexture.SetClamp(GL_CLAMP, GL_CLAMP);
    fTexture.SetFilter(GL_LINEAR_MIPMAP_LINEAR, GL_LINEAR_MIPMAP_LINEAR);
    fTexture.Fill(@A.Data[0], TexFormat);
    gluBuild2DMipmaps(GL_TEXTURE_2D, A.BPP div 8, A.Width, A.Height, TexFormat, GL_UNSIGNED_BYTE, @A.Data[0]);
    end;
  FinishedLoading := True;
end;

procedure TTextureResource.Free;
begin
  fTexture.Free;
  inherited Free;
end;

end.