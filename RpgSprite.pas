
unit RPGsprite;

interface

uses
  Windows, Messages, System.SysUtils, System.Classes, Graphics, Controls, Forms, Dialogs, dse_list,
  StdCtrls, ExtCtrls, dse_theater, dse_Bitmap,dse_defs, strUtils, inifiles, dse_misc,Generics.Collections ,Generics.Defaults ;

type TSpriteCategory = ( cPlayer, cNpc, cItem, cSpell );

type
  TEntitySprite = class( se_Sprite )
  private

    fBmpState: string ;       // casting moving hit
    FIsodirection: string;    // 1,2,3,4,5,6
    FVisibleDead : integer;   // per quanto tempo rimane visibile il cadavere
    FToIdle: Integer;

    (* Behaviour Auras *)
    FAuras: TstringList;      // Elenco di Taura con un limite di 6

    procedure SetBmpState (value:string);
    procedure SetIsoDirection ( const value: string );


  protected


  public
    Category: TSpriteCategory;       // type TSpriteCategory = ( cPlayer, cNpc, cItem, cSpell );
    SpritePriority: integer;         // usata per effetto Iso. Gli sprite più in basso sullo schermo hanno priorità
    Ids: string;                     // Identificativo stringa
    SpriteName : string;             // solo il nome dello sprite senza estensione es. 'albero'
    CharacterName: string;


    CharacterDir : String;           // directory /bmp/char
    AuraDir : string;                //

    Selected: boolean;
    Grouped: boolean;
    Number: integer;
    faction: string;

    Health: integer ;
    CurHealth: integer;
    Power: integer ;
    CurPower: integer ;
    CastBarText: string  ;
    CastBarValue: integer;

    constructor Create(const dir_Sprite,dir_aura, id: string;
                       const posX,posY: integer;
                       const TransparentSprite: boolean ;
                       const aCategory: TSpriteCategory ) ; reintroduce;
    destructor Destroy; override;

    property BmpState: string read fBmpState write SetBmpState;
    property IsoDirection: string read fIsodirection write SetIsoDirection;

    property ToIdle: integer read FtoIdle write FtoIdle;

    procedure VirtualAddAura (source,aura,duration:string);
    procedure VirtualDeleteAura (source,aura:string);

    procedure OverWriteBitmap( );
    procedure iOnDestinationReached ; override;
    procedure Render ( RenderTo: TRenderBitmap); override;
    procedure SetCurrentFrame; override;

  end;

// TSpellSprite deriva da se_Sprite.                                                                                                  |
  // Inizialmente la spell viene visualizzata in fase di casting, di solito posizionata sopra al Tcharacter. Terminato
  // il casting viene caricato con overwritebmp lo spite Moving e questo sprite si sposta da x,y verso il bersaglio.
  // Quando raggiunge x,y del bersaglio lo sprite Moving viene sovrascritto sempre con overwritebmp e
  // lo sprite hit compare alla posizione del bersagio e alla fine dell'animazione viene settato su
  // Dead. Per posizionare gli sprite ci sono comunque tutti i relativi CastingoffsetX, CastingOffsetY ecc...
  // OverwriteBmp viene chiamata ad ogni cambio di BmpState con setState. Bmpstate può essere 'casting' 'moving' hit'
  // in formato stringa proprio per caricare il relativo bmp da file. Questo tipo di gestione è solo un prototipo perchè
  // la gestione degli sprite dipende dal tipo di gioco che si sta creando. Può essere utile caricarli in memoria all'avvio
  // e assegnarli dalla memoria e non dai file ai vari sprite.

  TSpellSprite = class( se_Sprite )
  private

    fBmpState: string ;
    fIsoDirection: string;

    procedure SetBmpState (value:string);
    procedure SetIsoDirection ( const value: string );


  protected

  public
    Category: TSpriteCategory;
    SpritePriority: integer;
    Ids: string;
    SpriteName : string;
    SpellName: string;
    SpellDir : String;


    Origin: string; // TCharacter o System
    ToDead: integer;

    (* Behaviour Display *)
    CastingFramesX: integer;
    CastingFramesY: integer;
    CastingAnimationInterval: integer;
    CastingNotifyDestinationReached: boolean;
    CastingSpritePriority :integer;
    CastingOffsetX : integer;
    CastingOffsetY : integer;

    MovingFramesX: integer;
    MovingFramesY: integer;
    MovingAnimationInterval: integer;
    MovingNotifyDestinationReached: boolean;
    MovingSpritePriority :integer;
    MovingOffsetX : integer;
    MovingOffsetY : integer;

    HitFramesX: integer;
    HitFramesY: integer;
    HitAnimationInterval: integer;
    HitNotifyDestinationReached: boolean;
    HitSpritePriority :integer;
    HitOffsetX : integer;
    HitOffsetY : integer;

    constructor Create( const dir_Sprite, id: string;
                        const posX,posY: integer;
                        const TransparentSprite: boolean ) ; reintroduce;
    destructor Destroy; override;


    property Isodirection: string read fIsoDirection write SetIsoDirection;
    procedure OverWriteBitmap( );
    procedure iOnDestinationReached ; override;
    procedure SetCurrentFrame ; override;
    procedure Render ( RenderTo: TRenderBitmap) ; override;


  end;


type
  TEntitySpriteServer = class( TComponent )
  private
    FEngine: se_Engine;
  protected
  public
    constructor Create( AOwner: TComponent ); override;
    destructor Destroy; override;
    function CreateEntitySprite(const BaseDir, AuraDir, id: string;
                                   const posX, posY: integer;
                                   const Transparent: Boolean ;
                                   Const aCategory: TSpriteCategory ): TEntitySprite;

  published
    property Engine: se_Engine read FEngine write FEngine;
  end;
type
  TSpellSpriteServer = class( TComponent )
  private
    FEngine: se_Engine;
  protected
  public
    constructor Create( AOwner: TComponent ); override;
    destructor Destroy; override;
    function CreateSpellSprite(const BaseDir, id: string;
                               const posX, posY: integer;
                               const Transparent: Boolean ): TSpellSprite;
  published
    property Engine: se_Engine read FEngine write FEngine;
  end;



  function GetIsoDirection (X1,Y1,X2,Y2:integer): string;
  procedure register;
  implementation
procedure register;
begin
    RegisterComponents('DSERPG', [
    TEntitySpriteServer,
    TSpellSpriteServer
    ]);

end;

