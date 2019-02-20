unit DSE_GRID;
{ TODO : fare cellwidth personali }
interface
uses
  Windows, Messages, vcl.Graphics, vcl.Controls, vcl.Forms, system.Classes, system.SysUtils, vcl.StdCtrls, vcl.ExtCtrls,Math,
  Generics.Collections ,Generics.Defaults, DSE_Theater, DSE_bitmap, Dse_threadTimer,DSE_Misc;

  type SE_GridCellMouseEvent = procedure( Sender: TObject;  Button: TMouseButton; Shift: TShiftState; CellX, CellY: integer; Sprite: SE_Sprite) of object;
  type SE_GridCellMouseMoveEvent = procedure( Sender: TObject; Shift: TShiftState; CellX, CellY: integer; Sprite: SE_Sprite ) of object;
  Type TCellBorder = ( CellBorderNone, CellBorderSquare, CellBorderRound );
  Type TCellAlignmentH = ( HLeft, HCenter, HRight );
  Type TCellAlignmentV = ( VTop, VCenter, VBottom );
  Type SE_ProgressBarStyle = ( pbStandard, pbSingleLineTop,pbSingleLineCenter,pbSingleLineBottom );
  type SE_Cell = Class
    Sprite: SE_Sprite;
    Guid: Integer;
    Ids : string;
    Col : Integer;
    Row : Integer;
    Text : string;
    BackColor: TColor;
    FontName: String;
    FontSize: Integer;
    FontColor: TColor;
    FontStyle: TFontStyles;
    CellAlignmentH : TCellAlignmentH;
    CellAlignmentV : TCellAlignmentV;
    Bitmap : SE_Bitmap;
    BitmapCopies: integer;
    BitmapTransparent: boolean;
    ProgressBar : SE_Bitmap;
    ProgressBarValue : integer;
    ProgressBarStyle: SE_ProgressBarStyle;
    ProgressBarColor: TColor;
    ProgressBarShowPercent: boolean;
  end;
  type SE_Col = class
    Width: integer;
  end;
  type SE_Row = class
    Height: integer;
  end;

  type SE_Grid = Class(SE_Theater)
  private
    ffont: TFont;
    // Grid
    FCellBorderColor:TColor;
    FCellBorder: TCellBorder;

    fDefaultColwidth: integer;
    fDefaultRowHeight : integer;

    // Thread
    fCells: TObjectList<SE_Cell>;

    FOnGridCellMouseUp: SE_GridCellMouseEvent;
    FOnGridCellMouseDown: SE_GridCellMouseEvent;
    FOnGridCellMouseMove: SE_GridCellMouseMoveEvent;

    GridUpdate: boolean;

    function GetColCount: integer;
    function GetRowCount: integer;
    procedure SetColCount ( const n: integer );
    procedure SetRowCount ( const n: integer );
    function GetCell ( Col, Row : integer ): SE_Cell;
    procedure ProcessAllCells;
    procedure RoundBorder (bmp: TBitmap; w,h: Integer; CellBackColor :TColor);
    procedure SquareBorder (bmp: TBitmap; w,h: Integer; CellBackColor :TColor);
    function GetTotCellWidth ( Limit: integer ): integer;
    function GetTotCellHeight ( Limit: integer ): integer;
    function GetTotalCellWidth : integer;
    function GetTotalCellHeight : integer;
    procedure SetFont ( v: TFont );
  protected
    procedure Loaded; override;
    procedure MySpriteMouseDown(Sender: TObject; lstSprite: TObjectList<SE_Sprite>; Button: TMouseButton; Shift: TShiftState);
    procedure MySpriteMouseMove( Sender: TObject; lstSprite: TObjectList<SE_Sprite>; Shift: TShiftState; var Handled: boolean);
    procedure MySpriteMouseUp(Sender: TObject; lstSprite: TObjectList<SE_Sprite>; Button: TMouseButton; Shift: TShiftState);
    procedure RefreshSurface(Sender: TObject); override;

  public
    CellsEngine: SE_Engine;

    Columns: TObjectList<SE_Col>;
    Rows: TObjectList<SE_Row>;
    constructor Create(Owner: TComponent); override;
    destructor Destroy; override;

    property Cells [ c, r: integer ] : SE_Cell read GetCell;

    property ColCount : integer read GetColCount write SetColCount;
    property RowCount : integer read GetRowCount write SetRowCount;
    Property DefaultColWidth: integer read fDefaultColwidth  write fDefaultColwidth default 100;
    Property DefaultRowHeight: integer read fDefaultRowHeight write fDefaultRowHeight default 32;
    property TotalCellsWidth : Integer read GetTotalCellWidth;
    property TotalCellsHeight : Integer read GetTotalCellHeight;

    procedure ClearData;
    procedure AddRow;
    procedure AddColumn;
    procedure RemoveColumn ( const idx: integer );
    procedure RemoveRow ( const idx: integer );

    procedure AddSE_Bitmap ( const CellX, CellY, copies: integer; bmp: SE_Bitmap; Transparent:boolean);
    procedure AddProgressBar ( const CellX, CellY, Value: integer; Const Color: TColor; Style : SE_ProgressBarStyle);

  //    procedure AddPicture ( const CellX, CellY, strech: boolean);

  published

    property OnGridCellMouseDown: SE_GridCellMouseEvent read FOnGridCellMouseDown write FOnGridCellMouseDown;
    property OnGridCellMouseMove: SE_GridCellMouseMoveEvent read FOnGridCellMouseMove write FOnGridCellMouseMove;
    property OnGridCellMouseUp: SE_GridCellMouseEvent read FOnGridCellMouseUp write FOnGridCellMouseUp;
    property CellBorder: TCellBorder read FCellBorder write FCellBorder;
    property CellBorderColor: TColor read FCellBorderColor write FCellBorderColor default clBlack;
    property Font: TFont read FFont write setFont;

  end;
