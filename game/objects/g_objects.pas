unit g_objects;

interface

uses
  SysUtils, Classes, u_linkedlists, g_resources, u_scene, g_loader_ocf, g_res_textures, g_res_materials, u_xml, u_dom, u_vectors,
  g_res_lights, g_res_particles, g_res_objects, u_pathes;

type
  TRealObject = class(TLinkedListItem)
    protected
      fResource: TObjectResource;
      fGeoObject: TGeoObject;
    public
      property Resource: TObjectResource read fResource;
      property GeoObject: TGeoObject read fGeoObject;
      constructor Create(TheResource: TObjectResource);
      procedure Free;
    end;

  TObjectManager = class(TLinkedList)
    protected
    public
      constructor Create;
      function CreateOCFSection: TOCFBinarySection;
      procedure Advance;
      procedure Free;
    end;

implementation

uses
  u_events, main;

constructor TRealObject.Create(TheResource: TObjectResource);
begin
  inherited Create;
  fResource := TheResource;
  fGeoObject := Resource.GeoObject.Duplicate;
  fGeoObject.Register;
end;

procedure TRealObject.Free;
begin
  GeoObject.Free;
  inherited Free;
end;

procedure TObjectManager.Advance;
var
  CurrentObject: TRealObject;
begin
  CurrentObject := TRealObject(First);
  while CurrentObject <> nil do
    begin
    with CurrentObject.GeoObject do
      begin
      SetUnchanged;
      ExecuteScript;
      UpdateMatrix;
      UpdateArmatures;
      UpdateVertexPositions;
      RecalcFaceNormals;
      RecalcVertexNormals;
      end;
    CurrentObject := TRealObject(CurrentObject.Next);
    end;
end;

constructor TObjectManager.Create;
begin
  inherited Create;
end;

function TObjectManager.CreateOCFSection: TOCFBinarySection;
var
  CurrentObject: TRealObject;
  X: TDOMDocument;
  XMLString: String;
  I, J: Integer;
begin
  X := TDOMDocument.Create;
  X.AppendChild(X.CreateElement('objects'));
  CurrentObject := TRealObject(First);
  while CurrentObject <> nil do
    begin
    TDOMElement(X.LastChild).AppendChild(X.CreateElement('object'));
    TDOMElement(X.LastChild.LastChild).SetAttribute('resource:name', CurrentObject.Resource.Name);
    with CurrentObject.GeoObject do
      begin
      TDOMElement(X.LastChild.LastChild).AppendChild(X.CreateElement('matrix'));
      for I := 0 to 3 do
        begin
        TDOMElement(X.LastChild.LastChild.LastChild).AppendChild(X.CreateElement('row'));
        TDOMElement(X.LastChild.LastChild.LastChild.LastChild).SetAttribute('x', FloatToStr(Matrix[I].X));
        TDOMElement(X.LastChild.LastChild.LastChild.LastChild).SetAttribute('y', FloatToStr(Matrix[I].Y));
        TDOMElement(X.LastChild.LastChild.LastChild.LastChild).SetAttribute('z', FloatToStr(Matrix[I].Z));
        TDOMElement(X.LastChild.LastChild.LastChild.LastChild).SetAttribute('w', FloatToStr(Matrix[I].W));
        end;
      TDOMElement(X.LastChild.LastChild).AppendChild(X.CreateElement('mirror'));
      TDOMElement(X.LastChild.LastChild.LastChild).SetAttribute('x', IntToStr(Round(Mirror.X)));
      TDOMElement(X.LastChild.LastChild.LastChild).SetAttribute('y', IntToStr(Round(Mirror.Y)));
      TDOMElement(X.LastChild.LastChild.LastChild).SetAttribute('z', IntToStr(Round(Mirror.Z)));
      for I := 0 to high(Materials) do
        begin
        TDOMElement(X.LastChild.LastChild).AppendChild(X.CreateElement('material'));
        TDOMElement(X.LastChild.LastChild.LastChild).SetAttribute('name', Materials[I].Name);
        TDOMElement(X.LastChild.LastChild.LastChild).AppendChild(X.CreateElement('color'));
        TDOMElement(X.LastChild.LastChild.LastChild.LastChild).SetAttribute('r', FloatToStr(Materials[I].Color.X));
        TDOMElement(X.LastChild.LastChild.LastChild.LastChild).SetAttribute('g', FloatToStr(Materials[I].Color.Y));
        TDOMElement(X.LastChild.LastChild.LastChild.LastChild).SetAttribute('b', FloatToStr(Materials[I].Color.Z));
        TDOMElement(X.LastChild.LastChild.LastChild).AppendChild(X.CreateElement('emission'));
        TDOMElement(X.LastChild.LastChild.LastChild.LastChild).SetAttribute('r', FloatToStr(Materials[I].Emission.X));
        TDOMElement(X.LastChild.LastChild.LastChild.LastChild).SetAttribute('g', FloatToStr(Materials[I].Emission.Y));
        TDOMElement(X.LastChild.LastChild.LastChild.LastChild).SetAttribute('b', FloatToStr(Materials[I].Emission.Z));
        TDOMElement(X.LastChild.LastChild.LastChild).AppendChild(X.CreateElement('reflectivity'));
        TDOMElement(X.LastChild.LastChild.LastChild.LastChild).SetAttribute('v', FloatToStr(Materials[I].Reflectivity));
        end;
      end;
    CurrentObject := TRealObject(CurrentObject.Next);
    end;
  XMLString := XMLFromDOM(X);
  writeln(XMLString);
  Result := TOCFBinarySection.Create;
  Result.Append(@XMLString[1], Length(XMLString));
  X.Free;
end;

procedure TObjectManager.Free;
begin
  while First <> nil do
    TRealObject(First).Free;
  inherited Free;
end;

end.