unit g_res_objects;

interface

uses
  SysUtils, Classes, u_linkedlists, g_resources, u_scene, g_loader_ocf, g_res_textures, g_res_materials, u_xml, u_dom, u_vectors,
  g_res_lights, g_res_particles, g_res_pathes, g_res_scripts;

type
  TBonePathResourceAssoc = record
    Bone: TBone;
    PathResource: TPathResource;
    PathResourceName: String;
    end;

  TObjectResource = class(TAbstractResource)
    protected
      fGeoObject: TGeoObject;
      fBonePathResourceAssocs: Array of TBonePathResourceAssoc;
      fMaterialResources: Array of TMaterialResource;
      fMaterialResourceNames: Array of String;
      fLightSourceResourceNames: Array of Array of String;
      fLightSourceResourcePositions: Array of Array of TVector3D;
      fLightSourceResources: Array of Array of TLightResource;
      fParticleGroupResourceNames: Array of Array of String;
      fParticleGroupResourcePositions: Array of Array of TVector3D;
      fParticleGroupResources: Array of Array of TParticleResource;
      fScriptResourceName: String;
      fScriptResource: TScriptResource;
      fMaterialDefined: Array of Boolean;
      fFinalMaterialResourceNames: Array of String;
      fDepCount: Integer;
    public
      property GeoObject: TGeoObject read fGeoObject;
      constructor Create(ResourceName: String);
      class function Get(ResourceName: String): TObjectResource;
      function LoadMatrix(Element: TDOMElement): TMatrix4D;
      procedure FinalCreation;
      procedure FileLoaded(Data: TOCFFile);
      procedure DepLoaded(Event: String; Data, Result: Pointer);
      function LoadMesh(Element: TDOMElement): TGeoMesh;
      procedure LoadArmature(Element: TDOMElement);
      procedure Free;
    end;

implementation

uses
  u_functions, u_events, u_particles;

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
  if fScriptResource <> nil then
    fGeoObject.Script := fScriptResource.ScriptCode.CreateInstance;

  for i := 0 to high(fMaterialResources) do
    fGeoObject.AddMaterial(fMaterialResources[i].Material);

  for i := 0 to high(fGeoObject.Meshes) do
    begin
    for j := 0 to high(fFinalMaterialResourceNames) do
      if fFinalMaterialResourceNames[j] = fMaterialResourceNames[i] then
        fGeoObject.Meshes[i].Material := fMaterialResources[j].Material;

    setLength(fGeoObject.Meshes[i].LightSources, length(fLightSourceResources[i]));
    for j := 0 to high(fLightSourceResources[i]) do
      begin
      fGeoObject.Meshes[i].LightSources[j] := fLightSourceResources[i, j].Light;
      fGeoObject.Meshes[i].LightSources[j].Position := Vector(fLightSourceResourcePositions[i, j], 1.0);
      fGeoObject.Meshes[i].LightSources[j].OriginalPosition := fGeoObject.Meshes[i].LightSources[j].Position;
      end;

    setLength(fGeoObject.Meshes[i].ParticleGroups, length(fParticleGroupResources[i]));
    for j := 0 to high(fParticleGroupResources[i]) do
      begin
      TParticleGroup(fGeoObject.Meshes[i].ParticleGroups[j]) := fParticleGroupResources[i, j].Group;
      TParticleGroup(fGeoObject.Meshes[i].ParticleGroups[j]).InitialPosition := fParticleGroupResourcePositions[i, j];
      TParticleGroup(fGeoObject.Meshes[i].ParticleGroups[j]).OriginalPosition := fParticleGroupResourcePositions[i, j];
      end;
    end;

  for i := 0 to high(fBonePathResourceAssocs) do
    if fBonePathResourceAssocs[i].PathResourceName <> '' then
      fBonePathResourceAssocs[i].Bone.PathConstraint.Path := fBonePathResourceAssocs[i].PathResource.Path;

  fGeoObject.UpdateFaceVertexAssociationForVertexNormalCalculation;
  fGeoObject.RecalcFaceNormals;
  fGeoObject.RecalcVertexNormals;
