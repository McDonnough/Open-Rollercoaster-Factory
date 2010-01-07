unit g_terrain;

interface

uses
  SysUtils, Classes, l_ocf, g_park_types, u_vectors;

type
  TTerrain = class(TParkChild)
    protected
      fTextureCollectionName: String;
      fSizeX, fSizeY: Word;
      fHeightMap: Array of Single;
      fWaterMap: Array of Single;
      fTextureOffsetMap: Array of TVector2D;
    public
      procedure WriteOCFSection(var Section: TOCFSection);
      procedure ReadFromOCFSection(Section: TOCFSection);
    end;

implementation

procedure TTerrain.WriteOCFSection(var Section: TOCFSection);
var
  tmpW: Word;
begin
  Section.SectionType := 'Terrain';
  tmpw := Length(fTextureCollectionName);
  Section.Data.CopyFromByteArray(@tmpW, Sizeof(Word));
  Section.Data.AppendByteArray(@fSizeX, 2 * Sizeof(Word));
  Section.Data.AppendByteArray(@fHeightMap[0], (fSizeX + 1) * (fSizeY + 1) * Sizeof(Word));
  Section.Data.AppendByteArray(@fWaterMap[0], (fSizeX + 1) * (fSizeY + 1) * Sizeof(Word));
  Section.Data.AppendByteArray(@fTextureOffsetMap[0], (fSizeX + 1) * (fSizeY + 1) * Sizeof(TVector2D));
end;

procedure TTerrain.ReadFromOCFSection(Section: TOCFSection);
begin
end;

end.