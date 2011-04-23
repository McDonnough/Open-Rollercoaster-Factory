unit g_objects;

interface

uses
  SysUtils, Classes, u_linkedlists, g_resources, u_scene, g_loader_ocf, g_res_textures, g_res_materials, u_xml, u_dom;

type
  TObjectResource = class(TAbstractResource)
    protected
      fGeoObject: TGeoObject;
      fMaterialResources: Array of TMaterialResource;
      fMaterialResourceNames: Array of String;
      fMaterialDefined: Array of Boolean;
      fFinalMaterialResourceNames: Array of String;
      fDepCount: Integer;
    public
      property GeoObject: TGeoObject read fGeoObject;
      constructor Create(ResourceName: String);
      class function Get(ResourceName: String): TObjectResource;
      procedure FinalCreation;
      procedure FileLoaded(Data: TOCFFile);
      procedure DepLoaded(Event: String; Data, Result: Pointer);
      procedure LoadMesh(Element: TDOMElement);
      procedure Free;
    end;

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
      procedure AddTestObject(Event: String; Data, Result: Pointer);
      procedure Test;
      procedure Advance;
      procedure Free;
    end;

implementation

uses
  u_vectors, u_functions, u_events;

class function TObjectResource.Get(ResourceName: String): TObjectResource;
begin
  Result := TObjectResource(ResourceManager.Resources[ResourceName]);
  if Result = nil then
    Result := TObjectResource.Create(ResourceName)
  else
    ResourceManager.AddFinishedResource(Result);
end;

constructor TObjectResource.Create(ResourceName: String);
begin
  fDepCount := 0;
  fGeoObject := TGeoObject.Create;
  inherited Create(ResourceName, @FileLoaded);
end;

procedure TObjectResource.FinalCreation;
var
  i, j: Integer;
begin
  for i := 0 to high(fMaterialResources) do
    fGeoObject.AddMaterial(fMaterialResources[i].Material);

  for i := 0 to high(fGeoObject.Meshes) do
    for j := 0 to high(fFinalMaterialResourceNames) do
      if fFinalMaterialResourceNames[j] = fMaterialResourceNames[i] then
        fGeoObject.Meshes[i].Material := fMaterialResources[j].Material;
    
  fGeoObject.UpdateFaceVertexAssociationForVertexNormalCalculation;
  fGeoObject.RecalcFaceNormals;
  fGeoObject.RecalcVertexNormals;
end;

procedure TObjectResource.LoadMesh(Element: TDOMElement);
var
  Mesh: TGeoMesh;

  procedure CreateGeometry(TheElement: TDOMElement);
    procedure CreateVertices(MyElement: TDOMElement);
    var
      TheVertex: PVertex;
      
      procedure CreateVertex(AnElement: TDOMElement);
      var
        CurrElement: TDOMElement;
      begin
        CurrElement := TDOMElement(AnElement.FirstChild);
        while CurrElement <> nil do
          begin
          if CurrElement.TagName = 'position' then
            begin
            TheVertex^.Position := Vector(StrToFloatWD(CurrElement.GetAttribute('x'), 0), StrToFloatWD(CurrElement.GetAttribute('y'), 0), StrToFloatWD(CurrElement.GetAttribute('z'), 0));
            TheVertex^.OriginalPosition := TheVertex^.Position;
            end;
          CurrElement := TDOMElement(CurrElement.NextSibling);
          end;
      end;
    var
      CurrElement: TDOMElement;
    begin
      CurrElement := TDOMElement(MyElement.FirstChild);
      while CurrElement <> nil do
        begin
        if CurrElement.TagName = 'vertex' then
          begin
          TheVertex := Mesh.AddVertex;
          TheVertex^.UseFaceNormal := CurrElement.GetAttribute('usefacenormal') = 'true';
          CreateVertex(CurrElement);
          end;
        CurrElement := TDOMElement(CurrElement.NextSibling);
        end;
    end;

    procedure CreateTextureVertices(MyElement: TDOMElement);
    var
      CurrElement: TDOMElement;
      TheVertex: PTextureVertex;
    begin
      CurrElement := TDOMElement(MyElement.FirstChild);
      while CurrElement <> nil do
        begin
        if CurrElement.TagName = 'tvert' then
          begin
          TheVertex := Mesh.AddTextureVertex;
          TheVertex^.Position := Vector(StrToFloatWD(CurrElement.GetAttribute('x'), 0), StrToFloatWD(CurrElement.GetAttribute('y'), 0));
          end;
        CurrElement := TDOMElement(CurrElement.NextSibling);
        end;
    end;

    procedure CreateFaces(MyElement: TDOMElement);
    var
      TheFace: PFace;
      
      procedure CreateFace(AnElement: TDOMElement);
      var
        CurrElement: TDOMElement;
        indexid: Integer;
      begin
        indexid := 0;
        CurrElement := TDOMElement(AnElement.FirstChild);
        while CurrElement <> nil do
          begin
          if (CurrElement.TagName = 'index') and (indexid <= 2) then
            begin
            TheFace^.Vertices[indexid] := StrToIntWD(CurrElement.GetAttribute('vid'), indexid);
            TheFace^.TexCoords[indexid] := StrToIntWD(CurrElement.GetAttribute('tid'), indexid);
            inc(indexid);
            end;
          CurrElement := TDOMElement(CurrElement.NextSibling);
          end;
      end;
    var
      CurrElement: TDOMElement;
    begin
      CurrElement := TDOMElement(MyElement.FirstChild);
      while CurrElement <> nil do
        begin
        if CurrElement.TagName = 'face' then
          begin
          TheFace := Mesh.AddFace;
          CreateFace(CurrElement);
          end;          
        CurrElement := TDOMElement(CurrElement.NextSibling);
        end;
    end;

  var
    CurrElement: TDOMElement;
  begin
    CurrElement := TDOMElement(TheElement.FirstChild);
    while CurrElement <> nil do
      begin
      if CurrElement.TagName = 'vertices' then
        CreateVertices(CurrElement)
      else if CurrElement.TagName = 'texvertices' then
        CreateTextureVertices(CurrElement)
      else if CurrElement.TagName = 'faces' then
        CreateFaces(CurrElement);
      CurrElement := TDOMElement(CurrElement.NextSibling);
      end;
  end;
  
