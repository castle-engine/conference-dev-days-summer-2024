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
    MainViewport: TCastleViewport;
    MissileShooter: TCastleTransform;
    Player: TCastleTransform; //: TCastleScene
    Enemy1, Enemy2, Enemy3: TCastleScene;
    EnemyRigidBody1, EnemyRigidBody2, EnemyRigidBody3: TCastleRigidBody;
  private
    MissileFactory: TCastleComponentFactory;
    Timer: TCastleTimer;
    procedure DoTimer(Sender: TObject);
    procedure SkeletonCollides(const CollisionDetails: TPhysicsCollisionDetails);
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

{ TEnemyWalk ---------------------------------------------------------------- }

type
  TEnemyWalk = class(TCastleBehavior)
    procedure Update(const SecondsPassed: Single; var RemoveMe: TRemoveType); override;
  end;

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

{ TViewPlay ----------------------------------------------------------------- }

constructor TViewPlay.Create(AOwner: TComponent);
begin
  inherited;
  DesignUrl := 'castle-data:/gameviewplay.castle-user-interface';
end;

type
  { Helper class to access the MainRigidBody component of a spawned missile. }
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

procedure TViewPlay.SkeletonCollides(
  const CollisionDetails: TPhysicsCollisionDetails);
var
  Enemy: TCastleScene;
  EnemyRigidBody: TCastleRigidBody;
  WalkBehavior: TEnemyWalk;
begin
  Enemy := CollisionDetails.Transforms[0] as TCastleScene;
  Enemy.PlayAnimation('Death', false);

  EnemyRigidBody := Enemy.FindBehavior(TCastleRigidBody) as TCastleRigidBody;
  EnemyRigidBody.Exists := false;

  WalkBehavior := Enemy.FindBehavior(TEnemyWalk) as TEnemyWalk;
  if WalkBehavior <> nil then
    Enemy.RemoveBehavior(WalkBehavior);
end;

procedure TViewPlay.Start;
begin
  inherited;

  Timer := TCastleTimer.Create(FreeAtStop);
  Timer.IntervalSeconds := 0.25;
  Timer.OnTimer := {$ifdef FPC}@{$endif} DoTimer;
  InsertFront(Timer);

  MissileFactory := TCastleComponentFactory.Create(FreeAtStop);
  MissileFactory.Url := 'castle-data:/misssile.castle-transform';

  EnemyRigidBody1.OnCollisionEnter := {$ifdef FPC}@{$endif} SkeletonCollides;
  EnemyRigidBody2.OnCollisionEnter := {$ifdef FPC}@{$endif} SkeletonCollides;
  EnemyRigidBody3.OnCollisionEnter := {$ifdef FPC}@{$endif} SkeletonCollides;

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

end.
