unit u_ase;

interface

uses
  SysUtils, classes, u_scene, u_vectors, u_math, math, u_files, u_functions, u_arrays;

type
  TASEMaterial = record
    Name, MaterialClass: String;
    Ambient, Diffuse, Specular: TVector3D;                  // Diffuse = mesh color
    Shine, ShineStrength, Transprarency: Single;            // 1 / Shine / ShineStrength = Shininess
    WireSize: Single;                                       // Unused
    Shading: String;                                        // Unused
    SelFillNum, XPFallOff: Single;                          // Unused
    FallOff, XPType: String;                                // Unused
    end;

  TASENodeTM = record
    NodeName: String;
    InheritPos, InheritRot, InheritSCL: TVector3D;          // Unknown meaning
    TMMatrix: TMatrix4D;                                    // Applied on demand
    TMPos: TVector3D;                                       // Applied on demand
    TMRotAxis: TVector3D;                                   // Applied on demand
    TMRotAngle: Single;                                     // Applied on demand
    TMScale: TVector3D;                                     // Applied  on demand
    TMScaleAxis: TVector3D;                                 // Unused
    TMScaleAxisAng: Single;                                 // Unknown meaning
    end;

  TASEMeshFace = record
    A, B, C: Integer;
    AB, BC, CA: Integer;                                    // Unused
    // Rest unknown
    end;

  TASEVertexNormal = record
    VertexID: Integer;
    Normal: TVector3D;
    end;

  TASEMeshNormals = record
    FaceNormal: TVector3D;                                  // Unused
    VertexNormals: Array[0..2] of TASEVertexNormal;
    end;

  TASEMesh = record
    TimeValue: Single;                                      // Unused
    NumVertex, NumFaces: Integer;
    VertexList: Array of TVector3D;
    FaceList: Array of TASEMeshFace;
    NumTVertex: Integer;
    TVertexList: Array of TVector3D;
    NumTVFaces: Integer;
    TFaceList: Array of Array[0..2] of Integer;
    NumCVertex: Integer;                                    // Unused
    Normals: Array of TASEMeshNormals;
    end;

  TASEGeomObject = record
    NodeName: String;
    NodeTM: TASENodeTM;
    Mesh: TASEMesh;
    PropMotionBlur, PropCastShadow, PropRecvShadow: Boolean;// Unused
    MaterialRef: Integer;
    end;

  TASEFile = record
    MaterialCount: Integer;
    Materials: Array of TASEMaterial;
    GeomObjects: Array of TASEGeomObject;
    end;

function LoadASEFile(F: String): TASEFile;
function LoadASECode(A: String): TASEFile;
function ASEFileToMeshArray(F: TASEFile): TGeoObject;

implementation

uses
  m_varlist;

function LoadASEFile(F: String): TASEFile;
var
  B: String;
  i: Integer;
  A: TByteStream;
begin
  A := ByteStreamFromFile(F);
  writeln('Loading ASE file ' + GetFirstExistingFileName(F));
  SetLength(B, Length(A.Data));
  for i := 0 to high(A.Data) do
    B[i + 1] := Char(A.Data[i]);
  Result := LoadASECode(B);
end;

function LoadASECode(A: String): TASEFile;
const
  MATERIAL_LIST = 1;
  MATERIAL = 2;
  GEOMOBJECT = 3;
  NODE_TM = 4;
  MESH = 5;
  MESH_VERTEXLIST = 6;
  MESH_FACELIST = 7;
  MESH_TVERTLIST = 8;
  MESH_TFACELIST = 9;
  MESH_NORMALS = 10;
var
  Modes: TRow;
  Mode: Integer;
  CurrID, CurrID1, CurrID2: Integer;
  tmp, S: String;
  i: Integer;
  function GetNextWord: String;
  begin
    Result := '';
    try
      while IsWhitespace(A[i]) do
        inc(i);
      while not IsWhitespace(A[i]) do
        begin
        Result := Result + A[i];
        inc(i);
        end;
    except
      exit;
    end;
  end;
