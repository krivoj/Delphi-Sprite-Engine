unit Unit1;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, DSE_theater, Vcl.ExtCtrls, Vcl.StdCtrls, Generics.Collections ,Generics.Defaults;

type
  TForm1 = class(TForm)
    SE_Theater1: SE_Theater;
    SE_Background: SE_Engine;
    SE_Characters: SE_Engine;
    Button1: TButton;
    procedure FormCreate(Sender: TObject);
    procedure Button1Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
  aSpriteProgressBar: SE_SpriteProgressBar;
implementation

{$R *.dfm}

procedure TForm1.FormCreate(Sender: TObject);
var
  Background: SE_Sprite;
begin

  SE_Theater1.VirtualWidth := 1920;
  SE_Theater1.VirtualHeight := 1200;
  SE_Theater1.Width := 1024;
  SE_Theater1.Height := 600;

  SE_Background.Priority := 0;
  SE_Characters.Priority := 1;


  Background:= SE_Background.CreateSprite('..\!media\back1.bmp','background',{framesX}1,{framesY}1,{Delay}0,{X}0,{Y}0,{transparent}false,0);
  Background.Position := Point( Background.FrameWidth div 2 , Background.FrameHeight div 2 );

  SE_Theater1.Active := True;

  SE_Characters.CreateSprite('..\!media\gabriel_IDLE.1.bmp','gabriel',{framesX}15,{framesY}1,{Delay}5,{X}100,{Y}100,{transparent}true,1);
  SE_Characters.CreateSprite('..\!media\shahira_IDLE.1.bmp','shahira',{framesX}15,{framesY}1,{Delay}5,{X}200,{Y}100,{transparent}true,1);

  aSpriteProgressBar:= SE_Characters.CreateSpriteProgressBar('myprogressbar',200,200,300,32,'Calibri',clWhite-1,clRed,clBlue,14,'50', 50,true ,10);
  aSpriteProgressBar.pbHAlignment := dt_XRight;

end;

procedure TForm1.Button1Click(Sender: TObject);
var
  aRnd :  Integer;
begin
  aRnd := Random(100 );
  aSpriteProgressBar.Value := aRnd;
  aSpriteProgressBar.Text := IntToStr(aRnd);
end;

end.
