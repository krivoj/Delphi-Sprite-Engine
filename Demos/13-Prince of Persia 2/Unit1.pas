unit Unit1;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,math,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, DSE_theater, Vcl.ExtCtrls, Vcl.StdCtrls, Generics.Collections ,Generics.Defaults, DSE_Bitmap,
  DSE_ThreadTimer;

type
  TForm1 = class(TForm)
    SE_Theater1: SE_Theater;
    SE_Background: SE_Engine;
    SE_Engine1: SE_Engine;
    procedure FormCreate(Sender: TObject);
    procedure SE_Theater1AfterVisibleRender(Sender: TObject; VirtualBitmap, VisibleBitmap: SE_Bitmap);
  private
    { Private declarations }
  public
    { Public declarations }
  procedure Rectangle ( Name:string;X,Y,W,H,FrameY: integer );
  procedure CropTurn;
  procedure CropTurnRunning;
  procedure CropBrake;
  procedure CropRun;
 end;

var
  Form1: TForm1;
  prince2,aFrame,SpriteResult,SpriteTest: SE_Sprite;
  index: Integer;
  FrameCount : array [0..3] of Integer;
const
  FrameWidth = 34;
  FrameHeight = 40;
  ANIM_Y_TURN = 0;
  ANIM_Y_TURNRUNNING = 1;
  ANIM_Y_BRAKE = 2;
  ANIM_Y_RUN = 3;

implementation

{$R *.dfm}

procedure TForm1.FormCreate(Sender: TObject);
var
  bmp: SE_Bitmap;
begin

  SE_Theater1.VirtualWidth := 1024;
  SE_Theater1.VirtualHeight := 800;
  SE_Theater1.Width := 1024;
  SE_Theater1.Height := 800;

  SE_Background.Priority := 0;
  SE_Engine1.Priority := 1;

  bmp:= SE_Bitmap.Create(SE_Theater1.VirtualWidth,SE_Theater1.VirtualHeight);
  bmp.Bitmap.Canvas.Brush.Color := clGray;
  bmp.Bitmap.Canvas.FillRect( Rect(0,0,SE_Theater1.VirtualWidth,SE_Theater1.VirtualHeight));
  SE_Background.CreateSprite(bmp.Bitmap,'back',{framesX}1,{framesY}1,{Delay}0,{X}SE_theater1.Width div 2,{Y}SE_theater1.Height div 2,{transparent}false,0);
  bmp.Free;

  prince2:= SE_Engine1.CreateSprite('..\!media\prince2.bmp','prince2',{framesX}1,{framesY}1,{Delay}0,{X}(SE_theater1.Width div 2)-200,{Y}SE_theater1.Height div 2,{transparent}false,0);


  SE_Theater1.Active := True;


  // questo è il RESULT
  bmp:= SE_Bitmap.Create(FrameWidth*13,FrameHeight*4);
  bmp.Bitmap.Canvas.Brush.Color := $00ff00;//clBlue;
  bmp.Bitmap.Canvas.FillRect( Rect(0,0,bmp.Width,bmp.Height));
  SpriteResult := SE_Engine1.CreateSprite(bmp.Bitmap,'bmpresult',{framesX}1,{framesY}1,{Delay}2000,{X}(SE_theater1.Width div 2)+320,{Y}SE_theater1.Height div 2,{transparent}false,0);
  bmp.Free;

  CropTurn;
  FrameCount [ANIM_Y_TURN] := 9;

  CropTurnRunning;
  FrameCount [ANIM_Y_TURNRUNNING] := 9;

  CropBrake;
  FrameCount [ANIM_Y_BRAKE] := 8;

 // CropRun;
  FrameCount [ANIM_Y_RUN] := 13;

  //debug
  SE_engine1.RemoveAllSprites('turn.');
  SE_engine1.RemoveAllSprites('turnrunning.');




  SpriteTest := SE_Engine1.CreateSprite(SpriteResult.BMP.Bitmap,'bmpanim',{framesX}13,{framesY}4,{Delay}120,{X}SE_theater1.Width div 2,{Y}90,{transparent}true,0);
  SpriteTest.BMP.Bitmap.SaveToFile('..\!media\princeSheet.bmp'  );
  SpriteTest.FrameXmax := 8;
  SpriteTest.FrameY:= ANIM_Y_TURNRUNNING;
  //SpriteTest

end;
procedure TForm1.Rectangle ( Name:string; X,Y,W,H,FrameY: integer );
var
  bmp: SE_Bitmap;
begin
  prince2.BMP.CopyRectTo(SpriteResult.bmp,X,Y,(FrameWidth*index) + ((FrameWidth - W) div 2),(FrameY)*FrameHeight,W,H,False,0);


  // singolo frame
  bmp:= SE_Bitmap.Create(W,H);
  prince2.BMP.CopyRectTo(bmp,X,Y,0,0,W,H,False,0);
  aFrame:= SE_Engine1.CreateSprite(bmp.Bitmap,Name,{framesX}1,{framesY}1,{Delay}0,{X}(Index*10)+X+W,{Y}20,{transparent}false,0);
  SE_Engine1.ProcessSprites(2000);
  bmp.Free;

