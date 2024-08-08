{
  Copyright 2024-2024 Michalis Kamburelis.
  This file is part of "Demo game made during Dev Days of Summer 2024".
  It is free software, see LICENSE in this repo.
  ----------------------------------------------------------------------------
}

{ The main game logic. }
unit GameViewPlay;

interface

uses Classes,
  CastleVectors, CastleUIControls, CastleControls, CastleKeysMouse,
  CastleComponentSerialize, CastleViewport, CastleTransform, CastleScene;

type
  TViewPlay = class(TCastleView)
  published
    { Components designed using CGE editor.
      These fields will be automatically initialized at Start. }
    // ButtonXxx: TCastleButton;
    MainViewport: TCastleViewport;
    MissileShooter: TCastleTransform;
    Player: TCastleTransform; //: TCastleScene
    Enemy1, Enemy2, Enemy3: TCastleScene;
    EnemyRigidBody1, EnemyRigidBody2, EnemyRigidBody3: TCastleRigidBody;
  private
    MissileFactory: TCastleComponentFactory;
    Timer: TCastleTimer;
    procedure DoTimer(Sender: TObject);
    procedure Skeleton1Collides(const CollisionDetails: TPhysicsCollisionDetails);
    procedure Skeleton2Collides(const CollisionDetails: TPhysicsCollisionDetails);
    procedure Skeleton3Collides(const CollisionDetails: TPhysicsCollisionDetails);
  public
    constructor Create(AOwner: TComponent); override;
    procedure Start; override;
    procedure Update(const SecondsPassed: Single; var HandleInput: boolean); override;
  end;

var
  ViewPlay: TViewPlay;

implementation

uses SysUtils,
  CastleBehaviors;

type
  TEnemyWalk = class(TCastleBehavior)
    procedure Update(const SecondsPassed: Single; var RemoveMe: TRemoveType); override;
  end;

constructor TViewPlay.Create(AOwner: TComponent);
begin
  inherited;
  DesignUrl := 'castle-data:/gameviewplay.castle-user-interface';
end;

type
  TMissileDesign = class(TPersistent)
  published
    MainRigidBody: TCastleRigidBody;
  end;

procedure TViewPlay.DoTimer(Sender: TObject);
var
  MissileDesign: TMissileDesign;
  Missile: TCastleTransform;
  InitialDir: TVector3;
begin
  MissileDesign := TMissileDesign.Create;
  try
    Missile := MissileFactory.ComponentLoad(FreeAtStop, MissileDesign) as TCastleTransform;

    MainViewport.Items.Add(Missile);

    Missile.Translation := MissileShooter.WorldTranslation;
    InitialDir := MissileShooter.LocalToWorldDirection(Vector3(0, 0, 1));

    MissileDesign.MainRigidBody.LinearVelocity := InitialDir * 50;
  finally FreeAndNil(MissileDesign); end;
end;

procedure TViewPlay.Skeleton1Collides(
  const CollisionDetails: TPhysicsCollisionDetails);
var
  Walk: TEnemyWalk;
begin
  Enemy1.PlayAnimation('Death', false);
  EnemyRigidBody1.Exists := false;
  Walk := Enemy1.FindBehavior(TEnemyWalk) as TEnemyWalk;
  if Walk <> nil then
    Enemy1.RemoveBehavior(Walk);
end;

procedure TViewPlay.Skeleton2Collides(
  const CollisionDetails: TPhysicsCollisionDetails);
var
  Walk: TEnemyWalk;
begin
  Enemy2.PlayAnimation('Death', false);
  EnemyRigidBody2.Exists := false;
  Walk := Enemy2.FindBehavior(TEnemyWalk) as TEnemyWalk;
  if Walk <> nil then
    Enemy2.RemoveBehavior(Walk);
end;

procedure TViewPlay.Skeleton3Collides(
  const CollisionDetails: TPhysicsCollisionDetails);
var
  Walk: TEnemyWalk;
begin
  Enemy3.PlayAnimation('Death', false);
  EnemyRigidBody3.Exists := false;
  Walk := Enemy3.FindBehavior(TEnemyWalk) as TEnemyWalk;
  if Walk <> nil then
    Enemy3.RemoveBehavior(Walk);
end;

procedure TViewPlay.Start;
begin
  inherited;

  Timer := TCastleTimer.Create(FreeAtStop);
  Timer.IntervalSeconds := 0.25;
  Timer.OnTimer := DoTimer;
  InsertFront(Timer);

  MissileFactory := TCastleComponentFactory.Create(FreeAtStop);
  MissileFactory.Url := 'castle-data:/misssile.castle-transform';

  EnemyRigidBody1.OnCollisionEnter := Skeleton1Collides;
  EnemyRigidBody2.OnCollisionEnter := Skeleton2Collides;
  EnemyRigidBody3.OnCollisionEnter := Skeleton3Collides;

  Enemy1.AddBehavior(TEnemyWalk.Create(FreeAtStop));
  Enemy2.AddBehavior(TEnemyWalk.Create(FreeAtStop));
  Enemy3.AddBehavior(TEnemyWalk.Create(FreeAtStop));
end;

procedure TViewPlay.Update(const SecondsPassed: Single; var HandleInput: boolean);
const
  MoveSpeed = 5.0;
begin
  inherited;
  if Container.Pressed[keyArrowLeft] then
    Player.Translation := Player.Translation - Vector3(MoveSpeed * SecondsPassed, 0, 0);
  if Container.Pressed[keyArrowRight] then
    Player.Translation := Player.Translation + Vector3(MoveSpeed * SecondsPassed, 0, 0);
end;

{ TEnemyWalk }

procedure TEnemyWalk.Update(const SecondsPassed: Single;
  var RemoveMe: TRemoveType);
begin
  inherited;
  Parent.Translation := Parent.Translation + Vector3(2.5 * SecondsPassed, 0, 0);

  if Parent.Translation.X > 2 then
    Parent.Translation := Vector3(
      -5,
      Parent.Translation.Y,
      Parent.Translation.Z);
end;

end.
