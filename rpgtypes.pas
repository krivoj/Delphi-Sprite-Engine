unit RpgTypes;
{$define rpg_client}
//{$define server}

interface


uses
  Windows,{$ifdef rpg_client}dse_Bitmap,{$endif}SysUtils,Classes,vcl.Graphics;

Const RpgObj_Char=0;
Const RpgObj_Npc=1;
Const RpgObj_Item=2;
Const RpgObj_SkillIcon=3;
Const RpgObj_Aura=4;
Const RpgObj_Path=5;
Const RpgObj_Effect=6;

Const RpgObj_SkillCasting=7; // dead a StopEndX
Const RpgObj_SkillMoving=8;  // dead a destinationReached
Const RpgObj_SkillHit=9;     // dead a stopEndX
Const RpgObj_SkillDynMoving=10;  // dead a destinationReached
Const RpgObj_SkillDynHit=11;  // dead a destinationReached

Const cDead = 0;
Const cwalk = 1;
Const ccasting = 2;
Const cIdle = 3;
Const chitted = 4;
Const cSpawn = 5;

Const sDead = 0;
Const sReady = 1;
Const sMoving = 2;
Const sIdle = 3;
Const sCooldown = 4;
Const sActive = 5;
Const sCasting = 6;

Const aDead = 0;
Const aReady = 1;
Const aLoad = 2;
Const aDone = 3;
Const aCooldown = 4;
Const aActive = 5;


Type TmsgManager =  (msg_death, msg_cast, msg_execute, msg_hit, msg_hitted, msg_damaged, msg_damageDone, msg_healDone, msg_healed, msg_stack);
Type TArray7 = array [0..6] of integer;

Type TByteArray500 = array[0..499] of Byte;
Type PByteArray500 = ^TByteArray;

Type TByteArray4096 = array[0..4095] of Byte; // forse di più per affectedskills (tutte le skills)
Type PByteArray4096 = ^TByteArray;
type TneighboursFilter = (Friendly, Hostile, Neutral, All, AllButHostileStealth);


type
  TlocalMapCoord = record
    Terrain: integer;
    shadow: integer;
  end;



(*************************************************
TiraLabel
*************************************************)
Type TiraLabel = record
  ShowLabel:boolean;
  Font: TFont ;
  Style : TBrushStyle;
  Color: Tcolor;
  X,Y: integer;
  Text: String;
end;
 pIraLabel=^TIraLabel;