var
  OldSpriteMouseDown : SE_SpriteMouseEvent;
  OldSpriteMouseUp : SE_SpriteMouseEvent;
  OldSpriteMouseMove : SE_SpriteMouseMoveEvent;
  Mutex: Cardinal;
  IncPriority: integer;
procedure Register;
implementation
procedure Register;
begin
  RegisterComponents('DSE', [SE_Grid]);
end;

constructor SE_Grid.Create(Owner: TComponent);
var
  m: string;
begin
  ffont:= TFont.Create;
  m:= 'se_grid' + IntTostr(GetTickcount);
  inherited Create(Owner);
  if not (csDesigning in ComponentState) then begin
    Mutex:=CreateMutex(nil,false,  pwidechar(m) );
    Columns:= TObjectList<SE_Col>.Create(true);
    Rows:= TObjectList<SE_Row>.Create(true);
    fCells:= TObjectList<SE_Cell>.Create(true);
    CellsEngine:= SE_Engine.Create(Owner);
    CellsEngine.fTheater := Self;
    Self.AttachSpriteEngine(CellsEngine);
    IncPriority := 0;
 //   thrdAnimate.KeepAlive := false;

  end;

end;

destructor SE_Grid.Destroy;
var
  i: integer;
begin

  ffont.free;
  if not (csDesigning in ComponentState) then begin
    Columns.Free;
    Rows.Free;

    for i := 0 to fcells.Count -1 do begin
      if fCells[i].Bitmap <> nil then begin
        fCells[i].Bitmap.Free;
      end;
      if fCells[i].ProgressBar <> nil then begin
        fCells[i].ProgressBar.Free;
      end;
    end;
    fCells.Free;

  end;

  inherited;
 // CloseHandle(Mutex);
end;
procedure SE_grid.Loaded;
var
  aCol: SE_Col;
  aRow: SE_Row;
  aCell: SE_Cell;
  bmp: SE_Bitmap;
begin
  Inherited;
  if not (csDesigning in ComponentState) then begin
//    Passive := True;
    //thrdAnimate.Interval := AnimationInterval;
    OldSpriteMouseDown := OnSpriteMouseDown;
    OldSpriteMouseUp := OnSpriteMouseUp;
    OldSpriteMouseMove := OnSpriteMouseMove;
    OnSpriteMouseDown := MySpriteMouseDown;
    OnSpriteMouseUp := MySpriteMouseUp;
    OnSpriteMouseMove := MySpriteMouseMove;
    aCol := SE_col.Create;
    aCol.Width := iMax(1,fdefaultColwidth);
    Columns.Add(aCol);

    aRow := SE_Row.Create;
    aRow.Height := iMax(1,fdefaultRowHeight);
    Rows.Add(aRow);

    aCell := SE_Cell.Create;
    aCell.Col := 0;
    aCell.Row := 0;
    aCell.FontName := ffont.Name;
    aCell.FontSize := 8;
    aCell.FontColor := ffont.Color;
    aCell.BackColor := Backcolor;
    bmp:= SE_Bitmap.Create ( Columns[ACell.Col].Width, Rows[ACell.Row].Height) ;
    bmp.Canvas.Brush.Color := aCell.BackColor;
    bmp.FillRect(0,0,bmp.Width,bmp.Height,ACell.BackColor);

    aCell.Sprite := CellsEngine.CreateSprite(bmp.bitmap, IntToStr(aCell.Col) +':'+IntToStr(aCell.Row),1,1,1000,
                                                   bmp.Width div 2,bmp.Height div 2,false);
    bmp.Free;

    inc (IncPriority);
    aCell.Sprite.Priority := IncPriority;
    fCells.Add(aCell);
  end;