// Funzioni accessibili dalla unit                                                                                                         |
//-----------------------------------------------------------------------------------------------------------------------------------------}


function GetIsoDirection (X1,Y1,X2,Y2:integer): string;
begin

(*   solo mappe iso cone numeri negativi
    x:= MinWXYZ (X1,Y1,X2,Y2);
    if x < 0 then begin
      x:= abs(x);
      X1:= X1 + x;
      X2:= X2 + x;
      Y1:= Y1 + x;
      Y2:= Y2 + x;
    end;

*)
  if (X2 = X1) and (Y2 = Y1) then Result:='1';

  if (X2 = X1) and (Y2 < Y1) then Result:='4';
  if (X2 = X1) and (Y2 > Y1) then Result:='1';

  if (X2 < X1) and (Y2 < Y1) then Result:='5';
  if (X2 > X1) and (Y2 < Y1) then Result:='3';

  if (X2 > X1) and (Y2 > Y1) then Result:='2';
  if (X2 < X1) and (Y2 > Y1) then Result:='6';

  if (X2 > X1) and (Y2 = Y1) then Result:='3';
  if (X2 < X1) and (Y2 = Y1) then Result:='5';


end;



(*************************************************
TEntitySpriteServer
*************************************************)
function TEntitySpriteServer.CreateEntitySprite (const BaseDir, AuraDir, id: string;
                                                       const posX, posY: integer;
                                                       const Transparent: Boolean;
                                                       Const aCategory: TSpriteCategory ): TEntitySprite;
begin


  Result := TEntitySprite.Create(BaseDir, AuraDir , id, posX, posY, Transparent, aCategory);

  Result.Priority := Result.Position.Y + Result.ModPriority  ;  // viene aggiornata nel move
  fEngine.AddSprite(se_Sprite(Result));
end;
constructor TEntitySpriteServer.Create (AOwner: TComponent) ;
begin
  inherited Create( AOwner );
end;
destructor TEntitySpriteServer.Destroy () ;
begin
  inherited Destroy ();
end;
constructor TSpellSpriteServer.Create (AOwner: TComponent) ;
begin
  inherited Create( AOwner );
end;
destructor TSpellSpriteServer.Destroy () ;
begin
  inherited Destroy ();
end;


procedure TEntitySprite.VirtualAddAura (Source,aura,duration:string);
var
i: integer;
TsDetails: TStringList;
begin
  for I := 0 to fAuras.Count -1 do begin
    TsDetails:= TStringList.Create ;
    split (FAuras[i],',',Tsdetails);
      if TsDetails[1] = '0' then begin
        TsDetails[0]:=Source;
        TsDetails[1]:=aura;
        TsDetails[2]:=duration;
        FAuras[i]:= TsDetails.CommaText ;
        TsDetails.Free;
        break;
      end;
     TsDetails.Free;
  end;
end;
procedure TEntitySprite.VirtualDeleteAura (Source,aura:string);
var
i: integer;
TsDetails: TStringList;
begin

  for i := 0 to FAuras.Count -1 do begin
    TsDetails:= TStringList.Create ;
    split (FAuras[i],',',Tsdetails);
      if (TsDetails[0] = Source) and  (TsDetails[1] = aura) then begin
        TsDetails[0]:='0';
        TsDetails[1]:='0';
        TsDetails[2]:='0';
        FAuras[i]:= TsDetails.CommaText ;
        TsDetails.Free;
        break;
      end;
    TsDetails.Free;
  end;

end;

procedure TEntitySprite.SetCurrentFrame;
begin
    if bmpState = 'dead' then begin
      HideAtEndX:=true;
     // Visible:=false;
     // exit;
    end;
    inherited;
end;
procedure TEntitySprite.render( RenderTo: TRenderBitmap);
var
  i,lastX,lch,textWidth,diff:integer;
  bm,bm2: Tbitmap;
  TsAuras: Tstringlist;
  AuraCount: integer;

  label init,nocopy;