{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
(*                                                                         *)
(*                    TrpgVarCharDB                                           *)
(*                                                                         *)
{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
  Type TrpgVarCharDB = record
    id: integer;

    defaultname: string [20];
    Race: string [20];
    Classes: string [50];
    Vitality: single;
    Stamina: single;
    defense: single;
    Endurance: single;
    Accuracy: integer;
    Evasion: integer;
    Conviction: single;
    WillPower: single;
    skills    : TByteArray500;//array[0..499] of byte;
    //skills: string [255]; //500
    talents: string  [255];
    masteries: string  [255];
    resistances: string  [255];
    spritename :string  [20];
 end;
  Type
  PRpgVarCharDB = ^TRpgVarCharDB;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
(*                                                                         *)
(*                    TrpgCharDB                                           *)
(*                                                                         *)
{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
  Type TrpgCharDB = record
  id : integer;
  defaultname :string[20];
  attack : single ;
  defense : single ;
  stamina : single ;
  vitality : single ;

  masteries, resistances : array [0..8] of double;

  mfire : single ;
  mearth : single ;
  mlight : single ;
  mphysical : single ;
  mwater : single ;
  mdark : single ;
  mwind : single ;
  rfire : single ;
  rearth : single ;
  rlight : single ;
  rphysical : single ;
  rwater : single ;
  rdark : single ;
  rwind : single ;

  crit : single ;
  critdmg : single ;
  accuracy : single ;
  dodge : single ;
  power: single;
  talents  : string  [255];
  spritename : string [20];
  race : string [20];
  classes : string [20];
  regenhealth : integer;
  speed : double;
 end;
  Type
  PRpgCharDB = ^TrpgCharDB;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
(*                                                                         *)
(*                    TrpgItemDB                                           *)
(*                                                                         *)
{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}

Type
TRpgItemDB = TrpgCharDB;

  Type
  PRpgItemDB = ^TRpgCharDB;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
(*                                                                         *)
(*                    TrpgTalentDB                                          *)
(*                                                                         *)
{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}

Type
TRpgTalentDB = Record
  id : integer;
  tree : String[20];
  talentName : string[30];
  effects: string[255];
  //affectedskills : TByteArray4096;//array[0..499] of byte;
  rankinfo1: string[40];
  rankinfo2: string[40];
  loadpriority: integer;
  spritename: string[50];
  race : String[20];
  classes : String[20];
  descr   : string[255];
  descrr1 : string[40];
  descrr2 : string[40];
End;
  Type
  PRpgTalentDB = ^TRpgTalentDB;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
(*                                                                         *)
(*                    TrpgSkillDB                                          *)
(*                                                                         *)
{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}

Type
TRpgSkillDB = Record
    power : integer;
    kind : string[20];
    SkillName : string[30];
    afterCast:string[255];
    casttime : integer;
    cooldown: integer;
    school : String[20];
    mechanic : String[50];

    range: integer;
    channeling: integer;
    accuracy: integer;
    crit : single;

    icon: string[50];
    spritename: string[50];
    requiredAura:string[255];
    requiredNOAura:string[255];
    requiredHealth:string[255];

    id : integer;
    classes : String[20];
    descr: string[255];
End;
  Type
  PRpgSkillDB = ^TRpgSkillDB;


type TFixedMap = record
    Map: string[20];
    MapX: integer;
    MapY: integer;
    BaseFilename: string[20];
end;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
(*                                                                         *)
(*                    TrpgAuraDB                                           *)
(*                                                                         *)
{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
(*

  Type
  TRpgAuraDB = Record
    id : integer;
    slabel: string[100];
    state: string[20];
    effect: string[255];
    svalue: string[100];
    behaviour: string[20];
    school: string[255];
    condition: string[50];
    trigger: string[20];
    affectedskills: TByteArray4096;
    crit : single;
    stack: string[20];
    stackmax : integer;
    bmphidden : integer;
    persistent : integer;
    cooldown : integer;
    duration : integer;
    tick : integer;
    chance : single;
      requiredAura:string[255];
      requiredNOAura:string[255];
      requiredHealth:string[255];
    spritename: string[20];
    spritepriority :integer;
    note: string[255];
  end;
    Type
    PRpgAuraDB = ^TRpgAuraDB;
*)

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
(*                                                                         *)
(*                    TrpgAura                                             *)
(*                                                                         *)
{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
//  Type
//TRpgAura = Record
//
//    pAuraDB: pRpgAuraDB;
//    slabel  : string[50];
//    state   : string[50];
//    effect   : string[50];
//    svalue: string[50];
//    behaviour: string[50];
//    school: string[255];
//    condition: string[50];
//    trigger: string[50];
//    affectedskills: TByteArray4096;
//    crit: single;
//    stack   : string[20];
//    stackmax : integer;
//    bmphidden: integer;
//    persistent: boolean;
//    cooldown: integer;
//    duration: integer;
//    tick: integer;
//    chance: single;
//    requiredAura:string[255];
//    requiredNOAura:string[255];
//    requiredHealth:string[255];
//    spritename: string[50];
//    spritepriority :integer;
//    note: string[255];
//
//    //------------------// non db
//    copy: boolean;
//    stackn : integer;
//    fromSkill: Pointer;
//    fromChar: Pointer;
//    nV: single;
//    oldnV:single;
//
//    Source: string[50];
//    param1: string[50];
//
//
//    maxduration: integer;
//    maxcooldown: integer;
//    maxtick: integer;
//
//
//    {$ifdef rpg_client}irasprite: Pointer;{$endif}
//
//  end;
//  Type
//  PRpgAura = ^TRpgAura;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
(*                                                                         *)
(*                    TrpgConstDB                                           *)
(*                                                                         *)
{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}

Type
TRpgConstDB = Record
  id : integer;
  slabel: string[40];
  svalue : single;
end;
  Type
  PRpgConstDB = ^TRpgConstDB;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
(*                                                                         *)
(*                    TrpgColorDB                                           *)
(*                                                                         *)
{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
Type
TRpgColorDB = Record
  id : integer;
  slabel: string[40];
  schoolColor : integer;
end;
  Type
  PRpgColorDB = ^TRpgColorDB;


Type
  TPointArray = array [0..7] of Tpoint;



  TNpc = record
    Def_Npc_Name  : string[20];//
    x  : Integer;
    y  : Integer;
  end;
  pNpc = ^TNpc;
  TItem = record
    Def_Item_Name  : string[20];//
    x  : Integer;
    y  : Integer;
  end;
  pItem = ^Titem;


implementation

end.