end;

procedure SE_grid.RefreshSurface(Sender: TObject);
begin
  ProcessAllCells;
  inherited;

end;
function SE_grid.GetColCount : integer;
begin
  Result := Columns.Count;
end;
function SE_grid.GetRowCount : integer;
begin
  Result := Rows.Count;
end;
procedure SE_grid.SetColCount ( const n: integer );
var
  i: integer;
begin
  // aggiorno le colonne
  if not (csDesigning in ComponentState) then begin
    if n < 1 then
      exit;
    GridUpdate:= true;

    if n < ColCount then begin
      for I := Columns.Count -1 downto 0 do begin
        RemoveColumn ( Columns.Count -1 );
        if n >= Columns.Count then Exit;  // devo forzarlo
      end;
    end
    else if n > ColCount then begin
      while n > ColCount do begin
        AddColumn;
        if n = Columns.Count then Exit;   // devo forzarlo
      end;
    end;
    GridUpdate:= false;

  end;

end;
procedure SE_grid.SetRowCount ( const n: integer );
var
  i: integer;
begin
  // aggiorno le righe

  if not (csDesigning in ComponentState) then begin
    if n < 1 then
      exit;

  GridUpdate:= true;
    if n < Rows.Count then begin
      for I := Rows.Count -1 downto 0 do begin
        RemoveRow(i);
        if n >= Rows.Count then Exit;  // devo forzarlo
      end;
    end
    else if n > Rows.Count then begin
      while n > Rows.Count do begin
        AddRow;
        if n = Rows.Count then Exit;   // devo forzarlo
      end;
    end;
    GridUpdate:= false;

  end;
end;
procedure SE_grid.AddRow;
var
  C: integer;
  aCell: SE_Cell;
  aRow : SE_Row;
  TotCellWidth,TotCellHeight: integer;
  bmp: SE_Bitmap;
begin
  GridUpdate:= true;

  aRow := SE_Row.Create;
  aRow.Height := iMax(1,fdefaultRowHeight);
  Rows.Add(aRow);

  C:=0;
  while C < Columns.count do begin
    aCell := SE_Cell.Create;
    ACell.Col := C;
    aCell.Row := RowCount -1;
    aCell.FontName := ffont.Name;
    aCell.FontSize := ffont.Size;
    aCell.FontColor := ffont.Color;
    aCell.BackColor := Backcolor;

    TotCellWidth := GetTotCellWidth ( ACell.Col -1 ); // somma colWidth fino a i-1
    TotCellHeight := GetTotCellHeight ( ACell.Row -1 ); // somma Rowheight fino a i-1
    bmp:= SE_Bitmap.Create ( imax(Columns[ACell.Col].Width,1), imax(aRow.Height,1)) ;
    bmp.Canvas.Brush.Color := aCell.BackColor;
    bmp.FillRect(0,0,bmp.Width,bmp.Height,ACell.BackColor);

    aCell.Sprite := CellsEngine.CreateSprite(bmp.bitmap, IntToStr(aCell.Col) +':'+IntToStr(aCell.Row),1,1,1000,
                                                  TotCellWidth+bmp.Width div 2,TotCellHeight + bmp.Height div 2,false);
    bmp.Free;
    inc (IncPriority);
    aCell.Sprite.Priority := IncPriority;
    fCells.Add(aCell);
    Inc (C);
  end;
  GridUpdate:= false;
end;
procedure SE_grid.RemoveRow ( const idx: integer );
var
  i: integer;
  aSprite: SE_Sprite;
  aCell: SE_cell;
