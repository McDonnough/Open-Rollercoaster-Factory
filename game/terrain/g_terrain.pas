unit g_terrain;

interface

uses
  SysUtils, Classes, l_ocf, g_park_types, u_vectors;

type
  TTerrain = class(TParkChild)
    protected
      fTextureCollectionName: String;
      fSizeX, fSizeY: Word;
      fHeightMap: Array of Array of Single;
      fTextureOffsetMap: Array of Array of TVector2D;
    public
      procedure WriteOCFSection(var Section: TOCFSection);
      procedure ReadFromOCFSection(Section: TOCFSection);
    end;

implementation

procedure TTerrain.WriteOCFSection(var Section: TOCFSection);
begin

end;

procedure TTerrain.ReadFromOCFSection(Section: TOCFSection);
begin
end;

end.