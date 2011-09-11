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
      fLoadedDoc: TDOMDocument;
      fCurrentObjectNode: TDOMElement;
      fFinishedLoading: Boolean;
    public
      property FinishedLoading: Boolean read fFinishedLoading;
      constructor Create;
      function CreateOCFSection: TOCFBinarySection;
      procedure InitLoader(S: TOCFBinarySection);
      procedure ContinueLoading;
      procedure Remove(O: TGeoObject);
      procedure Advance;
      procedure Free;
    end;

implementation

uses
  u_events, main, g_park, g_parkui, g_object_builder;

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
      Advance(Round(Park.pSky.Time));
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
  fFinishedLoading := True;
  fLoadedDoc := nil;
  fCurrentObjectNode := nil;
end;

procedure TObjectManager.InitLoader(S: TOCFBinarySection);
var
  XML: String;
  I: Integer;
begin
  fFinishedLoading := False;
  SetLength(XML, Length(S.Stream.Data));
  for I := 0 to high(S.Stream.Data) do
    XML[I + 1] := Char(S.Stream.Data[I]);
  fLoadedDoc := DOMFromXML(XML);
  fCurrentObjectNode := TDOMElement(fLoadedDoc.FirstChild.FirstChild);
end;

procedure TObjectManager.ContinueLoading;
var
  O: TRealObject;
  E, F: TDOMElement;
  M: TMaterial;
  I: Integer;
begin
  if fFinishedLoading then
    exit;

  if not TObjectResource.Get(fCurrentObjectNode.GetAttribute('resource:name')).FinishedLoading then
    exit;

  O := TRealObject.Create(TObjectResource.Get(fCurrentObjectNode.GetAttribute('resource:name')));

  E := TDOMElement(fCurrentObjectNode.FirstChild);
  while E <> nil do
    begin
    if E.TagName = 'matrix' then
      begin
      F := TDOMElement(E.FirstChild);
      I := 0;
      while F <> nil do
        begin
        if (F.TagName = 'row') and (I <= 3) then
          begin
          O.GeoObject.Matrix[I].X := StrToFloat(F.GetAttribute('x'));
          O.GeoObject.Matrix[I].Y := StrToFloat(F.GetAttribute('y'));
          O.GeoObject.Matrix[I].Z := StrToFloat(F.GetAttribute('z'));
          O.GeoObject.Matrix[I].W := StrToFloat(F.GetAttribute('w'));
          inc(I);
          end;
        F := TDOMElement(F.NextSibling);
        end;
      end
    else if E.TagName = 'mirror' then
      begin
      O.GeoObject.Mirror.X := StrToInt(E.GetAttribute('x'));
      O.GeoObject.Mirror.Y := StrToInt(E.GetAttribute('y'));
      O.GeoObject.Mirror.Z := StrToInt(E.GetAttribute('z'));
      end
    else if E.TagName = 'material' then
      begin
      M := O.GeoObject.Materials[O.GeoObject.GetMaterialByName(E.GetAttribute('name'))];
      if M <> nil then
        begin
        F := TDOMElement(E.FirstChild);
        while F <> nil do
          begin
          if F.TagName = 'color' then
            M.Color := Vector(StrToFloat(F.GetAttribute('r')), StrToFloat(F.GetAttribute('g')), StrToFloat(F.GetAttribute('b')), M.Color.W)
          else if F.TagName = 'emission' then
            M.Emission := Vector(StrToFloat(F.GetAttribute('r')), StrToFloat(F.GetAttribute('g')), StrToFloat(F.GetAttribute('b')), M.Emission.W)
          else if F.TagName = 'reflectivity' then
            M.Reflectivity := StrToFloat(F.GetAttribute('v'));
          F := TDOMElement(F.NextSibling);
          end;
        end;
      end;
    E := TDOMElement(E.NextSibling);
    end;
  Park.NormalSelectionEngine.Add(O.GeoObject, 'TPark.Objects.Selected');
  Append(O);

  fCurrentObjectNode := TDOMElement(fCurrentObjectNode.NextSibling);
  fFinishedLoading := fCurrentObjectNode = nil;
  
  if fFinishedLoading then
    fLoadedDoc.Free;
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
  Result := TOCFBinarySection.Create;
  Result.Append(@XMLString[1], Length(XMLString));
  X.Free;
end;

procedure TObjectManager.Remove(O: TGeoObject);
var
  C: TRealObject;
begin
  Park.NormalSelectionEngine.Delete(O);
  TGameObjectBuilder(ParkUI.GetWindowByName('object_builder')).SelectionEngine.Delete(O);
  C := TRealObject(First);
  while C <> nil do
    begin
    if C.GeoObject = O then
      begin
      C.Free;
      exit;
      end
    else
      C := TRealObject(C.Next);
    end;
end;

procedure TObjectManager.Free;
begin
  while First <> nil do
    TRealObject(First).Free;
  inherited Free;
end;

end.