begin
  if (idx < 0) or (idx > RowCount -1) or (RowCount =1) then
    exit;
  WaitForSingleObject(Mutex,INFINITE);

  GridUpdate:= true;
  Rows.Delete(idx);

  // rimuovo le row
  for I := fCells.count -1 downto 0 do begin
    if fcells[i].Row = idx then begin
      if fCells[i].Bitmap <> nil then FreeAndNil(fCells[i].Bitmap);//.Free);
      if fCells[i].ProgressBar <> nil then FreeAndNil(fCells[i].ProgressBar);//.Free;
      aSprite := CellsEngine.FindSprite( IntTostr(fcells[i].Col) +':' +  IntTostr(fcells[i].Row)   );
      CellsEngine.RemoveSprite(aSprite);
      CellsEngine.ProcessSprites(1);
      fCells[i].Sprite := nil;
      fCells.Delete(i);
    end;
  end;
  CellsEngine.ProcessSprites( 1 ); // importante o memoryleak di sprites
  // scalo tutte le Row di 1
  fCells.sort(TComparer<SE_cell>.Construct(
  function (const L, R: SE_cell): integer
  begin
    Result := (L.Row )- (R.Row  );
  end
 ));

  for I := 0 to fCells.count -1 do begin
    if fcells[i].Row > idx then begin
      fcells[i].Row := fcells[i].Row -1;
      fcells[i].Sprite.Guid := IntToStr(fcells[i].Col) +':'+IntToStr(fcells[i].Row);
    end;
  end;

  GridUpdate:= false;
  ReleaseMutex(Mutex);

end;

procedure SE_grid.AddColumn;
var
  R: integer;
  aCell: SE_Cell;
  aCol : SE_Col;
  TotCellWidth,TotCellHeight: integer;
  bmp: SE_Bitmap;
begin
  GridUpdate:= true;
  aCol := SE_Col.Create;
  aCol.Width :=  iMax(1,fdefaultColWidth);
  Columns.Add(aCol);

  R:=0;
  while R < Rows.count do begin
    aCell := SE_Cell.Create;
    ACell.Col := ColCount-1;
    aCell.Row := R;
    aCell.FontName := ffont.Name;
    aCell.FontSize := 8;
    aCell.FontColor := clWhite;
    aCell.BackColor := Backcolor;
    TotCellWidth := GetTotCellWidth ( ACell.Col -1 ); // somma colWidth fino a i-1
    TotCellHeight := GetTotCellHeight ( ACell.Row -1 ); // somma Rowheight fino a i-1
    bmp:= SE_Bitmap.Create ( imax(aCol.Width,1), imax(Rows[ACell.Row].Height,1)) ;
    bmp.Canvas.Brush.Color := aCell.BackColor;
    bmp.FillRect(0,0,bmp.Width,bmp.Height,ACell.BackColor);

    aCell.Sprite := CellsEngine.CreateSprite(bmp.bitmap, IntToStr(aCell.Col) +':'+IntToStr(aCell.Row),1,1,1000,
                                                  TotCellWidth+bmp.Width div 2,TotCellHeight + bmp.Height div 2,false);
    bmp.Free;
    inc (IncPriority);
    aCell.Sprite.Priority := IncPriority;
    fCells.Add(aCell);
    Inc (R);
  end;
  GridUpdate:= false;
end;
procedure SE_grid.RemoveColumn ( const idx: integer );
var
  i: integer;
  aSprite: SE_Sprite;
begin
  if (idx < 0) or (idx > ColCount -1) or ( ColCount = 1) then
    exit;
  WaitForSingleObject(Mutex,INFINITE);
  GridUpdate:= true;

  Columns.Delete(idx);

  // rimuovo le row di quella colonna
  for I := fCells.count -1 downto 0 do begin
    if fcells[i].Col = idx then begin
      if fCells[i].Bitmap <> nil then fCells[i].Bitmap.Free;
      if fCells[i].ProgressBar <> nil then fCells[i].ProgressBar.Free;
      aSprite := CellsEngine.FindSprite( IntTostr(fcells[i].Col) +':' +  IntTostr(fcells[i].Row)   );
      CellsEngine.RemoveSprite(aSprite);
      CellsEngine.ProcessSprites(1);
      fcells[i].Sprite := nil;
      fCells.Delete(i);
    end;
  end;


  // scalo tutte le col di 1
  fCells.sort(TComparer<SE_cell>.Construct(
  function (const L, R: SE_cell): integer
  begin
    Result := (L.col )- (R.col  );
  end
 ));

  for I := 0 to fCells.count -1 do begin
    if fcells[i].Col > idx then begin
      fcells[i].Col := fcells[i].Col -1;
      fcells[i].Sprite.Guid := IntToStr(fcells[i].Col) +':'+IntToStr(fcells[i].Row);
    end;
  end;


  GridUpdate:= false;
  ReleaseMutex(Mutex);
end;
procedure SE_grid.ClearData;
var
  I: integer;