end;

function TObjectResource.LoadMatrix(Element: TDOMElement): TMatrix4D;
var
  CurrElement: TDOMElement;
  Row: Integer;
begin
  Row := 0;
  CurrElement := TDOMElement(Element.FirstChild);
  while CurrElement <> nil do
    begin
    if (CurrElement.TagName = 'row') and (Row < 4) then
      begin
      Result[Row] := Vector(StrToFloatWD(CurrElement.GetAttribute('x'), 0.0),
                            StrToFloatWD(CurrElement.GetAttribute('y'), 0.0),
                            StrToFloatWD(CurrElement.GetAttribute('z'), 0.0),
                            StrToFloatWD(CurrElement.GetAttribute('w'), 0.0));
      inc(Row);
      end;
    CurrElement := TDOMElement(CurrElement.NextSibling);
    end;
end;

function TObjectResource.LoadMesh(Element: TDOMElement): TGeoMesh;
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
            end
          else if CurrElement.TagName = 'bone' then
            begin
            setLength(TheVertex^.Bones, length(TheVertex^.Bones) + 1);
            TheVertex^.Bones[high(TheVertex^.Bones)].Bone := fGeoObject.GetBoneByName(CurrElement.GetAttribute('armature'), CurrElement.GetAttribute('name'));
            TheVertex^.Bones[high(TheVertex^.Bones)].Weight := StrToFloatWD(CurrElement.GetAttribute('weight'), 1.0);
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
  Mesh := fGeoObject.AddMesh;

  setLength(fMaterialResourceNames, length(fMaterialResourceNames) + 1);
  setLength(fMaterialDefined, length(fMaterialDefined) + 1);
  setLength(fLightSourceResourceNames, length(fLightSourceResourceNames) + 1);
  setLength(fLightSourceResourcePositions, length(fLightSourceResourcePositions) + 1);
  setLength(fParticleGroupResourceNames, length(fParticleGroupResourceNames) + 1);
  setLength(fParticleGroupResourcePositions, length(fParticleGroupResourcePositions) + 1);

  fMaterialResourceNames[high(fMaterialResourceNames)] := '';
  fMaterialDefined[high(fMaterialResourceNames)] := False;

  CurrElement := TDOMElement(Element.FirstChild);

  while CurrElement <> nil do
    begin
    if CurrElement.TagName = 'material' then
      fMaterialResourceNames[high(fMaterialResourceNames)] := CurrElement.GetAttribute('resource:name')
    else if CurrElement.TagName = 'bone' then
      Mesh.Bone := fGeoObject.GetBoneByName(CurrElement.GetAttribute('armature'), CurrElement.GetAttribute('name'))
    else if CurrElement.TagName = 'light' then
      begin
      setLength(fLightSourceResourceNames[high(fLightSourceResourceNames)], length(fLightSourceResourceNames[high(fLightSourceResourceNames)]) + 1);
      fLightSourceResourceNames[high(fLightSourceResourceNames), high(fLightSourceResourceNames[high(fLightSourceResourceNames)])] := CurrElement.GetAttribute('resource:name');

      setLength(fLightSourceResourcePositions[high(fLightSourceResourcePositions)], length(fLightSourceResourcePositions[high(fLightSourceResourcePositions)]) + 1);
      fLightSourceResourcePositions[high(fLightSourceResourcePositions), high(fLightSourceResourcePositions[high(fLightSourceResourcePositions)])] := Vector(StrToFloatWD(CurrElement.GetAttribute('x'), 0.0), StrToFloatWD(CurrElement.GetAttribute('y'), 0.0), StrToFloatWD(CurrElement.GetAttribute('z'), 0.0));
      end
    else if CurrElement.TagName = 'particle' then
      begin
      setLength(fParticleGroupResourceNames[high(fParticleGroupResourceNames)], length(fParticleGroupResourceNames[high(fParticleGroupResourceNames)]) + 1);
      fParticleGroupResourceNames[high(fParticleGroupResourceNames), high(fParticleGroupResourceNames[high(fParticleGroupResourceNames)])] := CurrElement.GetAttribute('resource:name');

      setLength(fParticleGroupResourcePositions[high(fParticleGroupResourcePositions)], length(fParticleGroupResourcePositions[high(fParticleGroupResourcePositions)]) + 1);
      fParticleGroupResourcePositions[high(fParticleGroupResourcePositions), high(fParticleGroupResourcePositions[high(fParticleGroupResourcePositions)])] := Vector(StrToFloatWD(CurrElement.GetAttribute('x'), 0.0), StrToFloatWD(CurrElement.GetAttribute('y'), 0.0), StrToFloatWD(CurrElement.GetAttribute('z'), 0.0));
      end
    else if CurrElement.TagName = 'geometry' then
      CreateGeometry(CurrElement)
    else if CurrElement.TagName = 'mindist' then
      Mesh.MinDistance := StrToFloatWD(CurrElement.FirstChild.NodeValue, Mesh.MinDistance)
    else if CurrElement.TagName = 'maxdist' then
      Mesh.MaxDistance := StrToFloatWD(CurrElement.FirstChild.NodeValue, Mesh.MaxDistance)
    else if CurrElement.TagName = 'matrix' then
      Mesh.Matrix := LoadMatrix(CurrElement)
    else if CurrElement.TagName = 'name' then
      Mesh.Name := CurrElement.FirstChild.NodeValue
    else if CurrElement.TagName = 'mesh' then
      Mesh.AddChild(LoadMesh(CurrElement));
    CurrElement := TDOMElement(CurrElement.NextSibling);
    end;
  Result := Mesh;
