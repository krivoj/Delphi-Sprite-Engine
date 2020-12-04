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
  private
    { Private declarations }
  public
    { Public declarations }
  procedure Rectangle ( Name:string;X,Y,W,H,FrameY: integer );
  procedure CropTurn;
  procedure CropTurnRunning;
 end;

var
  Form1: TForm1;
  prince2,aFrame,SpriteResult,SpriteTest: SE_Sprite;
  index: Integer;
  FrameCount : array [0..1] of Integer;
const
  FrameWidth = 32;
  FrameHeight = 40;
  ANIM_Y_TURN = 0;
  ANIM_Y_TURNRUNNING = 1;

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
  bmp:= SE_Bitmap.Create(FrameWidth*9,FrameHeight*2);
  bmp.Bitmap.Canvas.Brush.Color := $00ff00;//clBlue;
  bmp.Bitmap.Canvas.FillRect( Rect(0,0,bmp.Width,bmp.Height));
  SpriteResult := SE_Engine1.CreateSprite(bmp.Bitmap,'bmpresult',{framesX}1,{framesY}1,{Delay}2000,{X}(SE_theater1.Width div 2)+280,{Y}SE_theater1.Height div 2,{transparent}false,0);
  bmp.Free;

  CropTurn;
  FrameCount [ANIM_Y_TURN] := 9;
  CropTurnRunning;
  FrameCount [ANIM_Y_TURNRUNNING] := 9;

  //debug
  SE_engine1.RemoveAllSprites('turn.');




  SpriteTest := SE_Engine1.CreateSprite(SpriteResult.BMP.Bitmap,'bmpanim',{framesX}9,{framesY}2,{Delay}120,{X}SE_theater1.Width div 2,{Y}90,{transparent}true,0);
  SpriteTest.BMP.Bitmap.SaveToFile('..\!media\princeSheet.bmp'  );

end;
procedure TForm1.Rectangle ( Name:string; X,Y,W,H,FrameY: integer );
var
  bmp: SE_Bitmap;
begin
  prince2.BMP.CopyRectTo(SpriteResult.bmp,X,Y,(FrameWidth*index) + ((FrameWidth - W) div 2),FrameY*FrameHeight,W,H,False,0);


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
  Rectangle ('turnrunning.3',270,1,14,FrameHeight,1);    { TODO : continuare qui }
  inc(Index);
  Rectangle ('turnrunning.4',280,1,16,FrameHeight,1);
  inc(Index);
  Rectangle ('turnrunning.5',290,1,20,FrameHeight,1);
  inc(Index);
  Rectangle ('turnrunning.6',320,1,22,FrameHeight,1);
  inc(Index);
  Rectangle ('turnrunning.7',340,1,18,FrameHeight,1);
  inc(Index);
  Rectangle ('turnrunning.8',300,1,17,FrameHeight,1);
  inc(Index);
  Rectangle ('turnrunning.9',320,1,16,FrameHeight,1);
  inc(Index);

end;

end.