begin
  WaitForSingleObject(Mutex,INFINITE);
  GridUpdate:= true;
  for i := 0 to fCells.Count -1 do begin
    fcells[i].BackColor := BackColor;
    fcells[i].Text := '';
    if fcells[i].Bitmap <> nil then fcells[i].Bitmap.Free;
    fcells[i].Bitmap := nil;
    if fcells[i].ProgressBar <> nil then fcells[i].ProgressBar.Free;
    fcells[i].ProgressBar := nil;
  end;
  GridUpdate:= false;
  ReleaseMutex(Mutex);

end;

function SE_grid.GetCell ( Col, Row : integer ): SE_Cell;
var
  i: integer;
begin
  result := nil;
  for I := 0 to fCells.Count -1 do begin
    if (fCells[i].Col = Col) and (fCells[i].Row = Row) then begin
      Result := fCells[i];
      exit;
    end;
  end;
end;
procedure SE_grid.AddSE_Bitmap ( const CellX, CellY, copies: integer; bmp: SE_Bitmap; Transparent:boolean);
begin
  Cells[CellX,CellY].Bitmap := SE_Bitmap.Create (bmp);
  Cells[CellX,CellY].BitmapCopies := copies;
  Cells[CellX,CellY].BitmapTransparent := Transparent;
end;
procedure SE_grid.AddProgressBar ( const CellX, CellY, Value: integer; Const Color: TColor; Style: SE_ProgressBarStyle );
begin
  Cells[CellX,CellY].ProgressBar := SE_Bitmap.Create ( Columns[CellX].Width, Rows[CellY].Height  );
  Cells[CellX,CellY].ProgressBarStyle := Style;
  Cells[CellX,CellY].ProgressBarValue := Value;
  Cells[CellX,CellY].ProgressBarColor := Color;
end;
procedure SE_grid.ProcessAllCells;
var
  I,TotCellWidth,TotCellHeight,DstX,DstY,X: integer;
  bmp,tmp: SE_Bitmap;
  TextWidth,Diff: integer;
  aSize: TSize;
  XOutput,YOutput,NewVirtualWidth,NewVirtualHeight: integer;
