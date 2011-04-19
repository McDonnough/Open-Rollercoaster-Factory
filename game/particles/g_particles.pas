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
  Main;

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
      CurrentGroup.Free;
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
      CurrentGroup.Group.AdvanceGroup(FPSDisplay.MS)
    else
      CurrentGroup.Free;

    CurrentGroup := NextGroup;
    end;
end;

constructor TParticleManager.Create;
begin
  fEmitters := TParticleGroupList.Create;
end;

destructor TParticleManager.Free;
begin
  fEmitters.Free;
end;

end.