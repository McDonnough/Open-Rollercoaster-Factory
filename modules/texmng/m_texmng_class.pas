unit m_texmng_class;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, m_module, DGLOpenGL;

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
        * Set texure unit
        *@param tex unit number [0..7]
        *)
      procedure ActivateTexUnit(U: Integer); virtual abstract;
    end;

  TTexture = class
    protected
      fID: Integer;
      fWidth, fHeight: Integer;
    public
      property Width: Integer read fWidth;
      property Height: Integer read fHeight;
      procedure FromFile(FileName: String; VertexTexture: Boolean = false);
      procedure CreateNew(X, Y: Integer; Format: GLEnum);
      procedure Fill(Data: Pointer; Format: GLEnum);
      procedure Bind(U: Integer = -1);
      procedure Unbind;
      procedure SetFilter(Min, Max: GLEnum);
      procedure SetClamp(X, Y: GLEnum);
      destructor Free;
    end;

implementation

uses
  m_varlist;

procedure TTexture.FromFile(FileName: String; VertexTexture: Boolean = false);
begin
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
  if (U >= 0) and (U <= 7) then
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

destructor TTexture.Free;
begin
  ModuleManager.ModTexMng.DeleteTexture(fID);
end;

end.

