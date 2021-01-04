object Form1: TForm1
  Left = 0
  Top = 0
  Caption = 'SE-Massive Load'
  ClientHeight = 722
  ClientWidth = 1032
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object SE_Theater1: SE_Theater
    Left = 0
    Top = 0
    Width = 1024
    Height = 600
    MouseScrollRate = 1.000000000000000000
    MouseWheelInvert = False
    MouseWheelValue = 10
    MouseWheelZoom = True
    MousePan = True
    MouseScroll = False
    BackColor = clBlack
    AnimationInterval = 20
    GridInfoCell = False
    GridVisible = False
    GridColor = clSilver
    GridCellWidth = 40
    GridCellHeight = 30
    GridCellsX = 30
    GridCellsY = 20
    GridHexSmallWidth = 10
    CollisionDelay = 300
    ShowPerformance = True
    OnBeforeVisibleRender = SE_Theater1BeforeVisibleRender
    WrapHorizontal = False
    WrapVertical = False
    VirtualWidth = 1200
    Virtualheight = 1920
    TabOrder = 0
  end
  object Panel1: TPanel
    Left = 647
    Top = 611
    Width = 185
    Height = 97
    Alignment = taLeftJustify
    Caption = 'Scroll'
    TabOrder = 1
    VerticalAlignment = taAlignTop
    object Label1: TLabel
      Left = 16
      Top = 70
      Width = 89
      Height = 13
      AutoSize = False
      Caption = 'MouseScrollRate'
    end
    object CheckBox1: TCheckBox
      Left = -1
      Top = 24
      Width = 97
      Height = 17
      Caption = 'MousePan'
      Checked = True
      State = cbChecked
      TabOrder = 0
      OnClick = CheckBox1Click
    end
    object CheckBox2: TCheckBox
      Left = -1
      Top = 47
      Width = 97
      Height = 17
      Caption = 'MouseScroll'
      TabOrder = 1
      OnClick = CheckBox2Click
    end
    object Edit1: TEdit
      Left = 102
      Top = 67
      Width = 34
      Height = 21
      NumbersOnly = True
      TabOrder = 2
      Text = '1.00'
      OnChange = Edit1Change
    end
  end
  object Panel2: TPanel
    Left = 839
    Top = 611
    Width = 185
    Height = 97
    Alignment = taLeftJustify
    Caption = 'Zoom'
    TabOrder = 2
    VerticalAlignment = taAlignTop
    object Label2: TLabel
      Left = 16
      Top = 70
      Width = 89
      Height = 13
      AutoSize = False
      Caption = 'MouseWheelValue'
    end
    object CheckBox3: TCheckBox
      Left = -1
      Top = 24
      Width = 97
      Height = 17
      Caption = 'MouseWheelZoom'
      Checked = True
      State = cbChecked
      TabOrder = 0
      OnClick = CheckBox3Click
    end
    object CheckBox4: TCheckBox
      Left = -1
      Top = 47
      Width = 97
      Height = 17
      Caption = 'Invert Wheel'
      TabOrder = 1
      OnClick = CheckBox4Click
    end
    object Edit2: TEdit
      Left = 102
      Top = 67
      Width = 34
      Height = 21
      NumbersOnly = True
      TabOrder = 2
      Text = '10'
      OnChange = Edit2Change
    end
  end
  object Button1: TButton
    Left = 520
    Top = 607
    Width = 105
    Height = 25
    Caption = 'build random Path'
    TabOrder = 3
    OnClick = Button1Click
  end
  object Button2: TButton
    Left = 409
    Top = 606
    Width = 105
    Height = 25
    Caption = 'Add Buff'
    TabOrder = 4
    OnClick = Button2Click
  end
  object Button3: TButton
    Left = 298
    Top = 606
    Width = 105
    Height = 25
    Caption = 'Add labels'
    TabOrder = 5
    OnClick = Button3Click
  end
  object CheckBox5: TCheckBox
    Left = 176
    Top = 609
    Width = 97
    Height = 17
    Caption = 'PixelCollision'
    Checked = True
    State = cbChecked
    TabOrder = 6
    OnClick = CheckBox5Click
  end
  object CheckBox6: TCheckBox
    Left = 48
    Top = 609
    Width = 97
    Height = 17
    Caption = 'Show MovePath'
    TabOrder = 7
  end
  object Memo1: TMemo
    Left = 32
    Top = 632
    Width = 193
    Height = 89
    Lines.Strings = (
      'Memo1')
    TabOrder = 8
  end
  object SE_Background: SE_Engine
    ClickSprites = False
    PixelCollision = False
    HiddenSpritesMouseMove = False
    HiddenSpritesMouseClick = False
    IsoPriority = False
    Priority = 0
    Theater = SE_Theater1
    Left = 280
    Top = 656
  end
  object SE_Characters: SE_Engine
    PixelClick = True
    PixelCollision = False
    HiddenSpritesMouseMove = False
    HiddenSpritesMouseClick = False
    IsoPriority = True
    Priority = 1
    Theater = SE_Theater1
    OnCollision = SE_CharactersCollision
    OnSpriteDestinationReached = SE_CharactersSpriteDestinationReached
    Left = 512
    Top = 656
  end
  object SE_ThreadTimer1: SE_ThreadTimer
    Enabled = True
    Interval = 300
    KeepAlive = True
    OnTimer = SE_ThreadTimer1Timer
    Left = 368
    Top = 656
  end
  object SE_label: SE_Engine
    ClickSprites = False
    PixelCollision = False
    HiddenSpritesMouseMove = False
    HiddenSpritesMouseClick = False
    IsoPriority = False
    Priority = 1
    Theater = SE_Theater1
    RenderBitmap = VisibleRender
    Left = 232
    Top = 656
  end
  object SE_ThreadTimer2: SE_ThreadTimer
    Enabled = True
    KeepAlive = True
    OnTimer = SE_ThreadTimer2Timer
    Left = 456
    Top = 656
  end
end