//  prince2.BMP.Canvas.MoveTo(X,Y);
//  prince2.BMP.Canvas.LineTo(X+W,Y);
//  prince2.BMP.Canvas.LineTo(X+W,Y+H);
//  prince2.BMP.Canvas.LineTo(X,Y+H);
//  prince2.BMP.Canvas.LineTo(X,Y);
//aFrame.ChangeBitmap(bmp.Bitmap,1,1,1);


end;
procedure TForm1.SE_Theater1AfterVisibleRender(Sender: TObject; VirtualBitmap, VisibleBitmap: SE_Bitmap);
begin
  if GetAsyncKeyState (VK_LEFT) < 0 then begin
//    SpriteTest.Angle := Ship.Angle - 10;

  end;
  if GetAsyncKeyState (VK_RIGHT) < 0 then  begin
 //   SpriteTest.Angle := Ship.Angle + 10;
  end;

  if GetAsyncKeyState (VK_UP) < 0 then begin
//    SpriteTest.MoverData.MoveModeThrust_Thrust := 0.3;
  end
  else begin
 //   SpriteTest.MoverData.MoveModeThrust_Thrust := 0;
  end;

end;

procedure TForm1.CropTurn;
begin

  index :=0;
  Rectangle ('turn.1',5,1,13,FrameHeight,0);
  inc(Index);
  Rectangle ('turn.2',20,1,13,FrameHeight,0);
  inc(Index);
  Rectangle ('turn.3',35,1,14,FrameHeight,0);
  inc(Index);
  Rectangle ('turn.4',51,1,16,FrameHeight,0);
  inc(Index);
  Rectangle ('turn.5',67,1,20,FrameHeight,0);
  inc(Index);
  Rectangle ('turn.6',87,1,22,FrameHeight,0);
  inc(Index);
  Rectangle ('turn.7',111,1,18,FrameHeight,0);
  inc(Index);
  Rectangle ('turn.8',129,1,17,FrameHeight,0);
  inc(Index);
  Rectangle ('turn.9',148,1,16,FrameHeight,0);
  inc(Index);

end;
procedure TForm1.CropTurnRunning;
begin
  index :=0;
  Rectangle ('turnrunning.1',179,1,29,FrameHeight,1);
  inc(Index);
  Rectangle ('turnrunning.2',207,1,28,FrameHeight,1);
  inc(Index);
  Rectangle ('turnrunning.3',234,1,30,FrameHeight,1);
  inc(Index);
  Rectangle ('turnrunning.4',264,1,28,FrameHeight,1);
  inc(Index);
  Rectangle ('turnrunning.5',292,1,33,FrameHeight,1);
  inc(Index);
  Rectangle ('turnrunning.6',326,1,33,FrameHeight,1);
  inc(Index);
  Rectangle ('turnrunning.7',359,1,29,FrameHeight,1);
  inc(Index);
  Rectangle ('turnrunning.8',388,1,24,FrameHeight,1);
  inc(Index);
  Rectangle ('turnrunning.9',413,1,26,FrameHeight,1);
  inc(Index);

end;
procedure TForm1.CropBrake;
begin

  index :=0;
  Rectangle ('brake.1',2,44,29,FrameHeight,2);
  inc(Index);
  Rectangle ('brake.2',36,44,21,FrameHeight,2);
  inc(Index);
  Rectangle ('brake.3',56,44,37,FrameHeight,2);
  inc(Index);
  Rectangle ('brake.4',96,44,27,FrameHeight,2);
  inc(Index);
  Rectangle ('brake.5',167,44,20,FrameHeight,2);
  inc(Index);
  Rectangle ('brake.6',187,44,22,FrameHeight,2);
  inc(Index);
  Rectangle ('brake.7',191,44,18,FrameHeight,2);
  inc(Index);
  Rectangle ('brake.8',200,44,17,FrameHeight,2);
  inc(Index);

end;
procedure TForm1.CropRun;
begin

  index :=0;
  Rectangle ('run.1',5,1,13,FrameHeight,3);
  inc(Index);
  Rectangle ('run.2',20,1,13,FrameHeight,3);
  inc(Index);
  Rectangle ('run.3',35,1,14,FrameHeight,3);
  inc(Index);
  Rectangle ('run.4',51,1,16,FrameHeight,3);
  inc(Index);
  Rectangle ('run.5',67,1,20,FrameHeight,3);
  inc(Index);
  Rectangle ('run.6',87,1,22,FrameHeight,3);
  inc(Index);
  Rectangle ('run.7',111,1,18,FrameHeight,3);
  inc(Index);
  Rectangle ('run.8',129,1,17,FrameHeight,3);
  inc(Index);
  Rectangle ('run.9',129,1,17,FrameHeight,3);
  inc(Index);
  Rectangle ('run.10',129,1,17,FrameHeight,3);
  inc(Index);
  Rectangle ('run.11',129,1,17,FrameHeight,3);
  inc(Index);
  Rectangle ('run.12',129,1,17,FrameHeight,3);
  inc(Index);
  Rectangle ('run.13',129,1,17,FrameHeight,3);
  inc(Index);

end;

end.
