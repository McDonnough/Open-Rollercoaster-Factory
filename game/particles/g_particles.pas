unit g_particles;

interface

uses
  SysUtils, Classes, u_particles, u_linkedlists;

type
  TParticleGroupList = TLinkedList;

  TParticleGroupItem = class(TLinkedListItem)
    protected
      fGroup: TParticleGroup;
    public
      property Group: TParticleGroup read fGroup;
      constructor Create(TheGroup: TParticleGroup);
      procedure Free;
    end;

  TParticleManager = class
    protected
      fEmitters: TParticleGroupList;
    public
      property Emitters: TParticleGroupList read fEmitters;
      procedure Add(Group: TParticleGroup);
      procedure Delete(Group: TParticleGroup);
      procedure Advance;
      constructor Create;
      destructor Free;
    end;

implementation

uses
  Main, m_texmng_class, u_math, u_vectors, u_scene, u_events;

constructor TParticleGroupItem.Create(TheGroup: TParticleGroup);
begin
  inherited Create;
  fGroup := TheGroup;
end;

procedure TParticleGroupItem.Free;
begin
  Group.Free;
  inherited Free;
end;

procedure TParticleManager.Add(Group: TParticleGroup);
begin
  Emitters.Append(TParticleGroupItem.Create(Group));
  EventManager.CallEvent('TParticleManager.AddGroup', Group, nil);
end;

procedure TParticleManager.Delete(Group: TParticleGroup);
var
  CurrentGroup, NextGroup: TParticleGroupItem;
begin
  CurrentGroup := TParticleGroupItem(Emitters.First);
  while CurrentGroup <> nil do
    begin
    NextGroup := TParticleGroupItem(CurrentGroup.Next);
    if CurrentGroup.Group = Group then
      CurrentGroup.Group.Running := False;
    CurrentGroup := NextGroup;
    end;
end;

procedure TParticleManager.Advance;
var
  CurrentGroup, NextGroup: TParticleGroupItem;
begin
  CurrentGroup := TParticleGroupItem(Emitters.First);
  while CurrentGroup <> nil do
    begin
    NextGroup := TParticleGroupItem(CurrentGroup.Next);

    if (CurrentGroup.Group.Running) or (not CurrentGroup.Group.IsEmpty) then
      CurrentGroup.Group.AdvanceGroup(0.001 * FPSDisplay.MS)
    else
      begin
      EventManager.CallEvent('TParticleManager.DeleteGroup', CurrentGroup.Group, nil);
      CurrentGroup.Free;
      end;

    CurrentGroup := NextGroup;
    end;
end;

constructor TParticleManager.Create;
var
  A: TParticleGroup;
begin
  writeln('Hint: Creating ParticleManager object');
  fEmitters := TParticleGroupList.Create;
end;

destructor TParticleManager.Free;
begin
  writeln('Hint: Deleting ParticleManager object');
  fEmitters.Free;
end;

end.