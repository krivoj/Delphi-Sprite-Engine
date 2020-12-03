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
  procedure Rectangle ( Name:string;X,Y,W,H: integer );
  end;

var
  Form1: TForm1;
  prince2,aFrame,SpriteResult,SpriteTest: SE_Sprite;
  index: Integer;
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

  prince2:= SE_Engine1.CreateSprite('..\!media\prince2.bmp','prince2',{framesX}1,{framesY}1,{Delay}0,{X}SE_theater1.Width div 2,{Y}SE_theater1.Height div 2,{transparent}false,0);


  SE_Theater1.Active := True;

  bmp:= SE_Bitmap.Create(20*5,41);
  bmp.Bitmap.Canvas.Brush.Color := $00ff00;//clBlue;
  bmp.Bitmap.Canvas.FillRect( Rect(0,0,bmp.Width,bmp.Height));
  SpriteResult := SE_Engine1.CreateSprite(bmp.Bitmap,'bmpresult',{framesX}1,{framesY}1,{Delay}300,{X}SE_theater1.Width div 2,{Y}20,{transparent}false,0);
  bmp.Free;

  index :=0;
  Rectangle ('turn',5,0,13,41);
  inc(Index);
  Rectangle ('turn',20,0,13,41);
  inc(Index);
  Rectangle ('turn',35,0,14,41);
  inc(Index);
  Rectangle ('turn',50,0,17,41);
  inc(Index);
  Rectangle ('turn',68,0,20,41);
  inc(Index);

  SpriteResult := SE_Engine1.CreateSprite(SpriteResult.BMP.Bitmap,'bmpresult',{framesX}5,{framesY}1,{Delay}120,{X}SE_theater1.Width div 2,{Y}90,{transparent}true,0);

end;
procedure TForm1.Rectangle ( Name:string; X,Y,W,H: integer );
var
  bmp: SE_Bitmap;
begin
  prince2.BMP.CopyRectTo(SpriteResult.bmp,X,Y,(20*index) + ((20 - W) div 2),0,W+1,H+1,False,0);


  bmp:= SE_Bitmap.Create(W,H);
  prince2.BMP.CopyRectTo(bmp,X,Y,0,0,W,H,False,0);
  aFrame:= SE_Engine1.CreateSprite(bmp.Bitmap,Name,{framesX}1,{framesY}1,{Delay}0,{X}X+W,{Y}20,{transparent}false,0);
  bmp.Free;



//  prince2.BMP.Canvas.MoveTo(X,Y);
//  prince2.BMP.Canvas.LineTo(X+W,Y);
//  prince2.BMP.Canvas.LineTo(X+W,Y+H);
//  prince2.BMP.Canvas.LineTo(X,Y+H);
//  prince2.BMP.Canvas.LineTo(X,Y);


  //aFrame.ChangeBitmap(bmp.Bitmap,1,1,1);


end;
end.