begin
    { TODO : c'è ancora un piccolo memory leak }
//    BmpcurrentFrame.CopyRectTo(bmp,0,0,0,0,BmpcurrentFrame.Width ,BmpcurrentFrame.Height );
    (* DRAW CH*)
  if (Category = cNpc) or (Category = cPlayer)  then begin

    lch := trunc((CurHealth * (BmpcurrentFrame.Width / 3))  / Health);
    if (lch > 0) and (CurHealth < Health) then begin

      Bm:= TBitmap.Create ;
      bm.PixelFormat := pf24bit;
      bm.Height := 2;

      bm.Width := lch;

      BM.Canvas.Brush.Color := clRed;
      bm.Canvas.FillRect(Rect(0,0, lch ,2 ) );


      BitBlt(bmpCurrentFrame.Canvas.Handle,45,24, bm.width, bm.Height, bm.canvas.Handle, 0 , 0, SRCCOPY);

      bm.Free;
    end;
    (* DRAW CP*)

    if CastBarValue > 0 then begin

      Bm:= TBitmap.Create ;
      bm.PixelFormat := pf24bit;
      bm.Height := 14;


      BM.Canvas.Font.Size:= 8;
      BM.Canvas.Font.Style := [fsBold] ;
      BM.Canvas.Font.Color:= clwhite;
      textWidth:=BM.Canvas.TextWidth(CastBarText) ;

      bm.Width := textWidth;//FrameWidth ;
      BM.Canvas.Brush.Color := clBlue;
      bm.Canvas.FillRect(Rect(0,0, bm.width , 14 ) );
      BM.Canvas.Brush.Color := clGray;
      bm.Canvas.FillRect(Rect(0,0, Round(castbarValue * bm.Width / 100) , 14 ) );

      BM.Canvas.Brush.Style := bsClear;
      BM.Canvas.Font.Quality :=  fqAntialiased;

      BM.Canvas.TextOut ( 0 , 0 , CastBarText  ) ;


      Diff:= (FrameWidth - Bm.width ) div 2;
      BitBlt(bmpCurrentFrame.Canvas.Handle,diff,4, bm.width, bm.Height, bm.canvas.Handle, 0 , 0, SRCCOPY);

      bm.Free;
    end;

  {  if Selected then begin
      Bm:= TBitmap.Create ;
      bm.PixelFormat := pf24bit;
      bm.Height := 14;


      bm.Width := FrameWidth;
      BM.Canvas.Brush.Color := clGreen;
      bm.Canvas.FillRect(Rect(0,0, bm.width , 14 ) );

      BM.Canvas.Font.Size:= 8;
      BM.Canvas.Font.Style := [fsBold] ;
      BM.Canvas.Font.Color:= clwhite;
      BM.Canvas.Brush.Style := bsSolid;
      BM.Canvas.Font.Quality :=  fqAntialiased;

      textWidth:=BM.Canvas.TextWidth('Selected') ;
      Diff := (BM.Width - textWidth) div 2;
      BM.Canvas.TextOut ( diff , 0 , 'Selected'  ) ;



      BitBlt(bmpCurrentFrame.Canvas.Handle,0,90, bm.width, bm.Height, bm.canvas.Handle, 0 , 0, SRCCOPY);

      bm.Free;

    end;   }

     (* Show Numbers*)
      Bm:= TBitmap.Create ;
      bm.PixelFormat := pf24bit;


      BM.Canvas.Font.Color:= clwhite;
      if Grouped then  begin
        BM.Canvas.Font.Size:= 14;
        BM.Canvas.Font.Style := [fsBold];
        bm.Width := BM.Canvas.TextWidth( Inttostr(Number)) +10;// FrameWidth;
        bm.Height := BM.Canvas.TextHeight( Inttostr(Number))+10 ;
      end
      else begin
        BM.Canvas.Font.Size:= 8;
        BM.Canvas.Font.Style := [] ;
        bm.Width := BM.Canvas.TextWidth( Inttostr(Number)) ;// FrameWidth;
        bm.Height := BM.Canvas.TextHeight( Inttostr(Number)) ;
      end;

      BM.Canvas.Brush.Style := bsSolid;
      BM.Canvas.Font.Quality :=  fqAntialiased;

      if faction = '1' then
        BM.Canvas.Brush.Color := clMaroon else
      if faction = '2' then
        BM.Canvas.Brush.Color := clBlue else
      if faction = '0' then
        BM.Canvas.Brush.Color := clgray;

      bm.Canvas.FillRect(Rect(0,0, bm.width , bm.height ) );


      //textWidth:=BMp.Canvas.TextWidth( Inttostr(Number)) ;
      Diff := (FrameWidth - bm.Width) div 2;
//      BM.Canvas.TextOut ( diff , 0 , Inttostr(Number)  ) ;
      BM.Canvas.TextOut ( 0 , 0 , Inttostr(Number)  ) ;



        //  bmp.Canvas.TextOut (lastX+diff,84, Inttostr(Number)  );
          BitBlt(bmpCurrentFrame.Canvas.Handle,diff ,84, bm.width, bm.Height, bm.canvas.Handle, 0 , 0, SRCCOPY);

      bm.Free;

   (* Auree *)
   (* Auree punta a una directory come overwritebmp, solo che deve gestire una lista dinamica di auree per creare l'unico bmp*)

    bm2:= Tbitmap.Create;
    bm2.PixelFormat := pf24bit;
    AuraCount:=0;
    for i := 0 to FAuras.Count -1 do begin
      TsAuras:= TStringList.Create ;
      split (FAuras[i],',',TsAuras);
      if TsAuras[1] <> '0' then  inc(AuraCount);
      TsAuras.Free;
    end;
    bm2.Width := AuraCount * 16;       //  deve essere 16, o la width dei bmp che intendi utilizzare
    bm2.Height := 16;

    lastX:=0;                               // creo la riga di auree
    for i := 0 to FAuras.Count -1 do begin

      TsAuras:= TStringList.Create ;
      split (FAuras[i],',',TsAuras);
      if TsAuras[1] <> '0' then begin


          Bm:=Tbitmap.Create ;
          Bm.LoadFromFile( AuraDir + tsAuras[1] + '.bmp');


          BitBlt(bm2.Canvas.Handle,lastX,0, bm.width, bm.Height, bm.canvas.Handle, 0 , 0, SRCCOPY);
          lastX:=lastX + 16 ;

          bm.Free;
      end;
          TsAuras.Free;
    end;


        //  bmp.Canvas.TextOut (lastX+diff,84, Inttostr(Number)  );
          BitBlt(bmpCurrentFrame.Canvas.Handle,45,26, bm2.width, bm2.Height, bm2.canvas.Handle, 0 , 0, SRCCOPY);
      bm2.Free;

 end;

  inherited;
end;
procedure TEntitySprite.iOnDestinationReached;
begin
    // internamente reached

    //RpgState:= cidle;   // StopAtEndX:= true oppure termina di passeggiare e rimane in quel frame in attesa di uno state diverso
                        // evita il cambio di status e relativo caricamento sprite


    Inherited;  // <--- informa l'engine
end;




procedure TEntitySprite.OverWriteBitmap( );
var
  ini: Tinifile;
begin
    if bmp = nil then exit; // non ancora caricato
    
    if (fBmpstate = 'spell') and
    (not fileexists( CharacterDir  +'\' + fBmpstate + '.' + IsoDirection  + '.bmp' )) then
      fBmpstate := 'attack';

    bmp.BmpName := CharacterDir  +'\'  + fBmpstate + '.' + IsoDirection  + '.bmp' ;
    bmp.LoadFromFileBMP (  CharacterDir  +'\'  + fBmpstate + '.' + IsoDirection  + '.bmp' );
//    bmpdefault.LoadFromFileBMP (  CharacterDir  +'\' + 'cached_' + SpriteName + '_' + fBmpstate + '.' + IsoDirection  + '.bmp' );

    ini:= TIniFile.Create( CharacterDir  +'\sprite.ini');
    FramesX := Ini.readinteger(fBmpstate,'framesX',1);
    FramesY := Ini.readinteger(fBmpstate,'framesY',1);
    FrameXMax := FramesX;
    FrameXMin := 0;
    bmpCurrentFrame.Width := BMP.Width div FramesX;
    bmpCurrentFrame.Height:= BMP.height div FramesY;

    FrameX := 0;
    FrameY := 0;

    ini.Free;


end;

procedure TEntitySprite.SetBmpState (value: string);
begin

    if value = 'dead' then begin
      if fBmpState ='dead' then exit;
      fBmpState := 'dead';
      StopAtEndX:= true;
      HideAtEndX:= True;

    end
    else if value = 'walk' then begin

      if fBmpState <> 'dead' then begin     // mi può arrivare mentre sono dead

        fBmpState := 'walk';
        StopAtEndX:= false;
        HideAtEndX:= false;
        Visible:=true;

      end;
    end
    else if value = 'casting' then begin
      if fBmpState <> 'dead' then begin     // mi può arrivare mentre sono dead
        fBmpState := 'spell';
        StopAtEndX:= false;
        HideAtEndX:= false;
        Visible:=true;
      end;
    end
    else if value = 'idle' then begin
      if fBmpState <> 'dead' then begin     // mi può arrivare mentre sono dead
        fBmpState := 'idle';
        StopAtEndX:= false;
        HideAtEndX:= false;
        Visible:=true;
      end;
    end
    else
    if value = 'hitted' then begin
      if fBmpState <> 'dead' then begin     // mi può arrivare mentre sono dead
        fBmpState := 'hit' ;
        StopAtEndX:= false;
        HideAtEndX:= false;
        Visible:=true;
      end;
    end
    else if value = 'spawn' then begin
      fBmpState := 'idle' ;
      StopAtEndX:= false;
      HideAtEndX:= false;
      Visible:=true;
    end;

      OverWriteBitmap ;

end;
procedure TEntitySprite.SetIsoDirection ( const value: string );
begin
  if fIsoDirection <> value then begin
    fIsoDirection := value;
    overwriteBitmap;
  end;
end;

constructor TEntitySprite.Create ( const dir_Sprite, dir_Aura, id: string;
                                      const posX,posY: integer;
                                      const TransparentSprite: boolean;
                                      const aCategory: TSpriteCategory ) ;
var
  i: integer;
  ini : Tinifile;

begin
  Category:= aCategory;
  SpriteName := ExtractFileName(ExcludeTrailingPathDelimiter(dir_Sprite));
  CharacterDir:= dir_Sprite;

  Ids:= id;
  if rightstr(CharacterDir,1) <> '\' then CharacterDir:= CharacterDir + '\';


  AuraDir:= dir_aura;
  if rightstr(AuraDir,1) <> '\' then AuraDir:= AuraDir + '\';
  fAuras:= Tstringlist.Create;
  fauras.StrictDelimiter := true;
  fauras.Delimiter := '|';
  for I := 0 to 5 do
    fAuras.Add('0,0,0') ;

   NotifyDestinationReached:= true;

   fBmpstate:= 'idle';
   ini:= TIniFile.Create(CharacterDir + 'sprite.ini');
   FramesX := Ini.readinteger(Bmpstate,'framesX',1);
   FramesY := Ini.readinteger(Bmpstate,'framesY',1);
   SpritePriority := SpritePriority + Ini.readinteger('MAIN','priority',1);
   ModPriority := SpritePriority;
   AnimationInterval := Ini.readinteger('MAIN','delay',0);
   ini.Free;


   IsoDirection:= '1';
   inherited Create(CharacterDir + Bmpstate + '.' + IsoDirection  + '.bmp',
          ids, FramesX, FramesY, AnimationInterval, posX, posY, TransparentSprite);



end;
destructor TEntitySprite.Destroy () ;
begin
  fAuras.Free;
  inherited Destroy ();

end;




procedure TSpellSprite.iOnDestinationReached;
begin
    // internamente reached. Cambio da moving a hit
    fBmpState:= 'hit';
    overwriteBitmap;
    Inherited;  // <--- informa l'engine
end;

constructor TSpellSprite.Create ( const dir_Sprite, id: string;
                                  const posX,posY: integer; const TransparentSprite: boolean ) ;
var
  ini : Tinifile;
begin
  Ids:= id;
  SpellDir:= dir_Sprite;
  SpriteName := ExtractFileName(ExcludeTrailingPathDelimiter(SpellDir));
  if rightstr(SpellDir,1) <> '\' then SpellDir:= SpellDir + '\';


  CastingNotifyDestinationReached:= False;
  ini:= TIniFile.Create(SpellDir +  '\sprite.ini');

  CastingFramesX := Ini.readinteger('CASTING','framesX',1);
  CastingFramesY := Ini.readinteger('CASTING','framesY',1);
  CastingSpritePriority := CastingSpritePriority + Ini.readinteger('CASTING','priority',0);
  CastingAnimationInterval := Ini.readinteger('CASTING','delay',0);
  CastingOffsetX := Ini.readinteger('CASTING','offsetX',0);
  CastingOffsetY := Ini.readinteger('CASTING','offsetY',0);
  ini.Free;

  inherited Create(SpellDir +  'casting.bmp',ids, CastingFramesX, CastingFramesY, AnimationInterval, posX+sOffsetX, posY+soffsetY, TransparentSprite);
  fBmpState:='casting';
  HideAtEndX := true; // moving lo renderà di nuovo visibile


   MovingNotifyDestinationReached:= true;
   ini:= TIniFile.Create(SpellDir + 'sprite.ini');
   MovingFramesX := Ini.readinteger('MOVING','framesX',1);
   MovingFramesY := Ini.readinteger('MOVING','framesY',1);
   MovingSpritePriority := MovingSpritePriority + Ini.readinteger('MOVING','priority',0);
   MovingAnimationInterval := Ini.readinteger('MOVING','delay',0);
   MovingOffsetX := Ini.readinteger('MOVING','offsetX',0);
   MovingOffsetY := Ini.readinteger('MOVING','offsetY',0);


   HitNotifyDestinationReached:= false;
   ini:= TIniFile.Create(SpellDir + 'sprite.ini');
   HitFramesX := Ini.readinteger('HIT','framesX',1);
   HitFramesY := Ini.readinteger('HIT','framesY',1);
   HitSpritePriority := HitSpritePriority + Ini.readinteger('HIT','priority',0);
   HitAnimationInterval := Ini.readinteger('HIT','delay',0);
   HitOffsetX := Ini.readinteger('HIT','offsetX',0);
   HitOffsetY := Ini.readinteger('HIT','offsetY',0);
   ini.Free;


end;


destructor TSpellSprite.Destroy () ;
begin
  inherited Destroy ();

end;
procedure TSpellSprite.OverWriteBitmap( );
begin

    if bmp = nil then exit; // non ancora caricato

    bmp.BmpName := SpellDir  +'\' +  fBmpstate + '.bmp' ;
    bmp.LoadFromFileBMP (  SpellDir  +'\' + fBmpstate  + '.bmp' );
//    bmpdefault.LoadFromFileBMP (  SpellDir  +'\' +  fBmpstate  + '.bmp' );

    if fBmpState = 'moving' then begin

      NotifyDestinationReached := MovingNotifyDestinationReached;
      FramesX := MovingFramesX;
      FramesY := MovingFramesY;
      FrameWidth:=  BMP.Width div FramesX;
      FrameHeight:=  BMP.height div FramesY;
      FrameXMax := FramesX;
      FrameXMin := 0;

      SpritePriority := MovingSpritePriority;
      AnimationInterval := MovingAnimationInterval;
      sOffsetX:= MovingOffsetX;
      sOffsetY:= MovingOffsetY;
      FrameX:=0;
      FrameY:=0;
    end
    else if fBmpState = 'hit' then begin
      NotifyDestinationReached := HitNotifyDestinationReached;
      FramesX := HitFramesX;
      FramesY := HitFramesY;
      FrameWidth:=  BMP.Width div FramesX;
      FrameHeight:=  BMP.height div FramesY;
      FrameXMax := FramesX;
      FrameXMin := 0;

      SpritePriority := HitSpritePriority;
      AnimationInterval := HitAnimationInterval;
      sOffsetX:= HitOffsetX;
      sOffsetY:= HitOffsetY;
      DieAtendX:= true;
      FrameX:=0;
      FrameY:=0;
    end;


end;
procedure TSpellSprite.SetIsoDirection ( const value: string );
begin
  fIsoDirection := value;
  overwriteBitmap;
end;
procedure TSpellSprite.SetCurrentFrame() ;
begin
  // internamente Cambio da casting a moving. Il setCurrentFrame di se_Sprite lo ha settato visible = false
  // A questo punto annullo il not visible e carico/creo in overwriteBitmap moving.bmp.
  // Lo sprite Moving deve sapere anche dove andare, cioè MovingDstX e MovingDstY
  inherited;
  if (not Visible ) then begin
    visible:=true;
    fBmpState := 'moving';
    OverwriteBitmap;
  end;
end;
procedure TSpellSprite.render( RenderTo: TRenderBitmap) ;
begin
  // qui posso ruotare bmpcurrentframe in base a isodirection settando angle
  // posso anche impostare un resize
//          BitBlt(bmpCurrentFrame.Canvas.Handle,diff ,84, bm.width, bm.Height, bm.canvas.Handle, 0 , 0, SRCCOPY);

  inherited;


end;
function TSpellSpriteServer.CreateSpellSprite (const BaseDir, id: string;
                                               const posX, posY: integer;
                                               const Transparent: Boolean ): TSpellSprite;
begin


  Result := TSpellSprite.Create(BaseDir,  id, posX, posY, Transparent);

                   { TODO :  da verificare }

//  Result.oldDestinationReached:= Result.OnDestinationReached;
  //Result.OnDestinationReached:= Result.rpgOnDestinationReached;

//  Result.oldOnbeforeRenderCurrentFrameBMP := Result.OnBeforeRenderCurrentFrameBMP ;
//  Result.OnbeforeRenderCurrentFrameBMP:= Result.rpgOnbeforeRenderCurrentFrameBMP;

//  Result.oldOnafterRenderCurrentFrameBMP := Result.OnafterRenderCurrentFrameBMP;
//  Result.OnafterRenderCurrentFrameBMP:= Result.rpgOnafterRenderCurrentFrameBMP;

  Result.Priority := Result.Position.Y + Result.ModPriority  ;  // viene aggiornata nel move
  fEngine.AddSprite(se_Sprite(Result));
end;
procedure TSpellSprite.SetBmpState (value: string);
begin

    if value = 'casting' then begin

      fBmpState := 'casting';
      StopAtEndX:= true;
//      HideAtEndX:= false;

    end
    else if value = 'moving' then begin


        fBmpState := 'moving';
        StopAtEndX:= false;
//        HideAtEndX:= false;
//        Visible:=true;

    end
    else if value = 'hit' then begin
        fBmpState := 'hit';
        StopAtEndX:= true;
        DieAtEndX:= true;           // casting --> moving --> hit quindi e poi Dead := true con rimozione dell'oggetto solo ora
//        Visible:=true;
    end;

      OverWriteBitmap ;

end;







{constructor TGridSprite.Create( const id: string; engine: se_Engine;
                        posX,posY, aWidth, aHeight, ncols, nrows, aRowHeight: integer;
                        const backcolor: Tcolor; CtrlButtonBarVisible: boolean ) ;
var
  bm: TBitmap;
  x,y: integer;
  aSpriteLabel: se_SpriteLabel;
begin
  if (aWidth <=0) or (aHeight <= 0) or ( (nrows<=0) and (ncols <=0) ) or (aRowHeight <=0) then begin
    aWidth := 300;
    aHeight := 300;
    ncols := 4;
    nrows := 4;
    aRowHeight := 20;
  end;


  Ids:= id;
  fwidth:= aWidth;
  fheight:= aHeight;
  frowheight:= arowheight;
  rows:= nrows;
  cols:= ncols;
  CurIndex:= 0;
  ScrollCount:=1;
  UseActiveStyle := true;

  bm:= Tbitmap.Create;
  bm.Width := aWidth;
  bm.Height := aHeight;
  bm.PixelFormat := pf24bit;
  bm.Canvas.Brush.Color := backcolor;
  bm.Canvas.FillRect(rect(0,0,aWidth,aHeight));

  inherited Create(bm,ids, 1, 1, 20, posX, posY, false);
  bm.Free;
  fColumnSize:= TiraIntegerList.Create ;
  fColumnsize.Count := ncols;
  //fVisibleRows:= trunc( fHeight / frowHeight );
  LstVirtual:= TList<TTalentRowGrid>.Create ;
  fLstCells:= TObjectList<se_SpriteLabel>.create(true);
  // Subito a destra della grid. La width è la RowHeight (bmp quadrato);
  if CtrlButtonBarVisible then begin

    CtrlButtonBar:= TButtonBarSprite.Create('ctrl'+self.Ids,
                                                  PosX +aWidth div 2+arowheight div 2, posY ,
                                                  arowheight, aHeight, 1, nrows,
                                                  backcolor,true ) ;
    Engine.AddSprite(se_Sprite(CtrlButtonBar));

    CtrlButtonBar.ButtonBarMouseDown := CtrlButtonBarMouseDown;
  end;

  CurrentRow:=-1;
  ActiveRow.lFont:= Tfont.Create ;
  ActiveRow.lBackColor := backcolor;
  NormalRow.lFont:= Tfont.Create ;
  NormalRow.lBackColor := backcolor;

  for x := 0 to ncols -1 do begin
    for y := 0 to nrows -1 do begin
      aSpriteLabel:= se_SpriteLabel.create( x,y,'verdana',clwhite,backcolor,'',pmcopy,true);
      aSpriteLabel.lX := x;  // cell, non reale x
      aSpriteLabel.lY := y;
//      aSpriteLabel.lFont  := NormalRow.lFont;
      aSpriteLabel.Transparent := BmpTransparent;
      flstCells.Add(aSpriteLabel);
    end;
  end;

  fTexture:= se_Bitmap.Create ;

end;

procedure TGridSprite.CtrlButtonBarMouseDown  (Sender: TbtnSprite; CellX, CellY: integer) ;
begin
  // qui è già handled = true
  if cellY = 0 then begin // page up
    CurIndex := CurIndex - ScrollCount;
    if CurIndex < 0 then CurIndex:=0;

  end
  else if CellY = rows-1 then begin // page down
    CurIndex := CurIndex + ScrollCount;
    if CurIndex >= lstVirtual.Count -1 then
      CurIndex:= lstVirtual.Count -1-ScrollCount;
    if CurIndex < 0 then CurIndex:=0;
    if (CurIndex + rows) > lstVirtual.Count then
      CurIndex := CurIndex - ScrollCount;

  end;

  ReLoadCells;


end;
procedure TGridSprite.ReloadCells;
var
  maxIndex,x,i: integer;
begin
    MaxIndex := CurIndex + rows-1;
    if MaxIndex > lstVirtual.Count -1 then
      MaxIndex := lstVirtual.Count -1;

    x:=0;
    for I := CurIndex to MaxIndex do begin
//      Cells [0,x].lbmp.LoadFromFileBMP( lstVirtual.Items [i].SpriteName  );
      Cells [0,x].itag :=  lstVirtual.Items [i].itag;
      Cells [1,x].ltext :=  lstVirtual.Items [i].talentName;
      Cells [2,x].ltext :=  lstVirtual.Items [i].descraftercast;
      inc(x);
    end;
end;
destructor TGridSprite.Destroy () ;
begin
  flstcells.free;
  fColumnSize.Free;
  inherited Destroy ();

end;
procedure TGridSprite.SetCurrentFrame() ;
begin

  inherited;
//    OverwriteBitmap;
end;
procedure TGridSprite.render( RenderTo: TRenderBitmap);
var
  wtrans,x,y,Dstx,Dsty,i,cx,cy: integer;
  aTrgb: Trgb;
  UseTexture: boolean;
  aSize: TSize;
  s:string;
  a: integer;
begin
  // qui posso ruotare bmpcurrentframe in base a isodirection settando angle
  // posso anche impostare un resize
  if bmp = nil then exit;
  UseTexture:= false;
  Dstx:=0;
  Dsty:=0;

  if (Texture.Width > 1) and (Texture.Height > 1 )   then begin

    BMPCurrentFrame.Assign(Texture);
    UseTexture:= true;
  end;

  for I :=0 to flstCells.count -1 do begin
    Dstx:=0; Dsty:=0;
    cx:=flstCells.Items [i].lX;
    while true do begin
      dec(cx); // cella in X
      if cx =-1 then break;
      Dstx:= Dstx + fColumnSize [cx];
    end;
    // Dstx è l'effettivo x sul GridSprite , x y 0 0 della cella
    Dsty := flstCells.Items [i].lY * frowHeight;


    if UseActiveStyle then begin

      if CurrentRow = flstCells.Items [i].lY then begin
        BMPCurrentFrame.Canvas.Brush.Color := ActiveRow.lBackColor;
        if not UseTexture then BMPCurrentFrame.Canvas.FillRect(rect(Dstx,Dsty,DstX+fColumnSize[flstCells.Items [i].lX],Dsty+frowHeight ));
        BMPCurrentFrame.Canvas.Font := ActiveRow.lFont ;
        if flstCells.Items [i].lFont.Size <>  ActiveRow.lFont.size then
           BMPCurrentFrame.Canvas.Font.Size:= flstCells.Items [i].lFont.Size;
      end
      else begin
        BMPCurrentFrame.Canvas.Brush.Color := normalRow.lBackColor ;
        if not UseTexture then BMPCurrentFrame.Canvas.FillRect(rect(Dstx,Dsty,DstX+fColumnSize[flstCells.Items [i].lX],Dsty+frowHeight ));
       // a:= flstCells.Items [i].lFont.Size;
        BMPCurrentFrame.Canvas.Font := normalRow.lFont ;//flstCells.Items [i].lFont ;
        if flstCells.Items [i].lFont.Size <>  normalRow.lFont.size then begin
           BMPCurrentFrame.Canvas.Font.Size:= flstCells.Items [i].lFont.Size;
        end;
      end;

    end

    else begin
        BMPCurrentFrame.Canvas.Brush.Color := flstCells.Items [i].lbackcolor;
        if not UseTexture then BMPCurrentFrame.Canvas.FillRect(rect(Dstx,Dsty,DstX+fColumnSize[flstCells.Items [i].lX],Dsty+frowHeight ));
       // a:= flstCells.Items [i].lFont.Size;
        BMPCurrentFrame.Canvas.Font := flstCells.Items [i].lFont ;
    end;

    { TODO : usare subsprites }
   // if (flstCells.Items [i].lbmp.Width > 0) and (flstCells.Items [i].lbmp.Height > 0)then  begin
   //    aTRGB:= flstCells.Items [i].lbmp.Pixel24   [0,0];
   //    wtrans:=    RGB2TColor (aTRGB.b, aTRGB.g , aTRGB.r) ;

   //   flstCells.Items [i].lbmp.CopyRectTo(BMPCurrentFrame,0,0,DstX,DstY,
   //                                        flstCells.Items [i].lbmp.Width  , flstCells.Items [i].lbmp.height ,
    //                                       BmpTransparent ,
    //                                       wtrans );
    //end;

 {
    if flstCells.Items [i].lText <> '' then begin
        if UseTexture then BMPCurrentFrame.Canvas.brush.Style  := bsClear else
          BMPCurrentFrame.Canvas.brush.Style  := bsSolid;

        aSize:= BMPCurrentFrame.Canvas.TextExtent( flstCells.Items [i].lText );

        while aSize.cx > fColumnSize[flstCells.Items [i].lX] do begin
          BMPCurrentFrame.Canvas.Font.Size :=  BMPCurrentFrame.Canvas.Font.Size -2;
          if BMPCurrentFrame.Canvas.Font.Size <= 0 then break;
          aSize:= BMPCurrentFrame.Canvas.TextExtent( flstCells.Items [i].lText );
        end;

        BMPCurrentFrame.Canvas.TextOut(Dstx + ( fColumnSize[flstCells.Items [i].lX] - aSize.cx  ) div 2,
                                      Dsty +  ( frowheight - aSize.cy  ) div 2,
                                      flstCells.Items [i].lText );

    end;

  end;


  inherited;


end;
function TGridSprite.GetCell ( x,y: integer): se_SpriteLabel;
var
  i: integer;
begin

  for I := 0 to flstCells.Count -1 do begin
    if (flstCells.Items [i].lX = x ) and (flstCells.Items [i].lY = y ) then
    begin
      Result := flstCells.Items [i] ;
      exit;
    end;
  end;

end;
procedure TGridSprite.SetCell ( x,y: integer; value: se_SpriteLabel);
var
  i: integer;
begin


  for I := 0 to flstCells.Count -1 do begin
    if (flstCells.Items [i].lX = x ) and (flstCells.Items [i].lY = y ) then
    begin
      flstCells.Items [i] := value;
      exit;
    end;
  end;

end;
function TGridSprite.GetColWidth ( x: integer): integer;
begin
  result:= fColumnSize.Items [x];
end;
procedure TGridSprite.SetColWidth ( x: integer; value: integer);
begin
  fColumnSize.Items [x]:= value;
end;
procedure TGridSprite.SetGridMouseDown(const Value: TGridMouseEvent);
begin
  FgridMouseDown := Value;
end;
procedure TGridSprite.SetGridMouseMove(const Value: TGridMouseMoveEvent);
begin
  FgridMouseMove := Value;
end;

procedure TGridSprite.SetTexture ( aTexture: se_Bitmap );
begin
    if aTexture.Bitmap  <> nil then begin
      fTexture:= se_Bitmap.Create ( aTexture );
      fTexture.Stretch(fwidth,fheight);
      CtrlButtonBar.Texture := aTexture;
    end;

end;
procedure TGridSprite.MouseMove ( x,y: integer; Shift: TShiftState; var handled: boolean);
var
  i,s,s2: integer;
begin

  // x e y sono le coordinate relative allo sprite Grid. Da queste risalgo alla cella X,Y
  CurrentRow:= trunc( Y / frowheight );
  if fColumnsize.Count =1  then
    CurrentCol := 0
   else begin
    CurrentCol := 0;
    s:=0;s2:=0;
    for i:= 0 to fColumnsize.Count -1 do begin
      s2:= s2 + fColumnsize[i];
      if (x >= s) and (x <= s2) then begin
       CurrentCol := i;
       break;
      end;
      s:=s2;

    end;
  end;

  // per evitare il continuo refresh , solo quando cambia cella, non pixel
  if (CurrentCol = oldX) and (CurrentRow = oldY) then exit;
  oldx:=CurrentCol;
  oldy:=CurrentRow;


  Handled:= false;
  if Assigned ( FGridMouseMove) then FGridMouseMove ( self, CurrentCol, CurrentRow );

end;
procedure TGridSprite.MouseDown ( x,y: integer; Button: TMouseButton; Shift: TShiftState; var handled: boolean);
var
  i,s,s2: integer;
begin
  // x e y sono le coordinate relative allo sprite Grid. Da queste risalgo alla cella X,Y
  CurrentRow:= trunc( Y / frowheight );

  if fColumnsize.Count =1  then
    CurrentCol := 0
   else begin
    CurrentCol := 0;
    s:=0;s2:=0;
    for i:= 0 to fColumnsize.Count -1 do begin
      s2:= s2 + fColumnsize[i];
      if (x >= s) and (x <= s2) then begin
       CurrentCol := i;
       break;
      end;
      s:=s2;

    end;
  end;
  Handled:= true;
  if Assigned (FGridMouseDown) then FGridMouseDown ( self, CurrentCol, CurrentRow, Button, Shift );
end;
procedure TGridSprite.SetDead(const Value: boolean);
begin
  if CtrlButtonBar <> nil then CtrlButtonBar.Dead:= true;
  Inherited;

end;



function TGridSpriteServer.CreateGridSprite (const id: string;
                        const posX,posY, aWidth, aHeight, ncols,nrows,aRowHeight: integer;
                        const backcolor: Tcolor; CtrlButtonBarVisible: boolean ): TgridSprite;
begin


  Result := TGridSprite.Create( id,fEngine, posX, posY, aWidth, aHeight, ncols, nrows, aRowHeight, backcolor,CtrlButtonBarVisible ) ;

  Result.Priority := Result.Position.Y + Result.ModPriority  ;  // viene aggiornata nel move
  fEngine.AddSprite(se_Sprite(Result));
end;
destructor TGridSpriteServer.Destroy () ;
begin
  inherited Destroy ();
end;
constructor TGridSpriteServer.Create (AOwner: TComponent) ;
begin
  inherited Create( AOwner );
end;




constructor TbtnSprite.Create (aWidth, aHeight: integer; backcolor: Tcolor);
begin
  bmpUp:= se_Bitmap.Create ( aWidth, aHeight);
  bmpUp.Bitmap.Canvas.Brush.Color := BackColor;
  bmpUp.Bitmap.Canvas.FillRect(rect(0,0,aWidth,aHeight));

end;
destructor TbtnSprite.Destroy;
begin
  bmpUp.free;
  inherited;
end;

//
// TbuttonBarSprite
//

constructor TbuttonBarSprite.Create( const id: string;
                        posX,posY, aWidth, aHeight, ncols, nrows: integer;
                        const backcolor: Tcolor; TransparentButtons:boolean ) ;
var
  bm: TBitmap;
  x,y: integer;
  aBtn: TbtnSprite;
begin

  if (aWidth <=0) or (aHeight <= 0) or ( (nrows<=0) and (ncols <=0) )then begin
    aWidth := 300;
    aHeight := 100;
    ncols := 4;
    nrows := 1;
  end;

  Ids:= id;
  fwidth:= aWidth;
  fheight:= aHeight;
  rows:= nrows;
  cols:= ncols;
  fButtonWidth:= trunc ( aWidth / ncols );
  fButtonheight:= trunc ( aHeight / nRows );

  bm:= Tbitmap.Create;
  bm.Width := aWidth;
  bm.Height := aHeight;
  bm.PixelFormat := pf24bit;
  bm.Canvas.Brush.Color := backcolor;
  bm.Canvas.FillRect(rect(0,0,aWidth,aHeight));

  inherited Create(bm,ids, 1, 1, 20, posX, posY, false);
  bm.Free;

  fLstButtons:= TObjectList<TbtnSprite>.create(true);
  fTexture:= se_Bitmap.Create ;

  for x := 0 to ncols -1 do begin
    for y := 0 to nrows -1 do begin
      aBtn:= TbtnSprite.create(fButtonWidth,fButtonheight, backcolor);
      aBtn.lX := x;  // cell, non reale x
      aBtn.lY := y;
      aBtn.checked := false;
      aBtn.Transparent:= TransparentButtons;
      flstButtons.Add(aBtn);
    end;
  end;

end;


destructor TbuttonBarSprite.Destroy () ;
begin

  flstButtons.free;
  inherited Destroy ();

end;
procedure TbuttonBarSprite.SetCurrentFrame() ;
begin
  inherited;

end;
procedure TButtonBarSprite.SetButtonBarMouseDown(const Value: TButtonBarMouseEvent);
begin
  FButtonBarMouseDown := Value;
end;
procedure TbuttonBarSprite.SetTexture ( aTexture: se_Bitmap );
begin
    if aTexture.Bitmap  <> nil then begin
      fTexture:= se_Bitmap.Create ( aTexture );
      fTexture.Stretch(fwidth,fheight);
    end;
end;
procedure TButtonBarSprite.SetButtonBarMouseMove(const Value: TButtonBarMouseMoveEvent);
begin
  FButtonBarMouseMove := Value;
end;

procedure TButtonBarSprite.MouseMove ( x,y: integer; Shift: TShiftState; var handled: boolean);
var
  tmpCellX,tmpCellY: integer;
  tmpBtn: TBtnSprite;
begin

  // x e y sono le coordinate relative allo sprite TbuttonBar. Da queste risalgo al button X,Y
  tmpCellX := trunc(x / fbuttonwidth);
  tmpCellY := trunc(Y / fbuttonheight );
  // per evitare il continuo refresh , solo quando cambia cella, non pixel
  if (TmpCellX = oldX) and (TmpCellY = oldY) then exit;
  oldx:=TmpCellX;
  oldy:=TmpCellY;
  CurrentRow := TmpCellY;

  tmpBtn:= getButton ( tmpCellX, tmpCellY );
  Handled:= false;
  if Assigned ( FButtonBarMouseMove) then FButtonBarMouseMove ( tmpBtn, tmpCellX, tmpCellY );

end;

procedure TbuttonBarSprite.render( RenderTo: TRenderBitmap);
var
  wtrans,i,x,y: integer;
  aTrgb: Trgb;

begin
  if bmp = nil then exit;

  if (Texture.Width > 1) and (Texture.Height > 1 )   then begin

    BMPCurrentFrame.Assign(Texture);

  end;

  for I := 0 to flstButtons.Count -1 do begin
    X:= trunc((fWidth  *  flstButtons.Items [i].lx) / Cols) ;
    Y:= trunc((fHeight *  flstButtons.Items [i].ly) / Rows) ;

    aTRGB:= flstButtons.Items [i].bmpup.Pixel24   [0,0];
    wtrans:=    RGB2TColor (aTRGB.b, aTRGB.g , aTRGB.r) ;
    flstButtons.Items [i].BmpUp.CopyRectTo(BMPCurrentFrame,0,0,x,y,
                                           fButtonWidth ,fButtonHeight,flstButtons.Items [i].Transparent ,wtrans);


    flstButtons.Items [i].BmpUp.Canvas.font.Color := clyellow;
    flstButtons.Items [i].BmpUp.Canvas.brush.Color := clblack;
    flstButtons.Items [i].BmpUp.Canvas.Brush.Style := bsSolid;
    flstButtons.Items [i].BmpUp.Canvas.Font.Quality :=  fqAntialiased;


    if RowHighLight then begin

      if flstButtons.Items [i].ly = CurrentRow then begin
        flstButtons.Items [i].BmpUP.BlendMode := iraBlendGreen
      end
      else flstButtons.Items [i].BmpUP.BlendMode := iraBlendNormal;
      if ShowCoolDown then flstButtons.Items [i].BmpUp.Canvas.TextOut(3,3 , IntTostr(flstButtons.Items [i].Cooldown)   ) ;
    end
    else flstButtons.Items [i].BmpUP.BlendMode := iraBlendNormal;

  end;

  inherited;


end;
function TbuttonBarSprite.GetButton ( x,y: integer): TbtnSprite;
var
  i: integer;
begin

  for I := 0 to flstButtons.Count -1 do begin
    if (flstButtons.Items [i].lX = x ) and (flstButtons.Items [i].lY = y ) then
    begin
      Result := flstButtons.Items [i] ;
      exit;
    end;
  end;

end;
procedure TbuttonBarSprite.MouseDown ( x,y: integer; Button: TMouseButton; Shift: TShiftState; var handled: boolean);
var
  tmpCellX,tmpCellY: integer;
  tmpBtn: TBtnSprite;
begin
  // x e y sono le coordinate relative allo sprite TbuttonBar. Da queste risalgo al button X,Y
  Handled:= true;
  tmpCellX := trunc(x / fbuttonwidth);
  tmpCellY := trunc(Y / fbuttonheight );
  tmpBtn:= getButton ( tmpCellX, tmpCellY );
  tmpBtn.Checked := not tmpBtn.Checked;
  FButtonBarMouseDown ( tmpBtn, tmpCellX,tmpCellY);
  { TODO : click del button animazione }   {
end;

function TButtonBarSpriteServer.CreateButtonBarSprite (const id: string;
                        const posX,posY, aWidth, aHeight, ncols, nrows: integer;
                        const backcolor: Tcolor;TransparentButtons:boolean ): TButtonBarSprite;
begin


  Result := TButtonBarSprite.Create( id, posX, posY, aWidth, aHeight, ncols, nrows, backcolor,TransparentButtons ) ;

  Result.Priority := Result.Position.Y + Result.ModPriority  ;  // viene aggiornata nel move
  fEngine.AddSprite(se_Sprite(Result));
end;
destructor TButtonBarSpriteServer.Destroy () ;
begin
  inherited Destroy ();
end;
constructor TButtonBarSpriteServer.Create (AOwner: TComponent) ;
begin
  inherited Create( AOwner );
end;    }

end.