var
  CurrElement: TDOMElement;
begin
  setLength(fMaterialResourceNames, length(fMaterialResourceNames) + 1);
  setLength(fMaterialDefined, length(fMaterialDefined) + 1);
  fMaterialResourceNames[high(fMaterialResourceNames)] := '';
  fMaterialDefined[high(fMaterialResourceNames)] := False;
  CurrElement := TDOMElement(Element.FirstChild);
  Mesh := fGeoObject.AddMesh;
  while CurrElement <> nil do
    begin
    if CurrElement.TagName = 'material' then
      fMaterialResourceNames[high(fMaterialResourceNames)] := CurrElement.GetAttribute('resource:name')
    else if CurrElement.TagName = 'geometry' then
      CreateGeometry(CurrElement);
    CurrElement := TDOMElement(CurrElement.NextSibling);
    end;
end;

procedure TObjectResource.FileLoaded(Data: TOCFFile);
var
  S: String;
  Doc: TDOMDocument;
  i, j: Integer;
  CurrElement: TDOMElement;
begin
  with Data.ResourceByName(SubResourceName) do
    begin
    setLength(S, length(Data.Bin[Section].Stream.Data));
    for i := 0 to high(Data.Bin[Section].Stream.Data) do
      S[i + 1] := char(Data.Bin[Section].Stream.Data[i]);
    Doc := DOMFromXML(S);
    CurrElement := TDOMElement(Doc.GetElementsByTagName('object')[0].FirstChild);
    while CurrElement <> nil do
      begin
      if CurrElement.TagName = 'mesh' then
        LoadMesh(CurrElement);
      CurrElement := TDOMElement(CurrElement.NextSibling);
      end;
    Doc.Free;
    end;
  for i := 0 to high(fMaterialResourceNames) - 1 do
    if not fMaterialDefined[i] then
      for j := i + 1 to high(fMaterialResourceNames) do
        if fMaterialResourceNames[i] = fMaterialResourceNames[j] then
          fMaterialDefined[j] := True;
  for i := 0 to high(fMaterialDefined) do
    if not fMaterialDefined[i] then
      begin
      inc(fDepCount);
      setLength(fMaterialResources, length(fMaterialResources) + 1);
      setLength(fFinalMaterialResourceNames, length(fFinalMaterialResourceNames) + 1);
      end;
  if fDepCount = 0 then
    DepLoaded('', nil, nil)
  else
    begin
    j := 0;
    for i := 0 to high(fMaterialResources) do
      begin
      while fMaterialDefined[j] do
        inc(j);
      EventManager.AddCallback('TResource.FinishedLoading:' + fMaterialResourceNames[j], @DepLoaded);
      fFinalMaterialResourceNames[i] := fMaterialResourceNames[j];
      fMaterialResources[i] := TMaterialResource.Get(fMaterialResourceNames[j]);
      end;
    end;
end;

procedure TObjectResource.DepLoaded(Event: String; Data, Result: Pointer);
begin
  dec(fDepCount);
  if fDepCount <= 0 then
    begin
    FinalCreation;
    FinishedLoading := True;
    end;
end;

procedure TObjectResource.Free;
begin
  fGeoObject.Free;
  inherited Free;
end;

constructor TRealObject.Create(TheResource: TObjectResource);
begin
  inherited Create;
  fResource := TheResource;
  fGeoObject := Resource.GeoObject.Duplicate;
  fGeoObject.Register;
  fGeoObject.Matrix := TranslationMatrix(Vector(160, 64.5, 160));
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
      UpdateMatrix;
      UpdateArmatures;
      UpdateVertexPositions;
      RecalcFaceNormals;
      RecalcVertexNormals;
      end;
    CurrentObject := TRealObject(CurrentObject.Next);
    end;
end;

procedure TObjectManager.AddTestObject(Event: String; Data, Result: Pointer);
begin
  Append(TRealObject.Create(TObjectResource(ResourceManager.Resources['scenery/test.ocf/object'])));
end;

procedure TObjectManager.Test;
begin
  EventManager.AddCallback('TResource.FinishedLoading:scenery/test.ocf/object', @AddTestObject);
  TObjectResource.Get('scenery/test.ocf/object');
end;

constructor TObjectManager.Create;
begin
  inherited Create;
end;

procedure TObjectManager.Free;
begin
  while First <> nil do
    TRealObject(First).Free;
  inherited Free;
end;

end.