begin

  if GridUpdate then exit;
  WaitForSingleObject(Mutex,INFINITE);
  if (RowCount < 1) or ( ColCount < 1) then begin
    exit;

  end;

  NewVirtualWidth := iMax (GetTotCellWidth ( ColCount -1), Width) ;
  NewVirtualHeight := iMax (GetTotCellHeight ( RowCount -1), Height ) ;

  if NewVirtualWidth <> VirtualWidth then
    VirtualWidth :=  NewVirtualWidth;
  if NewVirtualHeight <> VirtualHeight then
    VirtualHeight := NewVirtualHeight ;

  VirtualBitmap.Bitmap.Canvas.Brush.Color := BackColor;
  VirtualBitmap.FillRect(0,0,  VirtualWidth, VirtualHeight,BackColor);


  for I := 0 to fCells.Count -1 do begin
    TotCellWidth := GetTotCellWidth ( fCells[i].Col -1 ); // somma colWidth fino a i-1
    TotCellHeight := GetTotCellHeight ( fCells[i].Row -1 ); // somma Rowheight fino a i-1

    tmp:= SE_Bitmap.Create ( Columns[fCells[i].col ].Width,Rows[fCells[i].Row ].height);

    //fCells[i].Sprite.BMP.Resize( Columns[fCells[i].col ].Width,Rows[fCells[i].Row ].height , fCells[i].BackColor );
    fcells[i].Sprite.ChangeBitmap (  tmp.Bitmap,1,1,1000);
    tmp.Free;

    bmp := fCells[i].Sprite.BMP;

    bmp.Canvas.Brush.Color := fCells[i].BackColor;
    bmp.Canvas.Brush.Style := bsSolid;
    bmp.FillRect(0,0,bmp.Width,bmp.Height,fCells[i].BackColor);


    // alignment
    aSize := bmp.Canvas.TextExtent(fCells[i].Text );
    if fCells[i].CellAlignmentH  = HLeft then begin
      XOutPut := 0;
    end
    else if fCells[i].CellAlignmentH  = HCenter then begin
      XOutPut := (Bmp.Width - aSize.Width) div 2;
    end
    else if fCells[i].CellAlignmentH  = HRight then begin
      XOutPut := (Bmp.Width - aSize.Width) - 4; // -4 pixel di sicurezza
    end;
    if fCells[i].CellAlignmentV  = VTop then begin
      YOutPut := 0;
    end
    else if fCells[i].CellAlignmentV  = VCenter then begin
      YOutPut := (Bmp.Height - aSize.Height) div 2;
    end
    else if fCells[i].CellAlignmentV  = VBottom then begin
      YOutPut := (Bmp.Height - aSize.Height);
    end;

    // TextOut
    if ( fcells[i].ProgressBar = nil ) and ( fCells[i].Text <> '') then begin
      bmp.Canvas.pen.mode := pmCopy ;
      bmp.bitmap.Canvas.Font.name := fCells[i].FontName;
      bmp.bitmap.Canvas.Font.Size := fCells[i].FontSize;
      bmp.bitmap.Canvas.Font.Style := fCells[i].FontStyle;
      bmp.bitmap.Canvas.Font.Color := fCells[i].FontColor;
      bmp.bitmap.Canvas.Brush.Style := bsClear;
      bmp.bitmap.Canvas.Font.Quality :=  fqAntialiased;
      bmp.Bitmap.Canvas.TextOut ( XOutPut , YOutPut, fCells[i].Text ) ;
    end;
    // Bitmap sempre centrata nella cella
    if fCells[i].Bitmap <> nil then begin
      dstX:=0;
      dstY:= (Rows[fcells[i].Row].Height - fCells[i].Bitmap.Height) div 2;
      for X := 0 to fCells[i].BitmapCopies -1 do begin
        fCells[i].Bitmap.CopyRectTo(bmp,0,0,dstX,dstY,fCells[i].Bitmap.Width,fCells[i].Bitmap.Height,fCells[i].BitmapTransparent,fCells[i].Bitmap.Pixel[0,0]   );
        dstX := dstX + fCells[i].Bitmap.Width;
      end;

    end;

    // ProgressBar
    if fCells[i].ProgressBar <> nil then begin
      // la cella ha il backColor già settato
      bmp.bitmap.Canvas.Font.name := fCells[i].FontName;
      bmp.bitmap.Canvas.Font.Size := fCells[i].FontSize;
      bmp.bitmap.Canvas.Font.Style := fCells[i].FontStyle;
      bmp.bitmap.Canvas.Font.Color := fCells[i].FontColor;
      bmp.bitmap.Canvas.Brush.Color := fCells[i].ProgressBarColor;
      bmp.bitmap.Canvas.Pen.Color := fCells[i].ProgressBarColor;
      bmp.bitmap.Canvas.Brush.Style := bsSolid;

      if fCells[i].ProgressBarValue > 0 then begin
        if fCells[i].ProgressBarStyle = pbStandard then begin
          bmp.FillRect(0,0, (fCells[i].ProgressBarValue * Columns[fCells[i].Col].Width) div 100,Rows[fCells[i].Row].Height,fCells[i].ProgressBarColor) ;
        end
        else if fCells[i].ProgressBarStyle = pbSingleLineTop then begin
          bmp.Canvas.MoveTo( 0, 1 );  // pixel alto riservato per il border
          bmp.Canvas.LineTo( (fCells[i].ProgressBarValue * Columns[fCells[i].Col].Width) div 100, 1 );
        end
        else if fCells[i].ProgressBarStyle = pbSingleLineCenter then begin
          bmp.Canvas.MoveTo( 0, Rows[fCells[i].Row].Height div 2 );  // al centro
          bmp.Canvas.LineTo( (fCells[i].ProgressBarValue * Columns[fCells[i].Col].Width) div 100,  Rows[fCells[i].Row].Height div 2 );
        end
        else if fCells[i].ProgressBarStyle = pbSingleLineBottom then begin
          bmp.Canvas.MoveTo( 0, Rows[fCells[i].Row].Height -2 );  // pixel basso riservato per il border
          bmp.Canvas.LineTo( (fCells[i].ProgressBarValue * Columns[fCells[i].Col].Width) div 100, Rows[fCells[i].Row].Height -2 );
        end;
      end;

      if fCells[i].Text <> '' then begin // ribadisco il testo ma lo centro
        bmp.bitmap.Canvas.Brush.Style := bsClear;
        aSize := bmp.Canvas.TextExtent(fCells[i].Text );
        XOutPut := (Bmp.Width - aSize.Width) div 2;
        YOutPut := (Bmp.Height - aSize.Height) div 2;
        bmp.Bitmap.Canvas.TextOut ( XOutPut , YOutPut, fCells[i].Text ) ;

      end
      else if fCells[i].ProgressBarShowPercent then begin  // ribadisco il testo ma lo centro
        bmp.bitmap.Canvas.Brush.Style := bsClear;
        if (fCells[i].ProgressBarValue > 0) and (fCells[i].ProgressBarValue < 101) then begin
          aSize := bmp.Canvas.TextExtent( IntTostr( fCells[i].ProgressBarValue) + '%');
          XOutPut := (Bmp.Width - aSize.Width) div 2;
          YOutPut := (Bmp.Height - aSize.Height) div 2;
          bmp.Bitmap.Canvas.TextOut ( XOutPut , YOutPut, IntTostr( fCells[i].ProgressBarValue) + '%' ) ;

        end;
      end;

    end;

    // BorderCell
    if fCellBorder = CellBorderSquare then begin
      SquareBorder (bmp.bitmap, bmp.width, Bmp.Height, fCells[i].BackColor );

    end
    else if fCellBorder = CellBorderRound then begin
      RoundBorder (bmp.bitmap, bmp.width, Bmp.Height, fCells[i].BackColor );

    end;

    fCells[i].Sprite.Position := Point( TotCellWidth + bmp.Width div 2 ,TotCellHeight + bmp.Height div 2);

  end;
  ReleaseMutex(Mutex);