end;

procedure TObjectResource.LoadArmature(Element: TDOMElement);
var
  Armature: TArmature;

  function AddBone(TheElement: TDOMElement; Parent: TBone): TBone;
  var
    CurrElement: TDOMElement;
    Bone: TBone;
  begin
    Bone := Armature.AddBone;
    Bone.ParentBone := Parent;

    setLength(fBonePathResourceAssocs, length(fBonePathResourceAssocs) + 1);
    fBonePathResourceAssocs[high(fBonePathResourceAssocs)].Bone := Bone;
    fBonePathResourceAssocs[high(fBonePathResourceAssocs)].PathResourceName := '';
    fBonePathResourceAssocs[high(fBonePathResourceAssocs)].PathResource := nil;

    CurrElement := TDOMElement(TheElement.FirstChild);

    while CurrElement <> nil do
      begin
      if CurrElement.TagName = 'name' then
        Bone.Name := CurrElement.FirstChild.NodeValue
      else if CurrElement.TagName = 'bone' then
        Bone.AddChild(AddBone(CurrElement, Bone))
      else if CurrElement.TagName = 'position' then
        Bone.SourcePosition := Vector(StrToFloatWD(CurrElement.GetAttribute('x'), 0), StrToFloatWD(CurrElement.GetAttribute('y'), 0), StrToFloatWD(CurrElement.GetAttribute('z'), 0))
      else if CurrElement.TagName = 'matrix' then
        Bone.Matrix := LoadMatrix(CurrElement)
      else if CurrElement.TagName = 'path' then
        begin
        Bone.PathConstraint.FollowOrientation := CurrElement.GetAttribute('followorientation') = 'true';
        Bone.PathConstraint.FollowBanking := CurrElement.GetAttribute('followbanking') = 'true';
        Bone.PathConstraint.Progress := StrToFloatWD(CurrElement.GetAttribute('progress'), 0);
        fBonePathResourceAssocs[high(fBonePathResourceAssocs)].PathResourceName := CurrElement.GetAttribute('resource:name');
        fBonePathResourceAssocs[high(fBonePathResourceAssocs)].PathResource := nil;
        end;

      CurrElement := TDOMElement(CurrElement.NextSibling);
      end;
    Result := Bone
  end;

var
  CurrElement: TDOMElement;
