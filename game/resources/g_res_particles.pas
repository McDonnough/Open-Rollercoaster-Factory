unit g_res_particles;

interface

uses
  SysUtils, Classes, m_texmng_class, g_resources, g_loader_ocf, dglOpenGL, u_scene, u_particles, g_particles, g_res_materials;

type
  TParticleResource = class(TAbstractResource)
    protected
      fGroup: TParticleGroup;
      fMaterialResource: TMaterialResource;
      fMaterialResourceName: String;
    public
      property Group: TParticleGroup read fGroup;
      class function Get(ResourceName: String): TParticleResource;
      constructor Create(ResourceName: String);
      procedure FileLoaded(Data: TOCFFile);
      procedure DepLoaded(Event: String; Data, Result: Pointer);
      procedure Free;
    end;

implementation

uses
  u_graphics, u_events, u_vectors, u_functions, u_dom, u_xml;

class function TParticleResource.Get(ResourceName: String): TParticleResource;
begin
  Result := TParticleResource(ResourceManager.Resources[ResourceName]);
  if Result = nil then
    Result := TParticleResource.Create(ResourceName)
  else
    ResourceManager.AddFinishedResource(Result);
end;

constructor TParticleResource.Create(ResourceName: String);
begin
  fGroup := TParticleGroup.Create;
  fMaterialResource := nil;
  fMaterialResourceName := '';
  inherited Create(ResourceName, @FileLoaded);
end;

procedure TParticleResource.FileLoaded(Data: TOCFFile);
var
  S: String;
  Doc: TDOMDocument;
  CurrElement: TDOMElement;
  i: Integer;