end;
procedure SE_grid.RoundBorder (bmp: TBitmap; w,h: Integer; CellBackColor :TColor);
var
x,y: Integer;
begin

      for x := 0 to bmp.Width -1 do begin
          bmp.Canvas.Pixels [x,0]:= FCellBorderColor;
          bmp.Canvas.Pixels [x,bmp.Height -1]:= FCellBorderColor;
      end;
      for y := 0 to bmp.height -1 do begin
          bmp.Canvas.Pixels [0,y]:= FCellBorderColor;
          bmp.Canvas.Pixels [bmp.width-1,y]:= FCellBorderColor;
      end;

      bmp.Canvas.Pixels [0,0]:= cellBackColor;
      bmp.Canvas.Pixels [0,1]:= cellBackColor;
      bmp.Canvas.Pixels [0,2]:= cellBackColor;
      bmp.Canvas.Pixels [1,0]:= cellBackColor;
      bmp.Canvas.Pixels [2,0]:= cellBackColor;

      bmp.Canvas.Pixels [w-3,0]:= cellBackColor;
      bmp.Canvas.Pixels [w-2,0]:= cellBackColor;
      bmp.Canvas.Pixels [w-1,0]:= cellBackColor;
      bmp.Canvas.Pixels [w-1,1]:= cellBackColor;
      bmp.Canvas.Pixels [w-1,2]:= cellBackColor;

      bmp.Canvas.Pixels [w-3,h-1]:= cellBackColor;
      bmp.Canvas.Pixels [w-2,h-1]:= cellBackColor;
      bmp.Canvas.Pixels [w-1,h-1]:= cellBackColor;
      bmp.Canvas.Pixels [w-1,h-2]:= cellBackColor;
      bmp.Canvas.Pixels [w-1,h-3]:= cellBackColor;

      bmp.Canvas.Pixels [0,h-3]:= cellBackColor;
      bmp.Canvas.Pixels [0,h-2]:= cellBackColor;
      bmp.Canvas.Pixels [0,h-1]:= cellBackColor;
      bmp.Canvas.Pixels [1,h-1]:= cellBackColor;
      bmp.Canvas.Pixels [2,h-1]:= cellBackColor;



end;
procedure SE_grid.SquareBorder (bmp: TBitmap; w,h: Integer; CellBackColor :TColor);
var
x,y: Integer;
begin

      for x := 0 to bmp.Width -1 do begin
          bmp.Canvas.Pixels [x,0]:= FCellBorderColor;
          bmp.Canvas.Pixels [x,bmp.Height -1]:= FCellBorderColor;
      end;
      for y := 0 to bmp.height -1 do begin
          bmp.Canvas.Pixels [0,y]:= FCellBorderColor;
          bmp.Canvas.Pixels [bmp.width-1,y]:= FCellBorderColor;
      end;


end;

Function SE_grid.GetTotalCellWidth : integer;
var
  i: integer;
begin
  Result := 0;
  for I := 0 to Columns.count -1 do begin
    Result := Result + Columns[i].Width ;
  end;

end;
Function SE_grid.GetTotalCellHeight: integer;
var
  i: integer;
begin

  Result := 0;
  for I := 0 to Rows.Count -1 do begin
    Result := Result + Rows[i].Height ;
  end;

end;
Function SE_grid.GetTotCellWidth ( Limit: integer ): integer;
var
  i: integer;