begin
  Armature := fGeoObject.AddArmature;

  CurrElement := TDOMElement(Element.FirstChild);

  while CurrElement <> nil do
    begin
    if CurrElement.TagName = 'name' then
      Armature.Name := CurrElement.FirstChild.NodeValue
    else if CurrElement.TagName = 'matrix' then
      Armature.Matrix := LoadMatrix(CurrElement)
    else if CurrElement.TagName = 'bone' then
      AddBone(CurrElement, nil);

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
  fScriptResource := nil;
  fScriptResourceName := '';

  with Data.ResourceByName(SubResourceName) do
    begin
    setLength(S, length(Data.Bin[Section].Stream.Data));
    for i := 0 to high(Data.Bin[Section].Stream.Data) do
      S[i + 1] := char(Data.Bin[Section].Stream.Data[i]);
    Doc := DOMFromXML(S);
    CurrElement := TDOMElement(Doc.GetElementsByTagName('object')[0].FirstChild);
    while CurrElement <> nil do
      begin
      if CurrElement.TagName = 'armature' then
        LoadArmature(CurrElement)
      else if CurrElement.TagName = 'script' then
        fScriptResourceName := CurrElement.GetAttribute('resource:name')
      else if CurrElement.TagName = 'mesh' then
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
      
  setLength(fLightSourceResources, length(fLightSourceResourceNames));
  for i := 0 to high(fLightSourceResourceNames) do
    begin
    setLength(fLightSourceResources[i], length(fLightSourceResourceNames[i]));
    inc(fDepCount, length(fLightSourceResourceNames[i]));
    end;
    
  setLength(fParticleGroupResources, length(fParticleGroupResourceNames));
  for i := 0 to high(fParticleGroupResourceNames) do
    begin
    setLength(fParticleGroupResources[i], length(fParticleGroupResourceNames[i]));
    inc(fDepCount, length(fParticleGroupResourceNames[i]));
    end;
    
  for i := 0 to high(fBonePathResourceAssocs) do
    if fBonePathResourceAssocs[i].PathResourceName <> '' then
      inc(fDepCount);

  if fScriptResourceName <> '' then
    inc(fDepCount);
  
  if fDepCount = 0 then
    DepLoaded('', nil, nil)
  else
    begin
    if fScriptResourceName <> '' then
      begin
      EventManager.AddCallback('TResource.FinishedLoading:' + fScriptResourceName, @DepLoaded);
      fScriptResource := TScriptResource.Get(fScriptResourceName);
      end;
    
    for i := 0 to high(fLightSourceResourceNames) do
      for j := 0 to high(fLightSourceResourceNames[i]) do
        begin
        EventManager.AddCallback('TResource.FinishedLoading:' + fLightSourceResourceNames[i, j], @DepLoaded);
        fLightSourceResources[i, j] := TLightResource.Get(fLightSourceResourceNames[i, j]);
        end;

    for i := 0 to high(fParticleGroupResourceNames) do
      for j := 0 to high(fParticleGroupResourceNames[i]) do
        begin
        EventManager.AddCallback('TResource.FinishedLoading:' + fParticleGroupResourceNames[i, j], @DepLoaded);
        fParticleGroupResources[i, j] := TParticleResource.Get(fParticleGroupResourceNames[i, j]);
        end;

    for i := 0 to high(fBonePathResourceAssocs) do
      if fBonePathResourceAssocs[i].PathResourceName <> '' then
        begin
        EventManager.AddCallback('TResource.FinishedLoading:' + fBonePathResourceAssocs[i].PathResourceName, @DepLoaded);
        fBonePathResourceAssocs[i].PathResource := TPathResource.Get(fBonePathResourceAssocs[i].PathResourceName);
        end;
        
    i := 0;
    for j := 0 to high(fMaterialDefined) do
      if not fMaterialDefined[j] then
        begin
        EventManager.AddCallback('TResource.FinishedLoading:' + fMaterialResourceNames[j], @DepLoaded);
        fFinalMaterialResourceNames[i] := fMaterialResourceNames[j];
        fMaterialResources[i] := TMaterialResource.Get(fMaterialResourceNames[j]);
        inc(i);
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

end.