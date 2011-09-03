unit m_gui_image_class;

interface

uses
  SysUtils, Classes, m_module, m_texmng_class, m_gui_class, u_vectors;

type
  TImage = class(TGUIComponent)
    public
      Tex: TTexture;
      Color: TVector3D;
      FreeTextureOnDestroy: Boolean;
      constructor Create(mParent: TGUIComponent);
      procedure Render; override;
      destructor Destroy; override;
    end;

  TModuleGUIImageClass = class(TBasicModule)
    public
      (**
        * Render image (well, pretty simple..)
        *)
      procedure Render(Img: TImage); virtual abstract;
    end;

implementation

uses
  m_varlist;

constructor TImage.Create(mParent: TGUIComponent);
begin
  inherited Create(mParent, CImage);
  Tex := nil;
  Color := Vector(1, 1, 1);
  FreeTextureOnDestroy := false;
end;

procedure TImage.Render;
begin
  ModuleManager.ModGUIImage.Render(Self);
end;

destructor TImage.Destroy;
begin
  if (FreeTextureOnDestroy) and (Tex <> nil) then
    Tex.Free;
  inherited Destroy;
end;

end.