begin
  Result := 0;
  if Limit < 0 then
    exit;

  for I := 0 to Limit do begin
    Result := Result + Columns[i].Width ;
  end;

end;
Function SE_grid.GetTotCellHeight ( Limit: integer ): integer;
var
  i: integer;
begin

  Result := 0;
  if Limit < 0 then
    exit;

  Result := 0;
  for I := 0 to Limit do begin
    Result := Result + Rows[i].Height ;
  end;

end;
procedure SE_Grid.SetFont ( v: TFont );
begin
  ffont.Assign(v);
end;

procedure SE_Grid.MySpriteMouseDown(Sender: TObject; lstSprite: TObjectList<SE_Sprite>; Button: TMouseButton; Shift: TShiftState);
var
  CellX,CellY: integer;
begin
//    OldSpriteMouseDown (Button, Shift,X, Y);
    //inherited MouseDown;
    if Assigned( FOnGridCellmousedown ) and (lstSprite.Count > 0)  then begin
      CellX := StrtoInt(ExtractWordL (1,lstSprite[0].Guid,':'));
      CellY := StrtoInt(ExtractWordL (2,lstSprite[0].Guid,':'));
      FOnGridCellmousedown( self,  Button, Shift, CellX, CellY, lstSprite[0] );
    end;
end;
procedure SE_Grid.MySpriteMouseUp(Sender: TObject; lstSprite: TObjectList<SE_Sprite>; Button: TMouseButton; Shift: TShiftState);
var
  CellX,CellY: integer;
begin
    if Assigned( FOnGridCellmouseUp ) and (lstSprite.Count > 0)  then begin
      CellX := StrtoInt(ExtractWordL (1,lstSprite[0].Guid,':'));
      CellY := StrtoInt(ExtractWordL (2,lstSprite[0].Guid,':'));
      FOnGridCellmouseUp( self,  Button, Shift, CellX, CellY, lstSprite[0] );
    end;
end;
procedure SE_Grid.MySpriteMouseMove(Sender: TObject; lstSprite: TObjectList<SE_Sprite>; Shift: TShiftState; var Handled: boolean);
var
  CellX,CellY: integer;
begin
  if Assigned( FOnGridCellMouseMove )  then begin
      Handled := True;
      CellX := StrtoInt(ExtractWordL (1,lstSprite[0].Guid,':'));
      CellY := StrtoInt(ExtractWordL (2,lstSprite[0].Guid,':'));
      FOnGridCellMouseMove( self, Shift, CellX, CellY, lstSprite[0]);
  end;
end;
{
procedure SE_Grid.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  ParForm: TCustomForm;
  i,L,Row,Col: integer;
begin
  inherited;
  ParForm := GetParentForm(Self);
  if (ParForm<>nil) and (ParForm.Visible) and CanFocus then
    SetFocus;


  L:=0;
  for I := 0 to Columns.Count -1 do  begin
    Inc(L, Columns[i].Width);
    if Y < L then begin
      Col := I;
      break;
    end;
  end;

  L:=0;
  for I := 0 to Rows.Count -1 do  begin
    Inc(L, Rows[i].Height);
    if X < L then begin
      Row := I;
      break;
    end;
  end;


  if Assigned( FOnCellMouseDown ) then
    FOnCellMouseDown( self, Button, Shift, Col, Row );


end;



procedure SE_grid.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  i,L,Row,Col: integer;
begin
  inherited;

  L:=0;
  for I := 0 to Columns.Count -1 do  begin
    Inc(L, Columns[i].Width);
    if Y < L then begin
      Col := I;
      break;
    end;
  end;

  L:=0;
  for I := 0 to Rows.Count -1 do  begin
    Inc(L, Rows[i].Height);
    if X < L then begin
      Row := I;
      break;
    end;
  end;


  if Assigned( FOnCellMouseMove )  then begin
    FOnCellMouseMove( self, Shift, Col, Row );
  end;


end;

procedure SE_grid.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  i,L,Row,Col: integer;
begin
  inherited;

  L:=0;
  for I := 0 to Columns.Count -1 do  begin
    Inc(L, Columns[i].Width);
    if Y < L then begin
      Col := I;
      break;
    end;
  end;

  L:=0;
  for I := 0 to Rows.Count -1 do  begin
    Inc(L, Rows[i].Height);
    if X < L then begin
      Row := I;
      break;
    end;
  end;


  if Assigned( FOnCellMouseUp ) then
    FOnCellMouseUp( self, Button, Shift, Col, Row );

end;
}

end.