begin
  with Data.ResourceByName(SubResourceName) do
    begin
    setLength(S, length(Data.Bin[Section].Stream.Data));
    for i := 0 to high(Data.Bin[Section].Stream.Data) do
      S[i + 1] := char(Data.Bin[Section].Stream.Data[i]);
    Doc := DOMFromXML(S);
    CurrElement := TDOMElement(Doc.GetElementsByTagName('particle')[0].FirstChild);
    while CurrElement <> nil do
      begin
      if CurrElement.TagName = 'name' then
        fGroup.Name := CurrElement.FirstChild.NodeValue
      else if CurrElement.TagName = 'material' then
        fMaterialResourceName := CurrElement.GetAttribute('resource:name')
      else if CurrElement.TagName = 'illumination' then
        fGroup.NeedsIllumination := CurrElement.FirstChild.NodeValue = 'true'
      else if CurrElement.TagName = 'lifetime' then
        begin
        fGroup.Lifetime := StrToFloatWD(CurrElement.GetAttribute('value'), fGroup.Lifetime);
        fGroup.LifetimeVariance := StrToFloatWD(CurrElement.GetAttribute('variance'), fGroup.LifetimeVariance);
        end
      else if CurrElement.TagName = 'gentime' then
        begin
        fGroup.GenerationTime := StrToFloatWD(CurrElement.GetAttribute('value'), fGroup.Generationtime);
        fGroup.GenerationTimeVariance := StrToFloatWD(CurrElement.GetAttribute('variance'), fGroup.GenerationtimeVariance);
        end
      else if CurrElement.TagName = 'size' then
        fGroup.InitialSize := Vector(StrToFloatWD(CurrElement.GetAttribute('x'), fGroup.InitialSize.X),
                                     StrToFloatWD(CurrElement.GetAttribute('y'), fGroup.InitialSize.Y))
      else if CurrElement.TagName = 'sizeexp' then
        fGroup.SizeExponent := Vector(StrToFloatWD(CurrElement.GetAttribute('x'), fGroup.SizeExponent.X),
                                      StrToFloatWD(CurrElement.GetAttribute('y'), fGroup.SizeExponent.Y))
      else if CurrElement.TagName = 'sizevar' then
        fGroup.SizeVariance := Vector(StrToFloatWD(CurrElement.GetAttribute('x'), fGroup.SizeVariance.X),
                                      StrToFloatWD(CurrElement.GetAttribute('y'), fGroup.SizeVariance.Y))
      else if CurrElement.TagName = 'color' then
        fGroup.InitialColor := Vector(StrToFloatWD(CurrElement.GetAttribute('r'), fGroup.InitialColor.X),
                                      StrToFloatWD(CurrElement.GetAttribute('g'), fGroup.InitialColor.Y),
                                      StrToFloatWD(CurrElement.GetAttribute('b'), fGroup.InitialColor.Z),
                                      StrToFloatWD(CurrElement.GetAttribute('a'), fGroup.InitialColor.W))
      else if CurrElement.TagName = 'colorexp' then
        fGroup.ColorExponent := Vector(StrToFloatWD(CurrElement.GetAttribute('r'), fGroup.ColorExponent.X),
                                       StrToFloatWD(CurrElement.GetAttribute('g'), fGroup.ColorExponent.Y),
                                       StrToFloatWD(CurrElement.GetAttribute('b'), fGroup.ColorExponent.Z),
                                       StrToFloatWD(CurrElement.GetAttribute('a'), fGroup.ColorExponent.W))
      else if CurrElement.TagName = 'colorvar' then
        fGroup.ColorVariance := Vector(StrToFloatWD(CurrElement.GetAttribute('r'), fGroup.ColorVariance.X),
                                       StrToFloatWD(CurrElement.GetAttribute('g'), fGroup.ColorVariance.Y),
                                       StrToFloatWD(CurrElement.GetAttribute('b'), fGroup.ColorVariance.Z),
                                       StrToFloatWD(CurrElement.GetAttribute('a'), fGroup.ColorVariance.W))
      else if CurrElement.TagName = 'velocity' then
        fGroup.InitialVelocity := Vector(StrToFloatWD(CurrElement.GetAttribute('x'), fGroup.InitialVelocity.X),
                                         StrToFloatWD(CurrElement.GetAttribute('y'), fGroup.InitialVelocity.Y),
                                         StrToFloatWD(CurrElement.GetAttribute('z'), fGroup.InitialVelocity.Z))
      else if CurrElement.TagName = 'velocityvar' then
        fGroup.VelocityVariance := Vector(StrToFloatWD(CurrElement.GetAttribute('x'), fGroup.VelocityVariance.X),
                                          StrToFloatWD(CurrElement.GetAttribute('y'), fGroup.VelocityVariance.Y),
                                          StrToFloatWD(CurrElement.GetAttribute('z'), fGroup.VelocityVariance.Z))
      else if CurrElement.TagName = 'acceleration' then
        fGroup.InitialAcceleration := Vector(StrToFloatWD(CurrElement.GetAttribute('x'), fGroup.InitialAcceleration.X),
                                             StrToFloatWD(CurrElement.GetAttribute('y'), fGroup.InitialAcceleration.Y),
                                             StrToFloatWD(CurrElement.GetAttribute('z'), fGroup.InitialAcceleration.Z))
      else if CurrElement.TagName = 'accelerationvar' then
        fGroup.AccelerationVariance := Vector(StrToFloatWD(CurrElement.GetAttribute('x'), fGroup.AccelerationVariance.X),
                                              StrToFloatWD(CurrElement.GetAttribute('y'), fGroup.AccelerationVariance.Y),
                                              StrToFloatWD(CurrElement.GetAttribute('z'), fGroup.AccelerationVariance.Z))
      else if CurrElement.TagName = 'position' then
        begin
        fGroup.InitialPosition := Vector(StrToFloatWD(CurrElement.GetAttribute('x'), fGroup.InitialPosition.X),
                                         StrToFloatWD(CurrElement.GetAttribute('y'), fGroup.InitialPosition.Y),
                                         StrToFloatWD(CurrElement.GetAttribute('z'), fGroup.InitialPosition.Z));
        fGroup.OriginalPosition := fGroup.InitialPosition;
        end
      else if CurrElement.TagName = 'positionvar' then
        begin
        fGroup.PositionVariance := Vector(StrToFloatWD(CurrElement.GetAttribute('x'), fGroup.PositionVariance.X),
                                          StrToFloatWD(CurrElement.GetAttribute('y'), fGroup.PositionVariance.Y),
                                          StrToFloatWD(CurrElement.GetAttribute('z'), fGroup.PositionVariance.Z));
        fGroup.OriginalVariance := fGroup.PositionVariance;
        end
      else if CurrElement.TagName = 'rotation' then
        begin
        fGroup.InitialRotation := StrToFloatWD(CurrElement.GetAttribute('value'), fGroup.InitialRotation);
        fGroup.RotationVariance := StrToFloatWD(CurrElement.GetAttribute('variance'), fGroup.RotationVariance);
        end
      else if CurrElement.TagName = 'spin' then
        begin
        fGroup.InitialSpin := StrToFloatWD(CurrElement.GetAttribute('value'), fGroup.InitialSpin);
        fGroup.SpinVariance := StrToFloatWD(CurrElement.GetAttribute('variance'), fGroup.SpinVariance);
        fGroup.SpinExponent := StrToFloatWD(CurrElement.GetAttribute('exponent'), fGroup.SpinExponent);
        end;
      CurrElement := TDOMElement(CurrElement.NextSibling);
      end;
    Doc.Free;
    end;
  if fMaterialResourceName = '' then
    DepLoaded('', nil, nil)
  else
    begin
    EventManager.AddCallback('TResource.FinishedLoading:' + fMaterialResourceName, @DepLoaded);
    fMaterialResource := TMaterialResource.Get(fMaterialResourceName);
    end;
end;

procedure TParticleResource.DepLoaded(Event: String; Data, Result: Pointer);
begin
  fGroup.Material := fMaterialResource.Material;
  FinishedLoading := True;
end;

procedure TParticleResource.Free;
begin
  fGroup.Free;
  inherited Free;
end;

end.