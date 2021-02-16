unit Unit1;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,math,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, DSE_theater, Vcl.ExtCtrls, Vcl.StdCtrls, Generics.Collections ,Generics.Defaults, DSE_Bitmap,
  DSE_ThreadTimer;

type
  TForm1 = class(TForm)
    SE_Theater1: SE_Theater;
    Panel1: TPanel;
    Label1: TLabel;
    CheckBox1: TCheckBox;
    CheckBox2: TCheckBox;
    Edit1: TEdit;
    Panel2: TPanel;
    Label2: TLabel;
    CheckBox3: TCheckBox;
    CheckBox4: TCheckBox;
    Edit2: TEdit;
    Button1: TButton;
    SE_Background: SE_Engine;
    SE_Characters: SE_Engine;
    Memo1: TMemo;
    CheckBox5: TCheckBox;
    procedure FormCreate(Sender: TObject);
    procedure CheckBox1Click(Sender: TObject);
    procedure CheckBox2Click(Sender: TObject);
    procedure CheckBox3Click(Sender: TObject);
    procedure CheckBox4Click(Sender: TObject);
    procedure Edit2Change(Sender: TObject);
    procedure Edit1Change(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure SE_CharactersCollision(Sender: TObject; Sprite1, Sprite2: SE_Sprite);
    procedure SE_CharactersSpriteDestinationReached(ASprite: SE_Sprite);
    procedure CheckBox5Click(Sender: TObject);
    procedure SE_Theater1MouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

procedure TForm1.FormCreate(Sender: TObject);
var
  Background,SpriteTree: SE_Sprite;
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


  SE_Characters.CreateSprite('..\!media\gabriel_WALK.bmp' ,'gabriel',{framesX}15,{framesY}6,{Delay}7,{X}100,{Y}100,{transparent}true,1);
  SE_Characters.CreateSprite('..\!media\shahira_WALK.bmp','shahira',{framesX}15,{framesY}6,{Delay}7,{X}500,{Y}100,{transparent}true,1);

  SpriteTree := SE_Characters.CreateSprite('..\!media\tree.bmp','tree',{framesX}2,{framesY}1,{Delay}5,{X}250,{Y}250,{transparent}true,1);
  SpriteTree.ModPriority := 170;

  SE_Characters.CreateSprite('..\!media\barrel.bmp','barrel',{framesX}1,{framesY}1,{Delay}2000,{X}500,{Y}300,{transparent}true,1);

  Randomize;

end;

procedure TForm1.SE_CharactersCollision(Sender: TObject; Sprite1, Sprite2: SE_Sprite);

begin
  memo1.Lines.Add( 'Collision ' + Sprite1.Guid + ' ' + Sprite2.guid );
  if ((Sprite1.guid= 'spell') and (Sprite2.guid = 'shahira' )) or ((Sprite1.guid= 'shahira') and (Sprite2.guid = 'spell' )) then begin

      if (Sprite1.LifeSpan = 0) and (Sprite1.Guid='spell') then Sprite1.LifeSpan := 10;
      if (Sprite2.LifeSpan = 0) and (Sprite2.Guid='spell') then Sprite2.LifeSpan := 10;
      if Sprite1.Guid = 'shahira' then Sprite1.DieAtEndX := True;
      if Sprite2.Guid = 'shahira' then Sprite2.DieAtEndX := True;
      if (Pos( 'shahira' , Sprite1.SpriteFileName, 1)  <> 0)  and (Pos( 'dead' , Sprite1.SpriteFileName, 1)  = 0) then
        Sprite1.ChangeBitmap('..\!media\shahira_dead.bmp', {framesX}15,{framesY}6,{Delay}5);
      if (Pos( 'shahira' , Sprite2.SpriteFileName, 1)  <> 0)  and (Pos( 'dead' , Sprite2.SpriteFileName, 1)  = 0) then
        Sprite2.ChangeBitmap('..\!media\shahira_dead.bmp', {framesX}15,{framesY}6,{Delay}5);
  end;

end;

procedure TForm1.SE_CharactersSpriteDestinationReached(ASprite: SE_Sprite);
begin
  if aSprite.guid= 'spell' then
      if aSprite.LifeSpan = 0 then aSprite.LifeSpan := 10;

end;

procedure TForm1.SE_Theater1MouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  //SE_Theater1.Angle:= SE_Theater1.Angle+1;

end;

procedure TForm1.Button1Click(Sender: TObject);
var
  SpriteGabriel, SpriteShahira, SpriteSpell: SE_Sprite;
begin
   SpriteShahira := SE_Characters.FindSprite('shahira');
   if SpriteShahira = nil then
     SE_Characters.CreateSprite('..\!media\shahira_WALK.bmp','shahira',{framesX}15,{framesY}6,{Delay}7,{X}500,{Y}100,{transparent}true,1);

   SpriteGabriel:= SE_Characters.FindSprite('gabriel');
   SpriteShahira:= SE_Characters.FindSprite('shahira');

   SpriteGabriel.ChangeBitmap('..\!media\gabriel_attack.bmp' ,{framesX}8,{framesY}6,{Delay}5);
   SpriteGabriel.StopAtEndX := True;
   SpriteGabriel.FrameY := 3;
   SpriteGabriel.FrameX := 1;

   SpriteSpell := SE_Characters.CreateSprite('..\!media\spell.bmp' ,'spell',{framesX}9,{framesY}1,{Delay}5,
   {X}SpriteGabriel.Position.X ,{Y}SpriteGabriel.Position.Y,{transparent}true,2);

   SpriteSpell.MoverData.Speed := 4.0;
   SpriteSpell.MoverData.Destination := SpriteShahira.Position ;
   SpriteSpell.NotifyDestinationReached := true;
end;

procedure TForm1.CheckBox1Click(Sender: TObject);
begin
  SE_Theater1.MousePan := checkBox1.Checked ;
end;

procedure TForm1.CheckBox2Click(Sender: TObject);
begin
  SE_Theater1.MouseScroll := checkBox2.Checked ;

end;

procedure TForm1.CheckBox3Click(Sender: TObject);
begin
  SE_Theater1.MouseWheelZoom  :=  checkBox3.Checked ;
end;

procedure TForm1.CheckBox4Click(Sender: TObject);
begin
  SE_Theater1.MouseWheelInvert  := checkBox4.Checked ;
end;

procedure TForm1.CheckBox5Click(Sender: TObject);
begin
  SE_Characters.PixelCollision := CheckBox5.Checked ;
end;

procedure TForm1.Edit1Change(Sender: TObject);
begin
  SE_Theater1.MouseScrollRate  := StrToFloatDef ( edit1.Text ,0 );

end;

procedure TForm1.Edit2Change(Sender: TObject);
begin
  SE_Theater1.MouseWheelValue  := StrToIntDef ( edit2.Text ,0 );

end;

end.