begin
  try
    Modes := TRow.Create;
    i := 1;
    while i <= Length(A) do
      begin
      if A[i] = '*' then
        begin
        Mode := 0;
        inc(i);
        S := GetNextWord;
        if S = 'MATERIAL_LIST' then
          Mode := MATERIAL_LIST
        else if (S = 'MATERIAL_COUNT') and (Modes.Last = MATERIAL_LIST) then
          begin
          Result.MaterialCount := StrToInt(GetNextWord);
          SetLength(Result.Materials, Result.MaterialCount);
          end
        else if (S = 'MATERIAL') and (Modes.Last = MATERIAL_LIST) then
          begin
          CurrID := StrToInt(GetNextWord);
          Mode := MATERIAL;
          end
        else if (S = 'MATERIAL_NAME') and (Modes.Last = MATERIAL) then
          Result.Materials[CurrID].Name := GetNextWord
        else if (S = 'MATERIAL_CLASS') and (Modes.Last = MATERIAL) then
          Result.Materials[CurrID].MaterialClass := GetNextWord
        else if (S = 'MATERIAL_AMBIENT') and (Modes.Last = MATERIAL) then
          begin
          Result.Materials[CurrID].Ambient.X := StrToFloat(GetNextWord);
          Result.Materials[CurrID].Ambient.Y := StrToFloat(GetNextWord);
          Result.Materials[CurrID].Ambient.Z := StrToFloat(GetNextWord);
          end
        else if (S = 'MATERIAL_DIFFUSE') and (Modes.Last = MATERIAL) then
          begin
          Result.Materials[CurrID].Diffuse.X := StrToFloat(GetNextWord);
          Result.Materials[CurrID].Diffuse.Y := StrToFloat(GetNextWord);
          Result.Materials[CurrID].Diffuse.Z := StrToFloat(GetNextWord);
          end
        else if (S = 'MATERIAL_SPECULAR') and (Modes.Last = MATERIAL) then
          begin
          Result.Materials[CurrID].Specular.X := StrToFloat(GetNextWord);
          Result.Materials[CurrID].Specular.Y := StrToFloat(GetNextWord);
          Result.Materials[CurrID].Specular.Z := StrToFloat(GetNextWord);
          end
        else if (S = 'MATERIAL_SHINE') and (Modes.Last = MATERIAL) then
          Result.Materials[CurrID].Shine := StrToFloat(GetNextWord)
        else if (S = 'MATERIAL_SHINESTRENGTH') and (Modes.Last = MATERIAL) then
          Result.Materials[CurrID].ShineStrength := StrToFloat(GetNextWord)
        else if (S = 'MATERIAL_TRANSPARENCY') and (Modes.Last = MATERIAL) then
          Result.Materials[CurrID].Transprarency := StrToFloat(GetNextWord)
        else if (S = 'MATERIAL_WIRESIZE') and (Modes.Last = MATERIAL) then
          Result.Materials[CurrID].WireSize := StrToFloat(GetNextWord)
        else if (S = 'MATERIAL_SHADING') and (Modes.Last = MATERIAL) then
          Result.Materials[CurrID].Shading := GetNextWord
        else if (S = 'MATERIAL_XP_FALLOFF') and (Modes.Last = MATERIAL) then
          Result.Materials[CurrID].XPFallOff := StrToFloat(GetNextWord)
        else if (S = 'MATERIAL_SELFILLUM') and (Modes.Last = MATERIAL) then
          Result.Materials[CurrID].SelFillNum := StrToFloat(GetNextWord)
        else if (S = 'MATERIAL_FALLOFF') and (Modes.Last = MATERIAL) then
          Result.Materials[CurrID].FallOff := GetNextWord
        else if (S = 'MATERIAL_XP_TYPE') and (Modes.Last = MATERIAL) then
          Result.Materials[CurrID].XPType := GetNextWord
        else if S = 'GEOMOBJECT' then
          begin
          Mode := GEOMOBJECT;
          SetLength(Result.GeomObjects, length(Result.GeomObjects) + 1);
          CurrID := High(Result.GeomObjects);
          end
        else if (S = 'NODE_NAME') and (Modes.Last = GEOMOBJECT) then
          Result.GeomObjects[CurrID].NodeName := GetNextWord
        else if (S = 'NODE_TM') and (Modes.Last = GEOMOBJECT) then
          Mode := NODE_TM
        else if (S = 'NODE_NAME') and (Modes.Last = NODE_TM) then
          Result.GeomObjects[CurrID].NodeTM.NodeName := GetNextWord
        else if (S = 'INHERIT_POS') and (Modes.Last = NODE_TM) then
          begin
          Result.GeomObjects[CurrID].NodeTM.InheritPos.X := StrToFloat(GetNextWord);
          Result.GeomObjects[CurrID].NodeTM.InheritPos.Y := StrToFloat(GetNextWord);
          Result.GeomObjects[CurrID].NodeTM.InheritPos.Z := StrToFloat(GetNextWord);
          end
        else if (S = 'INHERIT_ROT') and (Modes.Last = NODE_TM) then
          begin
          Result.GeomObjects[CurrID].NodeTM.InheritRot.X := StrToFloat(GetNextWord);
          Result.GeomObjects[CurrID].NodeTM.InheritRot.Y := StrToFloat(GetNextWord);
          Result.GeomObjects[CurrID].NodeTM.InheritRot.Z := StrToFloat(GetNextWord);
          end
        else if (S = 'INHERIT_SCL') and (Modes.Last = NODE_TM) then
          begin
          Result.GeomObjects[CurrID].NodeTM.InheritScl.X := StrToFloat(GetNextWord);
          Result.GeomObjects[CurrID].NodeTM.InheritScl.Y := StrToFloat(GetNextWord);
          Result.GeomObjects[CurrID].NodeTM.InheritScl.Z := StrToFloat(GetNextWord);
          end
        else if (S = 'TM_ROW0') and (Modes.Last = NODE_TM) then
          begin
          Result.GeomObjects[CurrID].NodeTM.TMMatrix[0].X := StrToFloat(GetNextWord);
          Result.GeomObjects[CurrID].NodeTM.TMMatrix[1].X := StrToFloat(GetNextWord);
          Result.GeomObjects[CurrID].NodeTM.TMMatrix[2].X := StrToFloat(GetNextWord);
          Result.GeomObjects[CurrID].NodeTM.TMMatrix[3].X := 0;
          end
        else if (S = 'TM_ROW1') and (Modes.Last = NODE_TM) then
          begin
          Result.GeomObjects[CurrID].NodeTM.TMMatrix[0].Y := StrToFloat(GetNextWord);
          Result.GeomObjects[CurrID].NodeTM.TMMatrix[1].Y := StrToFloat(GetNextWord);
          Result.GeomObjects[CurrID].NodeTM.TMMatrix[2].Y := StrToFloat(GetNextWord);
          Result.GeomObjects[CurrID].NodeTM.TMMatrix[3].Y := 0;
          end
        else if (S = 'TM_ROW2') and (Modes.Last = NODE_TM) then
          begin
          Result.GeomObjects[CurrID].NodeTM.TMMatrix[0].Z := StrToFloat(GetNextWord);
          Result.GeomObjects[CurrID].NodeTM.TMMatrix[1].Z := StrToFloat(GetNextWord);
          Result.GeomObjects[CurrID].NodeTM.TMMatrix[2].Z := StrToFloat(GetNextWord);
          Result.GeomObjects[CurrID].NodeTM.TMMatrix[3].Z := 0;
          end
        else if (S = 'TM_ROW3') and (Modes.Last = NODE_TM) then
          begin
          Result.GeomObjects[CurrID].NodeTM.TMMatrix[0].W := StrToFloat(GetNextWord);
          Result.GeomObjects[CurrID].NodeTM.TMMatrix[1].W := StrToFloat(GetNextWord);
          Result.GeomObjects[CurrID].NodeTM.TMMatrix[2].W := StrToFloat(GetNextWord);
          Result.GeomObjects[CurrID].NodeTM.TMMatrix[3].W := 1;
          end
        else if (S = 'TM_POS') and (Modes.Last = NODE_TM) then
          begin
          Result.GeomObjects[CurrID].NodeTM.TMPos.X := StrToFloat(GetNextWord);
          Result.GeomObjects[CurrID].NodeTM.TMPos.Y := StrToFloat(GetNextWord);
          Result.GeomObjects[CurrID].NodeTM.TMPos.Z := StrToFloat(GetNextWord);
          end
        else if (S = 'TM_ROTAXIS') and (Modes.Last = NODE_TM) then
          begin
          Result.GeomObjects[CurrID].NodeTM.TMRotAxis.X := StrToFloat(GetNextWord);
          Result.GeomObjects[CurrID].NodeTM.TMRotAxis.Y := StrToFloat(GetNextWord);
          Result.GeomObjects[CurrID].NodeTM.TMRotAxis.Z := StrToFloat(GetNextWord);
          end
        else if (S = 'TM_ROTANGLE') and (Modes.Last = NODE_TM) then
          Result.GeomObjects[CurrID].NodeTM.TMRotAngle := StrToFloat(GetNextWord)
        else if (S = 'TM_SCALE') and (Modes.Last = NODE_TM) then
          begin
          Result.GeomObjects[CurrID].NodeTM.TMScale.X := StrToFloat(GetNextWord);
          Result.GeomObjects[CurrID].NodeTM.TMScale.Y := StrToFloat(GetNextWord);
          Result.GeomObjects[CurrID].NodeTM.TMScale.Z := StrToFloat(GetNextWord);
          end
        else if (S = 'TM_SCALEAXIS') and (Modes.Last = NODE_TM) then
          begin
          Result.GeomObjects[CurrID].NodeTM.TMScaleAxis.X := StrToFloat(GetNextWord);
          Result.GeomObjects[CurrID].NodeTM.TMScaleAxis.Y := StrToFloat(GetNextWord);
          Result.GeomObjects[CurrID].NodeTM.TMScaleAxis.Z := StrToFloat(GetNextWord);
          end
        else if (S = 'TM_SCALEAXISANG') and (Modes.Last = NODE_TM) then
          Result.GeomObjects[CurrID].NodeTM.TMScaleAxisAng := StrToFloat(GetNextWord)
        else if (S = 'MESH') and (Modes.Last = GEOMOBJECT) then
          Mode := MESH
        else if (S = 'TIMEVALUE') and (Modes.Last = MESH) then
          Result.GeomObjects[CurrID].Mesh.TimeValue := StrToInt(GetNextWord)
        else if (S = 'MESH_NUMVERTEX') and (Modes.Last = MESH) then
          begin
          Result.GeomObjects[CurrID].Mesh.NumVertex := StrToInt(GetNextWord);
          SetLength(Result.GeomObjects[CurrID].Mesh.VertexList, Result.GeomObjects[CurrID].Mesh.NumVertex);
          end
        else if (S = 'MESH_NUMFACES') and (Modes.Last = MESH) then
          begin
          Result.GeomObjects[CurrID].Mesh.NumFaces := StrToInt(GetNextWord);
          SetLength(Result.GeomObjects[CurrID].Mesh.FaceList, Result.GeomObjects[CurrID].Mesh.NumFaces);
          SetLength(Result.GeomObjects[CurrID].Mesh.Normals, Result.GeomObjects[CurrID].Mesh.NumFaces);
          end
        else if (S = 'MESH_VERTEX_LIST') and (Modes.Last = MESH) then
          Mode := MESH_VERTEXLIST
        else if (S = 'MESH_VERTEX') and (Modes.Last = MESH_VERTEXLIST) then
          begin
          CurrID1 := StrToInt(GetNextWord);
          Result.GeomObjects[CurrID].Mesh.VertexList[CurrID1].X := StrToFloat(GetNextWord);
          Result.GeomObjects[CurrID].Mesh.VertexList[CurrID1].Y := StrToFloat(GetNextWord);
          Result.GeomObjects[CurrID].Mesh.VertexList[CurrID1].Z := StrToFloat(GetNextWord);
          end
        else if (S = 'MESH_FACE_LIST') and (Modes.Last = MESH) then
          Mode := MESH_FACELIST
        else if (S = 'MESH_FACE') and (Modes.Last = MESH_FACELIST) then
          begin
          tmp := GetNextWord;
          CurrID1 := StrToInt(SubString(tmp, 1, length(tmp) - 1));
          with Result.GeomObjects[CurrID].Mesh.FaceList[CurrID1] do
            begin
            GetNextWord;
            A := StrToInt(GetNextWord);
            GetNextWord;
            B := StrToInt(GetNextWord);
            GetNextWord;
            C := StrToInt(GetNextWord);
            GetNextWord;
            AB := StrToInt(GetNextWord);
            GetNextWord;
            BC := StrToInt(GetNextWord);
            GetNextWord;
            CA := StrToInt(GetNextWord);
            end;
          end
        else if (S = 'MESH_NUMTVERTEX') and (Modes.Last = MESH) then
          begin
          Result.GeomObjects[CurrID].Mesh.NumTVertex := StrToInt(GetNextWord);
          SetLength(Result.GeomObjects[CurrID].Mesh.TVertexList, Result.GeomObjects[CurrID].Mesh.NumTVertex);
          end
        else if (S = 'MESH_TVERTLIST') and (Modes.Last = MESH) then
          Mode := MESH_TVERTLIST
        else if (S = 'MESH_TVERT') and (Modes.Last = MESH_TVERTLIST) then
          begin
          CurrID1 := StrToInt(GetNextWord);
          Result.GeomObjects[CurrID].Mesh.TVertexList[CurrID1].X := StrToFloat(GetNextWord);
          Result.GeomObjects[CurrID].Mesh.TVertexList[CurrID1].Y := StrToFloat(GetNextWord);
          Result.GeomObjects[CurrID].Mesh.TVertexList[CurrID1].Z := StrToFloat(GetNextWord);
          end
        else if (S = 'MESH_NUMTVFACES') and (Modes.Last = MESH) then
          begin
          Result.GeomObjects[CurrID].Mesh.NumTVFaces := StrToInt(GetNextWord);
          SetLength(Result.GeomObjects[CurrID].Mesh.TFaceList, Result.GeomObjects[CurrID].Mesh.NumTVFaces);
          end
        else if (S = 'MESH_TFACELIST') and (Modes.Last = MESH) then
          Mode := MESH_TFACELIST
        else if (S = 'MESH_TFACE') and (Modes.Last = MESH_TFACELIST) then
          begin
          CurrID1 := StrToInt(GetNextWord);
          Result.GeomObjects[CurrID].Mesh.TFaceList[CurrID1, 0] := StrToInt(GetNextWord);
          Result.GeomObjects[CurrID].Mesh.TFaceList[CurrID1, 1] := StrToInt(GetNextWord);
          Result.GeomObjects[CurrID].Mesh.TFaceList[CurrID1, 2] := StrToInt(GetNextWord);
          end
        else if (S = 'MESH_NUMCVERTEX') and (Modes.Last = MESH) then
          Result.GeomObjects[CurrID].Mesh.NumCVertex := StrToInt(GetNextWord)
        else if (S = 'MESH_NORMALS') and (Modes.Last = MESH) then
          Mode := MESH_NORMALS
        else if (S = 'MESH_FACENORMAL') and (Modes.Last = MESH_NORMALS) then
          begin
          CurrID1 := StrToInt(GetNextWord);
          CurrID2 := 0;
          Result.GeomObjects[CurrID].Mesh.Normals[CurrID1].FaceNormal.X := StrToFloat(GetNextWord);
          Result.GeomObjects[CurrID].Mesh.Normals[CurrID1].FaceNormal.Y := StrToFloat(GetNextWord);
          Result.GeomObjects[CurrID].Mesh.Normals[CurrID1].FaceNormal.Z := StrToFloat(GetNextWord);
          end
        else if (S = 'MESH_VERTEXNORMAL') and (Modes.Last = MESH_NORMALS) then
          begin
          Result.GeomObjects[CurrID].Mesh.Normals[CurrID1].VertexNormals[CurrID2].VertexID := StrToInt(GetNextWord);
          Result.GeomObjects[CurrID].Mesh.Normals[CurrID1].VertexNormals[CurrID2].Normal.X := StrToFloat(GetNextWord);
          Result.GeomObjects[CurrID].Mesh.Normals[CurrID1].VertexNormals[CurrID2].Normal.Y := StrToFloat(GetNextWord);
          Result.GeomObjects[CurrID].Mesh.Normals[CurrID1].VertexNormals[CurrID2].Normal.Z := StrToFloat(GetNextWord);
          inc(CurrID2);
          end
        else if (S = 'PROP_MOTIONBLUR') and (Modes.Last = GEOMOBJECT) then
          Result.GeomObjects[CurrID].PropMotionBlur := GetNextWord = '1'
        else if (S = 'PROP_CASTSHADOW') and (Modes.Last = GEOMOBJECT) then
          Result.GeomObjects[CurrID].PropCastShadow := GetNextWord = '1'
        else if (S = 'PROP_RECVSHADOW') and (Modes.Last = GEOMOBJECT) then
          Result.GeomObjects[CurrID].PropRecvShadow := GetNextWord = '1'
        else if (S = 'MATERIAL_REF') and (Modes.Last = GEOMOBJECT) then
          Result.GeomObjects[CurrID].MaterialRef := StrToInt(GetNextWord);
        end
      else if A[i] = '{' then
        Modes.Push(Mode)
      else if A[i] = '}' then
        Modes.Pop;
      inc(i);
      end;
    Modes.Free;
  except
    ModuleManager.ModLog.AddError('Failed to load ASE code: Error in stream');
  end;
