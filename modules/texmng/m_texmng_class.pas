unit m_texmng_class;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, m_module, DGLOpenGL, u_graphics;

type
  TModuleTextureManagerClass = class(TBasicModule)
    private
      (**
        * Load a texture from file
        *@param file to load
        *@param internal format
        *@return Texture ID
        *)
      function LoadTexture(Filename: String; VertexTexture: Boolean; var X, Y: Integer): Integer; virtual abstract;

      (**
        * Create blank texture
        *@param width
        *@param height
        *@param internal format
        *@return Texture ID (>= 0 on success, < 0 on error)
        *)
      function EmptyTexture(X, Y: Integer; Format: GLEnum): Integer; virtual abstract;

      (**
        * Bind a texture to OpenGL
        *@param texture id
        *)
      procedure BindTexture(Texture: Integer); virtual abstract;

      (**
        * Delete a texture from memory
        *@param Texture to delete
        *)
      procedure DeleteTexture(Texture: Integer); virtual abstract;

      (**
        * Fill texture with data
        *@param Texture to fill
        *@param pointer to data
        *@param Format of input
        *)
      procedure FillTexture(Texture: Integer; Data: Pointer; InputFormat: GLEnum); virtual abstract;

      (**
        * Enable filtering
        *@param Minification filter
        *@param Magnification filter
        *)
      procedure SetFilter(Texture: Integer; Min, Mag: GLEnum); virtual abstract;

      (**
        * Enable clamp
        *@param X clamp method
        *@param Y clamp method
        *)
      procedure SetClamp(Texture: Integer; X, Y: GLEnum); virtual abstract;

      (**
        * Get a pixel
        *@param X position
        *@param Y position
        *@return pixel color
        *)
      function ReadPixel(Texture: Integer; X, Y: Integer): DWord; virtual abstract;

      (**
        * Set a pixel and update texture
        *@param X position
        *@param Y position
        *@param Color
        *)
      procedure SetPixel(Texture: Integer; X, Y: Integer; Color: DWord); virtual abstract;

      (**
        * Set texure unit
        *@param tex unit number [0..7]
        *)
      procedure ActivateTexUnit(U: Integer); virtual abstract;

      (**
        * Get the OpenGL Texture ID
        *)
      function GetRealTexID(Tex: Integer): GLUInt; virtual abstract;

      (**
        * Get the OpenGL Texture ID
        *)
      function GetBPP(Tex: Integer): Integer; virtual abstract;

      (**
        * Get the OpenGL Texture ID
        *)
      function CreateMipmaps(Tex: Integer): Integer; virtual abstract;

      (**
        * Copy one texture to another
        *)
      procedure Copy(Tex: Integer); virtual abstract;
    end;

  TTexture = class
    protected
      fID: Integer;
      fWidth, fHeight: Integer;
      procedure setPixel(X, Y: Integer; Color: DWord);
      function getPixel(X, Y: Integer): DWord;
    public
      property Width: Integer read fWidth;
      property Height: Integer read fHeight;
      property Pixels[X: Integer; Y: Integer]: DWord read getPixel write setPixel;
      procedure FromFile(FileName: String; VertexTexture: Boolean = false);
      procedure CreateNew(X, Y: Integer; Format: GLEnum);
      procedure Fill(Data: Pointer; Format: GLEnum);
      procedure Bind(U: Integer = -1);
      procedure Unbind;
      procedure SetFilter(Min, Max: GLEnum);
      procedure SetClamp(X, Y: GLEnum);
      function GetRealTexID: GLUInt;
      procedure FromTexImage(Tex: TTexImage);
      function BPP: Integer;
      procedure CreateMipmaps;
      procedure Copy;
      destructor Free;
    end;

implementation

uses
  m_varlist, u_math, u_files;

procedure TTexture.setPixel(X, Y: Integer; Color: DWord);
begin
  X := Round(Clamp(X, 0, Width - 1));
  Y := Round(Clamp(Y, 0, Height - 1));
  ModuleManager.ModTexMng.SetPixel(fID, X, Y, Color);
end;

function TTexture.getPixel(X, Y: Integer): DWord;
begin
  X := Round(Clamp(X, 0, Width - 1));
  Y := Round(Clamp(Y, 0, Height - 1));
  Result := ModuleManager.ModTexMng.ReadPixel(fID, X, Y);
end;

procedure TTexture.FromFile(FileName: String; VertexTexture: Boolean = false);
begin
  FileName := GetFirstExistingFilename(FileName);
  fID := ModuleManager.ModTexMng.LoadTexture(ModuleManager.ModPathes.Convert(FileName), VertexTexture, fWidth, fHeight);
end;

procedure TTexture.CreateNew(X, Y: Integer; Format: GLEnum);
begin
  fID := ModuleManager.ModTexMng.EmptyTexture(X, Y, Format);
  fWidth := X;
  fHeight := Y;
end;

procedure TTexture.Fill(Data: Pointer; Format: GLEnum);
begin
  ModuleManager.ModTexMng.FillTexture(fID, Data, Format);
end;

procedure TTexture.Bind(U: Integer = -1);
begin
  ModuleManager.ModTexMng.ActivateTexUnit(U);
  ModuleManager.ModTexMng.BindTexture(fID);
end;

procedure TTexture.Unbind;
begin
  ModuleManager.ModTexMng.BindTexture(-1);
end;

procedure TTexture.SetFilter(Min, Max: GLEnum);
begin
  ModuleManager.ModTexMng.SetFilter(fID, Min, Max);
end;

procedure TTexture.SetClamp(X, Y: GLEnum);
begin
  ModuleManager.ModTexMng.SetClamp(fID, X, Y);
end;

function TTexture.GetRealTexID: GLUInt;
begin
  Result := ModuleManager.ModTexMng.GetRealTexID(fID);
end;

procedure TTexture.FromTexImage(Tex: TTexImage);
var
  Format: GLEnum;
begin
  Format := GL_RGB;
  if Tex.BPP = 32 then
    Format := GL_RGBA;
  CreateNew(Tex.Width, Tex.Height, Format);
  Fill(@Tex.Data[0], Format);
end;

function TTexture.BPP: Integer;
begin
  Result := ModuleManager.ModTexMng.GetBPP(fID);
end;

procedure TTexture.CreateMipmaps;
begin
  ModuleManager.ModTexMng.CreateMipmaps(fID);
end;

procedure TTexture.Copy;
begin
  ModuleManager.ModTexMng.Copy(fID);
end;

destructor TTexture.Free;
begin
  ModuleManager.ModTexMng.DeleteTexture(fID);
end;

end.