end;

function ASEFileToMeshArray(F: TASEFile): TGeoObject;
var
  i, j: Integer;
begin
  Result := TGeoObject.Create;
  for i := 0 to F.MaterialCount do
    with Result.AddMaterial do
      begin
      Color := Vector(F.Materials[i].Diffuse, 1 - F.Materials[i].Transprarency);
      Hardness := 1 / F.Materials[i].Shine / F.Materials[i].ShineStrength;
      end;
  for i := 0 to high(F.GeomObjects) do
    with Result.AddMesh do
      begin
      Material := Result.Materials[F.GeomObjects[i].MaterialRef];
      MinDistance := -10000;
      MaxDistance := 10000;
      Parent := nil;

      for j := 0 to F.GeomObjects[i].Mesh.NumVertex - 1 do
        with (AddVertex)^ do
          Position := F.GeomObjects[i].Mesh.VertexList[j];

      for j := 0 to F.GeomObjects[i].Mesh.NumTVertex - 1 do
        with (AddTextureVertex)^ do
          Position := Vector2D(F.GeomObjects[i].Mesh.TVertexList[j]);

      for j := 0 to F.GeomObjects[i].Mesh.NumFaces - 1 do
        with (AddFace)^ do
          begin
          Vertices[0] := F.GeomObjects[i].Mesh.FaceList[j].A;
          Vertices[1] := F.GeomObjects[i].Mesh.FaceList[j].B;
          Vertices[2] := F.GeomObjects[i].Mesh.FaceList[j].C;
          TexCoords[0] := F.GeomObjects[i].Mesh.TFaceList[j, 0];
          TexCoords[1] := F.GeomObjects[i].Mesh.TFaceList[j, 1];
          TexCoords[2] := F.GeomObjects[i].Mesh.TFaceList[j, 2];
          Facenormal := F.GeomObjects[i].Mesh.Normals[j].Facenormal;
          Result.Meshes[i].Vertices[Vertices[0]].VertexNormal := F.GeomObjects[i].Mesh.Normals[j].VertexNormals[0].Normal;
          Result.Meshes[i].Vertices[Vertices[1]].VertexNormal := F.GeomObjects[i].Mesh.Normals[j].VertexNormals[1].Normal;
          Result.Meshes[i].Vertices[Vertices[2]].VertexNormal := F.GeomObjects[i].Mesh.Normals[j].VertexNormals[2].Normal;
          end;
      UpdateFaceVertexAssociationForVertexNormalCalculation;
      end;
end;

end.