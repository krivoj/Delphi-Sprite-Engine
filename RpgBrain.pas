unit RpgBrain;
//{$define rpg_logger}
interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs, Math, dse_List, ParseExpr,
  dse_ThreadTimer, IniFiles, utils,dse_Theater,RpgSprite,
  DSE_Random,StdCtrls,ExtCtrls,rpgtypes,Generics.Collections,Generics.Defaults,strutils,System.SyncObjs,
  dse_misc, DSE_PathPlanner;
type  TPointArray7 = array[0..6] of TPoint;
type ss20 = string[20];
type
  THexCellSize = record
    Width : Integer;
    Height : Integer;
    SmallWidth : Integer;
  end;
 Type
    TlocalMapCoords = record
    localMapCoords: SE_Matrix;// of TlocalMapCoord;
  end;


Type Taura = record
  AuraName    :string;
  v           :string;
  duration    :integer;
  maxduration :integer;
  cooldown    :integer;
  maxcooldown :integer;
  tick        :integer;
  school      :string ;
  radious     :integer;
  applychance :integer;

end;
Type
  TRpgBrain = class;
  TEntity = class;
  TAuraManager = class;
  TMechManager = class;
{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
(*                                                                         *)
(*                    TrpgAI                                               *)
(*                                                                         *)
{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
  TrpgAI = class (Tobject)
  private
    iInterval: integer;
    function isOnpath: Boolean;
  public
    fchar: TEntity;           // fchar.classes punta alla classe
    OnPathEngage: boolean;       // combat in qualunque incontro altrimenti arriva a destinazione - N tolleranza
    OnPathEngageOnly1v1: boolean;    // combat solo se 1vs1 in radious (tipico dei sin)
    OnPathEngageLowhealth: double;    // combat solo se 1vs1 in radious e la target health <= double in percentuale

    OnPathStun: boolean;          // sin che addormenta
    OnPathRoot: boolean;         // ranger che azzoppa
    OnPathPlaceTrap: boolean;    // ranger che mette trappole
    OnPathStealth: boolean;      // sin in ricerca
    OnPathPlaceHeal: boolean;    // priest che mette pozze heal

    Singleattack: Double;        // rnd per uso skill. un tipo di gioco. deprecated
    Multiattack: Double;
    Heal: Double;
    Curse: Double;

    AIClass: string;

  constructor create( owner: TEntity )  ;
  destructor Destroy; virtual;
    procedure Timer( Interval: integer);  // qui passa il thread che processa cosa fa il TEntity
  end;
  PRpgAI = ^TRpgAI;




{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
(*                                                                         *)
(*                    TrpgSkill                                            *)
(*                                                                         *)
{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
  TRpgSkill = class (TObject)
  private
  public
    fChar: TEntity;
    pSkillDB: pRpgSkillDB;
    power   : double;
    kind: string[20];
    SkillName  : string[30];

    afterCast:string[255];

    casttime   : integer;
    cooldown: integer;
    school: String[20];

    Mechanic: string[50];
    range: double;
    channeling:integer;

    accuracy: double;
    crit: double;

    icon: string[50];               // bmp dell'icone della spell
    spritename: string[50];         // folder contenente i bmp casting,moving,hit
    spritepriority :integer;        //
    requiredAura:string[255];
    requiredNOAura:string[255];
    requiredHealth:string[4];

    id : integer;
    classes   : String[20];
    descr: string[255];


    // non db
    lastinput:integer;
    state:integer;
    Maxaccuracy: double;  //
    Maxchanneling: integer;  //
    Maxcooldown: integer;  //
    {$ifdef rpg_client} EntitySprite: Pointer;{$endif}
  constructor Create (owner: TEntity);
  destructor Destroy;
  end;
  PRpgSkill = ^TRpgSkill;
{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
(*                                                                         *)
(*                    TrpgActiveSkill                                      *)
(*                                                                         *)
{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
  TRpgActiveSkill = class (TObject)
  private
  public
    fChar: TEntity;                     // Personaggio che crea questa Active Skill
    Skill: TRpgSkill;                      // Skill del personaggio
    CastTime: Integer;
    Source: TEntity;                    // Personaggio che esegue la Skill
    Target: TEntity;                    // Target della Skill
    aEffect:String[50];                    // es. a=SD,v=ma*1.5  (danno)
    x: integer;                            // coordinate nel caso di Skill Aoe
    y: integer;
    state: Integer;                        // in fase di casting, di esecuzione o sDead
    Used: Boolean;                         // per multiblsessing e aoe
  constructor Create (owner: TEntity);
  destructor Destroy;
end;
  PRpgActiveSkill = ^TRpgActiveSkill;
{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
(*                                                                         *)
(*                    TrpgAura                                             *)
(*                                                                         *)
{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
  TrpgAura = class (Tobject)
  private
    fParams: string;
    AuraManager: TAuraManager;             // auramanager.fchar è il Character
    Cancel: Boolean;                       // Ignora .Load
  public
    initialized: boolean;                  // settato True dalla procedure .load
    Behaviour: string;                     // onload, tick, trigger
    State: integer;                        // Const aDead = 0; Const aReady = 1;Const aLoad = 2;Const aDone = 3;Const aCooldown = 4;
                                           // Const aActive = 5;
    FromActiveSkill: TRpgActiveSkill;      // ActiveSkill che ha generato questa aura
    FromTalent: pRpgTalentDB        ;      // Talent che ha generato questa aura
    FromAura: TRpgAura             ;       // Aura che ha generato questa aura
    AuraName: string;                      // AuraManager cercherà per nome le auree
    v : string;                            // es. 5@7@7@9  oppure ma*1.4
    nv: Double;                            // valore numerico di V  ( solo per certe auree )
    school: string;                        // fire, water, wind, etc...
    tick: integer;                         //
    Maxtick: integer;                      //
    duration: integer;                     // ms rimanenti prima che venga chiamata DieAndRestore
    Maxduration: integer;                  //
    cooldown: integer;                     // per aureee di tipo trigger
    Maxcooldown: integer;                  //
    radious: integer;                      // nel caso di aoe ( area of effect )
    chance: Integer;                       // percentuale di creazione dell'aura
    category: string;                      // snare, root, freeze,silenced etc...

    requiredaura: string;                  // aure richieste per essere eseguite
    requiredNOaura: string;                // presenza di auree che inibiscono questa aura

    stack: integer;                        //
    MaxStack: integer;                     //

    persistent: boolean;                   // aura di tipo talento del TEntity es. trigger
    Timed: boolean;                        // aura che non decrementa la duration , come absorb.shield che aspetta l'exaust

    FExprParser1 : TExpressionParser ;     // Parser per calcolare V

    AuraShow: Boolean;                      // di solito i talenti trigger non vengono visualizzati sul client

  constructor create(params: string; fromSkill: TRpgActiveSkill)  ; overload;virtual;   // l'aura viene  creata dal lancio di una Skill
  constructor create(params: string; pTalentDB: PRpgTalentDB; manager: TAuraManager)  ;overload; virtual;   // l'aura viene  creata da un talento
  constructor create(params: string; ActiveAura: TRpgAura; Manager: TAuraManager)  ;overload; virtual;   // l'aura viene  creata da un'altra aura
  constructor create(params: string) ; overload; virtual;   // l'aura viene  creata da un'altra aura
  destructor Destroy; virtual;
    procedure Load; virtual;                      // primo caricamento es. +20 health
    procedure DieAndRestore;virtual;              // Restore dei dati es. - 20 health
    procedure onTick;virtual;abstract;            // es. DoT Damage over time
    procedure Timer( Interval: integer);virtual;  // qui passa il thread che processsa tutte le auree
    procedure Input (msg: TmsgManager; v: string); virtual; abstract;  // Messaggi all'aura, per attivare trigger
    procedure trigger;virtual;                    // es. quando health scende sotto 40% , si attiva questa aura
    procedure RenewAuraDuration ( IncrStackN: integer ); // rinnova la durata e incrementa gli stack
  end;
  PRpgAura = ^TRpgAura;




(*Forsaken world*)
  TBlessingOftheHumans =  Class(TrpgAura)   (*es. masteries +25 health +3%*)
  private                                   (* a=blessing.of.the.humans,v=25@3,d=300000 *)
      fhealth : double ;     // 3%%

      fmfire : double ;      // 25
      fmearth : double ;
      fmlight : double ;
      fmphysical : double ;
      fmwater : double ;
      fmdark : double ;
      fmwind : double ;

  public
  constructor create(params: string; fromSkill: TRpgActiveSkill)  ;
  destructor Destroy; override;
    procedure Load; override;
    procedure DieAndRestore; override;
    procedure Timer( Interval: integer); override;
    procedure Input (msg: TmsgManager; value: string );  override;
end;

  TBlessingOftheElves =  Class(TrpgAura)   (*es. resistances +25 mana +1%* accuracy +25) *)
  private                                  (*a=blessing.of.the.elves,v=25@1@25,d=300000 *)
      fpower : double ;     // 1%%

      frfire : double ;      // 25
      frearth : double ;
      frlight : double ;
      frphysical : double ;
      frwater : double ;
      frdark : double ;
      frwind : double ;

      fAccuracy: Double;   // 25
  public
  constructor create(params: string; fromSkill: TRpgActiveSkill)  ;
  destructor Destroy; override;
    procedure Load; override;
    procedure DieAndRestore; override;
    procedure Timer( Interval: integer); override;
    procedure Input (msg: TmsgManager; value: string );  override;
end;

  TBlessingOftheKindred =  Class(TrpgAura)  (*es. health +8% *)
  private                                   (* a=blessing.of.the.kindred,v=8,d=300000 *)
      fhealth : double ;     // 3%%

  public
  constructor create(params: string; fromSkill: TRpgActiveSkill)  ;
  destructor Destroy; override;
    procedure Load; override;
    procedure DieAndRestore; override;
    procedure Timer( Interval: integer); override;
    procedure Input (msg: TmsgManager; value: string );  override;
end;

  TBlessingOfFortune =  Class(TrpgAura)   (* es. a=blessing.of.fortune,v=5@7@7@9,d=300000 *)
  private
      fdefense : double ;     // 5%

      fAccuracy: integer;     // 5
      fdodge: integer;        // 5

      fmfire : double ;      // 9
      fmearth : double ;
      fmlight : double ;
      fmphysical : double ;
      fmwater : double ;
      fmdark : double ;
      fmwind : double ;

      finchealing: double;   // opzionale da fortune.wheel + 2% inchealing
      fincCritLight: double;   // opzionale da light.of.fortune +3% crit
  public
  constructor create(params: string; fromSkill: TRpgActiveSkill)  ;
  destructor Destroy; override;
    procedure Load; override;
    procedure DieAndRestore; override;
    procedure Timer( Interval: integer); override;
    procedure Input (msg: TmsgManager; value: string );  override;
end;
  TBlessingOfTenacity =  Class(TrpgAura)   (* es. a=blessing.of.tenacity,v=5,d=1800000,radious=20 *)
  private
      fdefense : double ;     // 5%

  public
  constructor create(params: string; fromSkill: TRpgActiveSkill)  ;
  destructor Destroy; override;
    procedure Load; override;
    procedure DieAndRestore; override;
    procedure Timer( Interval: integer); override;
    procedure Input (msg: TmsgManager; value: string );  override;
end;

  TBlessingOfLife =  Class(TrpgAura)   (* es.a=blessing.of.life,v=3,d=1800000,radious=20 *)
  private
      fhealth : double ;     // 4.5%

  public
  constructor create(params: string; fromSkill: TRpgActiveSkill)  ;
  destructor Destroy; override;
    procedure Load; override;
    procedure DieAndRestore; override;
    procedure Timer( Interval: integer); override;
    procedure Input (msg: TmsgManager; value: string );  override;
end;


  TSchoolDamage =  Class(TrpgAura)
  private
  public
    Periodic: boolean;
  constructor create(params: string;fromSkill: TRpgActiveSkill)  ;
  destructor Destroy; override;
    procedure Load; override;
    procedure DieAndRestore; override;
    procedure Timer( Interval: integer); override;
    procedure Input (msg: TmsgManager; value: string );  override;
end;

  TShadowPain =  Class(TrpgAura)   (*es per 6 secondi ogni 2 secondi danni di 300 *)
  private                                  (*a=light.of.healing,v=ma,d=6000  2% crit chance*)
  public
  constructor create(params: string;fromSkill: TRpgActiveSkill)  ;
  destructor Destroy; override;
    procedure Load; override;
    procedure onTick;override;
    procedure DieAndRestore; override;
    procedure Timer( Interval: integer); override;
    procedure Input (msg: TmsgManager; value: string );  override;
end;

  THeal =  Class(TrpgAura)
  private
  public
  constructor create(params: string;fromSkill: TRpgActiveSkill)  ;
  destructor Destroy; override;
    procedure Load; override;
    procedure DieAndRestore; override;
    procedure Timer( Interval: integer); override;
    procedure Input (msg: TmsgManager; value: string );  override;
end;

  TNaturalProtection =  Class(TrpgAura)  (* es. aggiunge 5% a outhealing per 10 secondi  *)
  private                                (* ,a=natural.protection,v=r1,d=10000 *)
  public
  constructor create(params: string;fromSkill: TRpgActiveSkill)  ;
  destructor Destroy; override;
    procedure Load; override;
    procedure DieAndRestore; override;
    procedure Timer( Interval: integer); override;
    procedure Input (msg: TmsgManager; value: string );  override;
end;

  TGodsGift =  Class(TrpgAura)
  private
  public
  constructor create(params: string;fromSkill: TRpgActiveSkill)  ;
  destructor Destroy; override;
    procedure Load; override;
    procedure DieAndRestore; override;
    procedure Timer( Interval: integer); override;
    procedure Input (msg: TmsgManager; value: string );  override;
end;
  TDamnation =  Class(TrpgAura)   (*es. attack -2% Masteries and resistances -30 per 20 secondi *)
  private                         (* a=damnation,v=-2@-30,d=20000 *)
      fattack : double ;     // -2%%

      fmfire : double ;      // -30
      fmearth : double ;
      fmlight : double ;
      fmphysical : double ;
      fmwater : double ;
      fmdark : double ;
      fmwind : double ;

      frfire : double ;      // -30
      frearth : double ;
      frlight : double ;
      frphysical : double ;
      frwater : double ;
      frdark : double ;
      frwind : double ;

  public
  constructor create(params: string; fromSkill: TRpgActiveSkill)  ;
  destructor Destroy; override;
    procedure Load; override;
    procedure DieAndRestore; override;
    procedure Timer( Interval: integer); override;
    procedure Input (msg: TmsgManager; value: string );  override;
end;

  TSlowed =  Class(TrpgAura)  (*es. speed -25% *)
  private                                   (* a=slowed,v=25,d=3000,applychance=50 *)
      fcs : double ;     // -25%%

  public
  constructor create(params: string; fromSkill: TRpgActiveSkill)  ;
  destructor Destroy; override;
    procedure Load; override;
    procedure DieAndRestore; override;
    procedure Timer( Interval: integer); override;
    procedure Input (msg: TmsgManager; value: string );  override;
end;
  TSilenced =  Class(TrpgAura)  (*es. silenced 7000ms *)
  private                                   (* a=silence,d=7000 *)

  public
  constructor create(params: string; fromSkill: TRpgActiveSkill)  ;
  destructor Destroy; override;
    procedure Load; override;
    procedure DieAndRestore; override;
    procedure Timer( Interval: integer); override;
    procedure Input (msg: TmsgManager; value: string );  override;
end;
  TAbsorbShield =  Class(TrpgAura)  (*es. absorbshield,v=ma*0.25 *)
  private                                   (* asssorbe il 25% di tutti i danni *)

  public
  constructor create(params: string; fromSkill: TRpgActiveSkill)  ;
  destructor Destroy; override;
    procedure Load; override;
    procedure DieAndRestore; override;
    procedure Timer( Interval: integer); override;
    procedure Input (msg: TmsgManager; value: string );  override;
end;
  TtriggerDivinePunishment =  Class(TrpgAura)
  private
    Active: boolean;
    LowHealth :  double;
    AttackSpeed :  double;
  public
  constructor create(params: string; fromTalent: pRpgTalentDB; manager: TAuraManager)  ;overload; virtual;   // l'aura viene  creata da un talento
  destructor Destroy; override;
    procedure Load; override;
    procedure DieAndRestore; override;
    procedure Timer( Interval: integer); override;
    procedure Input (msg: TmsgManager; value: string );  override;
end;
  TtriggerAttackSpeed =  Class(TrpgAura)
  private
    Active: boolean;
    LowHealth :  double;
    AttackSpeed :  double;
  public
  constructor create(params: string; fromTalent: pRpgTalentDB; manager: TAuraManager)  ;overload; virtual;   // l'aura viene  creata da un talento
  destructor Destroy; override;
    procedure Load; override;
    procedure DieAndRestore; override;
    procedure Timer( Interval: integer); override;
    procedure Input (msg: TmsgManager; value: string );  override;
end;
  TAttackSpeed =  Class(TrpgAura)
  private
    fdeccd: integer;
  public
  constructor create(params: string; fromAura: TRpgAura;  Manager: TAuraManager)  ;overload; virtual;   // l'aura viene  creata da un'altra aura
  destructor Destroy; override;
    procedure Load; override;
    procedure DieAndRestore; override;
    procedure Timer( Interval: integer); override;
    procedure Input (msg: TmsgManager; value: string );  override;
end;
  TDebuffAllMasteries =  Class(TrpgAura)  (*es. a=debuff.all.masteries,v=-5,d=12000 *)
  private
      fmfire : double ;      // -5
      fmearth : double ;
      fmlight : double ;
      fmphysical : double ;
      fmwater : double ;
      fmdark : double ;
      fmwind : double ;
  public
  constructor create(params: string; fromSkill: TRpgActiveSkill)  ;
  destructor Destroy; override;
    procedure Load; override;
    procedure DieAndRestore; override;
    procedure Timer( Interval: integer); override;
    procedure Input (msg: TmsgManager; value: string );  override;
end;
  TRevive =  Class(TrpgAura)
  private
  public
  constructor create(params: string;fromSkill: TRpgActiveSkill)  ;
  destructor Destroy; override;
    procedure Load; override;
    procedure DieAndRestore; override;
    procedure Timer( Interval: integer); override;
    procedure Input (msg: TmsgManager; value: string );  override;
end;

  TImmunity =  Class(TrpgAura)  (*es. a=immunity,v=fire,d=4000 *)
  private                                   (* a=immunity,v=slowed,d=4000 *)
    fImmunityStun: integer;
    fImmunitySilence: integer;
    fImmunityDisarm: integer;
    fImmunitySlowed: integer;
    fImmunityAll: integer;
    fImmunityFire: integer;
    fImmunityearth: integer;
    fImmunitylight: integer;
    fImmunityphysical: integer;
    fImmunitywater: integer;
    fImmunitydark: integer;
    fImmunitywind: integer;

  public
  constructor create(params: string; fromSkill: TRpgActiveSkill)  ;
  destructor Destroy; override;
    procedure Load; override;
    procedure DieAndRestore; override;
    procedure Timer( Interval: integer); override;
    procedure Input (msg: TmsgManager; value: string );  override;
  End;

  TFree =  Class(TrpgAura)  (*es. a=free,v=all *)
  private                                   (* a=free,v=slowed@stun *)
    fImmunityStun: Boolean;
    fImmunitySilence: Boolean;
    fImmunityDisarm: Boolean;
    fImmunitySlowed: Boolean;
    fImmunityAll: Boolean;
    fImmunityFire: Boolean;
    fImmunityearth: Boolean;
    fImmunitylight: Boolean;
    fImmunityphysical: Boolean;
    fImmunitywater: Boolean;
    fImmunitydark: Boolean;
    fImmunitywind: Boolean;

  public
  constructor create(params: string; fromSkill: TRpgActiveSkill)  ;
  destructor Destroy; override;
    procedure Load; override;
    procedure DieAndRestore; override;
    procedure Timer( Interval: integer); override;
    procedure Input (msg: TmsgManager; value: string );  override;
  End;

  TPray =  Class(TrpgAura)  (*es. +25% CP *)
  private                                   (* a=pray,v=maxpower*0.25 *)
    fImmunityStun: Boolean;
    fImmunitySilence: Boolean;
    fImmunityDisarm: Boolean;
    fImmunitySlowed: Boolean;
    fImmunityAll: Boolean;
    fImmunityFire: Boolean;
    fImmunityearth: Boolean;
    fImmunitylight: Boolean;
    fImmunityphysical: Boolean;
    fImmunitywater: Boolean;
    fImmunitydark: Boolean;
    fImmunitywind: Boolean;

  public
  constructor create(params: string; fromSkill: TRpgActiveSkill)  ;
  destructor Destroy; override;
    procedure Load; override;
    procedure DieAndRestore; override;
    procedure Timer( Interval: integer); override;
    procedure Input (msg: TmsgManager; value: string );  override;
  End;

  TdrainPower =  Class(TrpgAura)  (*es. drain di ma*2 del power *)
  private                                   (* a=drainpower,v=ma*2,applychance=25 *)

  public
  constructor create(params: string; fromSkill: TRpgActiveSkill)  ;
  destructor Destroy; override;
    procedure Load; override;
    procedure DieAndRestore; override;
    procedure Timer( Interval: integer); override;
    procedure Input (msg: TmsgManager; value: string );  override;
  End;
                { TODO : possibile accorpamento PeriodicHeal e periodicDamage }
  TLightofHealing =  Class(TrpgAura)   (*es cura di 700 e per 6 secondi ogni 2 secondi cura di 700 *)
  private                                  (*a=light.of.healing,v=ma,d=6000  2% crit chance*)
  public
  constructor create(params: string;fromSkill: TRpgActiveSkill)  ;
  destructor Destroy; override;
    procedure Load; override;
    procedure onTick;override;
    procedure DieAndRestore; override;
    procedure Timer( Interval: integer); override;
    procedure Input (msg: TmsgManager; value: string );  override;
end;
  TDivineLight =  Class(TrpgAura)   (*es cura di 700 e per 6 secondi ogni 1 secondi, l'ultimo Tick cura del doppio *)
  private                                  (*a=a=divine.light,v=ma*0.7,d=4000,tick=1000*)
  public
  constructor create(params: string;fromSkill: TRpgActiveSkill)  ;
  destructor Destroy; override;
    procedure Load; override;
    procedure onTick;override;
    procedure DieAndRestore; override;
    procedure Timer( Interval: integer); override;
    procedure Input (msg: TmsgManager; value: string );  override;
end;

  TDivinePunishment =  Class(TrpgAura)   (*es per 15 secondi riduce le resistenze light di 11 *)
  private                                (*a=Divine.punishment,v=11,d=15000*)
    frlight : Double;
  public                                      (*  stack = 5 *)
  constructor create(params: string; fromAura: TRpgAura;  Manager: TAuraManager)  ;overload; virtual;   // l'aura viene  creata da un'altra aura
  destructor Destroy; override;
    procedure Load; override;
    procedure DieAndRestore; override;
    procedure Timer( Interval: integer); override;
    procedure Input (msg: TmsgManager; value: string );  override;
end;


  TBrainEventChar = procedure (   Character:TEntity) of object;

  TBrainEventCharHealth = procedure (   Character:TEntity;  Aura:TrpgAura; ActiveSkill: TRpgActiveSkill; v:integer  ) of object;
  TBrainEventCharMove = procedure (   Character:TEntity; endX, endY: integer) of object;
  TBrainEventAura = procedure (   Sender: Tobject; Character: TEntity; Aura: TrpgAura; FromSkill: TrpgActiveSkill ) of object;

  TEntityEvent = procedure (  Sender: TObject;  value: string) of object;
  TEntityEventAura = procedure (  Sender: TObject;  Aura: TRpgAura) of object;
  TEntityEventHealth = procedure (  Sender: TObject;   Aura: TrpgAura; FromSkill: TrpgActiveSkill; v: integer) of object;


  //  TEntityRequestEvent = procedure (  Sender: TObject; var result: TEntity) of object;
  TBrainEventSkill = procedure (   Character:TEntity;  ActiveSkill: TRpgActiveSkill ) of object;
  TEntityEventSkill = procedure (  Character:TEntity;  ActiveSkill: TRpgActiveSkill) of object;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
(*                                                                         *)
(*                    TrpgAction                                           *)
(*                                                                         *)
{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
TrpgAction= class (TObject)
    private
    protected
    public
    fChar: TEntity;
    Path: string; // se attivo riprende il path
    action  : string;
    map  : string;                       // stormwind           stormwind
    mapcx: integer;                      // 5                   5
    mapcy: integer;                      // 6                   6
    Startx: integer;                     // -14                 -13
    Starty: integer;                     // 6                   6
    endX: integer;                       // -14                 -14
    endY: integer;                       // 7                   7
    duration : integer;                  //
    maxduration : integer;               //
    state: integer;                      // not 0               not 0
    svalue: string;                      //                     holy.blast
    target  : TEntity;                    // -1                  31
  constructor Create (owner: TEntity);
  destructor Destroy;
end;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
(*                                                                         *)
(*                    TauraManager                                         *)
(*                                                                         *)
{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
  TAuraManager = Class (Tobject)
  private
  public
    fChar: TEntity;
    lstAura : TObjectList<trpgAura>;
    Auras: TstringList;

    Slowed: integer;
    Stunned: integer;
    Disarmed: integer;
    Silenced: integer;

    ImmunityAll: integer;
    ImmunityStun: integer;
    ImmunitySilence: integer;
    ImmunityDisarm: integer;
    ImmunitySlowed: integer;

    ImmunityFire: integer;
    Immunityearth: integer;
    Immunitylight: integer;
    Immunityphysical: integer;
    Immunitywater: integer;
    Immunitydark: integer;
    Immunitywind: integer;


    Immunity: array [0..11] of integer;

    AbsorbAll: Double;
    AbsorbFire: double;
    Absorbearth: double;
    Absorblight: double;
    Absorbphysical: double;
    Absorbwater: double;
    Absorbdark: double;
    Absorbwind: double;

    Absorb: array [0..8] of integer;

    Inchealing: Double;  // percentuale
    Outhealing: Double;  // percentuale   equivale a incrementare la masteries light


  constructor Create (owner: TEntity);
  destructor Destroy;
  procedure Execute;
  procedure Broadcast (const msg: TmsgManager;Periodic: boolean; Skill: TRpgSkill; var Output: string ); overload;
  procedure Broadcast (const msg: TmsgManager;Periodic: boolean; Aura: TRpgAura; var Output: string ); overload;
  function TryAddRpgAura ( const Effect: string; ActiveSkill: TrpgActiveSkill ): boolean;
  procedure AddDirectAura ( Aura: TRpgAura );
  procedure SetAllDead ;
  function IsAuraLoaded (const v: string): TrpgAura;
  function IsAurafromChar ( const v: string; const Source: TEntity) : trpgAura;
  function String2Aura ( aString: string ): TAura;

  procedure AssignOwner ( const v: TEntity );
end;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
(*                                                                         *)
(*                    TSkillManager                                        *)
(*                                                                         *)
{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
  TSkillManager = class  (Tobject)
  private
    rnd: TtdCombinedPRNG;
    procedure Execute(pSkill: pRpgSkill);
  public
    fChar: TEntity;
    lstSkills : TObjectList<TrpgSkill>;
//    lstSkills : se_RecordList;
    decCd: integer;
  constructor Create (owner: TEntity);
  destructor Destroy;
    function GetDefSkill ( const SkillName: string): pRpgSkillDB; overload;  // per nome
    function GetDefSkill (const id: integer): pRpgSkillDB; overload; // per id utile nella skilllit
    function GetCharSkill (const skillname: string): TRpgSkill ; overload;   // per nome
    function GetCharSkill (const id: integer): TRpgSkill ;overload;   // per id


    procedure FillfromDB (skill: TRpgSkill);
    procedure AddSkill (v: string );
    procedure AddSkillList (v: string );

    function getRandomSkill (kind: string): TRpgSkill;
    function getNextRotationSkill : TRpgSkill;
    function getNextRotationSkillH : TRpgSkill;
    function getNextRotationSkillF : TRpgSkill;

    procedure tryExecuteSkill ( ActiveSkill: TrpgActiveSkill);
    procedure Broadcast (const msg: TmsgManager;Periodic: boolean; Skill:  TRpgSkill; var Output: string ); overload;
    procedure Broadcast (const msg: TmsgManager;Periodic: boolean; Aura:  TRpgAura; var Output: string ); overload;

    procedure SetAccuracyBySchool (const school: string; v: Double );
    procedure SetCritBySchool (const school: string; v: Double );
    procedure ModifyAllCooldowns (const Value: integer);  // mechanic cdrage
    procedure resetAllCooldowns ;  // mechanic cdrage
end;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
(*                                                                         *)
(*                    Tmechanic                                            *)
(*                                                                         *)
{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
  TMechanic = class  (Tobject)
  private
    fMechManager: TMechManager; // MechManager.fchar : TEntity;    // dal TChar risale a skil, defskill, aura, defaura, deftalent
  protected
    function BaseGetValue: double;
    procedure BaseSetValue(v: double);
    function BaseGetValueMax: double;
    procedure BaseSetValueMax(v: double);
    procedure BaseInput (const msg : TmsgManager; const v: string ); virtual; abstract;
  public
    fName: string[20];
    fValue: double;
    fValueMax: double;
    ftick: integer;

  constructor Create ( aMechManager: TMechManager); virtual;
  destructor Destroy; override;
  procedure Input  (const msg: TmsgManager; Skill: TRpgSkill; var Output: string ); overload; virtual; abstract;
  procedure Input  (const msg: TmsgManager; Aura: TrpgAura; var Output: string );  overload; virtual; abstract;
  procedure Timer (const interval: integer); virtual;abstract;   // per unico thread esterno che processa tutti i TEntity
  end;


TMechCdRage = class (Tmechanic)     // deprecated. sto usando skillManager
  private
  protected
  public
    HittedValue: integer;
    HitValue: integer;
    constructor Create  ( aMech: TMechManager) ; override;
    destructor Destroy;
    function GetValue: double;
    procedure SetValue(v: double);
    function GetValueMax: double;
    procedure SetValueMax(v: double);
    procedure Input  (const msg: TmsgManager; Skill: TRpgSkill; var Output: string ); override;
    procedure Input  (const msg: TmsgManager; Aura: TRpgAura; var Output: string ); override;
    procedure Timer (const interval: integer); override;

  end;

TMechOrbs = class (Tmechanic) // il valore è diviso in 2 per agony e blast
  private
    Agony: Byte;
    Blast: Byte;
    AgonyDuration: Integer;
    BlastDuration: Integer;
  protected
  public
    constructor Create  ( aMech: TMechManager) ; override;
    destructor Destroy;
    function GetValue: double;
    procedure SetValue(v: double);
    function GetValueMax: double;
    procedure SetValueMax(v: double);
    procedure Input  (const msg: TmsgManager; Skill: TRpgSkill; var Output: string ); override;
    procedure Input  (const msg: TmsgManager; Aura: TRpgAura; var Output: string ); override;
    procedure Timer (const interval: integer); override;

  end;
TMechStance = class (Tmechanic) // una esclude l'altra e mette a=battle.stance come auree non removibili
  private
  protected
  public
    constructor Create  ( aMech: TMechManager) ; override;
    destructor Destroy;
    function GetValue: double;
    procedure SetValue(v: double);
    function GetValueMax: double;
    procedure SetValueMax(v: double);
    procedure Input  (const msg: TmsgManager; Skill: TRpgSkill; var Output: string ); override;
    procedure Input  (const msg: TmsgManager; Aura: TRpgAura; var Output: string ); override;
    procedure Timer (const interval: integer); override;

  end;
TMechSoulBullet = class (Tmechanic) // i bullet si accumulano un tot al secondo e insieme al mana aumentano il danno
  private
  protected
  public
    constructor Create  ( aMech: TMechManager) ; override;
    destructor Destroy;
    function GetValue: double;
    procedure SetValue(v: double);
    function GetValueMax: double;
    procedure SetValueMax(v: double);
    procedure Input  (const msg: TmsgManager; Skill: TRpgSkill; var Output: string ); override;
    procedure Input  (const msg: TmsgManager; Aura: TRpgAura; var Output: string ); override;
    procedure Timer (const interval: integer); override;

  end;

TMechManager = class  (Tobject)
  private
    fChar: TEntity;
  public
    MechList: TObjectList<TMechanic>;
  constructor Create (owner: TEntity);
  destructor Destroy;
  procedure AddMechanic ( const v: string );
  procedure Broadcast  (const msg: TmsgManager; Skill:  tRpgSkill; var Output: string ); overload ;
  procedure Broadcast  (const msg: TmsgManager; Aura: tRpgAura; var Output: string ); overload;
end;


    TEntity = class (Tobject)
    private
      { Private declarations }
      fid : integer;           // mi linka a def_char
      fdefaultname : string;   // mi linka a def_char
      fattack : double ;
      fdefense : double ;
      fstamina : double ;
      fvitality : double ;
      fmfire, fmearth, fmlight, fmphysical, fmwater, fmdark, fmwind, frfire, frearth, frlight, frphysical, frwater, frdark, frwind: double;
      fcrit : double ;
      fcritdmg : double ;
      faccuracy : double ;
      fdodge : double ;
      fabsorb : double ;
      fpower : double ;
      Fmasteries: TStringList;
      FResistances: TStringList;
      FTalents: TStringList;
      fspritename : string;
      fspritepriority : integer;
      frace : string;
      fclasses : string;
      fregenhealth : integer;
      // fine def_char solo come indicazione

      FName: string;
      FMap: string;
      FMapCx: integer;
      FMapCy: integer;
      FCx: integer;
      FCy: integer;
      FLoot: TStringList;
      FRespawn: integer;
      FHealth: double;                                          // stamina * vitaly
      fauras: TstringList;
      ffAction: string;
      // fine var_char
//      fch è public qui sotto  assieme ad altre


      (*  Tcp *)

      FCliId: integer;
      FReady: boolean;                                          // se il char non è ready, non gli viene inviata nessuna iga
      FLoading: boolean;                                        // per ricevere i talenti a cd e duration 0. idle da subito.
      FIsoDirection: string;//                                    // 1,2,3,4,6 NE,NW ecc...
      FCombat: boolean;                                         // just true/false
      FRangeInteract: integer;                                   // distanza di interazione con altri npc
      FIDs: string;                                             // id string
      FSpeed: double;                                           // speed

      FmainPath: TPath;
      FLastInputWalk: integer;
      FLastInputSkill: integer;
      FInput: string;
      FLastInputMove: string;

      Fwall: boolean;
      FToidle: integer;
      FLastHitFrom: string;
      FFatherIDs: string;
      FRpgObj:integer;

      FEntitySprite: TEntitySprite;
      FExprParser1 : TExpressionParser;

      fGrouped: boolean;
      fNumber : Integer;

      procedure SetCH (const value: double);
      procedure SetHealth (const value: double);
      procedure SetCP (const value: double);
      procedure SetPower (const value: double);
      procedure SetEntitySprite ( spr: TentitySprite );

      procedure setAccuracy (const value: double);

      procedure SetCombat (const value: boolean);
      procedure SetState (const value: string);
      procedure SetIsoDirection (const value: string);

      procedure SetNumber ( const v: integer);
      procedure Setfaction ( const v: string);
    protected
      { Protected declarations }
    public
      { Public declarations }
{$ifdef rpg_logger}
    charLogger: TextFile;
{$endif rpg_logger}
      ToCombatOff: integer;                                     // ms per tornare a combat = false
      ToCombatOffMax: integer;                                  // Max ms per tornare a combat = false  5 secondi
      FState: string;                                           // idle, waking ecc...
      FCh: double;                                              // current health
      FCP: double;                                              // current power
      FCs: double;                                              // current speed


      Stunned: Boolean;      { TODO : forse qui non servono , cono in auramanager }
      Silenced: Boolean;
      Rooted: Boolean;
      Stealthed: Boolean;

      Brain: TrpgBrain;                                                               // Brain di appartenenza

      RpgAction: TRpgAction;
      MechManager: TMechmanager;
      SkillManager: TSkillManager;
      AuraManager: TAuraManager;
      AI: TrpgAI;

      Property id : integer read fid write fid ;         // mi linka a def_char
      Property defaultname :string  read fdefaultname write fdefaultname;  // mi linka a def_char

      Property attack : double read fattack write fattack;          { TODO : eliminare property dove non serve }
      Property defense : double read fdefense write fdefense;
      Property stamina : double read fstamina write fstamina;
      Property vitality : double read fvitality write fvitality;

      Property mfire : double read fmfire  write fmfire ;
      Property mearth : double read fmearth write fmearth ;
      Property mlight : double read fmlight write fmlight ;
      Property mphysical : double read fmphysical write fmphysical;
      Property mwater : double read fmwater  write fmwater ;
      Property mdark : double read fmdark  write fmdark ;
      Property mwind : double read fmwind  write fmwind ;
      Property rfire : double read frfire  write frfire ;
      Property rearth : double read frearth write frearth ;
      Property rlight : double read frlight write frlight ;
      Property rphysical : double read frphysical write frphysical ;
      Property rwater : double read frwater  write frwater ;
      Property rdark : double read frdark  write frdark ;
      Property rwind : double read frwind  write frwind ;

      Property crit : double  read fcrit write fcrit;
      Property critdmg : double  read fcritdmg write fcritdmg;
      Property accuracy : double  read faccuracy write Setaccuracy;
      Property dodge : double  read fdodge write fdodge;
      Property Talents: TStringList  read fTalents write fTalents;
      Property spritename : string  read fspritename write fspritename;
      Property spritepriority : integer read fspritepriority write fspritepriority;
      Property race : string  read frace write frace;
      Property classes : string  read fclasses write fclasses;
      Property regenhealth : integer read fregenhealth write fregenhealth;
      // fine def_char solo come indicazione

      Property Name: string read FName write FName ;
      Property Map: string read FMap write FMap ;
      Property MapCx: integer read FMapCx write FMapCx ;
      Property MapCy: integer read FMapCy write FMapCy ;
      Property Cx: integer read FCx write FCx ;
      Property Cy: integer read FCy write FCy ;

      Property Respawn: integer read FRespawn write FRespawn ;
      Property Loot: TStringList read FLoot write FLoot;


      Property State: string read FState write SetState ;
      Property CliID: integer read FCliID write FCliID ;
      Property Ready:boolean read Fready write FReady;
      Property Loading:boolean read FLoading write FLoading;
      Property IsoDirection: string read FIsoDirection write SetIsoDirection ;
      Property Combat: boolean read FCombat write SetCombat ;
      property RangeInteract: integer read FRangeInteract write FRangeInteract default 5;
      Property IDs: string read FIDs write FIDs ;
      Property Speed: double read FSpeed write FSpeed ;
      Property CS: double read FCS write FCS ;
      Property MainPath : Tpath read fMainPath write fmainPath;
      property LastInputWalk: integer read FLastInputWalk write FLastInputWalk;
      property LastInputSkill: integer read FLastInputSkill write FLastInputSkill;
      property Input : string read fInput write finput;
      property LastInputMove : string read fLastInputMove write flastinputMove;


      Property Wall: boolean read FWall write FWall ;
      Property ToIdle: integer read FToIdle write FToIdle ;
      Property LastHitFrom: string read FLastHitFrom write FLastHitFrom ;
      Property FatherIDs: string read FFatherIDs write FFatherIDs ;
      Property RpgObj: integer read FRpgObj write FRpgObj ;

      Property Faction: string read Ffaction write Setfaction ;

      Property Health: double read FHealth write SetHealth ;
      Property CH: double read FCh write SetCH ;
      Property power : double  read fpower write SetPower;
      Property CP : double  read fCP write setCP;
      Property Absorb : double  read fAbsorb write fAbsorb;

      Property Grouped: boolean read fGrouped write fGrouped;
      Property Number: integer read fNumber write SetNumber ;

      Property EntitySprite: TEntitySprite read FEntitySprite write SetEntitySprite;


      constructor Create();
      destructor Destroy; override;
      procedure LoadTalents( );
      function LoadRankDescr (  pTalentDB: PRpgTalentDB; rank:integer ): string;
      procedure LoadRank ( pTalentDB: PRpgTalentDB; rank:integer; out r1: Double; out r2:double ); overload;
      procedure LoadRank (  pTalentDB: PRpgTalentDB; rank:integer; out r1: string; out r2:string );overload;
      procedure ExecuteAuras (Interval:integer);
      procedure Group ;
      function GetNextKeyUp : TPoint;

   // published
      { Published declarations }


    end;
    PEntity = ^TEntity;



 TRpgOptions = class (TPersistent)
  private
    FFollow_Target: integer;
    FWalking_Time: integer;
    Fdelay_input_walk: integer;
    FGlobal_Cooldown: integer;
    fthread_interval: integer;

    protected
  public
    constructor Create(AOwner: TComponent);
    destructor Destroy; override;
  published

    property Follow_Target: integer read FFollow_Target write FFollow_Target;
    property Walking_Time: integer read FWalking_Time write FWalking_Time;
    property Delay_Input_Walk: integer read FDelay_Input_Walk write FDelay_Input_Walk;
    property Global_Cooldown: integer read FGlobal_Cooldown write FGlobal_Cooldown;
    property thread_interval: integer read fthread_interval write fthread_interval;

  end;


///////////////////////////////////////////////////////////////////////////////////
// TrpgBrain
///////////////////////////////////////////////////////////////////////////////////

{$REGION 'TrpgBrain'}
    TRpgBrain = class( TComponent )
    private

      flocal_cellsX: integer;
      flocal_cellsY: integer;
      fglobal_cellsX: integer;
      fglobal_cellsY: integer;


      FExprParser1 : TExpressionParser;
      FRandGen: TtdCombinedPRNG;




      fDefChar : SE_RecordList;
      fDefItem : se_RecordList;
      fDefConst : se_RecordList;
      FDefSkill : se_RecordList;
      FDefTalent : se_RecordList;
      fDefColor : se_RecordList;

      FNpcs: TObjectList<TEntity>;             // list of Npc, monsters
      FWorldItems: TObjectList<TEntity>;      // list of items, objects in the world, house ...

      finput: string;

      LstLocalMapCoord: TObjectList<se_Matrix>;


      FOnCharRespawn: TBrainEventChar;
      FOnCharEnter: TBrainEventChar;
      FOnCharExit: TBrainEventChar;


      FOnCharAbsorbDamage: TBrainEventCharhealth;
      FOnCharDropHealth: TBrainEventCharhealth;
      FOnCharRecoverHealth: TBrainEventCharHealth;
      FOnCharDeath: TBrainEventChar;
      FOnCharDroppower: TBrainEventChar;
      FOnCharRecoverpower: TBrainEventChar;


      FOnCharDrainedPower: TBrainEventChar;

      FOnCharAuraAdd : TBrainEventAura;
      FOnCharAuraLoad : TBrainEventAura;
      FonCharAuraTick: TBrainEventAura;
      FOnCharAuraDie : TBrainEventAura;

      FOnCharStopMove : TBrainEventCharMove;
      FOnCharStartMove : TBrainEventCharMove;


      FOnCharHealed: TBrainEventAura;
      FOnCharHitted: TBrainEventAura;
      FOnCharHit: TBrainEventAura;

      FOnCharCastingSkill: TBrainEventSkill;
      FOnCharExecuteSkill: TBrainEventSkill;
      FOnCharAbortSkill: TBrainEventSkill;




      FRpgOptions: TRpgOptions;
      procedure MainThreadTimer(Sender: TObject);
      procedure LoadDefsDB;

      function GetRandomtarget (aList:Tobjectlist<TEntity>): TEntity;
      function GetLowesthealthtarget (aList:Tobjectlist<TEntity>): TEntity;
  protected
    public

      FRpgThread: se_ThreadTimer;// main trhead che processa FqueueCompleteSkill e FQueueAnswer    // setta IGA  con applyaura, applyeffect

      GlobalMapCoords: se_Matrix ;/// array [1..1,1..1] of TlocalMapCoords;

      lstActiveSkills: TObjectList<TRpgActiveSkill>;

      ServerName: string;
      MapsDir: string;
      DefsDir: string;

      (* Solo per calcoli linea di tito*)
      FGrid                  : TgridStyle;
      fCellWidth             : integer;
      fCellHeight            : integer;
      fCellSmallWidth        : integer;
      VirtualWidth           : integer;
      Virtualheight          : integer;
      aHexCellSize           : THexCellSize;

      constructor Create( AOwner: TComponent ); override;
      destructor Destroy; override;


      procedure Start ( IniFile: string );
      function CreateCharacter(RpgObj:integer; defaultname, faction: string; number,Incr: integer): TEntity;
      procedure DeleteNpc(const ids:String);
      procedure DeleteItem(const ids:String);


      procedure Flush (rpgobj: integer);
      procedure DecodeFilename (FileName: string; out Map:ss20; out mapX,mapY: integer);
      function GetLocalMapCoord ( const Mapx, Mapy : Integer ): se_Matrix;
      procedure SaveLocalMap ( const Mapx, Mapy : Integer );
      procedure getneighbours ( aChar: TEntity ; radious: Integer; aFilter: TneighboursFilter;  IncludeSelf: Boolean; var aList:Tobjectlist<TEntity> );
      //uguali
      procedure SaveNpcToMap ( const Mapx, Mapy : Integer );
      procedure SaveItemToMap (const Mapx, Mapy : Integer );
      procedure LoadNpcFromMap ( const MapX, MapY: integer );
      procedure LoadItemFromMap ( const MapX, MapY: integer );

      property local_cellsX: integer read flocal_cellsX write flocal_cellsX default 3;
      property local_cellsY: integer read flocal_cellsY write flocal_cellsY default 3;
      property global_cellsX: integer read fglobal_cellsX write fglobal_cellsX default 10;
      property global_cellsY: integer read fglobal_cellsY write fglobal_cellsY default 10;

      property DefChar : se_RecordList read FDefChar write FDefChar;
      property DefItem : se_RecordList read FDefItem write FDefItem;
      property DefConst : se_RecordList read fDefConst write FDefConst;
      property DefSkill : se_RecordList read FdefSkill write FdefSkill;
      property DefTalent : se_RecordList read FdefTalent write FdefTalent;
      property DefColor : se_RecordList read FDefColor write FDefColor;

      property Npcs: TObjectList<TEntity> read FNpcs write FNpcs;
      property WorldItems: TObjectList<TEntity> read FWorldItems write FWorldItems;


      property Input: string read finput write finput ;   // utile per comandi generali da backend

      Function GetCliIdByIds  ( const Ids:String ): integer;
      Function GetCharByCliId ( const CliId:integer ): TEntity;



      function GetdefChar (const Name: string): PRpgCharDB;overload;
      function GetdefChar (const id: integer): PRpgCharDB;overload;
      function GetdefItem (const Name: string): PRpgItemDB; overload;
      function GetdefItem (const id: integer): PRpgItemDB;overload;
      function GetDefTalent (const TalentName: string): pRpgTalentDB;overload;
      function GetDefTalent (const id: integer): pRpgTalentDB;overload;

      Function GetNpcByIds(const Ids:String): TEntity;
      Function GetNpcByName(const Name:String): TEntity;
      Function GetNpcBymapXY(const Map:String; const mapcx, mapcy, cX,cY: integer): TEntity;
      Function GetNpc(const Faction:String; const Number : Integer): TEntity;

      Function GetWorldItemByName(const Name:String): TEntity;
      Function GetWorldItemByIds(const Ids:String): TEntity;
      function GetWorldItemBymapXY(const Map:String; const mapcx, mapcy, cX,cY: integer): TEntity;

      Function GetSomeThingByIds(const Ids:String): TEntity;
      procedure SetSomeThingByIds( IDs: string; aChar: TEntity ) ;

      function GetRange(aChar,bChar: TEntity): integer;
      function MinWXYZ (const Q, X, Y, Z: Int64): Integer;

      procedure CopyRpgPath ( src, dst: Tpath );
   //   function UseSkill (aChar: TEntity; X,Y: integer;aRpgSkill:TrpgSkill): string;

      procedure ProcessAllInput(Interval: integer);
      procedure ProcessInput(params:String);
  //    function EvaluateNumericValue(aRpgAura: TRpgAura; reverse: boolean): double;

      (*Sezione SKill*)

      procedure StopAllCasting (aChar: TEntity; IgnoreMove: boolean );

      procedure Map(const WorldX: Single; const WorldY: Single; out DisplayX: Integer; out DisplayY: Integer);
      procedure UnMap(const DisplayX: Integer; const DisplayY: Integer; out WorldX: Single;  out WorldY: Single);
      function Checklof( MapX, MapY: integer; hexA,Hext: TPoint; Map_Diagonal_attack: boolean; range: integer): TPoint;




      (*Sezione Aura*)

      procedure NilTarget (value: string);
      procedure Clean_AllAuras (Interval:integer);
      procedure Exec_AllAuras (Interval:integer);
      procedure Clean_AllActiveSkills (Interval:integer);
      procedure Exec_AllActiveSkills (Interval:integer);
      procedure Exec_AllCooldowns (Interval:integer);
      procedure Exec_AllRpgActions (Interval:integer);
      procedure AIEvent (Interval:integer);





    published
  //    property PathFinder: TPathFinder read FPathFinder write FPathFinder;
      property RpgOptions: TRpgOptions read FRpgOptions write FRpgOptions;


      (* Events *)
      property OnCharRespawn: TBrainEventChar read FOnCharRespawn write FOnCharRespawn;
      property OnCharEnter: TBrainEventChar read FOnCharEnter write FOnCharEnter;
      property OnCharExit: TBrainEventChar read FOnCharExit write FOnCharExit;


      property OnCharAbsorbDamage: TBrainEventCharHealth read FOnCharAbsorbDamage write FOnCharAbsorbDamage;
      property OnCharDrophealth: TBrainEventCharHealth read FOncharDrophealth write FOnCharDrophealth;
      property OnCharRecoverhealth: TBrainEventCharHealth read FOncharRecoverHealth write FOnCharRecoverHealth;
      property OnCharDeath: TBrainEventChar read FOnCharDeath write FOnCharDeath;
      property OnCharDroppower: TBrainEventChar read FOncharDroppower write FOnCharDroppower;
      property OnCharRecoverpower: TBrainEventChar read FOncharRecoverpower write FOnCharRecoverpower;


      property OnCharDrainedpower: TBrainEventChar read FOncharDrainedPower write FOnCharDrainedpower;

      property OnCharAuraAdd: TBrainEventAura read FOnCharAuraAdd write FOnCharAuraAdd;
      property OnCharAuraLoad: TBrainEventAura read FOnCharAuraLoad write FOnCharAuraLoad;
      property OnCharAuraTick: TBrainEventAura read FonCharAuraTick write FonCharAuraTick;
      property OnCharAuraDie: TBrainEventAura read FOnCharAuraDie write FOnCharAuraDie;

      property OnCharCastingSkill: TBrainEventSkill read FOnCharCastingSkill write FOnCharCastingSkill;
      property OnCharExecuteSkill: TBrainEventSkill read FOnCharExecuteSkill write FOnCharExecuteSkill;
      property OnCharAbortSkill: TBrainEventSkill read FOnCharAbortSkill write FOnCharAbortSkill;

      property OnCharStopMove: TBrainEventCharMove read fOnCharStopMove write fOnCharStopMove;
      property OnCharStartMove: TBrainEventCharMove read fOnCharStartMove write fOnCharStartMove;


      property OnCharHit: TBrainEventAura read FOnCharHit write FOnCharHit;
      property OnCharHitted: TBrainEventAura read FOnCharHitted write FOnCharHitted;
      property OnCharHealed: TBrainEventAura read FOnCharHealed write FOnCharHealed;
    end;

{$ENDREGION}

procedure Register;
function ReversePointOrder(LinePointList: TPath): TPath;
function GetLinePoints(X1, Y1, X2, Y2: Integer): TPath;
function GetHexDrawPoint( AHexCellSize : THexCellSize; ACol, ARow : Integer ) : TPoint;
function GetHexCellPoints( AOffSet : TPoint; AHexCellSize : THexCellSize; ACol, ARow : Integer ): TpointArray7;
procedure DrawHexCell( fVirtualBitmap: TBitmap; AOffSet : TPoint; AHexCellSize : THexCellSize; ACol, ARow : Integer );

implementation
procedure DrawHexCell( fVirtualBitmap: TBitmap; AOffSet : TPoint; AHexCellSize : THexCellSize; ACol, ARow : Integer );
var
  LPoint : TPoint;
  LXOffset : Integer;
begin
  { *************
    *   1---2
    *  /     \
    * 6       3
    *  \     /
    *   5---4
    ************* }

  LXOffset := ( AHexCellSize.Width - AHexCellSize.SmallWidth ) div 2;

  // Move to point 1
  LPoint := GetHexDrawPoint( AHexCellSize, ACol, ARow );
  LPoint.Offset( AOffSet );
  fVirtualBitmap.Canvas.MoveTo( LPoint.X, LPoint.Y );

    fVirtualBitmap.Canvas.Brush.Style := bsSolid;

  // Line to point 2
  LPoint.Offset( AHexCellSize.SmallWidth, 0 );
  fVirtualBitmap.Canvas.LineTo( LPoint.X, LPoint.Y );

  // Line to point 3
  LPoint.Offset( LXOffset, AHexCellSize.Height div 2 );
  fVirtualBitmap.Canvas.LineTo( LPoint.X, LPoint.Y );
  // Line to point 4
  LPoint.Offset( -LXOffset, AHexCellSize.Height div 2 );
  fVirtualBitmap.Canvas.LineTo( LPoint.X, LPoint.Y );
  // Line to point 5
  LPoint.Offset( -AHexCellSize.SmallWidth, 0 );
  fVirtualBitmap.Canvas.LineTo( LPoint.X, LPoint.Y );
  // Line to point 6
  LPoint.Offset( -LXOffset, -AHexCellSize.Height div 2 );
  fVirtualBitmap.Canvas.LineTo( LPoint.X, LPoint.Y );
  // Line to point 1
  LPoint.Offset( LXOffset, -AHexCellSize.Height div 2 );
  fVirtualBitmap.Canvas.LineTo( LPoint.X, LPoint.Y );
end;

// ----------------------------------------------------------------------------
// GetLinePoints
// ----------------------------------------------------------------------------
function GetLinePoints(X1, Y1, X2, Y2 : Integer) : TPath;
var
ChangeInX, ChangeInY, i, MinX, MinY, MaxX, MaxY, LineLength : Integer;
ChangingX : Boolean;
Point : TPoint;
ReturnList, ReversedList : TPath;
begin

  ReturnList := Tpath.Create;
 // ReversedList := Tpath.Create;


  if X1 > X2 then
  begin
  ChangeInX := X1 - X2;
  MaxX := X1;
  MinX := X2;
  end
  else
  begin
  ChangeInX := X2 - X1;
  MaxX := X2;
  MinX := X1;
  end;

  // Get the change in the Y axis and the Max & Min Y values
  if Y1 > Y2 then
  begin
  ChangeInY := Y1 - Y2;
  MaxY := Y1;
  MinY := Y2;
  end
  else
  begin
  ChangeInY := Y2 - Y1;
  MaxY := Y2;
  MinY := Y1;
  end;

  // Find out which axis has the greatest change
  if ChangeInX > ChangeInY then
  begin
  LineLength := ChangeInX;
  ChangingX := True;
  end
  else
  begin
  LineLength := ChangeInY;
  ChangingX := false;
  end;


  if X1 = X2 then
  begin
  for i := MinY to MaxY do
  begin
  Point.X := X1;
  Point.Y := i;
  ReturnList.Add(Point.X,Point.y);
  end;

  if Y1 > Y2 then
  begin
  ReversedList := ReversePointOrder(ReturnList);
  ReturnList := ReversedList;
  end;
  end

  else if Y1 = Y2 then
  begin
  for i := MinX to MaxX do
  begin
  Point.X := i;
  Point.Y := Y1;
  ReturnList.Add(Point.x,Point.Y );
  end;


  if X1 > X2 then
  begin
  ReversedList := ReversePointOrder(ReturnList);
  ReturnList := ReversedList;
  end;
  end
  else
  begin
  Point.X := X1;
  Point.Y := Y1;
  ReturnList.Add(Point.x,Point.y);

  for i := 1 to (LineLength - 1) do
  begin
  if ChangingX then
  begin
  Point.y := Round((ChangeInY * i)/ChangeInX);
  Point.x := i;
  end

  else
  begin
  Point.y := i;
  Point.x := Round((ChangeInX * i)/ChangeInY);
  end;

  if Y1 < Y2 then
  Point.y := Point.Y + Y1
  else
  Point.Y := Y1 - Point.Y;

  if X1 < X2 then
  Point.X := Point.X + X1
  else
  Point.X := X1 - Point.X;

  ReturnList.Add(Point.X,Point.y);
end;
// Add the second point to the list.
  Point.X := X2;
  Point.Y := Y2;
  ReturnList.Add(Point.X,Point.y);
end;
Result := ReturnList;
end;

function ReversePointOrder(LinePointList : TPath) : Tpath;
var
  NewPointList : TPath;
begin
  NewPointList := TPath.Create;
  NewPointList:=LinePointList;
  NewPointList.Reverse ;
  Result := NewPointList;
end;
function GetHexDrawPoint( AHexCellSize : THexCellSize; ACol, ARow : Integer ) : TPoint;
begin
  Result.X := ( ( AHexCellSize.Width - AHexCellSize.SmallWidth ) div 2 + AHexCellSize.SmallWidth ) * ACol;
  Result.Y := AHexCellSize.Height * ARow + ( AHexCellSize.Height div 2 ) * ( ACol mod 2 );
end;
function GetHexCellPoints( AOffSet : TPoint; AHexCellSize : THexCellSize; ACol, ARow : Integer ):TpointArray7;
var
  LPoint : TPoint;
  LXOffset : Integer;
begin
  LXOffset := ( AHexCellSize.Width - AHexCellSize.SmallWidth ) div 2;

  // Move to point 1
  LPoint := GetHexDrawPoint( AHexCellSize, ACol, ARow );
  LPoint.Offset( AOffSet );
  Result[0]:=Lpoint;
  // Line to point 2
  LPoint.Offset( AHexCellSize.SmallWidth, 0 );
  Result[1]:=Lpoint;
  // Line to point 3
  LPoint.Offset( LXOffset, AHexCellSize.Height div 2 );
  Result[2]:=Lpoint;
  // Line to point 4
  LPoint.Offset( -LXOffset, AHexCellSize.Height div 2 );
  Result[3]:=Lpoint;
  // Line to point 5
  LPoint.Offset( -AHexCellSize.SmallWidth, 0 );
  Result[4]:=Lpoint;
  // Line to point 6
  LPoint.Offset( -LXOffset, -AHexCellSize.Height div 2 );
  Result[5]:=Lpoint;
  // Line to point 1
  LPoint.Offset( LXOffset, -AHexCellSize.Height div 2 );
  Result[6]:=Lpoint;


end;

  function CompareCH (aitem1,aitem2: TEntity): integer;
  begin
    result := Trunc(aitem1.CH - aitem2.CH);
  end;

 { TODO : se nel moving di una skill si sposta, ricalcolo il mainpath con l'ultimo tpoint }
//uses misc;
procedure Register;
begin
  RegisterComponents('DSERPG', [TRpgBrain]);
end;
///////////////////////////////////////////////////////////////////////////////////
// TSkillManager  I
///////////////////////////////////////////////////////////////////////////////////


constructor TSkillManager.Create (owner: TEntity);
begin
  fChar:= Owner;
  lstSkills:= TObjectList<trpgSkill>.Create(true);
  rnd:= TtdCombinedPRNG.Create(0,0);
  //  lstSkills:= se_RecordList.CreateList(SizeOf(Trpgskill));
  decCd:=0;
end;
destructor TSkillManager.Destroy ;
begin
  rnd.Free;
  lstSkills.Free;
end;
procedure TSkillManager.AddSkilllist (v: string );
var
Skill: TrpgSkill;
ts: TStringList;
i: integer;
begin
  ts:= Tstringlist.Create ;
  ts.CommaText := v;

  for I := 0 to ts.Count -1 do begin

    Skill:= TRpgSkill.Create(fchar);
    Skill.pSkillDB               := GetDefSkill( StrToInt(ts[i])  );
    AddSkill(Skill.pSkillDB.SkillName);
    Skill.Free;
  end;
  ts.Free;
end;
procedure TSkillManager.AddSkill (v: string );
var
Skill: TrpgSkill;
Ts:TStringList;
m, input: string;
begin
  Skill:= TRpgSkill.Create(fchar);
  Skill.pSkillDB               := GetDefSkill(v);
  FillFromDb (Skill);
  lstSkills.Add(Skill);
  // innesco la mechanic
   if length(Skill.Mechanic) > 1 then begin
     ts:= tstringlist.Create ;
     ts.delimiter:='|'; ts.strictDelimiter:= true;
  	 ts.DelimitedText := Skill.Mechanic ; // prendo la mechanic dalla skill del char
     m        := ts.Values ['m'];
//     input    := ts.Values ['i'];   input ora non serve
     fchar.MechManager.AddMechanic(m) ;
     ts.Free;
  end;


end;
//  procedure TSkillManager.LoadSkills ;
//  var
//  s:integer;
//  aSkillDB: TRpgSkillDB;
//  aSkill: TrpgSkill;
//  begin
//
//    (*DA TSTRINGLIST SKILLS A SKILLLIST  CON VALORI BASE*)
//// le skill del char sono salvate nel db sotto forma di tstringlist. Qui vengono caricate
//// e viene riempita il record della char.skills con i valori base della skill (presi // anche questi dal db)
//// Successivamente i talenti aggiungono skill o modificano le skill esistenti
//    rlSkill.Clear ;
//
//    for s := 0 to Skills.Count -1 do begin
//      AddSkill (Skills[s]);
//    end;
//  end;

procedure TSkillManager.FillFromDB (Skill: TrpgSkill);
begin

    Skill.kind                   := Skill.pSkillDB.kind ;
    Skill.skillname              := Skill.pSkillDB.skillName;
    Skill.classes                := Skill.pSkillDB.classes;
    Skill.id                     := Skill.pSkillDB.id;

    Skill.cooldown               := Skill.pSkillDB.cooldown;
    Skill.Maxcooldown            := Skill.pSkillDB.cooldown;

    Skill.mechanic               := Skill.pSkillDB.mechanic;
    Skill.school                 := Skill.pSkillDB.school;

    Skill.casttime               := Skill.pSkillDB.casttime;
    Skill.power                  := Skill.pSkillDB.power;
    Skill.crit                   := Skill.pSkillDB.crit;
    Skill.range                  := Skill.pSkillDB.range;

    Skill.channeling             := Skill.pSkillDB.channeling ;
    Skill.Maxchanneling          := Skill.pSkillDB.channeling ;

    Skill.accuracy               := Skill.pSkillDB.accuracy ;
    Skill.Maxaccuracy            := Skill.pSkillDB.accuracy ;

    Skill.icon                   := Skill.pSkillDB.icon;
    Skill.spritename             := Skill.pSkillDB.spritename;

    Skill.Descr                  := Skill.pSkillDB.descr;

    Skill.Mechanic               := Skill.pSkillDB.mechanic ;

    Skill.requiredAura           := Skill.pSkillDB.requiredAura ;
    Skill.requiredNOAura         := Skill.pSkillDB.requiredNOAura ;
    Skill.requiredhealth         := Skill.pSkillDB.requiredHealth ;
    Skill.afterCast              := Skill.pSkillDB.afterCast ;

    Skill.lastinput              := 0;
        { TODO : mark importante }
    if Skill.SkillName <> 'move' then Skill.state:= sCooldown // le skill in quesot gioco partono in cooldown
    else Skill.State:= sready;

    {$ifdef rpg_client}
    Skill.EntitySprite              := nil;
    {$endif}

end;
function Trpgbrain.GetdefChar(const Name: string): PRpgCharDB;
var
i: integer;
begin
  result:= nil;
  for I := 0 to defChar.Count -1 do begin
    Result := defChar.Items[i];
    if Result.defaultname = Name then exit;
  end;

end;
function Trpgbrain.GetdefItem (const Name: string): PRpgItemDB;
var
i: integer;
begin
  result:= nil;
  for I := 0 to defItem.Count -1 do begin
    Result := defItem.Items[i];
    if Result.defaultname = Name then exit;
  end;

end;

function Trpgbrain.GetdefChar (const id: integer): PRpgCharDB;
var
i: integer;
begin
  result:= nil;
  for I := 0 to defChar.Count -1 do begin
    Result:= defChar.Items [i];
    if Result.id = id then exit;
  end;

end;
function Trpgbrain.GetdefItem (const id: integer): PRpgItemDB;
var
i: integer;
begin
  result:= nil;
  for I := 0 to defItem.Count -1 do begin
    Result:= defItem.Items [i];
    if Result.id = id then exit;
  end;

end;
function Trpgbrain.GetDefTalent (const TalentName: string): pRpgTalentDB;
var
i: integer;
begin
  result:= nil;
  for i := 0 to DefTalent.count -1 do begin
    Result:= DefTalent.items[i];
    if Result.talentName  = TalentName then exit;
  end;

end;


function TSkillManager.GetDefSkill (const SkillName: string): pRpgSkillDB;
var
i: integer;
pSkillDB: pRpgSkillDB;
begin
  for i := 0 to fchar.Brain.DefSkill.count -1 do begin
    pSkillDB:= fchar.Brain.DefSkill.items[i];
    if pSkillDB.skillname = skillname then begin
      result := pSkillDB;
      break;
    end;
  end;
end;
function TSkillManager.GetDefSkill (const id: integer): pRpgSkillDB;
var
i: integer;
pSkillDB: pRpgSkillDB;
begin
  for i := 0 to fchar.Brain.DefSkill.count -1 do begin
    pSkillDB:= fchar.Brain.DefSkill.items[i];
    if pSkillDB.id = id then begin
      result := pSkillDB;
      break;
    end;
  end;
end;

function TSkillManager.GetCharSkill (const SkillName: string): TRpgSkill  ;
var
i: integer;
pSkill: pRpgSkill;
begin
  Result:=nil;
  for i := 0 to lstSkills.count -1 do begin
    if  lstSkills.items[i].SkillName = SkillName then begin
      result := lstSkills.items[i];
      break;
    end;
  end;
end;
function TSkillManager.GetCharSkill (const id: integer): TRpgSkill  ;
var
i: integer;
pSkill: pRpgSkill;
begin
  Result:=nil;
  for i := 0 to lstSkills.count -1 do begin
    if  lstSkills.items[i].id = id then begin
      result := lstSkills.items[i];
      break;
    end;
  end;
end;
function TSkillManager.getRandomSkill (kind: string): TRpgSkill;
var
i, count, NewCount, aRND: integer;
pSkill: pRpgSkill;
begin
  (* Pos è utile per cercare attack multiattack *)
  Result:=nil;
  count:=0;
  for i := 2 to lstSkills.count -1 do begin                      // base 2. 0 è sempre move 1 autoattack
    if  (Pos ( kind, lstSkills.items[i].kind,1) <> 0) and (lstSkills.items[i].state = sReady)
    then begin
      Count := Count +1;
    end;
  end;

  if Count = 0 then Exit;


  aRND:=  rnd.AsInteger (count);  // lavoro in base 1 comunque dopo

  (*Le ritrovo e punto la count*)

  NewCount:=-1;
  for i := 2 to lstSkills.count -1 do begin
    if  (Pos ( kind, lstSkills.items[i].kind,1) <> 0) and (lstSkills.items[i].state = sReady) then begin
      Inc(NewCount);
      if NewCount = aRND then begin
        Result:= lstSkills.items[i];
        Exit;
      end;
    end;
  end;

end;
function TSkillManager.GetnextRotationSkill : TRpgSkill;
var
i : integer;
begin
  (* Pos è utile per cercare attack multiattack *)
  Result:=nil;
  for i := 2 to lstSkills.count -1 do begin                  // base 2. 0 è sempre move 1 autoattack
    if lstSkills.items[i].state = sReady
    then begin
        Result:= lstSkills.items[i];
        Exit;
    end;
  end;
end;
function TSkillManager.GetnextRotationSkillH : TRpgSkill;
var
i : integer;
begin
  (* Pos è utile per cercare attack multiattack *)
  Result:=nil;
  for i := 2 to lstSkills.count -1 do begin
    if  (    (Pos ( 'attack', lstSkills.items[i].kind,1) <> 0) or
             (Pos ( 'curse',  lstSkills.items[i].kind,1) <> 0))     and     (lstSkills.items[i].state = sReady)
    then begin
        Result:= lstSkills.items[i];
        Exit;
    end;
  end;
end;
function TSkillManager.GetnextRotationSkillF : TRpgSkill;
var
i : integer;
begin

  Result:=nil;
  for i := 2 to lstSkills.count -1 do begin                       // base 2. 0 è sempre move 1 autoattack
    if  (    (Pos ( 'heal', lstSkills.items[i].kind,1) <> 0) or
             (Pos ( 'blessing',  lstSkills.items[i].kind,1) <> 0))     and     (lstSkills.items[i].state = sReady)
    then begin
        Result:= lstSkills.items[i];
        Exit;
    end;
  end;
end;

procedure TSkillManager.ResetAllCooldowns ;  // mechanic cdrage
var
i: integer;
begin
  for i := 0 to lstSkills.count -1 do begin
      lstSkills.items[i].cooldown := lstSkills.items[i].Maxcooldown ;
  end;
end;
procedure TSkillManager.ModifyAllCooldowns (const Value: integer);  // mechanic cdrage
var
i: integer;
begin
  for i := 2 to lstSkills.count -1 do begin
      if lstSkills.items[i].state = sCooldown then
      lstSkills.items[i].cooldown := lstSkills.items[i].cooldown + Value;
  end;
end;


procedure TSkillManager.SetAccuracyBySchool (const school: string; v: double);
var
i: integer;
begin
  for i := 0 to lstSkills.count -1 do begin
    if  lstSkills.items[i].school  = school then begin
      lstSkills.items[i].accuracy := lstSkills.items[i].accuracy + v;
      lstSkills.items[i].Maxaccuracy := lstSkills.items[i].accuracy ;
    end;
  end;
end;
procedure TSkillManager.SetCritBySchool (const school: string; v: double);
var
i: integer;
begin
  for i := 0 to lstSkills.count -1 do begin
    if  lstSkills.items[i].school  = school then begin
      lstSkills.items[i].crit  := lstSkills.items[i].crit + v;
    end;
  end;
end;


procedure TSkillManager.Execute (pSkill: pRpgSkill);
var
  a,aa: integer;
  TsRequiredAura: TstringList;
  pAura,pAura2: PrpgAura;
begin
 // applyaura


end;

//  end;
procedure TSkillManager.Broadcast (const msg: TmsgManager; Periodic: boolean; Skill:  TRpgSkill; var Output: string );
var
i:integer;
pSkill2:  pRpgSkill;
found: Boolean;
RequiredAuras,RequiredNOAuras: TStringList;
begin
  (* Qui la Skill non è ancora completed. pSkill è la CharSkill *)
  if msg = msg_cast then begin

    // vedo se quella skill è nel char. Nel caso non fosse presente potrebbe essere un cheat
    for i := 0 to lstSkills.Count -1  do begin
      if lstSkills.Items [i].SkillName = Skill.SkillName  then begin
        Found:= true;
        Break;
      end;
    end;

    if Not Found then begin
      Output := 'hacked-skillNotFound';
      Exit;
    end;

    (*Il Client impedisce di inviare skill se queste sono in cooldown. Se ciò avviene è sicuramente un cheat *)
    if Skill.state <> sready then begin       // controllo la skill del Character, non la completedSkill
      Output := 'hacked-cooldown';
      Exit;
    end;

   (* check del power. Il client non può castare senza power in quanto il controllo è fatto sul client, ma intanto potrebbe essere
      stata generata del power quindi non è hacked e il client ancora non lo sapeva *)
    if fChar.CP < Skill.power  then begin
      Output := 'notenoughpower';
      Exit;
    end;

    {  lista di requiredAura della skill }
    RequiredAuras:= TStringList.Create ;
    RequiredAuras.DelimitedText := skill.requiredAura ;
    for i := 0 to RequiredAuras.Count -1 do begin
      if fchar.AuraManager.IsAuraLoaded(RequiredAuras[i]) = nil then   // manca anche solo 1 aura tra quelle richieste
      begin
      Output := 'aurarequired:' + RequiredAuras[i];
      RequiredAuras.Free;
      Exit;
      end;
    end;
    RequiredAuras.Free;

    {  lista di requiredNOAura della skill }
    RequiredNOAuras:= TStringList.Create ;
    RequiredNOAuras.DelimitedText := skill.requiredNOAura ;
    for i := 0 to RequiredNOAuras.Count -1 do begin
      if fchar.AuraManager.IsAuraLoaded(RequiredNOAuras[i]) <> nil then   // è presente manca anche solo 1 aura tra quelle non richieste
      begin
      Output := 'auraNOrequired:' + RequiredNOAuras[i];
      RequiredAuras.Free;
      Exit;
      end;
    end;
    RequiredAuras.Free;

              { TODO : requiredHelath <=35 }

      (* Stunned e silenced non è hacked, come la power può essere arrivato in corso, in millisecondi. Diverso è il discorso
        assenza di skill e cooldown *)

    if fChar.Stunned then begin
      Output := 'stunned';
      Exit;
    end;

    if (fChar.Silenced) and (Skill.school <> 'physical') then begin //  { TODO : or pSkill.canbecastes }
      Output := 'silenced';
      Exit;
    end;

    (* Sottraggo il power. Il check è stato fatto in precedenza *)
    skill.fChar.CP := skill.fChar.CP - Skill.power ;

    Output := 'OK';


  end
  else if msg = msg_execute then begin  (* la skill è stata regolarmnete eseguita. Possibili modifiche ad auree *)

  // qui setto il cooldown

  end
  else if msg = msg_hit then begin  (* la skill ha hittato qualcuno *)

  end
  else if msg = msg_hitted then begin  (* il Character è stato hittato. Le skill potrebbero alzare i cooldown *)


  end
  else if msg = msg_damaged then begin  (* il Character è stato danneggiato. Le skill reagiscono *)


  end
  else if msg = msg_damageDone then begin  (* il Character HA danneggiato. Le skill reagiscono *)

  end
  else if msg = msg_healed then begin  (* il Character è stato curato. Le skill reagiscono *)


  end
  else if msg = msg_healDone then begin  (* il Character HA curato. Le skill reagiscono *)


  end
  else if msg = msg_death then begin

        Skill.state := sdead;

  end;
  //    TsConditions:= TStringList.create;
  //    for a := 0 to SourceChar.AuraManager.auralist.Count -1  do begin
  //        ARpgAuraP:= SourceChar.AuraManager.Auralist.items [a];
  //        if ARpgAuraP.state <> 'idle' then Continue;
  //         // sfoglio tutte le auree onhitted
  //        TsConditions.CommaText := ARpgAuraP.Condition;  // a=aspect.of.the.light h=35
  //
  //        if Pos(ARpgAuraP.trigger , 'onhit' ,1) <> 0 then begin
  //
  //            //qui check conditions aspect.of.the.light
  //            if length (TsConditions.Values ['a']) > 1 then begin
  //              for aa := 0 to SourceChar.AuraManager.auralist.Count -1 do begin
  //                ARpgAuraP2:= SourceChar.AuraManager.auralist.items [aa];
  //
  //                if Pos( ARpgAuraP2.sLabel , TsConditions.Values ['a'],1) <> 0 then begin
  //                  // qui invece devo attivare la light slow x 5 secondi su qeesto carattere
  //                  // quindi la copio gli tolgo persistent e poi la metto in testa a character
  //                  if aRpgAura.copy  then begin
  //                    aRpgAura2:= ARpgAura;
  //                    aRpgAura2.persistent := false;
  //                    aRpgAura2.state := 'active';
  //                    Character.AddAura(@ARpgAura2);
  //                  end
  //                  else begin
  //                    ARpgAuraP.state := 'active';
  //                  end;
  //                end;
  //              end;
  //            end
  //            else
  //            begin                                         // nessuna condition, semplice onhitted execute
  //               if aRpgAura.copy  then begin
  //                  aRpgAura2:= ARpgAura;
  //                  aRpgAura2.persistent := false;
  //                  aRpgAura2.state := 'active';
  //                  Character.AddAura(@ARpgAura2);
  //               end
  //               else begin
  ////                    Character.auraList.state[a] := 'active';
  //                    ARpgAuraP.state := 'active';
  //                    //ARpgAura:= Character.AuraList.RpgAura [a];
  //               end;
  //            end;
  //        end;
  //    end;
  //   TsConditions.Free;


end;
procedure TSkillManager.Broadcast (const msg: TmsgManager; Periodic: boolean;  Aura:  TRpgAura; var Output: string );
var
i:integer;
pSkill2:  pRpgSkill;
begin
  if msg = msg_cast then begin


  end
  else if msg = msg_execute then begin  (* la skill è stata regolarmnete eseguita. Possibili modifiche ad auree *)


  end
  else if msg = msg_hit then begin  (* la skill che ha generato questa aura ha hittato qualcuno. es. slow a target *)

   if not Periodic then begin
    ModifyAllCooldowns (- 1000); // modifica solo le skill che sono sCooldown

    (* la skill che ha generato questa aura ha hittato qualcuno. es. slow a target *)
    (* Informo le auree (trigger specialemte) del source che ha hittato*)
    Aura.FromActiveSkill.Source.AuraManager.Broadcast(msg_hit,periodic,Aura.FromActiveSkill.Skill, output );
   end;
  end
  else if msg = msg_hitted then begin  (* il Character è stato hittato. Le skill decrementano i cooldown *)
     (* Potrebbe esistere il caso in cui essere hittati rallenta i cd. In ogni caso essere hittati decrementa i cooldown
        Ad alzare i cooldown sarà il successivo lancio afterhit del source che applicherà un'aura a tempo.
      *)

   if not Periodic then begin
   ModifyAllCooldowns (- 1000);
   { TODO : -1000 potrebbe esser il valore della skill campodb ragecd }
   end;
  end
  else if msg = msg_damageDone then begin  (* la skill che ha generato questa aura ha danneggiato qualcuno. es. slow a target *)

    Aura.FromActiveSkill.Source.AuraManager.Broadcast(msg_damageDone,periodic,Aura.FromActiveSkill.Skill, output );

  end
  else if msg = msg_damaged then begin  (*  *)


  end
  else if msg = msg_healed then begin  (* il Character è stato curato. Le skill reagiscono *)

  end
  else if msg = msg_healDone then begin  (* il Character HA curato. Le skill reagiscono *)

    Aura.FromActiveSkill.Source.AuraManager.Broadcast(msg_healDone,periodic,Aura.FromActiveSkill.Skill, output );
  end
  else if msg = msg_death then begin


  end;

end;

procedure TSkillManager.TryExecuteSkill (ActiveSkill: TrpgActiveSkill);
var
lstAfter: TStringList;
e,a,aa: integer;
aSubSkill:TRpgActiveSkill;
SkillUsed: boolean;
aSkill: TRpgSkill;
NewPos: TPoint;
begin
(* ExecuteSkill arriva dal trhead che processa le auree e le skill e NON dal caricamento talenti di un TEntity *)

(* Le mechanic sono già informate in processInput. Anche le auree (stun, silenced) sono già state informate *)


      (*Qui posso eseguire la skill, che contiene delle subskill*)
      lstAfter:= TStringList.create; lstAfter.Delimiter :='|';
      lstAfter.DelimitedText := ActiveSkill.skill.afterCast;   // a=SD,v=ma,d=0|a=ignite,v=ma*0.10,d=20000,tick=5000

      // una ActiveSkill può compiere diverse azioni. i dati sono tutti in effect
//      ActiveSkill.Used:= false;
      for e := 0 to lstAfter.Count -1 do begin
        aSubSkill:= ActiveSkill;
        aSubSkill.aEffect  :=  lstAfter[e]; //a=SD,v=ma
                                            //a=ignite,v=ma*0.10,d=20000,tick=5000
          { TODO : aoe ripete skillused }
         // if Not ActiveSkill.Used then begin    // può avere più effetti quindi ma qui setto il lancio unico della skill

            (* Devo conoscere ora il nome dell'aura per potere caricare l'oggetto giusto *)
            if ActiveSkill.Skill.SkillName = 'move' then begin
            // aggiorno le coordinate
              NewPos :=  ( ActiveSkill.Source.GetNextKeyUp );
              ActiveSkill.Source.Cx := NewPos.X;
              ActiveSkill.Source.Cy := NewPos.Y ;
              fChar.RpgAction.action  := '';
              { TODO : check dei polygon wall }


            end
            else if ActiveSkill.Target.AuraManager.TryAddRpgAura(lstAfter[e], ActiveSkill ) then begin
              // la skill viene eseguita per forza qui quindi posso chiamare l'evento
              if Assigned ( fChar.Brain.OnCharExecuteSkill )  then  fChar.Brain.OnCharExecuteSkill (fChar , ActiveSkill);
              ActiveSkill.Used:= true;           // setto che la skill è usata
              fChar.RpgAction.action  := '';     // il char non fa nulla
              fchar.State := 'cidle';
              (* setto il cooldown della skill *)
              aSkill:= fChar.SkillManager.GetCharSkill (  ActiveSkill.Skill.SkillName );
              aSkill.state := sCooldown;
              ActiveSkill.state:= sDead;
            end;

         //   end;

        end;
end;




{$ENDREGION}

  constructor TRpgSkill.Create (owner: TEntity);
  begin
    fChar:= Owner;
  end;
  destructor TRpgSkill.Destroy ;
  begin
    inherited;
  end;

constructor TRpgActiveSkill.Create (owner: TEntity);
begin
  fChar:= Owner;
end;
destructor TRpgActiveSkill.Destroy ;
begin
  inherited;
end;
constructor TRpgAction.Create (owner: TEntity);
begin
  fChar:= Owner;
end;
destructor TRpgAction.Destroy ;
begin
  inherited;
end;

{$REGION 'TAuramanager I'}
  constructor TAuraManager.Create (owner: TEntity);
  begin
    fChar:= Owner;
    Auras:=TStringList.Create ;
    lstAura:= TObjectList<TRpgAura>.Create();

  { Set the OwnsObjects to true - the List will free them automatically }
    lstAura.OwnsObjects := true;
  end;
  destructor TAuraManager.Destroy ;
  begin
    lstAura.Free;
    inherited;
  end;

  procedure TAuraManager.Execute ;
  begin
  //
  end;
procedure TAuraManager.Broadcast (const msg: TmsgManager; Periodic: boolean; Aura: TRpgAura; var Output: string );
var
i: integer;
begin
  if Msg =  msg_cast then   begin

      (* l'aura non è mai castata *)

    end
    else if Msg =  msg_execute then   begin     (* Qui le auree vengono informate che l'aura è eseguita*)

    end
    else if Msg =  msg_hit then   begin          (* Qui le auree vengono informate che l'aura ha hittato qualcuno*)
    (* per esempio ora he ha hittato può applicare slow o freeze o bleeding, ma forse lo fa la skill, questo tipo di effetto riguarda bombe auree che esplodono quando hittato *)
      fchar.Combat := true;
            {$ifdef rpg_logger}
                Writeln( fchar.charLogger ,  'AuraManager.Hit: ' + Aura.FromActiveSkill.Target.ids);
            {$endif rpg_logger}

    end
    else if Msg =  msg_hitted then   begin      (* Qui le auree vengono informate che il character è stato hittato*)
      fchar.Combat := true;
            {$ifdef rpg_logger}
                Writeln( fchar.charLogger ,  'AuraManager.Hitted from: ' + Aura.FromActiveSkill.fChar.ids);
            {$endif rpg_logger}

    end
    else if Msg =  msg_damaged then   begin      (* Qui le auree vengono informate che il character è stato danneggiato*)
      fchar.Combat := true;
            {$ifdef rpg_logger}
                Writeln( fchar.charLogger ,  'AuraManager.Damaged from: ' + Aura.FromActiveSkill.fchar.ids);
            {$endif rpg_logger}
      (* trigger.attack.speed e altre auree a trigger devono essere informate se attivarsi o meno*)
      for i := 0 to lstAura.Count -1  do begin
        lstAura.Items [i].Input (msg,  Output );
      end;

    end
    else if Msg =  msg_healed then   begin      (* Qui le auree vengono informate che il character è stato healeto*)
      fchar.Combat := true;
            {$ifdef rpg_logger}
                Writeln( fchar.charLogger ,  'AuraManager.Healed from: ' + Aura.FromActiveSkill.fChar.ids);
            {$endif rpg_logger}
      for i := 0 to lstAura.Count -1  do begin
        lstAura.Items [i].Input (msg,  Output );
      end;

    end
    else if Msg =  msg_damageDone then   begin      (* Qui le auree vengono informate che il character HA danneggiato*)
      fchar.Combat := true;
            {$ifdef rpg_logger}
                Writeln( fchar.charLogger ,  'AuraManager.Damage Done: ' + Aura.FromActiveSkill.Target.ids);
            {$endif rpg_logger}

    end
    else if Msg =  msg_healDone then   begin      (* Qui le auree vengono informate che il character HA curato*)
      fchar.Combat := true;
            {$ifdef rpg_logger}
                Writeln( fchar.charLogger ,  'AuraManager.HealDone: ' + Aura.FromActiveSkill.Target.ids);
            {$endif rpg_logger}

    end
    else if msg = msg_death then begin
     (* Per rimuovere absorbshield e tante altre belle cose *)
    for i := 0 to lstAura.Count -1  do begin     //sto verificando questo . adesso non deve sommarsi il bmp se non altro
      lstAura.Items [i].Input (msg,  Output );
    end;
    end;



end;
procedure TAuraManager.Broadcast (const msg: TmsgManager; Periodic: boolean; Skill: TRpgSkill; var Output: string );
var
i: Integer;
begin

  if Msg =  msg_cast then  begin   (* Qui le auree vengono informate che la skill vuole essere castata ma non è ancora in casting*)

      (* qui la skill è quasi eseguita. i controlli della skillmanager sono precedenti. Ora controllo le auree. le auree settano i flag
      stunned, silenced e rooted quando agiscono e qui è già stat checkato dalla skill se il TEntity era per esempio stunned.
      Qui devo calcolare auree come misdirection, confusion ecc.. in pratica: cambi di target *)

      //if pos (FAura,'confused',1) <> 0 then begin     // check confusion
      //qui guardare il db e calcolare le possibili cose che accadono.

      (* se hunter.mark non può stealth *)
    if (IsAuraLoaded('hunter.mark') <> nil ) and (Pos ( 'stealth', Skill.afterCast,1)   <> 0) then begin  {  non usare slabel ma in aftercast cercare stealth }
      Output:= 'hunter.mark_can_stealth';
      Exit;
    end;

    if IsAuraLoaded('confusion') <> nil then begin
            { TODO : confused 50% probabilità fallire? talento per diminuire fallimento?}
      Output:= 'change_target';
      Exit;
    end;
                              { TODO : gestire tutto con input su singola aura }
    { TODO : QUi FARE stunned, silence, rooted ecc.... category }
  { TODO : IMMUNE / REFLECT ALL applicazione di auree }

    Output:= 'OK';

    end
    else if Msg =  msg_execute then   begin     (* Qui le auree vengono informate che la skill è eseguita*)

    end
    else if Msg =  msg_hit then   begin          (* Qui le auree vengono informate che la skill ha hittato qualcuno*)
    (* per esempio ora he ha hittato può applicare slow o freeze o bleeding*)
      fchar.Combat := true;
    end
    else if Msg =  msg_hitted then   begin      (* Qui le auree vengono informate che il character è stato hittato*)
      fchar.Combat := true;

    end
    else if Msg =  msg_damaged then   begin      (* Qui le auree vengono informate che il character è stato danneggiato*)
      fchar.Combat := true;

    end
    else if Msg =  msg_damageDone then   begin      (* Qui le auree vengono informate che il character HA danneggiato*)
      fchar.Combat := true;

    end
    else if Msg =  msg_healed then   begin      (* Qui le auree vengono informate che il character è stato healeto*)
      fchar.Combat := true;

    end
    else if Msg =  msg_healDone then   begin      (* Qui le auree vengono informate che il character HA curato*)
      fchar.Combat := true;

    end
    else if msg = msg_death then begin


    end;

end;

Function TAuraManager.IsAuraLoaded ( const v: string ): TrpgAura;
var
  i: integer;
begin
    Result:= nil;
    for i := 0 to lstAura.Count -1 do begin
      if (v = lstAura.Items [i].auraname) and (lstAura.Items [i].State <> adead) then begin
        result:= lstAura.Items [i];
        Exit;
      end;

    end;
end;


procedure TAuraManager.AssignOwner ( const v: TEntity );
begin
 FChar := v;
end;
procedure TAuraManager.SetAllDead ( );
var
  i: integer;
begin
    for i := 0 to lstAura.Count -1 do begin
      if not( lstAura.Items [i].persistent ) then lstAura.Items [i].State := aDead;
    end;
end;

procedure TAuraManager.AddDirectAura ( Aura: TRpgAura );
begin
  lstAura.Add(Aura);
end;
function TAuraManager.String2Aura ( aString: string ): TAura;
var
ts: tstringlist;
begin
  ts:= tstringlist.Create ;
  ts.CommaText := aString;
  Result.AuraName:=  ts.Values ['a'];                            // es. blessing.of.fortune or  SD  or HEAL
  Result.v           := ts.Values ['v'];
  Result.duration    := StrToIntDef(ts.Values ['d'],0);          // durata della'aura
  Result.maxduration := Result.duration;
  Result.cooldown    := StrToIntDef(ts.Values ['cd'],0);         // cooldown dell'aura (spesso nel caso di trigger)
  Result.maxcooldown := Result.cooldown;
  Result.tick        := StrToIntDef(ts.Values ['tick'],0);       // Tempo di intervallo nel  caso di auree tick (DoT)
  Result.radious     := StrToIntDef(ts.Values ['radious'],0);    // nel caso di Aoe ( Area of Effect )
  Result.applychance := StrToIntDef(ts.Values ['ach'],0);    //
  ts.free;
end;

function TAuraManager.TryAddRpgAura ( const Effect: string; ActiveSkill: TrpgActiveSkill ): boolean;
var
Neighbours: Tobjectlist<TEntity>;
paskill: PRpgActiveSkill ;
canAddAura: boolean;
i: integer;
ts: tstringlist;

aGenericAura:TrpgAura;
AManager: TAuraManager;
aura: Taura;

aBlessingoftheHumans: TBlessingOfTheHumans;
aBlessingoftheelves: TBlessingOftheelves;
aBlessingofthekindred: TBlessingOftheKindred;
aBlessingoffortune: TBlessingOfFortune;
aBlessingoftenacity: TBlessingOftenacity;
aBlessingofLife: TBlessingOfLife;

aNaturalProtection: TNaturalProtection;
aSchoolDamage: TSchoolDamage;
aShadowPain: TShadowPain;
aheal: THeal;
aSilenced: TSilenced;
aAbsorbShield: TAbsorbShield;
adebuffallmasteries: Tdebuffallmasteries;

aGodsGift:TGodsGift;
aDamnation:TDamnation;
aSlowed: TSlowed;
aRevive : TRevive;
aImmunity : TImmunity;
aFree : TFree;
aPray : TPray;
aDrainPower: TdrainPower;
aLightOfhealing: TLightofHealing ;
aDivineLight : TDivineLight ;
aDivinePunishment: TDivinePunishment;
begin

  (* è chiamata da tryExecuteSkill*)
  if fChar.fstate = 'cdead' then Exit; // se sono morto non mi può accadere nulla
  {$ifdef rpg_server}
  Aura:= String2Aura (effect);
  Aura.school      := ActiveSkill.Skill.school ;                // es. fire, water, dark etc....

  (* Controllo subito la applychance, se fallisce inutile continuare*)
  { TODO : tdrandom ach }
   { TODO : qui evasion dodge }
   { TODO : per tutte fare il radious, tanto vale , no? }
  if Aura.auraName = 'SD' then begin
    aSchoolDamage:= TSchoolDamage.Create(effect, ActiveSkill );
    lstAura.Add(aSchoolDamage);

    if Aura.radious > 0 then begin

      (* qui non sono stati fatti i check per i target che vengono fatti con cancel in create *)
      Neighbours:= TObjectList<TEntity>.Create(false); // molta attenzione, è false per evitare il delete
      //problema immunitàImmunity per sD o frezze sotto pray   per cui vanno fatte nel create
      fchar.Brain.getneighbours (fchar , aura.radious, Friendly, false, Neighbours );
            //problema immunitàImmunity per sD o frezze sotto pray   per cui vanno fatte nel create

      for I := 0 to Neighbours.Count -1 do begin
        if Neighbours[i]= fChar then Continue;

          Activeskill.Target :=  Neighbours[i] ;       // proprio perchè è un puntatore il target rimane l'ultimo settato'
                                                      //  e nel load aCharT viene preso da fromtarget. Ora da Fchar                                                  '
          aSchoolDamage:= TSchoolDamage.Create(effect, ActiveSkill );
          Neighbours[i].AuraManager.AddDirectAura (aSchoolDamage);
        end;
      Neighbours.Free;
      (*Rimetto l'originale ActiveSkill per l'answer*)
      Activeskill.Target := fChar; // sè stessa
    end;

  end
  else if Aura.auraName = 'SDH' then begin

    aSchoolDamage:= TSchoolDamage.Create(effect, ActiveSkill );
    lstAura.Add(aSchoolDamage);

    if aura.radious > 0 then begin

      (* qui non sono stati fatti i check per i target che vengono fatti con cancel in create *)
      Neighbours:= TObjectList<TEntity>.Create(false); // molta attenzione, è false per evitare il delete
      //problema immunitàImmunity per sD o frezze sotto pray   per cui vanno fatte nel create
      fchar.Brain.getneighbours (fchar , aura.radious, Friendly, false, Neighbours );
            //problema immunitàImmunity per sD o frezze sotto pray   per cui vanno fatte nel create

      for I := 0 to Neighbours.Count -1 do begin
        if Neighbours[i]= fChar then Continue;

          Activeskill.Target :=  Neighbours[i] ;       // proprio perchè è un puntatore il target rimane l'ultimo settato'
                                                      //  e nel load aCharT viene preso da fromtarget. Ora da Fchar                                                  '
          aSchoolDamage:= TSchoolDamage.Create(effect, ActiveSkill );
          Neighbours[i].AuraManager.AddDirectAura (aSchoolDamage);
        end;
      Neighbours.Free;
      (*Rimetto l'originale ActiveSkill per l'answer*)
      Activeskill.Target := fChar; // sè stessa
    end;

  end
  else if Aura.auraName = 'shadow.pain' then begin
    aGenericAura :=  IsAuraFromChar  ( Aura.AuraName, ActiveSkill.Source ); // fromchar
    if aGenericAura <> nil  then aGenericAura.RenewAuraDuration(0) else begin
      aShadowPain:= TShadowPain.Create(effect, ActiveSkill );
      lstAura.Add(aShadowPain);
    end;

    if aura.radious > 0 then begin

      (* qui non sono stati fatti i check per i target che vengono fatti con cancel in create *)
      Neighbours:= TObjectList<TEntity>.Create(false); // molta attenzione, è false per evitare il delete
      //problema immunitàImmunity per sD o frezze sotto pray   per cui vanno fatte nel create
      fchar.Brain.getneighbours (fchar , aura.radious, Friendly, false, Neighbours );
            //problema immunitàImmunity per sD o frezze sotto pray   per cui vanno fatte nel create

      for I := 0 to Neighbours.Count -1 do begin
        if Neighbours[i]= fChar then Continue;

          Activeskill.Target :=  Neighbours[i] ;       // proprio perchè è un puntatore il target rimane l'ultimo settato'
                                                      //  e nel load aCharT viene preso da fromtarget. Ora da Fchar                                                  '
          aShadowPain:= TShadowPain.Create(effect, ActiveSkill );
          Neighbours[i].AuraManager.AddDirectAura (aShadowPain);
        end;
      Neighbours.Free;
      (*Rimetto l'originale ActiveSkill per l'answer*)
      Activeskill.Target := fChar; // sè stessa
    end;

  end
  else if Aura.auraName = 'HEAL' then begin
    aheal:= THeal.Create(effect, ActiveSkill );
    lstAura.Add(aHeal);

    if aura.radious > 0 then begin

      (* qui non sono stati fatti i check per i target che vengono fatti con cancel in create *)
      Neighbours:= TObjectList<TEntity>.Create(false); // molta attenzione, è false per evitare il delete
      //problema immunitàImmunity per sD o frezze sotto pray   per cui vanno fatte nel create
      fchar.Brain.getneighbours (fChar , aura.radious, Friendly, false, Neighbours );
            //problema immunitàImmunity per sD o frezze sotto pray   per cui vanno fatte nel create

      for I := 0 to Neighbours.Count -1 do begin
      //  if Neighbours[i]= fChar then Continue;

          Activeskill.Target :=  Neighbours[i] ;       // proprio perchè è un puntatore il target rimane l'ultimo settato'
                                                      //  e nel load aCharT viene preso da fromtarget. Ora da Fchar                                                  '
          aHeal:= THeal.Create(effect, ActiveSkill );
          Neighbours[i].AuraManager.AddDirectAura (aHeal);
        end;
      Neighbours.Free;
      (*Rimetto l'originale ActiveSkill per l'answer*)
      Activeskill.Target := fChar; // sè stessa
    end;

  end
  else if Aura.auraName = 'silenced' then begin

  (* il controllo dello stack avviene sul TEntity di questa AuraManager *)
  (* In questo caso slowed si somma in caso di source diverse , creando *)
  (* una slowed in più *)
    aGenericAura :=  IsAuraFromChar  ( Aura.AuraName, ActiveSkill.Source ); // fromchar
    if aGenericAura <> nil  then aGenericAura.RenewAuraDuration(0) else begin
      aSilenced:= TSilenced.Create(effect, ActiveSkill );
      lstAura.Add(aSilenced);
    end;

  end
  else if Aura.auraName = 'absorb.shield' then begin

  (* il controllo dello stack avviene sul TEntity di questa AuraManager *)
  (* In questo caso absorb.shield si somma in caso di source diverse , creando *)
  (* una absorb.shield in più. absorb.shield ha durata illimitata *)
  (* absorb.shield non può morire subito come SD ma rimane attiva fino a quando non viene consumato il bonus di absorb *)
    aGenericAura :=  IsAuraFromChar  ( Aura.AuraName, ActiveSkill.Source ); // fromchar
    if aGenericAura = nil  then  begin
      //non rinnovo duration. se c'è già non si somma dallo stesso character
      aAbsorbShield:= TAbsorbShield.Create(effect, ActiveSkill );
      lstAura.Add(aAbsorbShield);
    end;

  end
  else if Aura.auraName = 'debuff.all.masteries' then begin

  (* il controllo dello stack avviene sul TEntity di questa AuraManager *)
  (* In questo caso debuff.all.masteries si somma in caso di source diverse, creando *)
  (* una damnation in più *)
    aGenericAura :=  IsAuraFromChar  ( Aura.AuraName, ActiveSkill.Source ); // fromchar     prima sè stessi
    if aGenericAura <> nil  then aGenericAura.RenewAuraDuration(0) else begin
      adebuffallmasteries:= Tdebuffallmasteries.Create(effect, ActiveSkill );
      lstAura.Add(adebuffallmasteries);
    end;
    if aura.radious > 0 then begin                                                       // poi i vicini

      (* qui non sono stati fatti i check per i target che vengono fatti con cancel in create *)
      Neighbours:= TObjectList<TEntity>.Create(false); // molta attenzione, è false per evitare il delete
      //problema immunitàImmunity per sD o frezze sotto pray   per cui vanno fatte nel create
      fchar.Brain.getneighbours (fchar , aura.radious, friendly, false, Neighbours );  // cerco friendly perchè io subisco la penalità
            //problema immunitàImmunity per sD o frezze sotto pray   per cui vanno fatte nel create

      for I := 0 to Neighbours.Count -1 do begin
       // if Neighbours[i]= fChar then Continue;

          Activeskill.Target :=  Neighbours[i] ;       // proprio perchè è un puntatore il target rimane l'ultimo settato'
                                                      //  e nel load aCharT viene preso da fromtarget. Ora da Fchar                                                  '
          adebuffallmasteries:= Tdebuffallmasteries.Create(effect, ActiveSkill );
          Neighbours[i].AuraManager.AddDirectAura (adebuffallmasteries);
        end;
      Neighbours.Free;
      (*Rimetto l'originale ActiveSkill per l'answer*)
      Activeskill.Target := fChar; // sè stessa
    end;

  end
  else if Aura.auraName = 'blessing.of.the.humans' then begin

  (* il controllo dello stack avviene sul TEntity di questa AuraManager *)
  (* In questo caso Blessing of the Humans non si somma in alcun caso, ma si rinnova la durata *)
    aGenericAura := IsAuraLoaded  ( Aura.AuraName );
    if aGenericAura <> nil  then aGenericAura.RenewAuraDuration(0) else begin
      aBlessingoftheHumans:= TBlessingOfTheHumans.Create(effect, ActiveSkill );
      lstAura.Add(aBlessingofthehumans);
    end;

  end
  else if Aura.auraName = 'blessing.of.the.elves' then begin

  (* il controllo dello stack avviene sul TEntity di questa AuraManager *)
  (* In questo caso blessing.of.the.elves non si somma in alcun caso, ma si rinnova la durata *)
    aGenericAura := IsAuraLoaded  ( Aura.AuraName );
    if aGenericAura <> nil  then aGenericAura.RenewAuraDuration(0) else begin
      aBlessingoftheelves:= TBlessingOftheelves.Create(effect, ActiveSkill );
      lstAura.Add(aBlessingoftheelves);
    end;

  end
  else if Aura.auraName = 'blessing.of.the.kindred' then begin

  (* il controllo dello stack avviene sul TEntity di questa AuraManager *)
  (* In questo caso blessing.of.the.kindred non si somma in alcun caso, ma si rinnova la durata *)
    aGenericAura := IsAuraLoaded  ( Aura.AuraName );
    if aGenericAura <> nil  then aGenericAura.RenewAuraDuration(0) else begin
      aBlessingoftheKindred:= TBlessingOftheKindred.Create(effect, ActiveSkill );
      lstAura.Add(aBlessingoftheKindred);
    end;

  end
  else if Aura.auraName = 'blessing.of.fortune' then begin

  (* il controllo dello stack avviene sul TEntity di questa AuraManager *)
  (* In questo caso Blessing of fortune non si somma in alcun caso, ma si rinnova la durata *)
    aGenericAura := IsAuraLoaded  ( Aura.AuraName );
    if aGenericAura <> nil  then aGenericAura.RenewAuraDuration(0) else begin
      aBlessingoffortune:= TBlessingOfFortune.Create(effect, ActiveSkill );
      lstAura.Add(aBlessingoffortune);
      (* devo ciclare per tutti quelli nel aura.radious *)

      (* qui non sono stati fatti i check per i target che vengono fatti con cancel in create *)
      Neighbours:= TObjectList<TEntity>.Create(false); // molta attenzione, è false per evitare il delete
      //problema immunitàImmunity per sD o frezze sotto pray   per cui vanno fatte nel create
      fchar.Brain.getneighbours (fChar , aura.radious, friendly, false, Neighbours );
            //problema immunitàImmunity per sD o frezze sotto pray   per cui vanno fatte nel create

      for I := 0 to Neighbours.Count -1 do begin
        if Neighbours[i]= fChar then Continue; // se false sopra...

        aGenericAura := Neighbours[i].AuraManager.IsAuraLoaded  ( Aura.AuraName ); // molta attenzione...è la sua function
        if aGenericAura <> nil  then aGenericAura.RenewAuraDuration(0) else begin
          Activeskill.Target :=  Neighbours[i] ;       // proprio perchè è un puntatore il target rimane l'ultimo settato'
                                                      //  e nel load aCharT viene preso da fromtarget. Ora da Fchar                                                  '
          aBlessingofFortune:= TBlessingOfFortune.Create(effect, ActiveSkill );
          Neighbours[i].AuraManager.AddDirectAura (aBlessingofFortune);
        end;
      end;
      Neighbours.Free;
      (*Rimetto l'originale ActiveSkill per l'answer*)
      Activeskill.Target := fChar; // sè stessa
       { TODO : come viene notificato Abs client i multicambiamenti alla defense? }
    end;

  end
  else if Aura.auraName = 'blessing.of.tenacity' then begin

  (* il controllo dello stack avviene sul TEntity di questa AuraManager *)
  (* In questo caso Blessing of tenacity non si somma in alcun caso, ma si rinnova la durata *)
    aGenericAura := IsAuraLoaded  ( Aura.AuraName );
    if aGenericAura <> nil  then aGenericAura.RenewAuraDuration(0) else begin
      aBlessingofTenacity:= TBlessingOfTenacity.Create(effect, ActiveSkill );
      lstAura.Add(aBlessingofTenacity);
      (* devo ciclare per tutti quelli nel aura.radious *)

      (* qui non sono stati fatti i check per i target che vengono fatti con cancel in create *)
      Neighbours:= TObjectList<TEntity>.Create(false); // molta attenzione, è false per evitare il delete
      //problema immunitàImmunity per sD o frezze sotto pray   per cui vanno fatte nel create
      fchar.Brain.getneighbours (fChar , aura.radious, friendly, false, Neighbours );
            //problema immunitàImmunity per sD o frezze sotto pray   per cui vanno fatte nel create

      for I := 0 to Neighbours.Count -1 do begin
        if Neighbours[i]= fChar then Continue;

        aGenericAura := Neighbours[i].AuraManager.IsAuraLoaded  ( Aura.AuraName ); // molta attenzione...è la sua function
        if aGenericAura <> nil  then aGenericAura.RenewAuraDuration(0) else begin
          Activeskill.Target :=  Neighbours[i] ;       // proprio perchè è un puntatore il target rimane l'ultimo settato'
                                                      //  e nel load aCharT viene preso da fromtarget. Ora da Fchar                                                  '
          aBlessingofTenacity:= TBlessingOfTenacity.Create(effect, ActiveSkill );
          Neighbours[i].AuraManager.AddDirectAura (aBlessingofTenacity);
        end;
      end;
      Neighbours.Free;
      (*Rimetto l'originale ActiveSkill per l'answer*)
      Activeskill.Target := fChar; // sè stessa
       { TODO : come viene notificato Abs client i multicambiamenti alla defense? }
    end;

  end
  else if Aura.auraName = 'blessing.of.life' then begin

  (* il controllo dello stack avviene sul TEntity di questa AuraManager *)
  (* In questo caso Blessing of life non si somma in alcun caso, ma si rinnova la durata *)
    aGenericAura := IsAuraLoaded  ( Aura.AuraName );
    if aGenericAura <> nil  then aGenericAura.RenewAuraDuration(0) else begin
      aBlessingoflife:= TBlessingOflife.Create(effect, ActiveSkill );
      lstAura.Add(aBlessingoflife);
      (* devo ciclare per tutti quelli nel aura.radious *)

      (* qui non sono stati fatti i check per i target che vengono fatti con cancel in create *)
      Neighbours:= TObjectList<TEntity>.Create(false); // molta attenzione, è false per evitare il delete
      //problema immunitàImmunity per sD o frezze sotto pray   per cui vanno fatte nel create
      fchar.Brain.getneighbours (fChar , aura.radious, friendly, False, Neighbours );
            //problema immunitàImmunity per sD o frezze sotto pray   per cui vanno fatte nel create

      for I := 0 to Neighbours.Count -1 do begin
        if Neighbours[i]= fChar then Continue;

        aGenericAura := Neighbours[i].AuraManager.IsAuraLoaded  ( Aura.AuraName ); // molta attenzione...è la sua function
        if aGenericAura <> nil  then aGenericAura.RenewAuraDuration(0) else begin
          Activeskill.Target :=  Neighbours[i] ;       // proprio perchè è un puntatore il target rimane l'ultimo settato'
                                                      //  e nel load aCharT viene preso da fromtarget. Ora da Fchar                                                  '
          aBlessingoflife:= TBlessingOflife.Create(effect, ActiveSkill );
          Neighbours[i].AuraManager.AddDirectAura (aBlessingoflife);
        end;
      end;
      Neighbours.Free;
      (*Rimetto l'originale ActiveSkill per l'answer*)
      Activeskill.Target := fChar; // sè stessa
       { TODO : come viene notificato Abs client i multicambiamenti alla defense? }
    end;

  end
  else if Aura.auraName = 'natural.protection' then begin    (* proviene da Heal *)

  (* il controllo dello stack avviene sul TEntity di questa AuraManager *)
  (* In questo caso natural.protection si somma in caso di source diverse, creando *)
  (* una Natural.protection in più *)
//    aGenericAura := IsAuraFromChar  ( Aura.AuraName, TEntity(pActiveSkill.aChar )  ); // fromchar
    aGenericAura := IsAuraFromChar  ( Aura.AuraName, ActiveSkill.Source ) ; // fromchar
    if aGenericAura <> nil  then aGenericAura.RenewAuraDuration(0) else begin
      aNaturalProtection:= TNaturalProtection.Create(effect, ActiveSkill );
      lstAura.Add(aNaturalProtection);
    end;

  end


  else if Aura.auraName = 'gods^gift' then begin     (* proviene da light of sanctuary (heal)*)

  (* il controllo dello stack avviene sul TEntity di questa AuraManager *)
  (* In questo caso gods^gift si somma in caso di source diverse, creando *)
  (* una gods^gift in più *)
    aGenericAura :=  IsAuraFromChar  ( Aura.AuraName, ActiveSkill.Source )  ; // fromchar
    if aGenericAura <> nil  then aGenericAura.RenewAuraDuration(0) else begin
      aGodsGift:= TGodsGift.Create(effect, ActiveSkill );
      lstAura.Add(aGodsGift);
    end;

  end
  else if Aura.auraName = 'damnation' then begin

  (* il controllo dello stack avviene sul TEntity di questa AuraManager *)
  (* In questo caso damnation si somma in caso di source diverse, creando *)
  (* una damnation in più *)
    aGenericAura :=  IsAuraFromChar  ( Aura.AuraName, ActiveSkill.Source ); // fromchar
    if aGenericAura <> nil  then aGenericAura.RenewAuraDuration(0) else begin
      aDamnation:= TDamnation.Create(effect, ActiveSkill );
      lstAura.Add(aDamnation);
    end;

  end
  else if Aura.auraName = 'slowed' then begin

  (* il controllo dello stack avviene sul TEntity di questa AuraManager *)
  (* In questo caso slowed si somma in caso di source diverse , creando *)
  (* una slowed in più *)
    aGenericAura :=  IsAuraFromChar  ( Aura.AuraName, ActiveSkill.Source ); // fromchar
    if aGenericAura <> nil  then aGenericAura.RenewAuraDuration(0) else begin
      aSlowed:= TSlowed.Create(effect, ActiveSkill );
      lstAura.Add(aSlowed);
    end;

  end

  else if Aura.auraName = 'revive' then begin

  (* il controllo dello stack avviene sul TEntity di questa AuraManager *)
  (* In questo caso revive non si somma in alcun caso anche se non fa nulla *)

    aGenericAura :=  IsAuraLoaded  ( Aura.AuraName) ; // fromchar
    if aGenericAura = nil  then begin
      aRevive:= TRevive.Create(effect, ActiveSkill );
      lstAura.Add(aRevive);
    end;

  end
  else if Aura.auraName = 'immunity' then begin

  (* il controllo dello stack avviene sul TEntity di questa AuraManager *)
  (* In questo caso immunity viene sempre caricata gestendo internamente il *)
  (* valore di tutti flag *)
      aImmunity:= TImmunity.Create(effect, ActiveSkill );
      lstAura.Add(aImmunity);
  end
  else if Aura.auraName = 'free' then begin

  (* il controllo dello stack avviene sul TEntity di questa AuraManager *)
  (* In questo caso Free si applica sempre. Free rimuove altre auree settandole su aDead *)
      afree:= TFree.Create(effect, ActiveSkill );
      lstAura.Add(aFree);

  end
  else if Aura.auraName = 'pray' then begin

  (* il controllo dello stack avviene sul TEntity di questa AuraManager *)
  (* In questo caso pray Ricarica la CP e può stackare *)
      aPray:= TPray.Create(effect, ActiveSkill );
      lstAura.Add(aPray);

  end
  else if Aura.auraName = 'drainpower' then begin

  (* il controllo dello stack avviene sul TEntity di questa AuraManager *)
  (* In questo caso slowed si somma in caso di source diverse , creando *)
  (* una slowed in più *)
    aGenericAura :=  IsAuraFromChar  ( Aura.AuraName, ActiveSkill.Source ); // fromchar
    if aGenericAura <> nil  then aGenericAura.RenewAuraDuration(0) else begin
      aDrainPower:= TDrainPower.Create(effect, ActiveSkill );
      lstAura.Add(aDrainPower);
    end;

  end
  else if Aura.auraName = 'light.of.healing' then begin


  (* il controllo dello stack avviene sul TEntity di questa AuraManager *)
  (* In questo caso slowed si somma in caso di source diverse , creando *)
  (* una aLightOfhealing in più *)
    aGenericAura :=  IsAuraFromChar  ( Aura.AuraName, ActiveSkill.Source ); // fromchar
    if aGenericAura <> nil  then aGenericAura.RenewAuraDuration(0) else begin
      aLightOfhealing:= aLightOfhealing.Create(effect, ActiveSkill );
      lstAura.Add(aLightOfhealing);
    end;

  end
  else if Aura.auraName = 'divine.light' then begin

  (* il controllo dello stack avviene sul TEntity di questa AuraManager *)
  (* In questo caso Divine Light  si somma in caso di source diverse , creando *)
  (* una Divine Light in più. Nel caso della stessa Source rimuove la precedente
    e ne crea una nuova per attivare il load *)
    aGenericAura :=  IsAuraFromChar  ( Aura.AuraName, ActiveSkill.Source ); // fromchar
    if aGenericAura <> nil  then begin
      aGenericAura.State := aDead;
      aDivineLight:= TDivineLight.Create(effect, ActiveSkill );
      lstAura.Add(aDivineLight);
    end
    else begin
      aDivineLight:= TDivineLight.Create(effect, ActiveSkill );
      lstAura.Add(aDivineLight);
    end;


  end
  else if Aura.auraName = 'divine.punishment' then begin

  (* il controllo dello stack avviene sul TEntity di questa AuraManager *)
  (* In questo caso divine.punishment si somma in caso di source diverse, creando *)
  (* una divine.punishment in più e stack fino a 5.*)
    aGenericAura :=  IsAuraFromChar  ( Aura.AuraName, ActiveSkill.Source ); // fromchar
    if aGenericAura <> nil  then aGenericAura.RenewAuraDuration(1) else begin     // 1 !!!
      aDivinepunishment:= TDivinePunishment.Create(effect, ActiveSkill );
      lstAura.Add(aDivinepunishment);
    end;

  end;


  //    if Assigned( fChar.FOnAuraChanges ) then fChar.FOnAuraChanges( fChar , @Aura);

  {$ENDIF}

  Result:= True;


  {$ifdef rpg_client}
//   if Aura.HideBmp = 0 then begin
      //if Assigned( FBmpSprite ) then FBmpSprite.AddAura(Aura.Source,Aura.slabel , IntToStr(Aura.duration ));
//   end;
  {$ENDIF}



end;

function TAuraManager.IsAurafromChar ( const v: string; const Source: TEntity) :TrpgAura;
var
i:integer;
begin
  Result:= nil;
    for i := 0 to lstAura.Count -1 do begin
      if (v = lstAura.Items [i].auraname)
      and (lstAura.items[i].FromActiveSkill.source  = Source)
      and (lstAura.items[i].State <> aDead)  then begin
        result:= lstAura.Items [i];
        Exit;
      end;
    end;
end;


{$ENDREGION}


constructor TMechManager.Create (owner: TEntity);
begin
  fChar:= Owner;
  MechList:= TObjectList<TMechanic>.Create();

  { Set the OwnsObjects to true - the List will free them automatically }
  MechList.OwnsObjects := true;

end;
destructor TMechManager.Destroy ;
begin
  mechlist.Free;
end;

procedure TMechManager.Addmechanic (const v: string );
var
aMech: TMechanic;
i: integer;
begin
  (* Controllo che la Mechanic non sia già presente *)
  for I := 0 to MechList.Count -1 do begin
    aMech:= MechList.Items [i];
    if aMech.fName = v then exit;
  end;

    if v = 'soulbullet' then aMech:= TMechanic(TMechSoulBullet.create (self)  ) else
    if v = 'orbs' then aMech:= TMechanic(TMechOrbs.create(self) ) else
    if v = 'stances' then aMech:= TMechanic(TMechStance.create(self) ) else
    if v = 'cdrage' then aMech:= TMechanic(TMechCdrage.create(self) );

    MechList.Add (aMech);

end;

procedure TMechManager.Broadcast (const msg: TmsgManager; Skill: TRpgSkill; var Output: string );  // da skill
var
i:integer;
MechanicOutput: string;
begin
      (* qui la skill non ancora Completed *)

  if Msg =  msg_cast then  begin   (* Qui le Mechanic vengono informate che la skill vuole essere castata ma non è ancora in casting*)

      (* qui la skill è quasi eseguita. i controlli della skillmanager sono precedenti. Ora controllo le mechanic. *)
      (* un characther può avere più mechanic attive. Ognuna risponde accodando il risultato in una stringa *)
      (* Per esempio orbs può restituire un danno maggiore alla skill, quindi la pActiveSkill l'aftercast modificato nel danno *)
      (* Per esempio soulbullers modifica l'accuracy della ActiveSkill e anche il suo damage *)

    MechanicOutput:='';
    for i := 0 to MechList.Count -1 do begin

      MechList.items[i].Input ( msg, Skill, Output ) ; { TODO : forall }
      MechanicOutput := MechanicOutput + OUTPUT;
    end;

    Output:= 'OK';

  end
  else if Msg =  msg_execute then   begin     (* Qui le Mechanic vengono informate che la skill è eseguita*)

  end
  else if Msg =  msg_hit then   begin          (* Qui le Mechanic vengono informate che la skill ha hittato qualcuno*)
    (* per esempio ora che ha hittato una mechanic CdRage può decrementare i cooldown di tutte le skill *)
    for i := 0 to MechList.Count -1 do begin

      MechList.items[i].Input ( msg, Skill, Output ) ;
      MechanicOutput := MechanicOutput + OUTPUT;
    end;
  end
  else if Msg =  msg_execute then   begin      (* Qui le Mechanic vengono informate che la skill è eseguita*)

  end
  else if Msg =  msg_hitted then   begin      (* Qui le Mechanic vengono informate che il character è stato hittato*)
    (* per esempio ora che ha hittato una mechanic CdRage può decrementare i cooldown di tutte le skill *)
    for i := 0 to MechList.Count -1 do begin

      MechList.items[i].Input ( msg, Skill, Output ) ;
      MechanicOutput := MechanicOutput + OUTPUT;
    end;

  end
  else if Msg =  msg_damaged then   begin      (* Qui le Mechanic vengono informate che il character è stato danneggiato*)

  end
  else if Msg =  msg_healed then   begin      (* Qui le Mechanic vengono informate che il character è stato healeto*)

  end
  else if msg = msg_death then begin


  end;

end;
procedure TMechManager.Broadcast (const msg: TmsgManager; Aura: TRpgAura; var Output: string ); // da pAura  OVERLOAD
begin
  (* Qui l'aura informa le Mechanic*)
end;



constructor TMechanic.Create ( aMechManager: TMechManager);
begin

  inherited create;
  fMechManager:= aMechManager;
end;
destructor TMechanic.Destroy ;
begin
  inherited Destroy;
end;

function TMechanic.BaseGetValue: double;
begin
  Result:= fvalue;
end;
procedure TMechanic.BaseSetValue(v: double);
begin
  fvalue:= v;
end;
function TMechanic.BaseGetValueMax: double;
begin
  Result:= fvalueMax;
end;
procedure TMechanic.BaseSetValueMax(v: double);
begin
  fvalueMax:= v;
end;
{
  procedure TMechanic.Input  (const msg: TmsgManager; pRpgSkill: pRpgSkill; var Output: string );
  begin
  //
  end;
  procedure TMechanic.Input  (const msg: TmsgManager; pAura: pRpgSkill; var Output: string );
  begin
  //
  end;

}




constructor TMechCdRage.Create ( aMech: TMechManager) ;
begin
  inherited create (aMech);
  fName:= 'cdrage';
  fvalue:= 0;
end;

constructor TMechOrbs.Create ( aMech: TMechManager) ;
begin
  inherited create (aMech);
  fName:= 'orbs';
  fvalue:= 100;
end;

constructor TMechSoulBullet.Create( aMech: TMechManager) ;
begin
  inherited create (aMech);
  fName:= 'soulbullet';
  fvalue:= 20;
  fvalueMax:= 20;
end;
constructor TMechStance.Create( aMech: TMechManager) ;
begin
  inherited create (aMech);
  fName:= 'stances';
  fvalue:= 1;
end;
destructor TMechcdRage.Destroy ;
begin
  inherited destroy;
end;
destructor TMechOrbs.Destroy ;
begin
  inherited destroy;
end;

destructor TMechSoulBullet.Destroy ;
begin
  inherited destroy;
end;
destructor TMechStance.Destroy ;
begin
  inherited destroy;
end;

function TMechCdRage.GetValue: double;
begin
  Result:= BaseGetValue;
end;
procedure TMechCdRage.SetValue(v: double);
begin
  BaseSetValue (v);
end;
function TMechCdRage.GetValueMax: double;
begin
  Result:= BaseGetValueMax;
end;
procedure TMechCdRage.SetValueMax(v: double);
begin
  BaseSetValueMax (v);
end;

function TMechOrbs.GetValue: double;
begin
  Result:= BaseGetValue;
end;
procedure TMechOrbs.SetValue(v: double);
begin
  BaseSetValue (v);
  Agony:= loWord (Round(v)) ;
  Blast:= HiWord (Round(v)) ;
end;
function TMechOrbs.GetValueMax: double;
begin
  Result:= BaseGetValueMax;
end;
procedure TMechOrbs.SetValueMax(v: double);
begin
  BaseSetValueMax (v);
end;

function TMechSoulBullet.GetValue: double;
begin
  Result:= BaseGetValue;
end;
procedure TMechSoulBullet.SetValue(v: double);
begin
  BaseSetValue (v);
end;
function TMechSoulBullet.GetValueMax: double;
begin
  Result:= BaseGetValueMax;
end;
procedure TMechSoulBullet.SetValueMax(v: double);
begin
  BaseSetValueMax (v);
end;

function TMechStance.GetValue: double;
begin
  Result:= BaseGetValue;
end;
procedure TMechStance.SetValue(v: double);
begin
  BaseSetValue (v);
end;
function TMechStance.GetValueMax: double;
begin
  Result:= BaseGetValueMax;
end;
procedure TMechStance.SetValueMax(v: double);
begin
  BaseSetValueMax (v);
end;

procedure TMechCdRage.Input (const msg: TmsgManager; Skill: TRpgSkill; var Output: string );
var
ts,ts2: TStringList;
m, linput: string;
begin

(* Verifico che la Mechanic sia CDRAGE *)
    ts:= tstringlist.Create ;
    ts.delimiter:='|'; ts.strictDelimiter:= true;
  	ts.DelimitedText := Skill.Mechanic ; // prendo la mechanic dalla skill del char
    if ts.Values ['m'] <> 'cdrage' then begin
      Output:= 'OK';
      ts.Free;
      Exit;
    end;


    linput   := ts.Values ['i'];
    ts.Free;
  if Msg =  msg_cast then  begin   (* Qui CdRage vengono informate che la skill vuole essere castata ma non è ancora in casting*)


  end
  else if Msg =  msg_execute then   begin     (* Qui CdRage vengono informate che la skill è eseguita*)

  end
  else if Msg =  msg_hit then   begin          (* Qui CdRage vengono informate che la skill ha hittato qualcuno*)
  end
  else if Msg =  msg_execute then   begin      (* Qui CdRage vengono informate che la skill è eseguita*)

  end
  else if Msg =  msg_hitted then   begin      (* Qui CdRage vengono informate che il character è stato hittato*)
    (* per esempio ora che ha hittato CdRage incrementa il suo fvalue e decrementa i cooldow di tute le skill*)
    fValue := fValue + HitTedValue;

  end
  else if Msg =  msg_damaged then   begin      (* Qui CdRage vengono informate che il character è stato danneggiato*)

  end
  else if Msg =  msg_healed then   begin      (* Qui CdRage vengono informate che il character è stato healeto*)

  end
  else if msg = msg_death then begin


  end;
end;
procedure TMechCdRage.Input  (const msg: TmsgManager; Aura: TRpgAura; var Output: string );
begin


  if Msg =  msg_cast then  begin   (* Qui CdRage vengono informate che la skill vuole essere castata ma non è ancora in casting*)


  end
  else if Msg =  msg_execute then   begin     (* Qui CdRage vengono informate che la skill è eseguita*)

  end
  else if Msg =  msg_hit then   begin          (* Qui CdRage vengono informate che la skill ha hittato qualcuno*)
    (* per esempio ora che ha hittato CdRage incrementa il suo fvalue e decrementa i cooldow di tute le skill*)
    fValue := fValue + HitValue;
    Fmechmanager.fchar.SkillManager.ModifyAllCooldowns (-HitValue);
  end
  else if Msg =  msg_execute then   begin      (* Qui CdRage vengono informate che la skill è eseguita*)

  end
  else if Msg =  msg_hitted then   begin      (* Qui CdRage vengono informate che il character è stato hittato*)
    (* per esempio ora che ha hittato CdRage incrementa il suo fvalue e decrementa i cooldow di tute le skill*)
    fValue := fValue + HitTedValue;
    (* per esempio ora che ha hittato CdRage incrementa il suo fvalue e decrementa i cooldow di tute le skill*)
    fValue := fValue + HittedValue;
    Fmechmanager.fchar.SkillManager.ModifyAllCooldowns (-HittedValue);

  end
  else if Msg =  msg_damaged then   begin      (* Qui CdRage vengono informate che il character è stato danneggiato*)

  end
  else if Msg =  msg_healed then   begin      (* Qui CdRage vengono informate che il character è stato healeto*)

  end
  else if msg = msg_death then begin


  end;
end;





procedure TMechOrbs.Input  (const msg: TmsgManager; Skill: TRpgSkill; var Output: string );
var
ts,ts2: TStringList;
m, linput: string;
begin
(* Verifico che la Mechanic sia ORBS *)
    ts:= tstringlist.Create ;
    ts.delimiter:='|'; ts.strictDelimiter:= true;
  	ts.DelimitedText := Skill.Mechanic ; // prendo la mechanic dalla skill del char
    if ts.Values ['m'] <> 'orbs' then begin
      Output:= 'OK';
      ts.Free;
      Exit;
    end;


    linput   := ts.Values ['i'];     { TODO : fare più di una azione per Mechanic, per il moemnto solo una }
    ts.Free;

(*  cerco nella skill locale del player la skill, di solito punto una skill e gli cambio svalue aumentando il danno *)
(*  Non ho bisogno di conoscere X Y del target, quindi non mi serve la ActiveSkill *)

    // possibili mechanic
    // m=orbs|input=ac=replaceorbs               non consuma orbs, replace in tutti gli after di blast e agony
    // m=orbs|input=ac=addagony,v=1,d=20000,o=s
    // m=orbs|input=ac=addblast,v=1,d=20000,o=s
    // m=orbs|input=ac=setagony,v=0
    // m=orbs|input=ac=setblast,v=0
    // Output:= 'OK';

    ts2:= TStringList.Create ;
    ts2.CommaText := linput;    // ac=addblast,v=1,d=20000,o=s
    ts2.Free;

  if Msg =  msg_cast then  begin   (* Qui le Orbs vengono informate che la skill vuole essere castata ma non è ancora in casting*)


    (* Se questa skill richiede orbs non viene castata *)
    // es. aftercast a=SD,v= ma + (ma * (agony*15) / 100) + (ma*(blast*20)/100),d=0, st=nightmare.termination2|

    if ts2.Values ['ac'] = 'replaceorbs'  then begin

      ReplaceStr (Skill.afterCast , 'agony', IntToStr(agony));
      ReplaceStr (Skill.afterCast , 'blast', IntToStr(blast));

    end
    else if ts2.Values ['ac'] = 'addagony'  then begin
      Agony := Agony + StrToInt(ts2.Values ['v']);
      fValue := makeword ( Agony , Blast ) ;
      AgonyDuration:= StrToInt(ts2.Values ['d']);
    end
    else if ts2.Values ['ac']  = 'addblast'  then begin
      Blast := Blast + StrToInt(ts2.Values ['v']);
      fValue := makeword ( Agony , Blast ) ;
      BlastDuration:= StrToInt(ts2.Values ['d']);
    end
    else if ts2.Values ['ac']  = 'setagony'  then begin
      Agony := StrToInt(ts2.Values ['v']);
      fValue := makeword ( Agony , Blast ) ;
    end
    else if ts2.Values ['ac']  = 'setblast'  then begin
      Blast := StrToInt(ts2.Values ['v']);
      fValue := makeword ( Agony , Blast ) ;
    end ;

  end
  else if Msg =  msg_execute then   begin     (* Qui le orbs vengono informate che la skill è eseguita*)

  end
  else if Msg =  msg_hit then   begin          (* Qui le orbs vengono informate che la skill ha hittato qualcuno*)
    (* per esempio ora che ha hittato una mechanic può modificare stats per dire *)
  end
  else if Msg =  msg_execute then   begin      (* Qui le orbs vengono informate che la skill è eseguita*)

  end
  else if Msg =  msg_hitted then   begin      (* Qui le orbs vengono informate che il character è stato hittato*)

  end
  else if Msg =  msg_damaged then   begin      (* Qui le orbs vengono informate che il character è stato danneggiato*)

  end
  else if Msg =  msg_healed then   begin      (* Qui le orbs vengono informate che il character è stato healeto*)

  end
  else if msg = msg_death then begin


  end;

end;
procedure TMechOrbs.Input  (const msg: TmsgManager; Aura: TRpgAura; var Output: string );
begin
(*  cerco nella skill locale del player la skill, di solito punto una skill e gli cambio svalue aumentando il danno *)
(*  Non ho bisogno di conoscere X Y del target, quindi non mi serve la ActiveSkill *)
  if Msg =  msg_cast then  begin   (* Qui le Orbs vengono informate che la skill vuole essere castata ma non è ancora in casting*)

    (* Se questa skill richiede orbs non viene castata*)
    Output:= 'OK';

  end
  else if Msg =  msg_execute then   begin     (* Qui le orbs vengono informate che la skill è eseguita*)

  end
  else if Msg =  msg_hit then   begin          (* Qui le orbs vengono informate che la skill ha hittato qualcuno*)
    (* per esempio se fosse FANATICISM l'aura deve informare perchè fanaticsim lavora con tutte le auree *)
  end
  else if Msg =  msg_execute then   begin      (* Qui le orbs vengono informate che la skill è eseguita*)

  end
  else if Msg =  msg_hitted then   begin      (* Qui le orbs vengono informate che il character è stato hittato*)

  end
  else if Msg =  msg_damaged then   begin      (* Qui le orbs vengono informate che il character è stato danneggiato*)

  end
  else if Msg =  msg_healed then   begin      (* Qui le orbs vengono informate che il character è stato healeto*)

  end
  else if msg = msg_death then begin


  end;
end;
procedure TMechSoulBullet.Input  (const msg: TmsgManager; Skill: TRpgSkill; var Output: string );
begin
//  cerco nella skill locale del player la skill, leggo cosa fare
//  poi punto una skill e gli cambio svalue
end;
procedure TMechSoulBullet.Input  (const msg: TmsgManager; Aura: TRpgAura; var Output: string );
begin
//  cerco nella skill locale del player la skill, leggo cosa fare
//  poi punto una skill e gli cambio svalue
end;
procedure TMechStance.Input  (const msg: TmsgManager; Skill: TRpgSkill; var Output: string );
begin
//  cerco nella skill locale del player la skill, leggo cosa fare
//  poi punto una skill e gli cambio svalue
end;
procedure TMechStance.Input  (const msg: TmsgManager; Aura: TRpgAura; var Output: string );
begin
//  cerco nella skill locale del player la skill, leggo cosa fare
//  poi punto una skill e gli cambio svalue
end;

procedure TMechCdRage.Timer ( const interval: integer );
begin
//
end;

procedure TMechOrbs.Timer ( const interval: integer );
begin
  AgonyDuration := AgonyDuration - interval;
  if AgonyDuration <= 0 then begin
    AgonyDuration:=0;
    Agony:=0;
  end;

  BlastDuration := BlastDuration - interval;
  if BlastDuration <= 0 then begin
    BlastDuration:=0;
    Blast:=0;
  end;

end;
procedure TMechSoulBullet.Timer ( const interval: integer );
begin
//
end;
procedure TMechStance.Timer ( const interval: integer );
begin
//
end;
function TEntity.LoadRankDescr (  pTalentDB: PRpgTalentDB; rank:integer ): string;
var
ts: Tstringlist;
begin
  ts:= tstringlist.Create;
  ts.commatext := pTalentDB.descrr1;
  if ts.Count > 0 then begin
      Result :=  replacestr (pTalentDB.descr,'r1',ts[rank-1] ) ; //pTalentDB.effects ;

  end
  else
     Result := pTalentDB.descr ;

  ts.commatext := pTalentDB.descrr2;
  if ts.Count > 0 then result:= replacestr (Result,'r2',ts[rank-1] ) ; //pTalentDB.effects ;


  ts.Free;

end;
procedure TEntity.LoadRank (  pTalentDB: PRpgTalentDB; rank:integer; out r1: Double; out r2:double );
var
TsTmp2: TStringList;
begin

  tsTmp2:= tstringlist.Create; tsTmp2.StrictDelimiter := true;
  if pTalentDB.rankinfo1 <> '' then begin
  tsTmp2.commatext := pTalentDB.rankinfo1;
  r1 := StrToFloat ( tsTmp2[rank-1]); // RANK del TALENTO
  FExprParser1.DefineVariable('r1', @r1);
  end;
  if pTalentDB.rankinfo2 <> '' then begin
    tsTmp2.commatext := pTalentDB.rankinfo2;
    r2 := StrToFloat ( tsTmp2[rank-1]);
    FExprParser1.DefineVariable('r2', @r2);
  end;
  TsTmp2.Free;

end;
procedure TEntity.LoadRank (  pTalentDB: PRpgTalentDB; rank:integer; out r1: string; out r2:string );
var
TsTmp2: TStringList;
begin

  tsTmp2:= tstringlist.Create; tsTmp2.StrictDelimiter := true;
  if pTalentDB.rankinfo1 <> '' then begin
  tsTmp2.commatext := pTalentDB.rankinfo1;
  r1 :=  tsTmp2[rank-1]; // RANK del TALENTO
  end;
  if pTalentDB.rankinfo2 <> '' then begin
    tsTmp2.commatext := pTalentDB.rankinfo2;
    r2 :=  tsTmp2[rank-1];
  end;
  TsTmp2.Free;

end;

procedure TEntity.LoadTalents ;
var
t,e,i: integer;
Effects,tsTmp,tsTmp2,ts: tstringList;
pTalentDB: PRpgTalentDB;
Aura:TAura;
PO: double;
r1,r2,localpower:double;
pskill2: pRpgSkill;
askill2: TRpgSkill;
Skill: TRpgSkill;
addvalue,astring:string;
ptr: PDouble;
tsMod: TStringList;
iModValue: integer;
sModValue: string;
fModValue: double;
r: integer;
rstring1,rstring2: string;
aTriggerAttackSpeed: TTriggerAttackSpeed;
aTriggerDivinePunishment: TTriggerDivinePunishment;
begin
(* quindi abbiamo 4 tipi: addskill, modifica stat, modifica skill, e aura trigger dormienti che diventano canbedispelled= false e/o persistent=true *)
(* ordine: modstat,addskill,trigger,modskill *)
          if (Faction ='1') and (Number = 4) then begin

            asm
            //  int 3;
            end;
          end;
  SkillManager.lstSkills.Clear ;
  AuraManager.lstAura.Clear;
  MechManager.MechList.Clear;
(* Prima carico tutti i talenti modstat *)
      // es. maxpower = (maxpower * r1 / 100) + r2
  Effects:= TStringList.create; Effects.Delimiter :='|'; effects.StrictDelimiter := true;

  tsTmp:= tstringlist.Create; tsTmp.StrictDelimiter := true;
  tsTmp2:= tstringlist.Create; tsTmp2.StrictDelimiter := true;

  (************************************************************************)
  (*               Talenti Modstat                                        *)
  (************************************************************************)

  for t := 0 to Talents.Count -1 do begin
      pTalentDB:= brain.GetDefTalent (  StrToInt( Talents.Names  [t]) );                     //Talents.KeyNames [t] ));      if pTalentDB.talentName  = '' then continue;
      r:= StrToInt(Talents.ValueFromIndex [t]) ; // RANK

      Effects.DelimitedText := pTalentDB.effects;
        for e := 0 to Effects.Count -1 do begin
          tstmp.CommaText := Effects[e];  // es. modstat,maxpower,maxpower + ( maxpower * ( r1 / 100)) +r2
          if tsTmp[0] = 'modstat' then begin
                                            //       0         1          2
            if tsTmp[1] = 'maxpower' then begin

              FExprParser1.DefineVariable('maxpower', @fPower);

              LoadRank(  pTalentDB, r , r1 , r2);

              FExprParser1.ClearExpressions;
              FExprParser1.AddExpression ( tsTmp[2] );
              fPower:= RoundTo (FExprParser1.EvaluateCurrent,-2);
              fCP:=fPower;     // non chiamo la SETCP perchè sono in loadtalents
            end
            else if tsTmp[1]  = 'maxhealth' then begin

              FExprParser1.DefineVariable('maxhealth', @fhealth);

              LoadRank(  pTalentDB, r , r1 , r2);

              FExprParser1.ClearExpressions;
              FExprParser1.AddExpression ( tsTmp[2] );
              fhealth:= RoundTo (FExprParser1.EvaluateCurrent,-2);
              fCH:=fhealth;     // non chiamo la SETCP perchè sono in loadtalents
            end

            else if tsTmp[1]  = 'outhealing' then begin

              FExprParser1.DefineVariable('outhealing', @AuraManager.Outhealing );

              LoadRank(  pTalentDB, r , r1 , r2);

              FExprParser1.ClearExpressions;
              FExprParser1.AddExpression ( tsTmp[2]  );
              AuraManager.Outhealing := AuraManager.Outhealing +   RoundTo (FExprParser1.EvaluateCurrent,-2);
            end
            else if tsTmp[1]  = 'inchealing' then begin

              FExprParser1.DefineVariable('inchealing', @AuraManager.Inchealing );

              LoadRank(  pTalentDB, r , r1 , r2);

              FExprParser1.ClearExpressions;
              FExprParser1.AddExpression (tsTmp[2] );
              AuraManager.inchealing := AuraManager.inchealing +   RoundTo (FExprParser1.EvaluateCurrent,-2);
            end
            else if tsTmp[1]  = 'maslight' then begin

              FExprParser1.DefineVariable('maslight', @AuraManager.fChar.mlight  );

              LoadRank(  pTalentDB, r , r1 , r2);

              FExprParser1.ClearExpressions;
              FExprParser1.AddExpression ( tsTmp[2]  );
              AuraManager.fChar.mlight := AuraManager.fChar.mlight +   RoundTo (FExprParser1.EvaluateCurrent,-2);
            end;

          end;
      end;

  end;
(* Qui si comincia con le skill e posso caricare arbitrariamente tutte le skill della classe come fossero talenti tramite base.priest*)


  (************************************************************************)
  (*               Talenti AddSkill                                       *)
  (************************************************************************)
// es. AddSkill=divine.strike
  for t := 0 to Talents.Count -1 do begin
      pTalentDB:= brain.GetDefTalent (  StrToInt( Talents.Names  [t]) ) ;                  //Talents.KeyNames [t] ));
      if pTalentDB.talentName  = '' then continue;
      Effects.DelimitedText := pTalentDB.effects;
        for e := 0 to Effects.Count -1 do begin
          if Effects.IndexOfName ('addskill') > -1 then begin
         // if Effects.KeyNames [e] = 'addskill' then begin
            //aString:=Effects.ValueFromIndex [e];
            SkillManager.addSkill (effects.ValueFromIndex [e]);
          end
          else if Effects.IndexOfName ( 'addskilllist') > -1 then begin
            SkillManager.addSkilllist (effects.ValueFromIndex [e]); //passa gli id numerici
          end;

        end;
  end;

//QUI SETTARE LE ACCURACY e i CRIT DI TUTTE LE SINGOLE SKILL uguali alle stats del char
  for i := 0 to SkillManager.lstSkills.Count -1 do begin
    SkillManager.lstSkills.Items [i].accuracy := faccuracy;
    SkillManager.lstSkills.Items [i].crit := fcrit;

  end;


  (************************************************************************)
  (*               Talenti AddValue, AddString, modcd, modschoolacc       *)
  (*               ModDuration                                            *)
  (************************************************************************)
//qui i talenti di un certo tipo che modificano le skill,  MODSKILL SEMPRE IN MODALITA' ADD
// es. aftercast,a=light.of.sanctuary,v= (maxhealth * r1)  / 100|cd=-r2
  for t := 0 to Talents.Count -1 do begin
      pTalentDB:= brain.GetDefTalent (  StrToInt( Talents.Names  [t]) ) ;
      if pTalentDB.talentName  = '' then continue;
      r:= StrToInt(Talents.ValueFromIndex [t]) ; // RANK

      Effects.DelimitedText := pTalentDB.effects;       // qui delimitedtext è addvalue,light.of.sanctuary, (maxhealth * r1)  / 100|cd=-r2
        for e := 0 to Effects.Count -1 do begin         //      0           1                    2                     3
          tstmp.CommaText := Effects[e];                // addvalue,    light.of.sanctuary, (maxhealth * r1)  / 100
                                                        // addvalue,    blessing.of.life,          r1
          if tstmp[0]  = 'replacevalue' then begin
           (* replacevalue è la sostituzione totale del value v= *)
           (* r1 e r2 vanno calcolati *)

              Skill:= SkillManager.GetCharSkill (tstmp [1]); // ha ragione il char se non ha tra le skill  blessing.of.light
              if Skill = nil then continue;

              LoadRank(  pTalentDB, r , rstring1 , rstring2);  // r1 diventa ma*0.8

              tsMod:= tstringlist.Create ;
              tsMod.CommaText := Skill.afterCast;
              tsMod.Values ['v'] :=  rstring1;
              Skill.afterCast  := tsMod.CommaText;
              TSMod.free;

              Skill.descr := Skill.descr + #13#10 + LoadRankDescr (pTalentDB, r ) ;




          end
          else if tstmp[0]  = 'replaceduration' then begin
           (* replacevalue* è la sostituzione totale del value v= *)
           (* r1 e r2 vanno calcolati *)

              Skill:= SkillManager.GetCharSkill (tstmp [1]); // ha ragione il char se non ha tra le skill  blessing.of.light
              if Skill = nil then continue;

              LoadRank(  pTalentDB, r , r1 , r2);
              Tstmp[2] := replacestr ( Tstmp[2], 'r1', FloatTostr(r1) );
              Tstmp[2] := replacestr ( Tstmp[2], 'r2', FloatTostr(r2) );

              tsMod:= tstringlist.Create ;
              tsMod.CommaText := Skill.afterCast;
              tsMod.Values ['d'] :=  tstmp[2];
              Skill.afterCast  := tsMod.CommaText;
              TSMod.free;
              Skill.descr := Skill.descr + #13#10 + LoadRankDescr (pTalentDB, r ) ;


          end
          else if tstmp[0]  = 'addaura' then begin
           (* addaura aggiunge una aura trigger, persistent con opzionale cooldown *)
           (* r1 e r2 vanno calcolati *)
            //  tstmp[1] = auraname
           //   tstmp[2] = v
              tsTmp.Delete(0); // rimane a=trigger.attack.speed,v=r1@r2,radious=10
              aura:= AuraManager.String2Aura (tsTmp.CommaText );


              LoadRank(  pTalentDB, r , r1 , r2);
              tsTmp.commatext := replacestr ( tsTmp.commatext, 'r1', FloatTostr(r1) );  // sostituzione totale r1 e r2
              tsTmp.commatext := replacestr ( tsTmp.commatext, 'r2', FloatTostr(r2) );  // cosi' d=r2 radious=r1 ecc... non solo v

              if aura.AuraName  = 'trigger.attack.speed' then begin
                aTriggerAttackSpeed:= TTriggerAttackSpeed.Create(Tstmp.CommaText , pTalentDB, AuraManager );
                auraManager.lstAura.Add(aTriggerAttackSpeed);
              end
              else if aura.AuraName  = 'trigger.divine.punishment' then begin
                aTriggerDivinePunishment:= TTriggerDivinePunishment.Create(Tstmp.CommaText , pTalentDB, AuraManager );
                auraManager.lstAura.Add(aTriggerDivinePunishment);
              end;




          end
          else if tstmp[0]  = 'modvalue+' then begin
           (* modvalue+ è sempre in add e modifica ad esempio modvalue+,aftercast,heal,r1 + (maxpower * r2 ) / 100 *)
           (* r1 e r2 vanno calcolati *)
              Skill:= SkillManager.GetCharSkill (tstmp [1]); // ha ragione il char se non ha tra le skill  blessing.of.light
              if Skill = nil then continue;



              FExprParser1.DefineVariable('maxhealth', @fhealth);
              FExprParser1.DefineVariable('maxpower', @fpower);
              FExprParser1.DefineVariable('outhealing', @AuraManager.Outhealing);
              FExprParser1.DefineVariable('inchealing', @AuraManager.inchealing);

              LoadRank(  pTalentDB, r , r1 , r2);

              FExprParser1.ClearExpressions;
              FExprParser1.AddExpression ( tstmp[2] );               // (maxhealth * r1)  / 100
              fModValue:= RoundTo ( FExprParser1.EvaluateCurrent,-2);

              tsMod:= tstringlist.Create ;
              tsMod.CommaText := Skill.afterCast;
              tsMod.Values ['v'] :=  '(' + tsMod.Values ['v']  +  ')+' + FloatToStr(fModvalue );
              Skill.afterCast  := tsMod.CommaText;
              TSMod.free;


          end
          else if tstmp[0]  = 'modvalue*' then begin
           (* modvalue* è sempre la moltiplicazione del valore attuale es. modvalue*,aftercast,divine.strike,r1 *)
           (* r1 e r2 vanno calcolati *)

              Skill:= SkillManager.GetCharSkill (tstmp [1]); // ha ragione il char se non ha tra le skill  blessing.of.light
              if Skill = nil then continue;

              FExprParser1.DefineVariable('maxhealth', @fhealth);
              FExprParser1.DefineVariable('maxpower', @fpower);
              FExprParser1.DefineVariable('outhealing', @AuraManager.Outhealing);
              FExprParser1.DefineVariable('inchealing', @AuraManager.inchealing);

              LoadRank(  pTalentDB, r , r1 , r2);

              FExprParser1.ClearExpressions;
              FExprParser1.AddExpression ( tstmp[2] );               // (maxhealth * r1)  / 100
              fModValue:= RoundTo ( FExprParser1.EvaluateCurrent,-2);

              tsMod:= tstringlist.Create ;
              tsMod.CommaText := Skill.afterCast;
              tsMod.Values ['v'] :=  '(' + tsMod.Values ['v']  +  ')*' + FloatToStr(fModvalue );
              Skill.afterCast  := tsMod.CommaText;
              TSMod.free;


          end
          else if tstmp[0] = 'modcd' then begin
              // qui basterebbe un replacestr e usare direttamente r1
              // es. modcd,light.of.sanctuary,-r2
              Skill:= SkillManager.GetCharSkill (tstmp [1]); // ha ragione il char se non ha tra le skill  blessing.of.light
              if Skill = nil then continue;

              LoadRank(  pTalentDB, r , r1 , r2);

              FExprParser1.ClearExpressions;
              FExprParser1.AddExpression ( tstmp[2] );
              Skill.maxcooldown := Skill.maxcooldown + Trunc( RoundTo ( FExprParser1.EvaluateCurrent,-2));
              Skill.cooldown := Skill.maxcooldown;

          end
          else if tstmp[0] = 'modduration+' then begin
              // es. modduration,aftercast,blessing.of.fortune,r1
              Skill:= SkillManager.GetCharSkill (tstmp [1]); // ha ragione il char se non ha tra le skill  blessing.of.light
              if Skill = nil then continue;

              LoadRank(  pTalentDB, r , r1 , r2);

              FExprParser1.ClearExpressions;
              FExprParser1.AddExpression ( tstmp[2] );
              iModValue:= Trunc( RoundTo ( FExprParser1.EvaluateCurrent,-2));

              tsMod:= tstringlist.Create ;
              tsMod.CommaText := Skill.afterCast;
              tsMod.Values ['d'] :=  IntToStr( StrToInt( tsMod.Values ['d'] )  +  iModvalue );
              Skill.afterCast  := tsMod.CommaText;
              TSMod.free;

          end
          else if tstmp[0] = 'modschoolacc+' then begin
              // |es. modschoolacc+,light,r2
              // qui delimitedtext è modschoolacc+,light,r2
                                  //    0            1   2

              LoadRank(  pTalentDB, r , r1 , r2);

              FExprParser1.ClearExpressions;
              FExprParser1.AddExpression ( tstmp[2] );

              SkillManager.SetAccuracyBySchool (tsTmp[1], RoundTo ( FExprParser1.EvaluateCurrent,-2)) ; // light,20

          end
          else if tstmp[0] = 'modpower-*' then begin
              // |es. modpower-*,aftercast,blessing.of.fortune,r2
              //        0            1        2                3

              Skill:= SkillManager.GetCharSkill (tstmp [1]);
              if Skill = nil then continue;
              LoadRank(  pTalentDB, r , r1 , r2);

              FExprParser1.ClearExpressions;
              FExprParser1.AddExpression ( tstmp[2] );


              Skill.power := Skill.power - (Skill.power * r2);

          end

          else if  tstmp[0]  = 'addstring' then begin
          // es. tstmp è addstring,afterheal,heal,a=natural.protection.state,v=r1,d=10000
          // in addstring non devo calcolare r1 e r2 ma sostituire r1 e r2 con rankinfo1 e rankinfo2 che son per forza dei numeri
              Skill:= SkillManager.GetCharSkill (tstmp [1]); // ha ragione il char se non ha tra le skill  blessing.of.light
              if Skill = nil then continue;

              // tutto quello che viene dopo la terza virgola
              if pTalentDB.rankinfo1 <> '' then begin
              aString:='';
              for I := 3 to tsTmp.Count-1 do begin
                aString:=aString +  tsTmp[i]+',' ;       // astring:= a=natural.protection.state,v=r1,d=10000
              end;
              astring:= LeftStr(astring,length(aString)-1 ) ;
              tsTmp2.commatext := pTalentDB.rankinfo1;
              AddValue := replacestr ( aString , 'r1', tsTmp2[r-1] );
              end;

              if pTalentDB.rankinfo2 <> '' then begin
                tsTmp2.commatext := pTalentDB.rankinfo2;
                AddValue := replacestr ( addValue , 'r2', tsTmp2[r-1] );
                FExprParser1.DefineVariable('r2', @r2);
              end;

                if Skill.afterCast= '' then  Skill.afterCast  := Skill.afterCast  + AddValue
                else  Skill.afterCast  := Skill.afterCast  + '|' + AddValue;

          end
          else if tstmp[0] = 'modvalue@' then begin
           (* modvalue@ è sempre in add e modifica ad esempio |modvalue@,aftercast,blessing.of.fortune,5,r2 *)
           (* modifica a=blessing.of.fortune,v=5@7@7@9@0#0,d=300000 in a=blessing.of.fortune,v=5@7@7@9@r2@0,d=300000 *)
           (* o modifica a=blessing.of.fortune,v=5@7@7@9@0@0,d=300000 in a=blessing.of.fortune,v=5@7@7@9@0@r2,d=300000 *)
           (* r2 va calcolato *)
              Skill:= SkillManager.GetCharSkill (tstmp [1]); // la skill deve esistere
              if Skill = nil then continue;

              // r1 e r2 vanno calcolati
              LoadRank(  pTalentDB, r , r1 , r2);

              FExprParser1.ClearExpressions;
              FExprParser1.AddExpression ( tstmp[3] );
              sModValue:= FloatTostr(  RoundTo ( FExprParser1.EvaluateCurrent,-2));
             // qui devo puntare il 5 o il 6 Di tsMod 3@4@5@6@0@0
              tsMod:= tstringlist.Create ;
                tsMod.CommaText := Skill.afterCast;
                tsTmp2.Delimiter := '@';
                tsTmp2.DelimitedText := tsMod.Values ['v'] ;
                tsTmp2[StrToInt(tstmp[2])-1] := sModValue;
                tsMod.Values ['v'] := tsTmp2.DelimitedText ;

                Skill.afterCast  := tsMod.CommaText;
              TSMod.free;



          end;
        end;
//addstring,afterheal,s=heal,a=natural.protection.state,v=r1,d=10000
  end;

  (* Infine dopo aver usato addstring potrei avere delle aure come a=natural.protection,v=r1,d=10000 che richiedono un ulteriore calcolo *)



tsTmp.Free;
tsTmp2.Free;
Effects.Free;

// load stats points sul client nonviene eseguito
// I talenti sono un elenco di skill che vengono eseguite in successione al caricamento
// del char. Creano un'aura ca perdere che muore subito.

// ApplyAura=a=light^s.reach,v=5,d=1
// AddSkill=cleansing.flame_01

          //TsEffects[e]:=''; // importante p trova 2 applyaura
end;

procedure TEntity.SetAccuracy(const value:double);
var
i: Integer;
pSkill: PrpgSkill;
begin
  FAccuracy:= value;
  for i := 0 to SkillManager.lstSkills.Count -1 do begin
    SkillManager.lstSkills.Items [i].accuracy := faccuracy;
//  pSkill:= SkillManager.lstSkills.Items [i];
//  pskill.accuracy := faccuracy;
  end;
end;
procedure TEntity.SetPower(const value:double);
begin
  Fpower:= value;
  if FCp > FPower then FCp := FPower;
  {$ifdef rpg_client}
//  if Assigned (EntitySprite) then EntitySprite.CurPower  := Trunc(fCP);
  {$endif}
  end;

procedure TEntity.SetHealth(const value:double);
begin
  FHealth:= value;
  if FCh > FHealth then FCh := FHealth;

  {$ifdef rpg_client}
 // if Assigned (EntitySprite) then EntitySprite.health  := Trunc(FHealth);
  {$endif}

  end;
procedure TEntity.SetCH(const value:double);
var
oldfch: double;
begin

    if FCh = value then Exit;

    oldFch:= FCh;
    FCh:= value;
    if FCh > fHealth then FCh:= FHealth;  // controllo overhealing


    if FCh < 0 then begin
     FCh:=0;
     State:='cdead';  // @setstate

    end;

  {$ifdef rpg_client}
  if Assigned (EntitySprite) then begin
//    EntitySprite.CurHealth   := Trunc(FCH);
  end;
  {$endif}



end;
procedure TEntity.SetCP(const value:double);
var
oldfcP: double;
begin

    if FCP = value then Exit;

    oldFCP:= FCP;
    FCp:= value;
    if FCP > fpower then FCP:= FPower;  // controllo overPower

    if FCP < 0 then begin
     FCP:=0;
    end;
  {$ifdef rpg_client}
 // if Assigned (EntitySprite) then EntitySprite.CurPower   := Trunc(FCP);
  {$endif}



end;




constructor TEntity.Create();
begin
     inherited Create(  );
     FExprParser1 := TExpressionParser.Create;

     MainPath:= Tpath.Create ;
     RpgAction := TrpgAction.create(self);
     MechManager:= TMechManager.Create(self);
     SkillManager:= TSkillManager.Create(self );
     AuraManager:= TAuraManager.Create(self );
     AI:= TrpgAI.create(self);



     Fmasteries:= TStringList.Create ;
     FResistances:= TStringList.Create ;
     FTalents:= TStringList.Create ;
     FLoot:= TStringList.Create ;

end;

destructor TEntity.Destroy;
var
en: se_Engine;
begin

     if assigned (EntitySprite) then begin

       en:= EntitySprite.Engine;
       en.RemoveSprite(EntitySprite);
       // EntitySprite.Free; lo libero già nel processprite

     end;

     FExprParser1.free;

     AI.Free;
     RpgAction.Free;
     MechManager.Free;
     SkillManager.Free;
     AuraManager.Free;
     FLoot.free;

{$ifdef rpg_logger}
if RpgObj = rpgObj_npc then   CloseFile(CharLogger);
{$endif rpg_logger}

     FMasteries.free;
     FResistances.free;
     FTalents.free;


     inherited Destroy;
end;


function TRpgbrain.Checklof( MapX, MapY: integer; hexA,Hext: TPoint; Map_Diagonal_attack: boolean; range: integer): Tpoint;
var
StartCenter,DstCenter: TPoint;
i,x,y,v: integer;
Wall: boolean;
path: TPath;
Points: polygonSquare ;
aLocalMapcoord: se_Matrix;
aLocalrecord: TlocalMapCoord;
aBmp: TBitmap;
PtPoly: TpointArray7;
lCellX,lCelly:single;
label done;
begin
  (* Map e Unmap sono replicate sia sul brain che sul theater . Al brain serve per la linea di tiro*)
  Result:=Point(-1,-1);
  alocalMapCoord:= GetLocalMapCoord(MapX,MapY);

  path := GetLinePoints(HexA.X, HexA.Y, HexT.X, HexT.Y);
  for I := 0 to path.Count -1 do begin
    alocalMapCoord.Read(path[i].x,path[i].y,aLocalRecord);
      if aLocalRecord.terrain >= 255 then begin
        result.x:= path[i].x;
        result.y:= path[i].y;
        exit;
      end;
  end;
end;

procedure TEntity.Setfaction ( const v: string);
begin
  ffaction := v;
  {$ifdef rpg_client}
//  if assigned( FEntitySprite) then fEntitySprite.Faction:= v;

  {$endif}
end;
procedure TEntity.SetNumber ( const v: integer);
begin
  fNumber := v;
  {$ifdef rpg_client}
//  if assigned( FEntitySprite) then fEntitySprite.Number:= v;

  {$endif}
end;
procedure TEntity.group;
begin
  fgrouped := not fGrouped;
  {$ifdef rpg_client}
//  if assigned( FEntitySprite) then fEntitySprite.Grouped:=fGrouped;

  {$endif}

end;
function TEntity.GetNextKeyUp : TPoint;
begin
  case StrToInt(FIsoDirection) of
    1: begin
      Result.X := Cx;
      Result.Y := Cy +(1*trunc(fCS));
    end;
    2: begin
      Result.X := Cx +(1*trunc(fCS));
      Result.Y := Cy +(1*trunc(fCS));
    end;
    3: begin
      Result.X := Cx +(1*trunc(fCS));
      Result.Y := Cy -(1*trunc(fCS));
    end;
    4: begin
      Result.X := Cx;
      Result.Y := Cy -(1*trunc(fCS));
    end;
    5: begin
      Result.X := Cx -(1*trunc(fCS));
      Result.Y := Cy -(1*trunc(fCS));
    end;
    6: begin
      Result.X := Cx -(1*trunc(fCS));
      Result.Y := Cy +(1*trunc(fCS));
    end;
  end;
end;
procedure TEntity.SetEntitySprite( spr:TEntitySprite);
begin
  spr.health := Trunc(fhealth);
  spr.CurHealth  := Trunc(fCh);
  spr.power := Trunc(fpower);
  spr.CurPower  := Trunc(fCp);
  FEntitySprite:=spr;
end;
procedure TEntity.SetCombat(const value:boolean);
var
Neighbours: TObjectList<TEntity>;
aSource: TEntity;
begin

{$ifdef rpg_logger}
    if rpgobj = rpgobj_npc then begin
      WriteLn(charLogger, 'SetCombat:' + boolTostr(value));
    end;
{$endif rpg_logger}

  if fstate = 'cdead' then exit;
  if fCombat = value then begin
    if value then
      ToCombatOff := ToCombatOffMax;      // ogni volta che viene generato una skill (non move) fa ripartire il cooldown
      exit;
  end;

    fcombat:= value;
    if (fcombat = true) then begin

    (* se non ho già un target, lo cerco. in questo caso sono stato colpito ed è arrivato il messaggio hitted. Chi mi ha colpito
    è lasthitfrom (ids), se non lo trovo non faccio nulla.
     *)
      { TODO : gestire l'aura confusion }
//      if not fcombat then  begin
       // aSource := brain.GetNpcByIds (lasthitfrom) ;
       // if aSource <> nil then begin
          if rpgaction.target = nil then begin

            Neighbours:= TObjectList<TEntity>.Create(false); // molta attenzione, è false per evitare il delete
            brain.getneighbours(self,frangeInteract,hostile,false,Neighbours);
            if Neighbours.Count > 0 then begin
              RpgAction.target := Neighbours.Items [0];
            {$ifdef rpg_logger}
                WriteLn(charLogger, 'SetCombatChangeTarget:' + Neighbours.Items [0].Faction  + IntTostr(Neighbours.Items [0].number));
            {$endif rpg_logger}
            end;
            Neighbours.free;
          end;
    end
    else if (fcombat = false) and (fmainPath.currentStep <> -1) then begin
      State:= 'cidle';
      fInput:= 'lclick|' + Fids + '|' +
      IntToStr(MainPath.Step[MainPath.Count -1].X  ) + '|' +
      IntToStr(MainPath.Step[MainPath.Count -1].Y  ) + '|' +
          '|mainpath|' + ' ' +'|' + Fids +'|';
            {$ifdef rpg_logger}
                WriteLn(charLogger, 'SetCombat Input:' + fInput);
            {$endif rpg_logger}
    end;
 // end;

end;
procedure TEntity.SetState(const value:string);
begin

{$ifdef rpg_logger}
                WriteLn(charLogger, 'SetState:' + IntTostr(value)  );
{$endif rpg_logger}

  if FState = Value then Exit;


      if Value = 'cdead' then begin
//        FToidle:= FRespawn;
       FState:= value;
       brain.nilTarget (fids);
       fcombat:= false;
       ToCombatOff := ToCombatOffMax;
       skillmanager.resetAllCooldowns;
       AuraManager.SetAllDead ;
       if Assigned( Brain.OnCharDeath  ) then Brain.OnCharDeath( Self );
      end
      else if Value = 'chitted' then begin
        if FState <> 'cdead' then FState:= 'chitted';//FToidle:=600;
      end
      else if Value = 'cwalk' then begin
        if FState <> 'cdead' then  FState:='cwalk';//FToidle:=1200;
      end
      else if Value ='ccasting' then begin
        if FState <> 'cdead' then FState:= 'ccasting';
      end
      else if  value  = 'cidle' then begin
        if FState <> 'cdead' then FState:= 'cidle';
      end

      else if FState = 'cSpawn' then begin
           FState:= 'cidle';
           if Assigned( Brain.OnCharRespawn ) then Brain.OnCharRespawn( Self   );

      end;
        //FToIdle:= 1200;


//     {$ifdef rpg_client} FEntitySprite.BmpState:= LookupCharacterBmpState (fState); {$endif}


end;
procedure TEntity.SetisoDirection(const value: string);
begin
  if FisoDirection <> Value then begin

    FisoDirection:= value;
    {$ifdef rpg_client} if EntitySprite <> nil then begin
//    EntitySprite.Isodirection := fisoDirection;
    end;
     {$endif}

  end;

end;




constructor TRpgOptions.Create(AOwner: TComponent);
begin
  inherited Create;
end;

destructor TRpgOptions.Destroy;
begin
  inherited Destroy;
end;

procedure TRpgBrain.AiEvent (Interval: integer);
var
i: integer;
begin
  //Exit;
  for i := 0 to Fnpcs.Count -1 do begin
    if Fnpcs[i].State <> 'cdead' then  Fnpcs[i].AI.timer (Interval)  ;
  end;

end;
procedure TRpgBrain.NilTarget (value: string);
var
i: integer;
begin
  for i := 0 to Fnpcs.Count -1 do begin
    if fNpcs[i].RpgAction.target = nil then continue;
    if fNpcs[i].RpgAction.target.fIDs  = value then begin
      fNpcs[i].RpgAction.target := nil;
    end;
  end;
end;

procedure TRpgBrain.Clean_AllAuras (Interval: integer);
var
i,a: integer;
begin
  for i := 0 to Fnpcs.Count -1 do begin
    for a := fNpcs[i].AuraManager.lstAura.Count -1 downto 0 do begin
      if fNpcs[i].AuraManager.lstAura.Items [a].State = aDead then fNpcs[i].AuraManager.lstAura.Delete(a);
    end;
  end;
  for i := 0 to FWorldItems.Count -1 do begin
    for a := FWorldItems[i].AuraManager.lstAura.Count -1 downto 0 do begin
      if FWorldItems[i].AuraManager.lstAura.Items [a].State = aDead then FWorldItems[i].AuraManager.lstAura.Delete(a);
    end;
  end;
end;
procedure TRpgBrain.Exec_AllAuras (Interval: integer);
var
i: integer;
begin
  for i := 0 to Fnpcs.Count -1 do begin
    fNpcs[i].ExecuteAuras(Interval);
  end;
  for i := 0 to FWorldItems.Count -1 do begin
    fworlditems[i].ExecuteAuras(Interval);
  end;
end;

procedure TRpgBrain.Clean_AllActiveSkills (Interval: integer);
var
i: integer;
begin
    for i := lstActiveSkills.Count  -1 downto 0 do begin
      if lstActiveSkills.Items [i].state = sdead then lstActiveSkills.Delete(i);
    end;
end;

procedure TRpgBrain.Exec_AllActiveSkills (Interval: integer);
var
i: integer;
aChar: TEntity;
begin
    for i := 0 to lstActiveSkills.Count  -1 do begin
      if lstActiveSkills.Items [i].state = sdead then Continue;

      (* Solo per animazione moving del client *)
      if (lstActiveSkills.Items [i].state = scasting) and (lstActiveSkills.Items [i].Skill.SkillName ='move') then begin

      end;

      (* Decremento il casttime della active skill. Quando è zero la skill diventa sready *)
      lstActiveSkills.Items [i].casttime := lstActiveSkills.Items [i].casttime - (Interval);
      {$ifdef rpg_client}

      // trovo e inverto la percentuale per potere scrivere la progressbar
      if lstActiveSkills.Items [i].Skill.SkillName <> 'move' then begin

     // lstActiveSkills.Items [i].fChar.EntitySprite.CastBarText := lstActiveSkills.Items [i].Skill.SkillName;
     // lstActiveSkills.Items [i].fChar.EntitySprite.CastBarValue :=  round(100 -  (lstActiveSkills.Items [i].casttime * 100)  / lstActiveSkills.Items [i].Skill.casttime);
      end;
      {$endif rpg_client}

      if lstActiveSkills.Items [i].casttime <= 0 then begin
        lstActiveSkills.Items [i].state := sready;
        {$ifdef rpg_client}
        // metto a zero la castbar
       // lstActiveSkills.Items [i].fChar.EntitySprite.CastBarValue :=  0;
        {$endif rpg_client}

        lstActiveSkills.Items [i].Source.SkillManager.tryExecuteSkill( lstActiveSkills.Items [i] );
        lstActiveSkills.Items [i].state := sdead;


      end;
    end;
end;
procedure TRpgBrain.Exec_AllCooldowns (Interval: integer);
var
i,s: integer;
aChar: TEntity;
begin
      for i := 0 to fNpcs.Count  -1 do begin
        if fNpcs.Items [i].State = 'cdead' then continue;
        aChar:=  fNpcs.Items [i] ;

            for s := 0 to aChar.SkillManager.lstSkills.Count -1  do begin


                if aChar.Combat then begin   // tipo di gioco
                 if aChar.SkillManager.lstSkills.items[s].state = scooldown then begin

    //            if aChar.SkillManager.lstSkills.items[s].state = sCasting then continue;

                    aChar.SkillManager.lstSkills.items[s].cooldown :=  aChar.SkillManager.lstSkills.items[s].cooldown
                    - (Interval + aChar.SkillManager.decCd  );//TRpgThread(Sender).Interval ;
                                         // deccd viene modificato ad esempio da trigger.attack.speed
                    if aChar.SkillManager.lstSkills.items[s].cooldown <=0 then begin
                       aChar.SkillManager.lstSkills.items[s].cooldown := aChar.SkillManager.lstSkills.items[s].maxcooldown;
                       aChar.SkillManager.lstSkills.items[s].state :=sready;
                    end;
                  end;
                end
                else begin // se non sono in combat
                     aChar.SkillManager.lstSkills.items[s].cooldown := aChar.SkillManager.lstSkills.items[s].maxcooldown;
                end;


            end;



      end;
end;
procedure TRpgBrain.Exec_AllRpgActions (Interval: integer);
var
i: integer;
aChar: TEntity;
begin
      for i := 0 to fNpcs.Count  -1 do begin
        aChar:=  fNpcs.Items [i] ;

(*
            if aChar.State <> 'cidle' then begin
                  aChar.ToIdle := aChar.ToIdle - (GetTickCount-Thread.LastTickCount);//TRpgThread(Sender).Interval;

                  if aChar.ToIdle <= 0 then begin

                      if aChar.FState = 'cdead' then aChar.State:= 'cidle' else aChar.FState := 'cidle';       // da dead a idle = respawn
                  end;
            end;

*)

          if aChar.RpgAction.action = '' then Continue;

          aChar.RpgAction.duration := aChar.RpgAction.duration - (Interval);//TRpgThread(Sender).Interval;
//          Thread.LastTickCount:= GetTickCount;




            if aChar.RpgAction.duration <= 0 then begin
                //ConnId:= RpgBrain1.GetConnectionIdByCharIds(aChar.IDs   ) ;

                if (aChar.RpgAction.action  = 'moving') and (aChar.RpgAction.state= sactive)  then begin
                  aChar.RpgAction.state:= sdead;

                  //if ConnId = 0 then Continue;             // disconessione problema poi su server
                  // memory
                  aChar.cx:= aChar.Rpgaction.endX ;
                  aChar.cy:= aChar.Rpgaction.endY ;
                 // aChar.state:= 'cidle';


                end
                else if (aChar.RpgAction.action = 'casting') and (aChar.RpgAction.state= sactive)then begin


                  aChar.RpgAction.state:= sdead;
                  //if ConnId = 0 then Continue;             // disconessione problema poi su server
                  // memory


                  end;

            end;

//         end; c




      end;
end;



procedure TEntity.ExecuteAuras (Interval: integer);
var
i: integer;
aRpgAura: TRpgAura;
pAura: PRpgAura;
label CleanAuras;

  (*@ExecuteAuras (lato Server) processa tutte le auree di un Char. Viene decrementata la duration. Una volta raggiunto 0 l'aura si autoelimina
  settandosi su state !dead.
    Tutte le done vengono elaborate una sola volta e aspettano solo il dieandrestore. Le tick vengono elaborate N ms. Le Dead vengono rimosse
  e proprio in quel momento, viene ricalcolata l'aura al contrario con dieandrestore.
  *)
begin

  // le done persistenti (talenti) entrano in cooldown. sono auree che hanno già fatto il loro dovere e che al momento della morte, saranno ricalcolate
  // sul char. Aspect-of.the.light è una aura che si setta subito su done. La duration comunque varia perchè nessuna aura ha
  // durata illimitata
// {$ifdef rpg_clientMODE}
{if pos(application.ExeName,'client',1) <> 0 then begin

  for i := 0 to aChar.AuraList.Count -1  do begin
    aRpgAura:= aChar.AuraList.RpgAura [i];
    aRpgAura.duration :=  aRpgAura.duration - Interval ;
    if aRpgAura.duration <=0 then aRpgAura.duration:=0;
    aChar.AuraList.RpgAura [i]:= aRpgAura;
  end;
  aChar.Refreshgrid;
  Exit;
end;     }
  // {$ENDIF}

// {$ifdef rpg_serverMODE}
//if pos(application.ExeName,'server',1) <> 0 then begin
  if fState = 'cdead' then goto CleanAuras;

  for i := 0 to AuraManager.lstAura.Count -1  do begin
    //aRpgAura:= aChar.rlAura.RpgAura [i];
    if AuraManager.lstAura.items [i].State = adead then Continue;


          if  Not (AuraManager.lstAura.items [i].initialized ) then begin
             AuraManager.lstAura.items [i].Load;
             if fState ='cdead' then goto CleanAuras;           // può morire aura per aura
          end
          else if AuraManager.lstAura.items [i].initialized then begin
              AuraManager.lstAura.items [i].Timer(Interval);
              if fState ='cdead' then goto CleanAuras;          // può morire aura per aura
          end;


  end;
// end;
 //{$ENDIF}
  // Clean Auree
CleanAuras:
   for i := AuraManager.lstAura.Count -1 downto 0 do begin
      if ( AuraManager.lstAura.items [i].state = adead ) or ((FState = 'cdead') and  ( not AuraManager.lstAura.items [i].persistent ) )  then begin
         AuraManager.lstAura.Delete (i);
      end;
   end;


end;
procedure Trpgbrain.getneighbours ( aChar: TEntity ; radious: Integer; aFilter: TneighboursFilter; IncludeSelf: Boolean; var aList:Tobjectlist<TEntity> );
var
i: integer;
begin

  { TODO : assumo che sia afilter = ALL }
  (* aList contine dei TEntity già filtrati di solito friendly, hostile, all e soprattutto not dead e not stealth se hostile*)

  for i := 0 to Npcs.count -1 do begin
      if getRange (Npcs[i], aChar) <= radious then begin
        if Npcs[i].State  = 'cdead' then continue;
        if (not IncludeSelf ) and (aChar.IDs = Npcs[i].ids) then continue;
        if (aFilter = Friendly) and (aChar.Faction = Npcs[i].Faction)  then begin
          aList.Add(Npcs[i]);
        end
        else if (aFilter = Neutral) and (Npcs[i].Faction = '0')  then begin
          aList.Add(Npcs[i]);
        end
        else if (aFilter = Hostile) and (Npcs[i].Faction <> '0') and (Npcs[i].Faction <> aChar.Faction) and ( not Npcs[i].Stealthed ) then begin
          aList.Add(Npcs[i]);
        end
        else if (aFilter = All) then begin
          aList.Add(Npcs[i]);
        end
        else if (aFilter = AllButHostileStealth) and ((Npcs[i].Faction <> aChar.Faction) and ( not Npcs[i].Stealthed )
        or  (aChar.Faction = Npcs[i].Faction))
        then begin
          aList.Add(Npcs[i]);
        end;

        //type TneighboursFilter = (Friendly, Hostile, Neutral, All);

      end;
  end;

  // gli item non vanno buffati

end;
function TRpgbrain.GetRandomtarget (aList:Tobjectlist<TEntity>): TEntity;
var
i, aRND: integer;
begin
  (* aList contine dei TEntity già filtrati di solito friendly, hostile, all e soprattutto not dead e not stealth se hostile*)
  aRND:= fRandgen.AsInteger(aList.Count );
  Result:= aList.items[aRND];

end;
function TRpgBrain.GetLowesthealthtarget (aList:Tobjectlist<TEntity>): TEntity;
var
i: integer;
begin
  (* aList contine dei TEntity già filtrati di solito friendly, hostile, all e soprattutto not dead e not stealth se hostile*)
 // aList.TListCompareFunc  := compareCH;
  aList.sort(TComparer<TEntity>.Construct(
   function (const L, R: TEntity): integer
   begin
     result := trunc(L.fch - R.fch);
   end
  ));
  Result:= aList.items[0];

end;
procedure TRpgBrain.SetSomethingByIds( IDs: string; aChar: TEntity ) ;
var
i: integer;
begin

  for i := 0 to FNpcs.count -1 do begin
    if FNpcs[i].IDs  = Ids then begin
      Fnpcs[i]:= aChar;
      exit;
    end;
  end;
  for i := 0 to FworldItems.count -1 do begin
    if FworldItems[i].IDs  = Ids then begin
      FworldItems[i]:= achar;
      exit;
    end;
  end;

end;
Function TRpgBrain.GetSomeThingByIds(const Ids:String): TEntity;
begin
  Result:= GetNpcByIds(Ids);
  if Result <> Nil then Exit;
  Result:= GetWorldItemByIds(Ids);
  //if Result <> Nil then Exit;


end;

Function TRpgBrain.GetCliIdByIds(const Ids:string): integer;
var
i: integer;
begin
  Result:=0;
  for i := 0 to FNpcs.count -1 do begin
    if FNpcs[i].Ids = Ids then begin
      Result:= FNpcs[i].CliId;
      exit;
    end;
  end;

end;
procedure TRpgBrain.DeleteNpc(const ids:String);
var
i: integer;
Item,Bmp: Pointer;
begin
  for i := fNpcs.Count -1 downto 0 do begin
    if fNpcs.Items [i].ids = Ids then begin
      fNpcs.Delete(i);
      exit;
    end;
  end;
end;
procedure TRpgBrain.DeleteItem(const ids:String);
var
i: integer;
Item,Bmp: Pointer;
begin
  for i := fWorldItems.Count -1 downto 0 do begin
    if fWorldItems.Items [i].ids = Ids then begin
      fWorldItems.Delete(i);
      exit;
    end;
  end;
end;
Function TRpgBrain.GetCharByCliId(const CliId:integer): TEntity;
var
i: integer;
begin
  Result:=nil;
  for i := 0 to FNpcs.count -1 do begin
    if FNpcs[i].CliId = CliId then begin
      Result:= FNpcs[i];
      exit;
    end;
  end;

end;
Function TRpgBrain.GetWorldItemByName(const Name:String): TEntity;
var
i: integer;
begin
  Result:=nil;
  for i := 0 to FWorldItems.count -1 do begin
    if FWorldItems[i].Name   = Name then begin
      Result:= FWorldItems[i];
      exit;
    end;
  end;
end;
Function TRpgBrain.GetWorldItemByIds(const Ids:String): TEntity;
var
i: integer;
begin
  Result:=nil;
  for i := 0 to FWorldItems.count -1 do begin
    if FWorldItems[i].Ids   = Ids then begin
      Result:= FWorldItems[i];
      exit;
    end;
  end;
end;
Function TRpgBrain.GetNpcByName(const Name:String): TEntity;
var
i: integer;
begin
  Result:=nil;
  for i := 0 to FNpcs.count -1 do begin
    if FNpcs[i].Name   = Name then begin
      Result:= FNpcs[i];
      exit;
    end;
  end;
end;
Function TRpgBrain.GetNpc(const Faction:String; const Number : Integer): TEntity;
var
i: integer;
begin
  Result:=nil;
  for i := 0 to FNpcs.count -1 do begin
    if (FNpcs[i].Faction   = Faction) and (FNpcs[i].Number   = Number)  then begin
      Result:= FNpcs[i];
      exit;
    end;
  end;
end;
Function TRpgBrain.GetNpcByIds(const Ids:String): TEntity;
var
i: integer;
begin
  Result:=nil;
  for i := 0 to FNpcs.count -1 do begin
    if FNpcs[i].ids   = ids then begin
      Result:= FNpcs[i];
      exit;
    end;
  end;
end;
Function TRpgBrain.GetNpcBymapXY(const Map:String; const mapcx, mapcy, cX,cY: integer): TEntity;
var
i: integer;
begin
  Result:=nil;
  for i := 0 to FNpcs.count -1 do begin
    if (FNpcs[i].Map  = Map ) and (FNpcs[i].MapcX  = mapcX ) and (FNpcs[i].MapcY  = mapcy )
    and (FNpcs[i].Cx  = cX ) and (FNpcs[i].cY  = cy )
    then begin
      Result:= FNpcs[i];
      exit;
    end;
  end;
end;
Function TRpgBrain.GetWorldItemBymapXY(const Map:String; const mapcx, mapcy, cX,cY: integer): TEntity;
var
i: integer;
begin
  Result:=nil;
  for i := 0 to FWorldItems.count -1 do begin
    if (FWorldItems[i].Map  = Map ) and (FWorldItems[i].MapcX  = mapcX ) and (FWorldItems[i].MapcY  = mapcy )
    and (FWorldItems[i].Cx  = cX ) and (FWorldItems[i].cY  = cy )
    then begin
      Result:= TEntity(FWorldItems[i]);
      exit;
    end;
  end;
end;

constructor TRpgBrain.Create(AOwner: TComponent);
var
i,x,y,x2,y2: integer;
begin
  inherited Create( AOwner );

  FRpgOptions := TRpgOptions.Create(Self);


  if not (csDesigning in ComponentState) then begin

    FExprParser1 := TExpressionParser.Create;
    FRandGen:= TtdCombinedPRNG.create(0,0);

    fDefChar := se_RecordList.createList (sizeof (TrpgCharDB));
    //fDefNpc := se_RecordList.createList (sizeof (TrpgNpcDB));
    fDefItem := se_RecordList.createList (sizeof (TrpgItemDB));
    fDefConst := se_RecordList.createList (sizeof (TrpgConstDB));
    FDefSkill := se_RecordList.createList (sizeof (TrpgSkillDB));
    FDefTalent := se_RecordList.createList (sizeof (TrpgTalentDB));
    fDefColor := se_RecordList.createList (sizeof (TrpgColorDB));

    LstLocalMapCoord := TObjectList<se_Matrix>.Create;

    lstActiveSkills := TobjectList<TRpgActiveSkill>.Create(true);

    FWorldItems := TObjectList<TEntity>.Create;
    FWorldItems.OwnsObjects := true;

    FNpcs := TObjectList<TEntity>.Create;
    fnpcs.OwnsObjects := true;


    //GlobalMapCoords :=

    (* Sezione thread *)

    frpgThread := se_ThreadTimer.Create(self);
    frpgThread.KeepAlive := True;
    frpgThread.Interval := 50;//FRpgOptions.fthread_interval  ;//50

    frpgThread.OnTimer :=  MainThreadTimer ;
    frpgThread.Enabled := false;

  end;

end;
procedure TRpgBrain.Start(inifile: string);
var
  ini: Tinifile;
  x,y,x2,y2: Integer;
  aLocalMapcoord: se_Matrix;
  aLocalrecord: TlocalMapCoord;
  MyFile: File of TlocalMapCoord;
  fileName,grid: string;
  label Done;
begin
  (* Carico i dati del server                                            *)
  ini:= TIniFile.Create(iniFile);
  ServerName                    := ini.readstring('setup','name','');
  MapsDir                       := ini.readstring('setup','maps','');
  DefsDir                       := ini.readstring('setup','defs','');
  LOCAL_CELLSX:= ini.ReadInteger('setup', 'local_x', 0);
  LOCAL_CELLSY:= ini.ReadInteger('setup', 'local_y', 0);
  GLOBAL_CELLSX:= ini.ReadInteger('setup', 'global_x', 0);
  GLOBAL_CELLSY:= ini.ReadInteger('setup', 'global_y', 0);

  Grid                  := ini.readstring('setup','grid','hex');
  if grid = 'hex' then fGrid := gsHex;

  fCellWidth             := ini.ReadInteger('setup', 'CellWidth', 0);
  fCellHeight            := ini.ReadInteger('setup', 'CellHeight', 0);
  fCellSmallWidth        := ini.ReadInteger('setup', 'CellSmallWidth', 0);
  aHexCellSize.SmallWidth := fCellSmallWidth;

  AHexCellSize.Width := FCellWidth;
  AHexCellSize.Height:= FCellHeight;

//  if FGrid  = gsSquare then begin
//    VirtualWidth := (LOCAL_CELLSX * FCellwidth );
//    Virtualheight := (LOCAL_CELLSY * FCellHeight ) ;
//  end
  if FGrid  = gsHex then begin
    VirtualWidth := LOCAL_CELLSX * (AHexCellSize.Width - AHexCellSize.SmallWidth  );
    Virtualheight := (LOCAL_CELLSY * FCellHeight ) ;
  end;

  FRpgOptions.Walking_Time := ini.readinteger('setup','walking_time',1000);
  FRpgOptions.Delay_Input_Walk :=  ini.readinteger('setup','delay_input_walk',1500);
  FRpgOptions.Global_Cooldown :=  ini.readinteger('setup','global_cooldown',1500);
  FRpgOptions.Follow_Target :=  ini.readinteger('setup','follow_target',1);


  ini.Free;

  LoadDefsDb;

    {* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
    (* Carico tutte le mappe del server *)
    {* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
    globalMapCoords := se_Matrix.Create(global_cellsX, global_cellsX, sizeof(Pointer) );
  //  local_cellsX:= local_cellsX +40;
  //  local_cellsY:= local_cellsY +30;
   (* inizializzo tutte le singole celle *)
    for X := 0 to global_cellsX -1 do begin
      for Y := 0 to global_cellsY -1 do begin

       alocalMapCoord := se_Matrix.Create(local_cellsX, local_cellsY, sizeof(TlocalMapCoord) );  // creo la matrix
       aLocalMapcoord.x := X;
       aLocalMapcoord.y := Y;
       GlobalMapCoords.Fill(alocalMapCoord);
       lstLocalMapCoord.Add (aLocalMapcoord);
       Filename :=  MapsDir + ServerName + '_' + MyFormat(x) + '_' + MyFormat(y) + '_.txt';
       AssignFile(myFile, FileName );
       FileMode := fmOpenRead;
       Reset(myFile);

         for x2 := 0 to local_cellsX -1 do begin              // inizializzo
           for y2 := 0 to local_cellsY -1 do begin
              if Eof(myFile) then goto done;

              Read(myFile, aLocalRecord);
              if Eof(myFile) then goto done;

              alocalMapCoord.write(x2,y2,aLocalRecord);

           end;
         end;

       Done:
       CloseFile(myFile);
       globalMapCoords.write  (x, y, alocalMapCoord ); // <-- inserisce la mappa finita nella lista delle globali
       LoadNpcFromMap  (X,Y);
       LoadItemFromMap  (X,Y);
      end;
    end;

   frpgThread.Interval := FRpgOptions.fthread_interval  ;//50
   frpgThread.Enabled := true;



end;



function TRpgBrain.CreateCharacter(RpgObj:integer; defaultname, faction: string; number,Incr: integer): TEntity;
begin
    Result := TEntity.Create(  );         { TODO : Aggiungo proc char, ma servovo?}
    Result.faction := faction;
    result.Number := number;
    Result.Brain := self;

    Result.Rpgobj:= RpgObj;
    Result.CS:= result.Speed ;

    if RpgObj = rpgObj_npc then begin
      result.IDs :=  'f' + faction + 'n' + Inttostr(Number);
      FNpcs.Add(result) ;
    {$ifdef rpg_logger}
        AssignFile (Result.CharLogger, 'c:\temp\' + Result.IDs + '.txt');
        ReWrite(Result.CharLogger);
    {$endif rpg_logger}
    end
    else if RpgObj = rpgObj_Item then  begin
      result.IDs :=  defaultname + Inttostr(Incr);
      FWorldItems.Add(result);
    end;





    (*

    Result.OnDeath := aCharDeath ;
    Result.ondropHealth := aCharDrophealth ;
    Result.OnRecoverHealth := aCharRecoverhealth ;
    Result.ondroppower := aCharDroppower ;
    Result.OnRecoverpower := aCharRecoverpower ;

    Result.OnDrainedPower := aCharDrainedpower ;


    Result.OnRespawn := aCharRespawn ;
    Result.OnEnter := aCharEnter ;
    Result.OnExit := aCharExit ;

      Result.OnBeforeAddAura := BeforeCharAddAura;
      Result.f .OnAfterAddAura := AfterCharAddAura;
      Result.OnAuraChanges := CharAuraChanges;

      Result.OnBeforeUseSkill := BeforeCharUseSkill;
      Result.OnAfterUseSkill := AfterCharUseSkill;

      Result.OnHitted := aCharHitted;
      Result.OnHit := aCharHit;
      Result.OnHealed := aCharHealed;

*)



end;


destructor TRpgBrain.Destroy;
begin

  if not (csDesigning in ComponentState) then begin
    FRpgThread.Enabled := False;

    FExprParser1.Free;
    FRandGen.free;

    lstActiveSkills.Free;

    //Flush(-1);


  //  FWorldItems.Free;
  //  FNpcs.Free;

    fDefChar.Free;
    fDefItem.Free;
    fDefConst.Free;
    FDefSkill.Free;
    FDefTalent.Free;
    fDefColor.Free;

    LstLocalMapCoord.Free;

  end;

  FRpgOptions.Free;
  inherited Destroy;
end;

procedure TRpgBrain.Flush(rpgobj:integer);
var
Item,Bmp:pointer;
aEntitySprite: SE_Sprite;
begin
  if (rpgobj = -1) or (rpgobj = 1) then begin

    while FNpcs.Count > 0 do
    begin
      FNpcs.Delete( 0 );
    end;
  end;
  if (rpgobj = -1) or (rpgobj = 2) then begin

    while FWorldItems.Count > 0 do
    begin
      FWorldItems.Delete( 0 );
    end;
  end;
end;
procedure Trpgbrain.CopyRpgPath(src: TPath; dst: TPath);
var
i: integer;
aStep: TpathStep;
begin
  dst.Clear ;

  for I := 0 to src.Count -1 do begin
    aStep:= TpathStep.Create();
    aStep.X := src.Step [i].X;
    aStep.Y := src.Step [i].Y;
//    dst.Add(src.Step [i]);
    dst.Add(aStep);
  end;
end;
procedure TRpgBrain.ProcessAllInput(Interval: integer);
var
i: integer;
begin
  for i := 0 to Fnpcs.Count -1 do begin
    if fNpcs[i].Input <> '' then begin
      ProcessInput ( fNpcs[i].Input );
    end;
  end;
  for i := 0 to FWorldItems.Count -1 do begin
    if FWorldItems[i].Input <> '' then begin
    ProcessInput ( FWorldItems[i].Input );
   end;
  end;
end;
procedure TRpgBrain.ProcessInput(Params:string);
var
xxx,X,Y,Target: string;
i,c,j,dd:integer;
aChar,aTargetChar: TEntity;
Skill:  TRpgSkill;
ActiveSkill: TRpgActiveSkill;
pActiveSkill: pRpgActiveSkill;
ov:boolean;
TsCardFlagged:TStringList;
aCommaText: string;
alocalmapCoord: se_Matrix;
aLocalrecord: TlocalMapCoord;
Found: boolean;
Output: string;
Myparams: TStringList;
AnEvent: TStateEvent;
label done;
// procedure AnEvent ( Sender: TObject; State: TCustomSearchState ) ;
// begin
//   State.Terrain
// end;
begin
//  ENTERCS   { TODO : arrrivano input dai client e dagli npc }
//  EnterCriticalSection(TProcessInput);
  //InterlockedExchange


  Myparams := Tstringlist.Create ;                                            (* non può entrare una stringa vuota dal client *)
  MyParams.StrictDelimiter := True;
  Split  (params, '|',  MyParams) ;

  if myParams[0] = 'lclick' then begin

      aChar := GetSomethingByIds(MyParams[1]);
      aTargetChar:= GetSomethingByids (myParams[6]); //char,npc,item)   // se non ho target è strano perchè il client lo setta per forza
      if aTargetChar = nil then goto Done; // non può essere hacked perchè un char può essere sloggato

      //MyParams.Insert(1,aChar.IDs );  //0=lclcik aggiungo param(1) 2=x 3=y 4=action 5=fireball, 6=target
      X:=MyParams[2];  { TODO : x e y potrebbero essere isnum = false }
      Y:=MyParams[3];
      Target:=MyParams[6];

              alocalMapCoord:= GetLocalMapCoord(0,0);   { TODO : dal char si rialse alla mapcoord desisderata MAPX MAPY del char }

        if (myParams[4] ='skill') then begin
            if (GetTickCount - aChar.LastInputSkill ) < RpgOptions.FGlobal_Cooldown  then begin
              // il globalcooldown si attiva vale solo dopo il casting di una skill. Dopo avere lanciato una skill, per
              // 1,5 secondi il client non spedirà più skill nè casting. Il Client può spedire walking, ma è gestito a
              // parte. Ne consegue che se arriva un altro casting o una skill istant cast c'è qualcosa che non va nel client.

              // hacked
              goto Done;
            end;
            if aChar.State = 'ccasting' then goto done;
            if aChar.RpgAction.action = 'casting' then goto done;

            aChar.LastInputSkill := GetTickCount;



            (* Qui la skill è completed e devo chiedere alla skill se è in cooldown o se deve essere presente qualche aura o
               se per esempio la health (CH) è una certa percentuale   *)
            Skill := aChar.SkillManager.GetCharSkill(myparams[5]); // la chiamo più volte e serve a getrange
            //pSkill:= @aSkill;  a chi punta?
            //ShowMessage(pskill.SkillName );

            aChar.SkillManager.Broadcast ( msg_cast, false, Skill , Output ) ;  // informo le skill
            if Output = 'cooldown' then begin
              // testato prima con state. non è hacked perchè un npc può alzare i cooldow dell'avversario
               (* auree che scadono non sono hacked*)
              goto Done;
            end
            else if Output ='notenoughpower' then begin
              goto Done;
            end
            else if Output ='hacked-cooldown' then begin
              goto Done;
            end
            else if Output ='hacked-skillNotFound' then begin
              goto Done;
            end
            else if pos( 'aurarequired:', Output,1) <> 0 then begin
              goto Done;
            end
            else if pos( 'auraNOrequired::', Output,1) <> 0 then begin
              goto Done;
            end;

            if Output <> 'OK' then goto Done;



            (* Informo le Mechanic che potrebbero aumentare il mio danno o  accuracy della skill per esempio *)
            aChar.MechManager.Broadcast ( msg_cast, Skill, Output ) ;
            if Output = 'xxx' then
            begin
              goto Done;
            end;
            if Output <> 'OK' then goto Done;


            (* Subito dopo, occorre capire se il nostro char è sotto effetto di auree negative come confusion o misdirection. Aureee che
              possono far cambiare target oppure che possono fare fallire il lancio della skill.
            Ooccorre verificare la auree sul Char che effettua l'azione per determinare se può usare la skill. Un esito negativo è
            sicuramente un hack. Per esempio un personaggio stunnato non può lanciare incantesimi di norma. Il Client non  lo permette *)

            aChar.AuraManager.Broadcast ( msg_Cast, false, Skill, Output ); (* check auree stunned, silence non sono hacked perchè subentrate in corso*)
            if Output <> 'OK' then goto Done;

            (* Qui la skill ha superato tutti i check e ora informa nuovamente le auree *)
            (* es. se il Char si muove un'aura può recare danni o se viene lanciata una certa skill.*)
            aChar.AuraManager.Broadcast( msg_execute, false,Skill, Output);

            (* se il char si muove o lancia un'altra skill il casting precedente di una skill viene annullato *)
            (* se il char si muove certe skill possono cambiare cooldown, per questo broadcast *)
            aChar.SkillManager.Broadcast( msg_execute, false,Skill, Output);

            { solitamente il lancio della skill interrompe il casting di altre skill, qui check }
            StopAllCasting( AChar, false ); // fermo il moving

            (*ottengo la distanza tra i due char*)
            if Skill.SkillName <> 'move' then begin

                       if GetRange (aChar, aTargetChar) <= Skill.range then begin

                        (*qui aRpgSkill è già modificata da eventuali talenti del char o da telenti sulla skill del char
                          annullo il precedente castin o move di qiel char,m tutto da fcharachters
                          setto inrpgactions. il nuovo casting. fare tutto quesot anche inmove estop
                          e oi il timer che decrementa *)
                          //FCharactions.RemoveActions (aChar);
                  //        aRpgAction.char := aChar;
                        //  aChar.RpgAction.target := GetSomeThingByIds( myParams[6]);   // getsomething prende anche i 'cdead'
                          if aChar.RpgAction.target.State <> 'cdead' then begin
                            aChar.RpgAction.action := 'casting';
                           // aChar.RpgAction.target := GetSomeThingByIds( myParams[6]);
{                            aChar.RpgAction.map := aChar.Map ;
                            aChar.RpgAction.mapcx := aChar.Mapcx ;
                            aChar.RpgAction.mapcy := aChar.Mapcy ;
                            aChar.RpgAction.startx := aChar.cx ;
                            aChar.RpgAction.starty := aChar.cy ;
                            aChar.RpgAction.endx := aChar.cx;
                            aChar.RpgAction.endy := aChar.cy;  }
                            aChar.RpgAction.svalue  := Skill.SkillName ;
                            aChar.RpgAction.duration := Skill.casttime ;
                            aChar.RpgAction.maxduration :=  aChar.RpgAction.duration ;
                            aChar.RpgAction.state := sactive ;


                            ActiveSkill:= TRpgActiveSkill.Create(aChar);
                            ActiveSkill.Skill := skill;

                            ActiveSkill.Source:= aChar;
                            ActiveSkill.Target:= aTargetChar;
                            ActiveSkill.CastTime := ActiveSkill.Skill.casttime ;
                            ActiveSkill.x   := aTargetChar.cx;
                            ActiveSkill.y   := aTargetChar.cy;
                            ActiveSkill.state := sCasting;
                            Skill.state := sCasting; // setta la skill del character in casting per gestire il cooldown

                            lstActiveSkills.Add(ActiveSkill);
                            //Answer.Add( 'casting*'+ aRpgSkill.slabel + '*' + aRpgSkill.target +'*');

                            if Assigned (FOnCharCastingSkill ) then FOnCharCastingSkill (aChar, ActiveSkill);

                          end;
                              { TODO : grosso bug: in memoria locale ci sono le coordinate dei cloni }

                       end; // fine in range   { TODO : else (not in range) in followtarget skill.skillname='move'e un jump }
            end

            else if Skill.SkillName = 'move' then begin

                          aChar.LastInputWalk:= GetTickCount;
                         // if RpgOptions.FFollow_Target = 0 then goto Done;

                          if aTargetChar.state <> 'cdead' then begin
                            aChar.RpgAction.action    := 'moving';
                            aChar.RpgAction.target := nil;//aTargetChar;
                            aChar.RpgAction.map := aChar.Map ;
                            aChar.RpgAction.mapcx := aChar.Mapcx ;
                            aChar.RpgAction.mapcy := aChar.Mapcy ;
                           { aChar.RpgAction.startx := aChar.cx ;
                            aChar.RpgAction.starty := aChar.cy ;
                            aChar.RpgAction.endx := aChar.MainPath[achar.MainPath.CurrentStep].X;
                            aChar.RpgAction.endy := aChar.MainPath[achar.MainPath.CurrentStep].Y;   }
                         //   aChar.RpgAction.duration := round (RpgOptions.FWalking_Time / aChar.CS)  ;
                            { TODO : bug cs }
                            aChar.RpgAction.maxduration := aChar.RpgAction.duration;
                            aChar.RpgAction.state := sActive ;

                            (* Creo ed inserisco in coda una skill 'move' con i parametri di NPF *)
                            Skill := TrpgSkill (aChar.SkillManager.GetCharSkill('move'));
                            ActiveSkill:= TRpgActiveSkill.Create(aChar);
                            ActiveSkill.Skill := skill;

                            ActiveSkill.Source:= aChar;
                            ActiveSkill.Target:= aTargetChar;
                            ActiveSkill.CastTime := ActiveSkill.Skill.casttime ;
                           // ActiveSkill.x   := aChar.MainPath[achar.MainPath.CurrentStep].X;
                           // ActiveSkill.y   := aChar.MainPath[achar.MainPath.CurrentStep].Y;
                            ActiveSkill.state := sCasting;


                            lstActiveSkills.Add(ActiveSkill);
                          //  if Assigned (FOnCharStartMove )  then FOnCharStartMove (aChar ,  aChar.MainPath[achar.MainPath.CurrentStep].X, aChar.MainPath[achar.MainPath.CurrentStep].Y );
                          end;



                          goto Done;
            end;

        end;

    end;

Done:
  if aChar <> nil then aChar.Input := '';
  if Myparams <> nil then Myparams.Free;

//  LeaveCriticalSection(TProcessInput);

end;

procedure TRpgBrain.SaveLocalMap(const Mapx: Integer; const Mapy: Integer);
var
  MyFile: File of TlocalMapCoord;
  aLocalMapCoord: se_Matrix;
  aLocalrecord: TlocalMapCoord;
  fileName: string;
  x,y: integer;
begin
  Filename :=  MapsDir + ServerName + '_' + MyFormat(Mapx) + '_' + MyFormat(Mapy) + '_.txt';
  AssignFile(myFile,  fileName );
  FileMode:=fmOpenWrite;
   ReWrite(myFile);

  aLocalMapCoord := GetLocalMapCoord(MapX,MapY);
  for x := 0 to LOCAL_CELLSX -1  do begin
    for y := 0  to LOCAL_CELLSY -1 do begin
    aLocalMapCoord.Read (x,y, aLocalRecord );
    if aLocalrecord.terrain = 0 then aLocalrecord.terrain := 1;// costo non può essere 0

    Write(myFile, aLocalRecord);
  end;
  end;
  CloseFile(myFile);

  SaveNpcToMap ( Mapx, MapY);
  SaveItemToMap(  Mapx, MapY);

end;
function TRpgBrain.GetLocalMapCoord ( const Mapx, Mapy : Integer ): se_Matrix ;
var
i: Integer;
aLocalMapCoord: se_Matrix;
begin

      for I := 0 to LstLocalMapCoord.Count -1 do begin

        if (LstLocalMapCoord[i].X = MapX) and (LstLocalMapCoord[i].Y = MapY) then begin
          result := LstLocalMapCoord[i];
          Exit;
        end;

      end;



end;

procedure TRpgBrain.MainThreadTimer(Sender: TObject);
var
i,R,s: integer;
aCharAction: TRpgAction;
aChar: TEntity;
AnSwer:TStringList;
aRpgSkill: TRpgSkill;
aActiveSkill: TRpgActiveSkill;
pActiveSkill: pRpgActiveSkill;
Arr  : TArray<TrpgActiveSkill>;

begin
    (* Qui vengono elaborate tutte le aureee e successivamente tutte le ActiveSkill *)

    Clean_allAuras ( FrpgThread.Interval );
    Exec_AllAuras ( FrpgThread.Interval );  // il clean è dentro char per char
//    Arr:= lstActiveSkills.ToArray ;
//    pActiveSkill :=  prpgActiveSkill (@Arr[i]);
    Application.ProcessMessages ;


    (* Tutte le skill sia in casting che ready che dead devono essere processate. Si può verificare che il target
    sia ucito dal range della skill.La getRange è stata eseguita al momento del casting quindi la skill è già qui
    pronta per essere eseguita, ma è possibile verificare nuovamente questa condizione. Inolte Nel Tempo in cui
    il char è rimasto a castare le condizioni della skill potrebbero essere state modificate da altri fattori,
    per esempio un debuff che abbassi la mastery della skill, ma questo non è più possibile modificarlo. *)

   // Clean_allActiveSkills ( FrpgThread.Interval ); pericolodo, farlo solo a partita finita o se skill più vecchie di 1 minuto
    Exec_allActiveSkills (FrpgThread.Interval);
    Application.ProcessMessages ;

    // Clean ActiveSkill    { TODO : Clean activeSkill solo dopo 1 minuto dalla morte della skill o perde il riferimento Source per le skill in elaborazione }
(*
     Application.ProcessMessages ;
     for i := lstActiveSkills.Count -1 downto 0 do begin
        if lstActiveSkills.items [i].state = sdead AND SEPOLTA > 600000 then begin     ma devo comununqe gestire la grafica
           lstActiveSkills.Delete (i);
        end;
     end;

*)    // Cooldown gestire una lista npc

     Exec_AllCooldowns (FrpgThread.Interval);
    Application.ProcessMessages ;

     Exec_AllRpgActions (FrpgThread.Interval);
    Application.ProcessMessages ;

    //startAi
    AIEvent (FrpgThread.Interval);
    Application.ProcessMessages ;

    ProcessAllInput( FrpgThread.Interval);

end;


function TrpgBrain.GetDefTalent (const id: integer): pRpgTalentDB;
var
i: integer;
pTalentDB: pRpgTalentDB;
begin

  for i := 0 to fDefTalent.count -1 do begin
    pTalentDB:= fDefTalent.items[i];
    if pTalentDB.id = id then begin
      result := pTalentDB;
      break;
    end;
  end;

end;
function TrpgBrain.MinWXYZ (const Q, X, Y, Z: Int64): Integer;
begin
     Result := Q;
     if X < Result then
          Result := X;
     if Y < Result then
          Result := Y;
     if Z < Result then
          Result := Z;
end;
function TrpgBrain.GetRange(aChar,bChar: TEntity): integer;
var
x,X1,X2,Y1,Y2: integer;
begin
  if aChar.Map <> bChar.Map  then begin
    Result:=1000000;
    Exit;
  end;

(*trovo il valore minimom se sotto zero incremento tutti di quel valore cosi' siamo in positivo*)
  X1:=aChar.cx; Y1:=aChar.cy; X2:= bChar.cx; Y2:= bchar.cy;
//  X1:=-1;Y1:=-2; X2:=-2;Y2:=-1;
  x:= MinWXYZ (X1,Y1,X2,Y2);
  if x < 0 then begin
    x:= abs(x);
    X1:= X1 + x;
    X2:= X2 + x;
    Y1:= Y1 + x;
    Y2:= Y2 + x;
  end;
   { TODO : forse fare sqr }
  result:= round(Hypot(X1-X2, Y1-Y2));
end;

procedure TRpgBrain.SaveNpcToMap(const MapX, MapY: integer);
var
ini: Tinifile;
c,x,y,i: integer;
ppNpc: pNpc;
pNpcDB: pRpgCharDB;
aNpc:TEntity;
map: ss20;
prefix: string;
filename: string;
label done;
begin
   Prefix:='npc';
   Filename :=  MapsDir + ServerName + '_' + MyFormat(Mapx) + '_' + MyFormat(Mapy) + '_.npcs';
   c:=0;
   if FileExists(FileName) then DeleteFile(pchar(FileName));
   ini:= TIniFile.Create(Filename);

   for i:= 0 to Npcs.Count -1 do begin

   aNpc:= Npcs.Items [i];
     if (aNpc.map = map) and (aNpc.Mapcx = Mapx) and (aNpc.MapCy = MapY) then begin

       for x := 0 to DefChar.Count -1 do begin

          pNpcDB := defChar.Items [x];
          if pNpcDB.defaultname = aNpc.defaultname  then begin  { TODO : usare ID }

           Ini.Writeinteger(prefix+ IntToStr(c),'id',              aNpc.id);
           Ini.WriteString(prefix + IntToStr(c),'defaultname',     pNpcDB.defaultname);// water1, water 2 ....
           Ini.WriteFloat(prefix+ IntToStr(c),'attack',            aNpc.attack);
           Ini.WriteFloat(prefix+ IntToStr(c),'defense',           aNpc.defense);
           Ini.WriteFloat(prefix+ IntToStr(c),'stamina',           aNpc.stamina);
           Ini.WriteFloat(prefix+ IntToStr(c),'vitality',          aNpc.vitality);

           Ini.WriteFloat(prefix+ IntToStr(c),'mfire',             aNpc.mfire);
           Ini.WriteFloat(prefix+ IntToStr(c),'mearth',            aNpc.mearth);
           Ini.WriteFloat(prefix+ IntToStr(c),'mlight',            aNpc.mlight);
           Ini.WriteFloat(prefix+ IntToStr(c),'mphysical',         aNpc.mphysical);
           Ini.WriteFloat(prefix+ IntToStr(c),'mwater',            aNpc.mwater);
           Ini.WriteFloat(prefix+ IntToStr(c),'mdark',             aNpc.mdark);
           Ini.WriteFloat(prefix+ IntToStr(c),'mwind',             aNpc.mwind);
           Ini.WriteFloat(prefix+ IntToStr(c),'rfire',             aNpc.rfire);
           Ini.WriteFloat(prefix+ IntToStr(c),'rearth',            aNpc.rearth);
           Ini.WriteFloat(prefix+ IntToStr(c),'rlight',            aNpc.rlight);
           Ini.WriteFloat(prefix+ IntToStr(c),'rphysical',         aNpc.rphysical);
           Ini.WriteFloat(prefix+ IntToStr(c),'rwater',            aNpc.rwater);
           Ini.WriteFloat(prefix+ IntToStr(c),'rdark',             aNpc.rdark);
           Ini.WriteFloat(prefix+ IntToStr(c),'rwind',             aNpc.rwind);


           Ini.WriteFloat(prefix+ IntToStr(c),'crit ',             aNpc.crit );
           Ini.WriteFloat(prefix+ IntToStr(c),'critdmg',           aNpc.critdmg);
           Ini.WriteFloat(prefix+ IntToStr(c),'accuracy',          aNpc.accuracy  );
           Ini.WriteFloat(prefix+ IntToStr(c),'dodge',             aNpc.dodge );

           Ini.WriteString(prefix+ IntToStr(c),'talents',          aNpc.talents.CommaText );
           Ini.WriteString(prefix+ IntToStr(c),'spritename',       pNpcDB.spritename);

           Ini.WriteString(prefix + IntToStr(c),'race',            pNpcDB.race);
           Ini.WriteString(prefix + IntToStr(c),'classes',         pNpcDB.classes);
           Ini.WriteInteger(prefix+ IntToStr(c),'regenhealth',     pNpcDB.regenhealth);

           Ini.WriteString(prefix+ IntToStr(c),'auras',            aNpc.AuraManager.auras.CommaText );
           // Non serve salvare skills.
           //Ini.WriteString(prefix+ IntToStr(c),'skills',           aNpc.SkillManager.skills.CommaText );


           Ini.WriteString(prefix + IntToStr(c),'name',            aNpc.name);// water1, water 2 ....
           Ini.WriteString(prefix+ IntToStr(c),'map',              Map) ;
           Ini.WriteInteger(prefix+ IntToStr(c),'mapcx',           MapX) ;
           Ini.WriteInteger(prefix+ IntToStr(c),'mapcy',           MapY) ;
           Ini.Writeinteger(prefix+ IntToStr(c),'cx',              aNpc.cX);
           Ini.Writeinteger(prefix+ IntToStr(c),'cy',              aNpc.cY);

           Ini.WriteInteger(prefix+ IntToStr(c),'respawn',         aNpc.respawn);
           Ini.WriteString(prefix+ IntToStr(c),'loot',             aNpc.loot.CommaText );

           ini.WriteString(prefix + IntToStr(c),'state',          aNpc.FState );
           ini.WriteString(prefix + IntToStr(c),'isodirection',    aNpc.IsoDirection );

           // ID unico sul server
           Ini.WriteString(prefix + IntToStr(c),'ids',   pNpcDB.defaultname  +  '-' + IntToStr(i)  );
           ini.WriteBool(prefix + IntToStr(c),'combat',            aNpc.Combat );
           Ini.WriteFloat(prefix+ IntToStr(c),'speed' ,            aNpc.speed);
           ini.WriteFloat(prefix+ IntToStr(c), 'cs',               aNpc.cs);
           ini.WriteBool(prefix + IntToStr(c),'Wall',              aNpc.Wall );
           ini.WriteFloat(prefix+ IntToStr(c), 'ch',               aNpc.ch);
           ini.WriteString(prefix + IntToStr(c),'fatherids',       aNpc.FatherIDs );

           ini.WriteFloat(prefix+ IntToStr(c), 'power',            aNpc.power);
           ini.WriteFloat(prefix+ IntToStr(c), 'cp',               aNpc.cp);

           ini.WriteString(prefix+ IntToStr(c), 'faction',          aNpc.faction);

           Ini.WriteInteger(prefix+ IntToStr(c),'number',         aNpc.number);

          inc(c);
          Break;
          end;
       end;
     end;
   end;

done:
  Ini.WriteInteger('setup' ,'count',c);
  Ini.Free;
end;

procedure TRpgBrain.SaveItemToMap (const MapX, MapY: integer);
(****************************************************************************)
{
 DEVE ESSERE SEMPRE COPIATA E INCOLLATA DA SAVENPCTOMAP
 E CAMBIARE NPC IN WORLDITEMS
}
(****************************************************************************)
var
ini: Tinifile;
c,x,y,i: integer;
ppItem: pItem;
aEntitySprite: SE_Sprite;
pItemDB: pRpgItemDB;
aItem:TEntity;
map: ss20;
Filename :string;
prefix: string;
label done;
begin
   Prefix:='item';
   Filename :=  MapsDir + ServerName + '_' + MyFormat(Mapx) + '_' + MyFormat(Mapy) + '_.items';
   c:=0;
   if FileExists(FileName) then DeleteFile(pchar(FileName));
   ini:= TIniFile.Create(Filename);


   for i:= 0 to WorldItems.Count -1 do begin
   aItem:= WorldItems.Items [i];
   if aItem.defaultname = 'irarpgwall' then continue;
    if (aItem.map = map) and (aItem.Mapcx = Mapx) and (aItem.MapCy = Mapy) then begin

       for x := 0 to DefItem.Count -1 do begin
          pItemDB := defItem.Items [x];
          if pItemDB.defaultname = aItem.defaultname then begin


           Ini.Writeinteger(prefix+ IntToStr(c),'id',              aitem.id);
           Ini.WriteString(prefix + IntToStr(c),'defaultname',     pitemDB.defaultname);// water1, water 2 ....
           Ini.WriteFloat(prefix+ IntToStr(c),'attack',             aitem.attack);
           Ini.WriteFloat(prefix+ IntToStr(c),'defense',       aitem.defense);
           Ini.WriteFloat(prefix+ IntToStr(c),'stamina',           aitem.stamina);
           Ini.WriteFloat(prefix+ IntToStr(c),'vitality',          aitem.vitality);

           Ini.WriteFloat(prefix+ IntToStr(c),'mfire',             aitem.mfire);
           Ini.WriteFloat(prefix+ IntToStr(c),'mearth',            aitem.mearth);
           Ini.WriteFloat(prefix+ IntToStr(c),'mlight',            aitem.mlight);
           Ini.WriteFloat(prefix+ IntToStr(c),'mphysical',         aitem.mphysical);
           Ini.WriteFloat(prefix+ IntToStr(c),'mwater',            aitem.mwater);
           Ini.WriteFloat(prefix+ IntToStr(c),'mdark',             aitem.mdark);
           Ini.WriteFloat(prefix+ IntToStr(c),'mwind',             aitem.mwind);
           Ini.WriteFloat(prefix+ IntToStr(c),'rfire',             aitem.rfire);
           Ini.WriteFloat(prefix+ IntToStr(c),'rearth',            aitem.rearth);
           Ini.WriteFloat(prefix+ IntToStr(c),'rlight',            aitem.rlight);
           Ini.WriteFloat(prefix+ IntToStr(c),'rphysical',         aitem.rphysical);
           Ini.WriteFloat(prefix+ IntToStr(c),'rwater',            aitem.rwater);
           Ini.WriteFloat(prefix+ IntToStr(c),'rdark',             aitem.rdark);
           Ini.WriteFloat(prefix+ IntToStr(c),'rwind',             aitem.rwind);

           Ini.WriteFloat(prefix+ IntToStr(c),'crit ',             aitem.crit );
           Ini.WriteFloat(prefix+ IntToStr(c),'critdmg',           aitem.critdmg);
           Ini.WriteFloat(prefix+ IntToStr(c),'accuracy',          aitem.accuracy  );
           Ini.WriteFloat(prefix+ IntToStr(c),'dodge',             aitem.dodge );

           Ini.WriteString(prefix+ IntToStr(c),'talents',          aitem.talents.CommaText );
           Ini.WriteString(prefix+ IntToStr(c),'spritename',       pitemDB.spritename);

           Ini.WriteString(prefix + IntToStr(c),'race',            pitemDB.race);
           Ini.WriteString(prefix + IntToStr(c),'classes',         pitemDB.classes);
           Ini.WriteInteger(prefix+ IntToStr(c),'regenhealth',     pitemDB.regenhealth);
           Ini.WriteFloat(prefix+ IntToStr(c),'speed',           pitemDB.speed);

           Ini.WriteString(prefix+ IntToStr(c),'auras',            aitem.AuraManager.auras.CommaText );


           Ini.WriteString(prefix + IntToStr(c),'name',            aitem.name);// water1, water 2 ....
           Ini.WriteString(prefix+ IntToStr(c),'map',              Map) ;
           Ini.WriteInteger(prefix+ IntToStr(c),'mapcx',           MapX) ;
           Ini.WriteInteger(prefix+ IntToStr(c),'mapcy',           MapY) ;
           Ini.Writeinteger(prefix+ IntToStr(c),'cx',              aitem.cX);
           Ini.Writeinteger(prefix+ IntToStr(c),'cy',              aitem.cY);

           Ini.WriteInteger(prefix+ IntToStr(c),'respawn',         aitem.respawn);
           Ini.WriteString(prefix+ IntToStr(c),'loot',             aitem.loot.CommaText );

           ini.WriteString(prefix + IntToStr(c),'state',          aitem.FState );
           ini.WriteString(prefix + IntToStr(c),'isodirection',    aitem.IsoDirection );

           // ID unico sul server
           Ini.WriteString(prefix + IntToStr(c),'ids',   pitemDB.defaultname  +  '-' + IntToStr(i)  );
           ini.WriteBool(prefix + IntToStr(c),'combat',            aitem.Combat );
           Ini.WriteFloat(prefix+ IntToStr(c),'speed' ,            aitem.speed);
           ini.WriteFloat(prefix+ IntToStr(c), 'cs',               aitem.cs);
           ini.WriteBool(prefix + IntToStr(c),'Wall',              aitem.Wall );
           ini.WriteFloat(prefix+ IntToStr(c), 'ch',               aitem.ch);
           ini.WriteString(prefix + IntToStr(c),'fatherids',       aitem.FatherIDs );

           ini.WriteFloat(prefix+ IntToStr(c), 'power',            aitem.power);
           ini.WriteFloat(prefix+ IntToStr(c), 'cp',               aitem.cp);
           ini.WriteFloat(prefix+ IntToStr(c), 'cs',               aitem.cs);

           ini.WriteString(prefix+ IntToStr(c), 'faction',          aItem.faction);

            inc(c);
            Break;
          end;
       end;
   end;
 end;
done:

  Ini.WriteInteger('setup' ,'count',c);
  Ini.Free;
end;
procedure TRpgBrain.LoadNpcFromMap ( const MapX, MapY: integer );
var
i,x2,y2,n,Count: integer;
ini: TIniFile;
aChar:TEntity;
d,f,filename: string;

begin
          Filename :=  MapsDir + ServerName + '_' + MyFormat(Mapx) + '_' + MyFormat(Mapy) + '_.npcs';
          ini:= TiniFile.create ( filename );
          Count:= ini.ReadInteger('setup','count',0);

          for i := 0 to Count -1 do begin

            d                      := ini.ReadString('npc' + IntToStr(i),'defaultname','');
            f                      := ini.ReadString('npc' + IntToStr(i),'faction','0');
            n                      := ini.ReadInteger('npc' + IntToStr(i),'number',0);
            aChar:= CreateCharacter(rpgobj_npc,d,f,n,i);

            aChar.defaultname      := d;
            aChar.Faction          := f;
            aChar.Number           := n;
//            aChar.IDs               :=  ini.ReadString('npc' + IntToStr(i),'ids',''); // è creato in createcharacter


            aChar.id                := ini.ReadInteger('npc' + IntToStr(i),'id',0);
            aChar.attack            := ini.ReadFloat('npc' + IntToStr(i),'attack',0);
            aChar.defense           := ini.ReadFloat('npc' + IntToStr(i),'defense',0);
            aChar.stamina           := ini.ReadFloat('npc' + IntToStr(i),'stamina',0);
            aChar.vitality          := ini.ReadFloat('npc' + IntToStr(i),'vitality',0);

            aChar.mfire             := ini.ReadFloat('npc' + IntToStr(i),'mfire',0);
            aChar.mearth            := ini.ReadFloat('npc' + IntToStr(i),'mearth',0);
            aChar.mlight            := ini.ReadFloat('npc' + IntToStr(i),'mlight',0);
            aChar.mphysical         := ini.ReadFloat('npc' + IntToStr(i),'mphysical',0);
            aChar.mwater            := ini.ReadFloat('npc' + IntToStr(i),'mwater',0);
            aChar.mdark             := ini.ReadFloat('npc' + IntToStr(i),'mdark',0);
            aChar.mwind             := ini.ReadFloat('npc' + IntToStr(i),'mwind',0);
            aChar.rfire             := ini.ReadFloat('npc' + IntToStr(i),'rfire',0);
            aChar.rearth            := ini.ReadFloat('npc' + IntToStr(i),'rearth',0);
            aChar.rlight            := ini.ReadFloat('npc' + IntToStr(i),'rlight',0);
            aChar.rphysical         := ini.ReadFloat('npc' + IntToStr(i),'rphysical',0);
            aChar.rwater            := ini.ReadFloat('npc' + IntToStr(i),'rwater',0);
            aChar.rdark             := ini.ReadFloat('npc' + IntToStr(i),'rdark',0);
            aChar.rwind             := ini.ReadFloat('npc' + IntToStr(i),'rwind',0);

            aChar.crit              := ini.ReadFloat('npc' + IntToStr(i),'crit',0);
            aChar.critdmg           := ini.ReadFloat('npc' + IntToStr(i),'critdmg',0);
            aChar.dodge             := ini.ReadFloat('npc' + IntToStr(i),'dodge',0);

            aChar.talents.commatext := ini.readstring('npc' + IntToStr(i),'talents','');
            aChar.spritename        := ini.readstring('npc' + IntToStr(i),'spritename','');
            aChar.spritepriority    := ini.readinteger ('npc' + IntToStr(i),'spritepriority',0);

            aChar.Race              := ini.ReadString('npc' + IntToStr(i),'race','');
            aChar.Classes           := ini.ReadString('npc' + IntToStr(i),'classes','');
            aChar.regenhealth       := ini.readinteger ('npc' + IntToStr(i),'regenhealth',0);
            aChar.Speed             := ini.readinteger ('npc' + IntToStr(i),'speed',1);
      // fine def_char solo come indicazione

            aChar.AuraManager.Auras.commatext:=ini.ReadString('npc' + IntToStr(i),'auras','');
            //aChar.SkillManager.skills.commatext:=  ini.ReadString('npc' + IntToStr(i),'skills','');


            aChar.Name              := ini.ReadString('npc' + IntToStr(i),'name' + IntToStr(i),'');   // water1, water 2 ...
            aChar.Map               := ini.ReadString('npc' + IntToStr(i),'map','');
            aChar.MapCx             := ini.ReadInteger('npc' + IntToStr(i),'mapcx',0);
            aChar.MapCy             := ini.ReadInteger('npc' + IntToStr(i),'mapcy',0);
            aChar.Cx                := ini.ReadInteger('npc' + IntToStr(i),'cx',0);
            aChar.Cy                := ini.ReadInteger('npc' + IntToStr(i),'cy',0);

            aChar.Respawn           := ini.ReadInteger('npc' + IntToStr(i),'respawn',0);
            aChar.loot.CommaText    := ini.ReadString('npc' + IntToStr(i),'loot','');


            aChar.fState            := 'cidle'; // forzato a idle o rimane su casting ini.ReadInteger('npc' + IntToStr(i),'state','cidle');
            aChar.IsoDirection      := ini.ReadString('npc' + IntToStr(i),'isodirection','');
            aChar.Combat            := ini.ReadBool('npc' + IntToStr(i),'combat',false);

            aChar.Wall              := ini.ReadBool('npc' + IntToStr(i),'wall',false);
            aChar.toidle            := 1200; //ini.ReadInteger('npc' + IntToStr(i),'notckiclable',0);

            aChar.Health            := Round(aChar.stamina * aChar.Vitality) ;
            aChar.Ch               := ini.Readfloat('npc' + IntToStr(i),'ch',0);

            aChar.power             := ini.ReadFloat('npc' + IntToStr(i),'power',0);
            aChar.CP               := ini.Readfloat('npc' + IntToStr(i),'cp',0);

            aChar.fcs               := ini.ReadFloat('npc' + IntToStr(i),'cs',1);

            aChar.FatherIDs         :=ini.ReadString('npc' + IntToStr(i),'father','');

            aChar.RangeInteract       :=ini.ReadInteger('npc' + IntToStr(i),'rangeinteract',2);
            aChar.ToCombatOffMax      :=ini.ReadInteger('npc' + IntToStr(i),'tocombatoffmax',5000);

            aChar.Loading:=true;
            aChar.MechManager.AddMechanic('cdrage');
            aChar.LoadTalents;
            aChar.Loading:=false;
            aChar.Ready:=true;

        end;
            ini.Free;
end;
procedure TRpgBrain.LoadItemFromMap (const MapX, MapY: integer );
var
i,x2,y2,n,Count: integer;
ini: TIniFile;
aChar:TEntity;
prefix: string;
d,f,filename: string;
begin
    Filename :=  MapsDir + ServerName + '_' + MyFormat(Mapx) + '_' + MyFormat(Mapy) + '_.items';
    ini:= TiniFile.create (filename );
    Count:= ini.ReadInteger('setup','count',0);

    for i := 0 to Count -1 do begin

      d                      := ini.ReadString('item' + IntToStr(i),'defaultname','');
      f                      := ini.ReadString('item' + IntToStr(i),'faction','0');
      n                      := ini.ReadInteger('item' + IntToStr(i),'number',0);
      aChar:= CreateCharacter(rpgobj_item,d,f,n,i);

      aChar.defaultname      := d;
      aChar.Faction          := f;
      aChar.Number           := n;

      aChar.id                := ini.ReadInteger('item' + IntToStr(i),'id',0);
//      aChar.IDs               :=  ini.ReadString('item' + IntToStr(i),'ids',''); // questo è l'id unico per mappa , creato in createcharacter

      aChar.attack             := ini.ReadFloat('item' + IntToStr(i),'attack',0);
      aChar.defense       := ini.ReadFloat('item' + IntToStr(i),'defense',0);
      aChar.stamina           := ini.ReadFloat('item' + IntToStr(i),'stamina',0);
      aChar.vitality          := ini.ReadFloat('item' + IntToStr(i),'vitality',0);

      aChar.mfire           := ini.ReadFloat('item' + IntToStr(i),'mfire',0);
      aChar.mearth          := ini.ReadFloat('item' + IntToStr(i),'mearth',0);
      aChar.mlight          := ini.ReadFloat('item' + IntToStr(i),'mlight',0);
      aChar.mphysical       := ini.ReadFloat('item' + IntToStr(i),'mphysical',0);
      aChar.mwater          := ini.ReadFloat('item' + IntToStr(i),'mwater',0);
      aChar.mdark           := ini.ReadFloat('item' + IntToStr(i),'mdark',0);
      aChar.mwind           := ini.ReadFloat('item' + IntToStr(i),'mwind',0);
      aChar.rfire           := ini.ReadFloat('item' + IntToStr(i),'rfire',0);
      aChar.rearth          := ini.ReadFloat('item' + IntToStr(i),'rearth',0);
      aChar.rlight          := ini.ReadFloat('item' + IntToStr(i),'rlight',0);
      aChar.rphysical       := ini.ReadFloat('item' + IntToStr(i),'rphysical',0);
      aChar.rwater          := ini.ReadFloat('item' + IntToStr(i),'rwater',0);
      aChar.rdark           := ini.ReadFloat('item' + IntToStr(i),'rdark',0);
      aChar.rwind           := ini.ReadFloat('item' + IntToStr(i),'rwind',0);

      aChar.crit              := ini.ReadFloat('item' + IntToStr(i),'crit',0);
      aChar.critdmg           := ini.ReadFloat('item' + IntToStr(i),'critdmg',0);
      aChar.accuracy          := ini.ReadFloat('item' + IntToStr(i),'accuracy',0);
      aChar.dodge             := ini.ReadFloat('item' + IntToStr(i),'dodge',0);

      aChar.talents.commatext := ini.readstring('item' + IntToStr(i),'talents','');
      aChar.spritename        := ini.readstring('item' + IntToStr(i),'spritename','');
      aChar.spritepriority    := ini.readinteger ('item' + IntToStr(i),'spritepriority',0);

      aChar.Race              := ini.ReadString('item' + IntToStr(i),'race','');
      aChar.Classes           := ini.ReadString('item' + IntToStr(i),'classes','');
      aChar.regenhealth       := ini.readinteger ('item' + IntToStr(i),'regenhealth',0);
      aChar.Speed              := ini.readinteger ('npc' + IntToStr(i),'speed',1);

      // fine def_char solo come indicazione

      aChar.AuraManager.Auras.commatext:=ini.ReadString('item' + IntToStr(i),'auras','');
      //aChar.SkillManager.skills.commatext:=  ini.ReadString('item' + IntToStr(i),'skills','');


      aChar.Name              := ini.ReadString('item' + IntToStr(i),'name' + IntToStr(i),'');   // water1, water 2 ...
      aChar.Map               := ini.ReadString('item' + IntToStr(i),'map','');
      aChar.MapCx             := ini.ReadInteger('item' + IntToStr(i),'mapcx',0);
      aChar.MapCy             := ini.ReadInteger('item' + IntToStr(i),'mapcy',0);
      aChar.Cx                := ini.ReadInteger('item' + IntToStr(i),'cx',0);
      aChar.Cy                := ini.ReadInteger('item' + IntToStr(i),'cy',0);

      aChar.Respawn           := ini.ReadInteger('item' + IntToStr(i),'respawn',0);
      aChar.loot.CommaText    := ini.ReadString('item' + IntToStr(i),'loot','');


      aChar.fState            := ini.ReadString('item' + IntToStr(i),'state','cidle');
      aChar.IsoDirection      := ini.ReadString('item' + IntToStr(i),'isodirection','');
      aChar.Combat            := ini.ReadBool('item' + IntToStr(i),'combat',false);
      aChar.speed             := ini.ReadFloat('item' + IntToStr(i),'speed',1);
      aChar.fcs               := ini.ReadFloat('item' + IntToStr(i),'cs',1);

      aChar.Wall              := ini.ReadBool('item' + IntToStr(i),'wall',false);
      aChar.toidle            := 1200; //ini.ReadInteger('item' + IntToStr(i),'notckiclable',0);

      aChar.Health            := Round(aChar.stamina * aChar.Vitality) ;
      aChar.Ch                := ini.Readfloat('item' + IntToStr(i),'ch',0);

      aChar.power             := ini.ReadFloat('npc' + IntToStr(i),'power',0);
      aChar.CP                := ini.Readfloat('npc' + IntToStr(i),'cp',0);

      aChar.fcs               := ini.ReadFloat('npc' + IntToStr(i),'cs',1);
      aChar.FatherIDs         :=ini.ReadString('item' + IntToStr(i),'father','');

      aChar.Faction          :=ini.ReadString('item' + IntToStr(i),'faction','');


      aChar.Loading:=true;
      if length(aChar.Talents.CommaText) > 1  then aChar.LoadTalents;   // i talenti chiamano direttamente applyeffect
      aChar.Loading:=false;
      aChar.Ready:=true;
    end;
    ini.Free;

end;

procedure TRpgBrain.DecodeFilename (FileName: string; out Map:ss20; out mapx,mapy: integer);
begin

  filename:= justnameL ( filename );
  Map:= ExtractWordL(1, Filename, '_') ;
  MapX:= StrToInt(ExtractWordL(2, Filename, '_') );
  MapY:= StrToInt(ExtractWordL(3, Filename, '_') );
  {-Given an array of word delimiters, return the N'th word in a string.}

end;
(*************************************************************************
         TRPGAI       TRPGAI      TRPGAI      TRPGAI
         TRPGAI       TRPGAI      TRPGAI      TRPGAI
         TRPGAI       TRPGAI      TRPGAI      TRPGAI

(*************************************************************************)
constructor TrpgAI.create( owner: TEntity)  ;
begin
  fchar:= owner;
  AIClass:= fchar.classes ;
  (*Setto dei Default*)
  iInterval:=0;
  SingleAttack := 25;
  MultiAttack := 25;
  Heal:= 25;
  Curse:= 25;
end;

destructor TrpgAI.Destroy  ;
begin
  inherited;
end;
function trpgAI.isOnpath : boolean;
begin
  result := fchar.MainPath.CurrentStep <> -1;
end;
procedure TrpgAI.timer ( interval: integer );
var
aSkill: TRpgSkill;
aRND: integer;
Neighbours,NeighboursFar: TObjectList<TEntity>;
AneighboursFilter: TneighboursFilter;
IncludeSelf: Boolean;
aStep: TpathStep;
cr:integer;
aInput: string;
atarget: TEntity;
hexA,Hext: TPoint;
aPoint: Tpoint;
label Magiccombat, Magicmainpath, Myexit;
begin
// exit;

 (* tenere in considerazione RpgAction.path *)
 (*    solo RPG reale: controllo di non essere già in casting ma non posso puntare la lstactiveskill perchè nel client
       potrebbe non esserci e qui non posso leggere qualcosa che potrebbe cambiare da un input
       esterno. uso RpgAction che è stata settata bene. Se Stunned posso evitare tutto. *)
  iinterval := iinterval + Interval ;
  if fchar.State = 'cdead' then exit;

      (* Prima di tutto se sono in combat verifico di uscirne del tutto per resettare i cooldown di tutte le skill. uscire dal combat
      + una penalità in questo senso.
      *)
    if fchar.Combat then begin
      fchar.ToCombatOff := fchar.ToCombatOff - Interval;
      if fchar.ToCombatOff <= 0 then begin
        fchar.ToCombatOff := fchar.ToCombatOffMax;
        fchar.Combat := false;
      end;
    end;

//  if  iinterval >= 1000 then begin                 // un npc 'pensa' ogni n millisecondi.
      iinterval:=0;
      //qui decido bene il combattimento
      Neighbours:= TObjectList<TEntity>.Create(false); // molta attenzione, è false per evitare il delete
  //  goto MagicMainpath;


    if (fchar.auramanager.Stunned > 0 )  then goto MyExit;    // stunnato esco
    (* Da qui esco che o ho un target oppure mainpath *)
   fchar.AI.OnPathEngage:= true;
//      if fchar.classes <>'priest' then exit;
     // if fchar.classes ='priest' then fchar.AI.OnPathEngageLowhealth := 100;        { TODO : rimuovere cheat }
//      if fchar.classes ='warrior' then fchar.AI.OnPathEngageLowhealth := 100;        { TODO : rimuovere cheat }

//      if (isOnPath  and OnPathEngage)   // onpath cerco un target
//      or (isOnPath  and OnPathEngageOnly1v1)   // onpath cerco un target
//      or (isOnPath  and (OnPathEngageLowhealth <> 0))   // onpath cerco un target
//      or (not isOnPath )                                                    // fermo cerco un target)
   //    then begin
          fchar.RangeInteract:=6;
          if not fchar.Combat then Begin        // se npc non è già in combat cerca un target ma solo se engaged
            {$ifdef rpg_logger}
                Writeln( fchar.charLogger , 'AIevent: non sono in combat. cerco un target');
            {$endif rpg_logger}
            fchar.Brain.getneighbours (fChar , fchar.RangeInteract  , Hostile, false , Neighbours  );
            if Neighbours.Count > 0 then begin
               if isOnPath and OnPathEngage then begin
                   fchar.RpgAction.target := fchar.brain.GetRandomtarget (Neighbours)  // tra quelli trovati
               end
               else if isOnPath and OnPathEngageOnly1v1 then begin

                  if Neighbours.Count = 1 then begin
                    NeighboursFar:= TObjectList<TEntity>.Create(false); // molta attenzione, è false per evitare il delete
                    fchar.Brain.getneighbours (fChar , fchar.RangeInteract +5 , Hostile, false , NeighboursFar  );  { TODO : testare bene +5 = 10 range? }
                    if NeighboursFar.Count = 1 then fchar.RpgAction.target := Neighbours.Items [0];
                    NeighboursFar.Free;
                  end;
               end
               else if isOnPath and (OnPathEngageLowhealth <> 0 )then begin
                   aTarget := fchar.brain.GetLowestHealthtarget (Neighbours);  // tra quelli trovati
                   if ((aTarget.Ch * 100) / aTarget.Health <= OnPathEngageLowhealth) then fchar.RpgAction.target := Neighbours.Items [0];
               end
               else if isOnPath and OnPathPlaceHeal  then begin
               // placeheal
               end
               else if isOnPath and OnPathStun  then begin
               // sap    // deve avere sap. non importa la classe , può essere rubata da un faceless
               end
               else if isOnPath and  OnPathRoot  then begin
               // root
               end
               else if isOnPath and OnPathPlaceTrap  then begin
               // placetrap
               end
               else if isOnPath and OnPathStealth  then begin
               // stealth
               end
               else if not isOnPath   then begin // fermo a far nulla
                   fchar.RpgAction.target := fchar.brain.GetRandomtarget (Neighbours);  // se non sono in combat con target prendo il primo target
            {$ifdef rpg_logger}
                Writeln( fchar.charLogger ,  'AIevent: fermo a far nulla, cerco un target:' + fchar.RpgAction.target.Faction + Inttostr(fchar.RpgAction.target.number));
            {$endif rpg_logger}
               end;

            end;

//            else goto MagicMainpath;              // se non trova un target esegue il MainPath
          end;

        (* se doveva ingaggiare ma non ci sono target disponibili va al mainpath, ma solo se non era in combat. se è già in combat
           non esegue il mainpath ma esce col suo combat normale
         *)
          if fchar.RpgAction.target = nil then goto MagicMainpath; // neigbourn può essere piena, ma non 1v1 quindi target è = nil
            {$ifdef rpg_logger}
                Writeln( fchar.charLogger ,  'AIevent: ho trovato un target:' + fchar.RpgAction.target.Faction + Inttostr(fchar.RpgAction.target.number));
            {$endif rpg_logger}


          // ho usato la tecnica del nil. si può usare <> 'cdead'. Essendo un mainthread tutto in fila va bene anche nil
Magiccombat:
      (* Qui il char è in combat o entra in combat ora, oppure è in casting move e solo adesso ha trovato un target. Oppure è in combat ma
      con un 'cdead'. Il target è comunque ostile. Le cure si riferiscono sempre a chi ha la health più bassa. Qui esistono diversi comportamenti:
      se non engage prosegue col mainpath. oppure nel caso di rogue, ranger sono diverse le cose da fare. Anche il priest può curare.
       *)
          hexA.X := fchar.Cx;
          hexA.Y := fchar.Cy;
          hexT.X :=  fchar.RpgAction.target.Cx;
          hexT.Y :=  fchar.RpgAction.target.Cy;
          aPoint:= fchar.Brain.Checklof  ( fchar.MapCx, fchar.MapCy , HexA, HexT, false,  fchar.RangeInteract) ;
          if aPoint.x <> -1  then begin    (* Linea di tiro*)
                             // MapX, MapY: integer; hexA,Hext: TPoint; Map_Diagonal_attack: boolean;PGWH, range: integer): boolean;
            {$ifdef rpg_logger}
                Writeln( fchar.charLogger ,  'AIevent: ho trovato un target, :' + fchar.RpgAction.target.Faction + Inttostr(fchar.RpgAction.target.number)+ ' NO ldt ' + Inttostr(aPoint.x)+':'+ Inttostr(aPoint.y));
            {$endif rpg_logger}
            goto MagicMainpath;
          end;
          fchar.Combat := true; // ricalcola il mainpath quando torna false inserendo una skill 'mainpath' nativa
          (* se non c'è una skill di attacco, eseguo l'autoattack, oppure una skill di attacco*)
          (* Se è disponibile una skill di cura, curo chi ha la health più bassa del proprio team in radious*)
          Askill:= fchar.SkillManager.getNextRotationSkill ;
          if aSkill = nil then begin        //  Se non ha trovato una skill pronta di quel genere, genera solo l'autoattack
            if not ((fchar.SkillManager.lstSkills [1].school  <> 'physical') and (fchar.AuraManager.Silenced > 0))      then begin // se non sono silenziato
               fchar.Input := 'lclick|' + fchar.ids + '|' + IntToStr(fchar.RpgAction.target.cX) + '|' + IntToStr(fchar.RpgAction.target.cY)
                  + '|skill|' + fchar.SkillManager.lstSkills [1].SkillName  +'|' + fchar.RpgAction.target.ids +'|'        { TODO : scegliere danno base }
            end;
          end
          else begin // Skill di attaco o cura?
            if not ((aSkill.school <> 'physical') and (fchar.AuraManager.Silenced > 0))      then begin // se non sono silenziato
                if (pos('attack',aSkill.kind,1) <> 0) or (pos('curse',aSkill.kind,1) <> 0) then begin
                  fchar.Input := 'lclick|' + fchar.ids + '|' + IntToStr(fchar.RpgAction.target.cX) + '|' + IntToStr(fchar.RpgAction.target.cY)
                      + '|skill|' + aSkill.SkillName   +'|' + fchar.RpgAction.target.ids +'|';
                end     // cura
                else if (pos('blessing',aSkill.kind,1) <> 0) or (pos('heal',aSkill.kind,1) <> 0) then begin
                  fchar.Brain.getneighbours (fChar , fchar.RangeInteract  , Friendly, true , Neighbours  ) ;
    //              if Neighbours.Count > 0 then begin       {  count è sempre 1 includeself }
                     aTarget := fchar.brain.GetLowestHealthtarget (Neighbours);  // tra quelli trovati
                      fchar.Input := 'lclick|' + fchar.ids + '|' + IntToStr(atarget.cX) + '|' + IntToStr(atarget.cY)
                      + '|skill|' + aSkill.SkillName   +'|' + atarget.ids +'|';
                end;
            end
            else begin
            {$ifdef rpg_logger}
                Writeln( fchar.charLogger , 'AIevent: Silenced:' );{ TODO : c'è il controllo dopo in brodcast della activeskill }
            {$endif rpg_logger}

            end;
          end;
            {$ifdef rpg_logger}
                Writeln( fchar.charLogger , 'AIevent: input:' + fchar.Input );
            {$endif rpg_logger}
          //Neighbours.Free;
          (* *)
             // OutputDebugString (pchar('neigbourns: ' + Inttostr (Neighbours.Count)));
              { senza outputdebug si pianta }
          goto Myexit;
      //    if fchar.RpgAction.target = nil then Exit else goto combat;

   //   end;

      // niente target, proseguo con il mainpath se esiste, altrimenti nin fa nulla
      (* Se il MainPath non è vuoto allora mi muovo se non sono in combat *)

Magicmainpath:
    if isOnPath  then begin

         cr:=fchar.MainPath.CurrentStep ;
          { TODO : l'ultimo input deve sostituire activeskill di input già presenti. quelle di movimento, non le altre }

         aInput:= 'lclick|' + fchar.ids + '|' +
         IntToStr(fchar.MainPath.Step  [ cr ].X  )  + '|' + IntToStr( fchar.MainPath.step [cr ].Y)
               + '|skill|' + 'move'   +'|' + fchar.ids +'|';

//         outputdebugstring(pwidechar( IntTostr(fChar.MainPath.Step [cr].X) + ':'+
//                           IntTostr(fChar.MainPath.Step [cr].Y) + ' '));

    //     if (fchar.lastInputMove <> aInput)
    //      or ((fchar.MainPath.Step  [ cr ].X = fchar.Cx)
    //      and (fchar.MainPath.Step  [ cr ].Y = fchar.Cy)) then begin
    //      fchar.lastInputMove:= aInput;
          fchar.Input := aInput;
       //  end;
        goto Myexit;
    end
    else goto Myexit;   // no mainpath, no target, esco





  myexit:
  Neighbours.Free;

 // end;

end;

(*************************************************************************
         TRPGAURA       TRPGAURA      TRPGAURA      TRPGAURA
         TRPGAURA       TRPGAURA      TRPGAURA      TRPGAURA
         TRPGAURA       TRPGAURA      TRPGAURA      TRPGAURA

(*************************************************************************)
constructor TrpgAura.create(params: string; fromSkill: TRpgActiveSkill)  ;
var
ts: tstringlist;
begin
  (* Tutte le auree derivate chiamano questa inherited. Qui vengono elaborati i parametri in entrata *)
  (* e viene salvata la skill completa da cui è stata generata. apActiveSkill ci fornisce accesso *)
  (* anche ai TEntity Source e Target così da non perdere nessuna informazione.                                                            *)
  (*  es. v=5,d=30000,cd=3,tick=1000,radious=7 *)
  fParams:= params;
  AuraManager := fromSkill.Target.AuraManager ;  // importante per multiblessing
  FromActiveSkill := fromSkill;     // pointer alla skill completa che ha generato questa aura
  FromTalent := nil;
  school      := fromSkill.Skill.school ;                // es. fire, water, dark etc....

  Create (params);


end;
constructor TrpgAura.create(params: string; pTalentDB: PRpgTalentDB; manager: TAuraManager)  ;
var
ts: tstringlist;
begin
  (* Tutte le auree derivate chiamano questa inherited. Qui vengono elaborati i parametri in entrata *)
  (* e viene salvata il talento da cui è stata generata. Manager ci fornisce accesso al TEntity Source
   così da non perdere nessuna informazione.                                                            *)
  (*  es. v=5,d=30000,cd=3,tick=1000,radious=7 *)
  fParams:= params;
  AuraManager := Manager ;  // importante per multiblessing
  FromTalent := pTalentDB;     // pointer al talento che ha generato questa aura
  FromActiveSkill:= nil;
  FromAura:= nil;
  school      := pTalentDB.tree;   // es. skill, talent, auto

  Create (params);

end;
constructor TrpgAura.create(params: string; ActiveAura: TrpgAura; Manager: TAuraManager)  ;
var
ts: tstringlist;
begin
  (* Tutte le auree derivate chiamano questa inherited. Qui vengono elaborati i parametri in entrata *)
  (* e viene salvata l'aura da cui è stata generata.l'aura ci fornisce accesso al TEntity Source
   così da non perdere nessuna informazione.                                                            *)
  (*  es. v=5,d=30000,cd=3,tick=1000,radious=7 *)
  fParams:= params;
  AuraManager := Manager  ;  // importante per multiblessing
  FromActiveSkill:= nil;
  FromAura:= ActiveAura;
  FromTalent := nil;     // pointer al talento che ha generato questa aura
  school      :=  ActiveAura.school ;                // es. fire, water, dark etc....

  Create (params);


end;
constructor TrpgAura.create(params: string)  ;
var
ts: tstringlist;
begin
  ts:= tstringlist.Create ;
  ts.CommaText := params;
  AuraName:=  ts.Values ['a'];                            // es. blessing.of.fortune or  SD  or HEAL
  v           := ts.Values ['v'];
  duration    := StrToIntDef(ts.Values ['d'],0);          // durata della'aura
  maxduration := duration;
  cooldown    := StrToIntDef(ts.Values ['cd'],0);         // cooldown dell'aura (spesso nel caso di trigger)
  maxcooldown := cooldown;
  tick        := StrToIntDef(ts.Values ['tick'],0);       // Tempo di intervallo nel  caso di auree tick (DoT)
  MaxTick     := Tick;
  radious     := StrToIntDef(ts.Values ['radious'],0);    // nel caso di Aoe ( Area of Effect )
  chance      := StrToIntDef(ts.Values ['applychance'],0);  // % che si scateni l'effetto dell'aura. 0= 100%
  ts.Free;
  persistent  := False; // i talenti trigger sono persistent come altri buff a tempo di gioco
  State       := aReady;
  Stack:=1;
  Timed       := true;  // viene processata la duration
  AuraShow:= false;
  (*Esistono 4 tipi di auree: quelle che lavorano onload o one shoot , quelle a tick timer, quelle a trigger
  Quelle a trigger spesso sono caricate direttamente dai talenti come trigger.attack.speed
  *)
end;


procedure TrpgAura.Load;
begin
  {$ifdef rpg_client}
  if assigned(auramanager.fchar.EntitySprite ) then begin
    if AuraShow then begin
//      auramanager.fchar.EntitySprite.VirtualAddAura(self.AuraManager.fChar.ids  , auraname, Inttostr(duration) )
    end;
  end;

  {$endif rpg_client}
  if Assigned( AuraManager.fchar.Brain.OnCharAuraLoad )  then AuraManager.fchar.Brain.OnCharAuraLoad ( AuraManager.fchar.Brain, AuraManager.fchar, TrpgAura(Self), fromActiveskill );

end;
procedure TrpgAura.DieAndrestore;
begin
  {$ifdef rpg_client}
  if assigned(auramanager.fchar.EntitySprite ) then begin
//    auramanager.fchar.EntitySprite.VirtualDeleteAura (self.AuraManager.fChar.ids  , auraname ) ;
  end;

  {$endif rpg_client}

  if Assigned( AuraManager.fchar.Brain.OnCharAuraDie )  then AuraManager.fchar.Brain.OnCharAuraDie ( AuraManager.fchar.Brain, AuraManager.fchar, TrpgAura(Self), fromActiveskill );

end;

destructor TrpgAura.Destroy  ;
begin
  inherited;
end;
procedure TrpgAura.timer ( interval: integer );      (*tick e duration sono generici comuni*)
begin
   (* Il threadTimer che processa tutte le auree di un TEntity può avere un intervallo diverso, di *)
   (* solito molto più basso. Per questo il tick va decrementato dell'intervallo del threadtimer      *)
   (* es. damage over time ogni 2000 ms per un totale di 14000 ms *)
   if Behaviour = 'tick' then begin   // ci consente di mantenere abstract l'evento onTick
                                      // alternativatemente possiamo creare un TrpgAura.OnTick vuota.
     tick := tick - Interval ;
        if tick < 0 then begin
            tick := maxtick;
            OnTick;            // è il momento di agire per le auree Tick
        end;

   end;
   (* La duration è generica per tutte le auree e quindi ci occupiamno qui di decrementarla *)
   (* Es. un buff di 30 minuti è giunto alla fine. L'aura si setta su adead, un flag che ci *)
   (* permette di rimuoverla quando il ciclo che processa tutte le auree del TEntity sarà terminato*)
   (* persistent è un talent passivo come quello che trigga quando Ch raggiunge una certa soglia *)
   if Timed then
    begin
     duration :=  duration - Interval ;
     if (Duration <= 0 ) and (not Persistent) then begin
      {$ifdef rpg_client}
      if assigned(auramanager.fchar.EntitySprite ) then begin
//        if Behaviour <> 'waitforexaust' then auramanager.fchar.EntitySprite.VirtualDeleteAura (self.auramanager.fChar.IDs  , auraname ) ;
      end;
    {$endif rpg_client}
      if Behaviour <> 'waitforexaust' then State:= adead;
     end;
     // il cooldown non è generico quindi lo fa la singola aura, non la classe generica
    end;
end;
procedure TrpgAura.trigger ;
begin
    (* Quando un'aura di tipo trigger si attiva, entra in cooldown *)
    state:=acooldown;

end;
procedure TrpgAura.RenewAuraDuration ( IncrStackN: integer ); (* duration e stack sono  generici comuni*)
begin
   if (stack + IncrStackN ) > MaxStack then begin
    Stack := MaxStack;
    Exit;
   end;
   duration  := MaxDuration;

   if IncrStackN > 0 then begin
     Stack := stack  + IncrStackN;
     Input( msg_stack, IntTostr(IncrStackN));
   end;


end;

(*************************************************************************
         BLESSING OF THE HUMANS      BLESSING OF THE HUMANS     BLESSING OF THE HUMANS
         BLESSING OF THE HUMANS      BLESSING OF THE HUMANS     BLESSING OF THE HUMANS
         BLESSING OF THE HUMANS      BLESSING OF THE HUMANS     BLESSING OF THE HUMANS

(**************************************************************************)
constructor TBlessingOfTheHumans.create( params: string; fromSkill: TRpgActiveSkill )  ;
begin
  inherited;
  category:= 'buff';
  auraName:= 'blessing.of.the.humans';
  Behaviour:= 'onload';
  MaxStack:= 1;
end;
destructor TBlessingOfTheHumans.destroy ;
begin
  inherited;
end;
procedure TBlessingOfTheHumans.Load;
var
tsTmp: Tstringlist;
aCharT: TEntity ;

begin
(*  (*es. masteries +25 health +3%*)
(*a=blessing.of.the.humans,v=25@3,d=300000 *)

  // qui è già stato assegnato nel party o nel radious dal brain.
  // questa è l'applicazione sul singolo target

  if Cancel then Exit;


//  aCharT := FromActiveSkill.Target ;
  aCharT := AuraManager.fChar;

  TsTmp:= Tstringlist.Create ;
  TsTmp.Delimiter := '@';
  TsTmp.DelimitedText := v;

  (* Salvo tutti i dati in entrata per poi ripristinarli nella .DieAndRestore *)
  fhealth := Perc (StrtoFloat(tsTmp[1]), aCharT.Health );

  fMfire := StrtoFloat(tsTmp[0]);
  fmearth := StrtoFloat(tsTmp[0]);
  fmlight :=  StrtoFloat(tsTmp[0]);
  fmphysical := StrtoFloat(tsTmp[0]);
  fmwater := StrtoFloat(tsTmp[0]);
  fmdark := StrtoFloat(tsTmp[0]);
  fmwind := StrtoFloat(tsTmp[0]);

  (* Setto i valori onload *)

  aCharT.Health  := aCharT.Health   + StrtoInt(tsTmp[1]);

  aCharT.mfire := aCharT.mfire + Perc (StrtoFloat(tsTmp[0]), aCharT.mfire);
  aCharT.mearth := aCharT.mearth + Perc (StrtoFloat(tsTmp[0]), aCharT.mearth);
  aCharT.mlight := aCharT.mlight + Perc (StrtoFloat(tsTmp[0]), aCharT.mlight);
  aCharT.mphysical := aCharT.mphysical + Perc (StrtoFloat(tsTmp[0]), aCharT.mphysical);
  aCharT.mwater := aCharT.mwater + Perc (StrtoFloat(tsTmp[0]), aCharT.mwater);
  aCharT.mdark := aCharT.mdark + Perc (StrtoFloat(tsTmp[0]), aCharT.mdark);
  aCharT.mwind := aCharT.mwind + Perc (StrtoFloat(tsTmp[0]), aCharT.mwind);


  TsTmp.Free;
  Initialized:= true;
  State:= aDone;

  inherited;

end;
procedure TBlessingOfTheHumans.DieAndRestore;
var
aChar: TEntity;
begin
  aChar := AuraManager.fChar; // FromActiveSkill.Target;
  // riptistino oldvalue MAI percentuale sempre fisso
  aChar:= FromActiveSkill.Target ;
  aChar.mfire := aChar.mfire - fMfire;
  aChar.mearth := aChar.mearth - fMearth;
  aChar.mlight := aChar.mlight - fMlight;
  aChar.mphysical := aChar.mphysical - fMphysical;
  aChar.mwater := aChar.mwater - fMwater;
  aChar.mdark := aChar.mdark - fMdark;
  aChar.mwind := aChar.mwind - fMwind;

  aChar.Health := aChar.Health -fHealth ;
  inherited;

end;
procedure TBlessingOfTheHumans.Timer(interval: integer);
begin
  inherited; // trpAura setta subito !dead se duration <= 0
  if State = adead then DieAndRestore;
end;
procedure TBlessingOfTheHumans.Input (msg: TmsgManager; value: string );

begin
inherited;

end;

(*************************************************************************
         BLESSING OF THE ELVES      BLESSING OF THE ELVES     BLESSING OF THE ELVES
         BLESSING OF THE ELVES      BLESSING OF THE ELVES     BLESSING OF THE ELVES
         BLESSING OF THE ELVES      BLESSING OF THE ELVES     BLESSING OF THE ELVES

(**************************************************************************)
constructor TBlessingOfTheElves.create( params: string; fromSkill: TRpgActiveSkill )  ;
begin
  inherited;
  category:= 'buff';
  auraName:= 'blessing.of.the.elves';
  Behaviour:= 'onload';
  MaxStack:= 1;
end;
destructor TBlessingOfTheElves.destroy ;
begin
  inherited;
end;
procedure TBlessingOfTheElves.Load;
var
tsTmp: Tstringlist;
aCharT: TEntity ;

begin
(*   es. resistances +25 mana +1%* accuracy +25) *)
(*a=blessing.of.the.elves,v=25@1@25,d=300000 *)

  // qui è già stato assegnato nel party o nel radious dal brain.
  // questa è l'applicazione sul singolo target come sè stessi
  if Cancel then Exit;

//  aCharT := FromActiveSkill.Target;
  aCharT := AuraManager.fChar; // FromActiveSkill.Target;

  TsTmp:= Tstringlist.Create ;
  TsTmp.Delimiter := '@';
  TsTmp.DelimitedText := v;

  (* Salvo tutti i dati in entrata per poi ripristinarli nella .DieAndRestore *)
  fpower := Perc (StrtoFloat(tsTmp[1]), aCharT.power );

  frfire := StrtoFloat(tsTmp[0]);
  frearth := StrtoFloat(tsTmp[0]);
  frlight :=  StrtoFloat(tsTmp[0]);
  frphysical := StrtoFloat(tsTmp[0]);
  frwater := StrtoFloat(tsTmp[0]);
  frdark := StrtoFloat(tsTmp[0]);
  frwind := StrtoFloat(tsTmp[0]);

  faccuracy := StrtoFloat(tsTmp[2]);

  (* Setto i valori onload *)

  aCharT.power := aCharT.power  + StrtoInt(tsTmp[1]);

  aCharT.rfire := aCharT.rfire + Perc (StrtoFloat(tsTmp[0]), aCharT.rfire);
  aCharT.rearth := aCharT.rearth + Perc (StrtoFloat(tsTmp[0]), aCharT.rearth);
  aCharT.rlight := aCharT.rlight + Perc (StrtoFloat(tsTmp[0]), aCharT.rlight);
  aCharT.rphysical := aCharT.rphysical + Perc (StrtoFloat(tsTmp[0]), aCharT.rphysical);
  aCharT.rwater := aCharT.rwater + Perc (StrtoFloat(tsTmp[0]), aCharT.rwater);
  aCharT.rdark := aCharT.rdark + Perc (StrtoFloat(tsTmp[0]), aCharT.rdark);
  aCharT.rwind := aCharT.rwind + Perc (StrtoFloat(tsTmp[0]), aCharT.rwind);

  aCharT.accuracy  := aCharT.accuracy  + StrtoInt(tsTmp[2]);   // innesca il cambio di accuracy a tutte le skill del TEntity

  TsTmp.Free;
  Initialized:= true;
  State:= aDone;
  inherited;

end;
procedure TBlessingOfTheElves.DieAndRestore;
var
aChar: TEntity;
begin
  // riptistino oldvalue MAI percentuale sempre fisso
  aChar := AuraManager.fChar; // FromActiveSkill.Target;
  aChar := FromActiveSkill.Target;
  aChar.rfire := aChar.rfire - frfire;
  aChar.rearth := aChar.rfire - frearth;
  aChar.rlight := aChar.rfire - frlight;
  aChar.rphysical := aChar.rfire - frphysical;
  aChar.rwater := aChar.rfire - frwater;
  aChar.rdark := aChar.rfire - frdark;
  aChar.rwind := aChar.rfire - frwind;

  aChar.power := aChar.power -fpower ;
 // innesca il cambio di accuracy a tutte le skill del TEntity
  aChar.accuracy := aChar.accuracy - fAccuracy;

  inherited;

end;
procedure TBlessingOfTheElves.Timer(interval: integer);
begin
  inherited; // trpAura setta subito !dead se duration <= 0
  if State = adead then DieAndRestore;

end;
procedure TBlessingOfTheElves.Input (msg: TmsgManager; value: string );

begin
inherited;

end;

(*************************************************************************
         BLESSING.OF.FORTUNE       BLESSING.OF.FORTUNE      BLESSING.OF.FORTUNE      BLESSING.OF.FORTUNE
         BLESSING.OF.FORTUNE       BLESSING.OF.FORTUNE      BLESSING.OF.FORTUNE      BLESSING.OF.FORTUNE
         BLESSING.OF.FORTUNE       BLESSING.OF.FORTUNE      BLESSING.OF.FORTUNE      BLESSING.OF.FORTUNE

(*************************************************************************   Fortune^s.Wheel
                                                      addduration,aftercast,blessing.of.fortune,r1|modvalue@,aftercast,blessing.of.fortune,r2  *)
constructor TBlessingOfFortune.create( params: string; fromSkill: TRpgActiveSkill )  ;

//constructor TBlessingOfFortune.create(aChar: TObject; params:string; fromSkill:pRpgSkill; fromChar: TObject) ;
begin
  inherited;
  category:= 'buff';
  auraName:= 'blessing.of.fortune';
  Behaviour:= 'onload';
  MaxStack:= 1;
end;
destructor TBlessingOfFortune.destroy ;
begin
  inherited;
end;
procedure TBlessingOfFortune.Load;
var
apChar2: PEntity;
aCharT: TEntity ;
tsTmp: Tstringlist;
aa:Pointer;

begin
(* es. defense +5% , accuracy +7,  dodge +7 , masteries +9  *)
(* a=blessing.of.fortune,v=5@7@7@9@0@0,d=30000  OPPURE a=blessing.of.fortune,v=5@7@7@9@2@0,d=30000 *)
(* Può contenere un parametro in piu'*)

  // qui è già stato assegnato nel party o nel radious dal brain.
  // questa è l'applicazione sul singolo target come sè stessi
  // Altre skill richiedono di conoscere la health del source ad esempio


//  io di me stesos devo conoscere MA, DEF, ACC e EVA
  //apChar2 := pEntity ( apChar);
//  aCharT := pEntity ( @TEntity(apActiveSkill.aTargetChar ));  //  aChar2:= TEntity(apActiveSkill.aTargetChar);
  if Cancel then Exit;


//  aCharT := FromActiveSkill.Target;
  aCharT := AuraManager.fChar; // FromActiveSkill.Target;

  TsTmp:= Tstringlist.Create ;
  TsTmp.Delimiter := '@';
  TsTmp.DelimitedText := v;

  (* Salvo tutti i dati in entrata per poi ripristinarli nella .DieAndRestore *)
  fDefense := Perc (StrtoFloat(tsTmp[0]), aCharT.defense );
  fAccuracy:= StrtoInt(tsTmp[1]) ;
  fDodge:= StrtoInt(tsTmp[2]) ;

  fMfire := StrtoFloat(tsTmp[3]);
  fmearth := StrtoFloat(tsTmp[3]);
  fmlight :=  StrtoFloat(tsTmp[3]);
  fmphysical := StrtoFloat(tsTmp[3]);
  fmwater := StrtoFloat(tsTmp[3]);
  fmdark := StrtoFloat(tsTmp[3]);
  fmwind := StrtoFloat(tsTmp[3]);

  // |modvalue@,aftercast,blessing.of.fortune,5,r2
  // |modvalue@,aftercast,blessing.of.fortune,6,r2
  finchealing := StrtoFloat(tsTmp[4]);
  fincCritLight := StrtoFloat(tsTmp[5]);

  (* Setto i valori onload *)

  aCharT.defense := aCharT.defense  + fdefense ;//StrtoInt(tsTmp[0]);

  aCharT.accuracy  := aCharT.accuracy + StrtoInt(tsTmp[1]);
  aCharT.dodge   := aCharT.dodge  + StrtoInt(tsTmp[2]);

  aCharT.mfire := aCharT.mfire + Perc (StrtoFloat(tsTmp[3]), aCharT.mfire);      { TODO : fmfire, inutile fare il calcolo 2 volte }
  aCharT.mearth := aCharT.mearth + Perc (StrtoFloat(tsTmp[3]), aCharT.mearth);
  aCharT.mlight := aCharT.mlight + Perc (StrtoFloat(tsTmp[3]), aCharT.mlight);
  aCharT.mphysical := aCharT.mphysical + Perc (StrtoFloat(tsTmp[3]), aCharT.mphysical);
  aCharT.mwater := aCharT.mwater + Perc (StrtoFloat(tsTmp[3]), aCharT.mwater);
  aCharT.mdark := aCharT.mdark + Perc (StrtoFloat(tsTmp[3]), aCharT.mdark);

  aCharT.mwind := aCharT.mwind + Perc (StrtoFloat(tsTmp[3]), aCharT.mwind);

  aCharT.AuraManager.Inchealing  := aCharT.AuraManager.Inchealing + StrtoFloat(tsTmp[4]);
//  aCharT.AuraManager.InchCritLight  := aCharT.AuraManager.Inchealing + StrtoFloat(tsTmp[4]);
  aCharT.SkillManager.SetCritBySchool('light',StrtoFloat(tsTmp[5]) );

  TsTmp.Free;
  Initialized:= true;
  State:= aDone;

  inherited;
//oppure                   aCharSkillP.range:= ModifyPerc(pAura.nv,aCharSkillP.range, reverse);

end;
procedure TBlessingOfFortune.DieAndRestore;
var
aChar: TEntity;
begin
  // riptistino oldvalue MAI percentuale sempre fisso
  aChar := AuraManager.fChar; // FromActiveSkill.Target;
  aChar := FromActiveSkill.Target;
  aChar.mfire := aChar.mfire - fMfire;
  aChar.mearth := aChar.mearth - fMearth;
  aChar.mlight := aChar.mlight - fMlight;
  aChar.mphysical := aChar.mphysical - fMphysical;
  aChar.mwater := aChar.mwater - fMwater;
  aChar.mdark := aChar.mdark - fMdark;
  aChar.mwind := aChar.mwind - fMwind;

  aChar.defense := aChar.defense  -fdefense;

  aChar.accuracy  := aChar.accuracy - fAccuracy;
  aChar.dodge   := aChar.dodge  - fdodge;

// se esiste il parametro aggiunivo Fortune^s.Wheel |modvalue@,aftercast,blessing.of.fortune,r2
  aChar.AuraManager.Inchealing  := aChar.AuraManager.Inchealing  - fincHealing; // al massimo è 0.
  inherited;
end;
procedure TBlessingOfFortune.Timer(interval: integer);
begin
  inherited; // trpAura setta subito !dead se duration <= 0
  if State = adead then DieAndRestore;

  //State:= '!dead';


  // se è un trigger DA FARE
//    if cooldown <=0 then begin
//  quando è finito il cooldown  aChar.ReverseAura (pAura); //if SERVER dentro reverseaura
//      cooldown := maxcooldown;
//    end;



end;
procedure TBlessingOfFortune.Input (msg: TmsgManager; value: string );

begin
inherited;

end;
(*************************************************************************
         BLESSING.OF.TENACITY       BLESSING.OF.TENACITY      BLESSING.OF.TENACITY      BLESSING.OF.TENACITY
         BLESSING.OF.TENACITY       BLESSING.OF.TENACITY      BLESSING.OF.TENACITY      BLESSING.OF.TENACITY
         BLESSING.OF.TENACITY       BLESSING.OF.TENACITY      BLESSING.OF.TENACITY      BLESSING.OF.TENACITY

(*************************************************************************   *)

constructor TBlessingOfTenacity.create( params: string; fromSkill: TRpgActiveSkill )  ;
begin
  inherited;
  category:= 'buff';
  auraName:= 'blessing.of.tenacity';
  Behaviour:= 'onload';
  MaxStack:= 1;
end;
destructor TBlessingOfTenacity.destroy ;
begin
  inherited;
end;
procedure TBlessingOfTenacity.Load;
var
apChar2: pEntity;
aCharT: TEntity ;
aa:Pointer;

begin
(* es. defense +5%  *)
(* a=blessing.of.tenacity,v=5,d=1800000,radious=20  *)

  if Cancel then Exit;

  aCharT := AuraManager.fChar; // FromActiveSkill.Target;


  (* Salvo tutti i dati in entrata per poi ripristinarli nella .DieAndRestore *)
  fDefense := Perc (StrtoFloat(v), aCharT.defense );

  (* Setto i valori onload *)

  aCharT.defense := aCharT.defense  + fdefense;

  Initialized:= true;
  State:= aDone;
  inherited;

end;
procedure TBlessingOfTenacity.DieAndRestore;
var
aChar: TEntity;
begin
  // riptistino oldvalue MAI percentuale sempre fisso
  aChar := AuraManager.fChar; // FromActiveSkill.Target;

  aChar.defense := aChar.defense  -fdefense;
  inherited;

end;
procedure TBlessingOfTenacity.Timer(interval: integer);
begin
  inherited; // trpAura setta subito !dead se duration <= 0
  if State = adead then DieAndRestore;


end;
procedure TBlessingOfTenacity.Input (msg: TmsgManager; value: string );

begin
inherited;

end;
(*************************************************************************
         BLESSING.OF.LIFE       BLESSING.OF.LIFE      BLESSING.OF.LIFE      BLESSING.OF.LIFE
         BLESSING.OF.LIFE       BLESSING.OF.LIFE      BLESSING.OF.LIFE      BLESSING.OF.LIFE
         BLESSING.OF.LIFE       BLESSING.OF.LIFE      BLESSING.OF.LIFE      BLESSING.OF.LIFE

(*************************************************************************   *)

constructor TBlessingOfLife.create( params: string; fromSkill: TRpgActiveSkill )  ;
begin
  inherited;
  category:= 'buff';
  auraName:= 'blessing.of.life';
  Behaviour:= 'onload';
  MaxStack:= 1;
end;
destructor TBlessingOfLife.destroy ;
begin
  inherited;
end;
procedure TBlessingOfLife.Load;
var
apChar2: pEntity;
aCharT: TEntity ;
aa:Pointer;

begin
(* es. health +4.5%  *)
(* a=blessing.of.life,v=3,d=1800000,radious=20  *)

  if Cancel then Exit;

  aCharT := AuraManager.fChar; // FromActiveSkill.Target;


  (* Salvo tutti i dati in entrata per poi ripristinarli nella .DieAndRestore *)
  (* Qui entra un valore come 3+1, cioè una formula. In questo caso usiamo fexpressionparser *)
  FExprParser1 := TExpressionParser.Create;
  FExprParser1.AddExpression ( v );               // 3+1

  fhealth := Perc ( RoundTo (FExprParser1.EvaluateCurrent,-2), aCharT.health );

  (* Setto i valori onload *)

  aCharT.Health := aCharT.health  + fhealth;

  FExprParser1.Free;

  Initialized:= true;
  State:= aDone;
  inherited;

end;
procedure TBlessingOfLife.DieAndRestore;
var
aChar: TEntity;
begin
  // riptistino oldvalue MAI percentuale sempre fisso
  aChar := AuraManager.fChar; // FromActiveSkill.Target;

  aChar.health := aChar.defense  - fhealth;
  inherited;

end;
procedure TBlessingOfLife.Timer(interval: integer);
begin
  inherited; // trpAura setta subito !dead se duration <= 0
  if State = adead then DieAndRestore;


end;
procedure TBlessingOfLife.Input (msg: TmsgManager; value: string );

begin
inherited;

end;

(*************************************************************************
         SD=SchoolDamage       SD=SchoolDamage      SD=SchoolDamage      SD=SchoolDamage
         SD=SchoolDamage       SD=SchoolDamage      SD=SchoolDamage      SD=SchoolDamage
         SD=SchoolDamage       SD=SchoolDamage      SD=SchoolDamage      SD=SchoolDamage

(*************************************************************************)
constructor TSchoolDamage.create( params: string; fromSkill: TRpgActiveSkill )  ;

begin
  inherited;
  category:= 'SD';
  auraName:= 'SD';
  Behaviour:= 'onload';
  MaxStack:= 1;
  Duration:=0;   // se creata da periodic mi entra duration=15000
  MaxDuration:=0;
  Periodic:= false;
  FExprParser1 := TExpressionParser.Create ;
  if AuraManager.ImmunityAll > 0 then Cancel := True;
end;
destructor TSchoolDamage.destroy ;
begin
  FExprParser1.Free;
  inherited;
end;
//apCharT,apCharS: pEntity;
  //apCharT := pEntity ( @TEntity(apActiveSkill.aTargetChar ));
  //apCharS := pEntity ( @TEntity(apActiveSkill.aChar  ));
procedure TSchoolDamage.Load;
var
aCharT,aCharS: TEntity ;
dmg: double;
aa:Pointer;
DiffPerc: Double;
Absorb: Double;
Output:string;
TsTmp: Tstringlist;
Drain: double;
label done;

begin
(* es. 140 danni da fuoco  =    a=SD,v=ma*1.5  *)
(* es. 140 danni da fuoco e cura del 100% del danno =    a=SD,v=ma*1.5@100  *)

  // questa è l'applicazione sul singolo target. L'aura si applica a AuraManager.fChar e non a FromActiveSkill.Target
  // SD richiede di conoscere la Health e le resistances. Eventuali reflectDamage sono stati già calcolati.
  // QUi è richiesto solo verificare absorb della determinata school e sostituire la variabile 'ma'
  // 'v' è già stata caricata da TrpgAura.create

  // devo conoscere le RESISTANCES del TargetChar e le MASTERIES del sourceChar
  if Cancel then goto done;

  (* Prendo i Tcharcater interessati *)
  aCharS := FromActiveSkill.Source;

  aCharT := AuraManager.fChar; // FromActiveSkill.Target;



  if school= 'fire' then begin
    if aCharT.AuraManager.ImmunityFire > 0 then goto done;
    if aCharS.mfire <= 0 then goto done;
    DiffPerc :=  100 - (( aCharT.rfire * 100 ) / aCharS.mfire) + 50;
    Absorb := aCharT.AuraManager.AbsorbFire ;
    FExprParser1.DefineVariable('ma', @aCharS.mfire );
  end
  else if school= 'earth' then begin
    if aCharT.AuraManager.ImmunityEarth > 0  then goto done;
    if aCharS.mearth <= 0 then goto done;
    DiffPerc :=  100 - (( aCharT.rearth * 100 ) / aCharS.mearth) + 50 ;
    Absorb := aCharT.AuraManager.AbsorbEarth ;
    FExprParser1.DefineVariable('ma', @aCharS.mearth );
  end
  else if school= 'light' then begin
    if aCharT.AuraManager.Immunitylight > 0 then goto done;
    if aCharS.mlight <= 0 then goto done;
    DiffPerc :=  100 - (( aCharT.rlight * 100 ) / aCharS.mlight) + 50 ;
    Absorb := aCharT.AuraManager.Absorblight ;
    FExprParser1.DefineVariable('ma', @aCharS.mlight  );
  end
  else if school= 'physical' then begin
    if aCharT.AuraManager.ImmunityPhysical > 0 then goto done;
    if aCharS.mphysical  <= 0 then goto done;
    DiffPerc :=  100 - (( aCharT.rphysical * 100 ) / aCharS.mphysical) + 50 ;
    Absorb := aCharT.AuraManager.AbsorbPhysical ;
    FExprParser1.DefineVariable('ma', @aCharS.mphysical );
  end
  else if school= 'water' then begin
    if aCharT.AuraManager.ImmunityWater > 0 then goto done;
    if aCharS.mwater <= 0 then goto done;
    DiffPerc :=  100 - (( aCharT.rwater * 100 ) / aCharS.mwater) + 50 ;
    Absorb := aCharT.AuraManager.AbsorbWater ;
    FExprParser1.DefineVariable('ma', @aCharS.mwater );
  end
  else if school= 'dark' then begin
    if aCharT.AuraManager.ImmunityDark > 0 then goto done;
    if aCharS.mdark <= 0 then goto done;
    DiffPerc :=  100 - (( aCharT.rdark * 100 ) / aCharS.mdark) + 50 ;
    Absorb := aCharT.AuraManager.AbsorbDark ;
    FExprParser1.DefineVariable('ma', @aCharS.mdark );
  end
  else if school= 'wind' then begin
    if aCharT.AuraManager.ImmunityWind > 0 then goto done;
    if aCharS.mWind <= 0 then goto done;
    DiffPerc :=  100 - (( aCharT.rwind * 100 ) / aCharS.mWind) + 50 ;
    Absorb := aCharT.AuraManager.AbsorbWind ;
    FExprParser1.DefineVariable('ma', @aCharS.mwind );
  end;
     { TODO : nature  }

  Drain:=0;
  TsTmp:= Tstringlist.Create ;
  TsTmp.Delimiter := '@';
  TsTmp.DelimitedText := v;
  if TsTmp.Count > 1 then begin
    v:= tsTmp[0];
  end;


  FExprParser1.ClearExpressions;
  FExprParser1.AddExpression(v);
  dmg := RoundTo (FExprParser1.EvaluateCurrent,-2);
  if TsTmp.Count > 1 then begin
    Drain :=  (StrToInt(tstmp[1])  * dmg ) / 100 ;
  end;
  TsTmp.Free;

// di base un uguale valore di resistances dimezza la masteries
//                                             la diff non è 8-7=1 ma la percentuale di differenza
//                                             16 8 = + 50%         + 50
//                                             16 13  + 9%          + 50
//                                             16 18  -12%          + 50
//                                             a questo valore va aggiunto 50

  dmg:= ( DiffPerc * dmg) / 100;
  if dmg < 0 then Dmg:=0;


  (* Absorb generico di qualunque school *)
  if aCharT.AuraManager.AbsorbAll > 0 then begin
    if Assigned( AuraManager.fchar.Brain.OnCharAbsorbDamage  )  then AuraManager.fchar.Brain.OnCharAbsorbDamage ( AuraManager.fchar, TrpgAura(Self), fromActiveskill, Trunc(dmg) );
    aCharT.AuraManager.AbSorbAll := aCharT.AuraManager.AbsorbAll - dmg;

  end;

  if aCharT.AuraManager.AbsorbAll < 0 then begin
    Dmg:= Abs(aCharT.AuraManager.AbsorbAll);     // il resto dei danni da sottrarre
    aCharT.AuraManager.AbsorbAll:=0;             // lo metto a 0 perchè altri shield potrebbero sommarsi e devono farlo a partire dal valore attuale
    Output:= 'absorb.shield';
    aCharT.AuraManager.Broadcast(msg_death, false,TrpgAura(Self), Output ) ; // broadcast source a tutte le auree hit. dall'aura risale alla skill
  end;

  (* Absorb realtiva alla school specifica *)
  if Absorb > 0 then begin
    AbSorb := Absorb - dmg;
    if Assigned( AuraManager.fchar.Brain.OnCharAbsorbDamage  )  then AuraManager.fchar.Brain.OnCharAbsorbDamage ( AuraManager.fchar, TrpgAura(Self), fromActiveskill, Trunc(absorb) );
  end;

  if Absorb < 0 then begin
    Dmg:= Abs(Absorb);     // il resto dei danni da sottrarre
  end;
//  if periodic  then asm int 3 end;

  aCharS.SkillManager.Broadcast(msg_hit, Periodic, TrpgAura(Self), Output ) ; // broadcast source a tutte le Skill hit. Attiva cdrage che decrementa tutti i cd
  aCharT.SkillManager.Broadcast(msg_hitted, Periodic, TrpgAura(Self), Output ) ; // broadcast source a tutte le Skill hitted. Attiva cdrage che decrementa tutti i cd

  aCharS.AuraManager.Broadcast(msg_hit, Periodic, TrpgAura(Self), Output ) ; // broadcast source a tutte le auree hit. dall'aura risale alla skill
  aCharT.AuraManager.Broadcast(msg_hitted, Periodic, TrpgAura(Self), Output ) ; // broadcast source a tutte le auree hit. dall'aura risale alla skill

  (* Non devo salvare i dati in entrata per poi ripristinarli nella .DieAndRestore *)

  (* Setto i valori onload della health del Target *)

    aCharT.CH := aCharT.CH - dmg;  // chiama la SetCH
  FromActiveSkill.Target := AuraManager.fChar; // IMPORTANTE per aoe

  if dmg > 0 then begin
    (* Drain effettivo della health *)

    if Drain > 0 then begin
      aCharS.CH := aCharS.CH + Drain ;
      // importante passare aCharT sotto
      if Assigned( AuraManager.fchar.Brain.OnCharRecoverhealth  )  then AuraManager.fchar.Brain.OnCharRecoverhealth ( aCharT, TrpgAura(Self), fromActiveskill, Trunc(dmg) );

    end;

    aCharS.SkillManager.Broadcast(msg_damagedone, Periodic, TrpgAura(Self), Output ) ; // broadcast source a tutte le Skill damaged
    aCharS.AuraManager.Broadcast(msg_damageDone, Periodic, TrpgAura(Self), Output ) ; // broadcast source a tutte le auree damaged

    aCharT.AuraManager.Broadcast(msg_damaged, Periodic, TrpgAura(Self), Output ) ; // broadcast target tutte le auree damaged
    aCharT.SkillManager.Broadcast(msg_damaged, Periodic, TrpgAura(Self), Output ) ; // broadcast target tutte le skill damaged
 // il broadcast informa tutte le auree del drophealth per attivare eventuali auree trigger. Tipicamente il warrior quando
 // scende sotto una certa percentuale di maxhealth attiva delle resistenze
 // Output può essere usato anch per un jump veloce all'inizio della procedure per replicare il danno
  if Assigned( AuraManager.fchar.Brain.OnCharDrophealth  )  then AuraManager.fchar.Brain.OnCharDrophealth ( AuraManager.fchar, TrpgAura(Self), fromActiveskill, Trunc(dmg) );
  end;
Done:
  Initialized:= true;
  State:= aDone;
//  inherited;
end;
procedure TSchoolDamage.DieAndRestore;
var
aChar2: TEntity;
begin
//  inherited;
end;
procedure TSchoolDamage.Timer(interval: integer);
begin
  inherited; // trpgAura setta subito adead se duration <= 0
  if State = adead then DieAndRestore;

  //State:= '!dead';


end;
procedure TSchoolDamage.Input (msg: TmsgManager; value: string );

begin
//
end;

(*************************************************************************
         THeal       THeal      THeal      THeal
         THeal       THeal      THeal      THeal
         THeal       THeal      THeal      THeal

(*************************************************************************)
constructor THeal.create( params: string; fromSkill: TRpgActiveSkill )  ;

begin
  inherited;
  category:= 'heal';
  auraName:= 'HEAL';
  Behaviour:= 'onload';
  MaxStack:= 1;
  FExprParser1 := TExpressionParser.Create ;
end;
destructor THeal.destroy ;
begin
  FExprParser1.Free;
  inherited;
end;
procedure THeal.Load;
var
aCharS: TEntity ;
heal: double;
aa:Pointer;
DiffPerc: Double;
Absorb: Double;
pSkill: PRpgSkill;
output:string;
begin
(* es. Cura di 30  *)
(* a=HEAL,v=4*ma/100 *)

  // questa è l'applicazione sul singolo target.
  // Heal richiede di conoscere la Health. Qui è richiesto solo di sostituire la variabile 'ma'
  // Potrebbero esserci bonus o malus in healing. Vedere incHealing che funziona in percentuale.
  // 'v' è già stata caricata da TrpgAura.create
  if Cancel then Exit;


  aCharS := FromActiveSkill.Source;
//  aCharT := FromActiveSkill.Target;



  FExprParser1.DefineVariable('ma', @aCharS.mlight  );              // light = masteries healing
  FExprParser1.DefineVariable('maxhealth', @aCharS.health );        // health
  FExprParser1.ClearExpressions;
  FExprParser1.AddExpression(v);
  Heal := RoundTo (FExprParser1.EvaluateCurrent,-2);
  Heal :=  Heal + (( heal * AuraManager.Inchealing  ) / 100);

  { TODO : qui si può inserire un aura che asorbe healing in entrata }

  (* Non devo salvare i dati in entrata per poi ripristinarli nella .DieAndRestore *)

  (* Setto i valori onload della health del Target *)

  AuraManager.fChar.CH := AuraManager.fChar.CH  + Heal;  // chiama la SetCH

  Initialized:= true;
  State:= aDone;

  (* Adesso che ho curato guardo afteheal del SourceChar. Per esempio posso applicare natural protection    *)
  (* Che incrementa del 5% per 10 secondi outhealing. Lo faccio qui e non di seguito al lancio della skill (tryexecuteSkill) *)
  (* es. a=natural.protection,v=5,d=10000 *)
  (* il valore 5 era r1 che è già stato calcolato in loadtalents, quindi ora devo solo caricare l'aura  *)

  (* Devo processare tutta la lista in afterHeal *)
  //if apActiveSkill.pSkill.afterHeal // è per forza del charS
  //aCharT.AuraManager.AddRpgAura(  TrpgAura (TnaturalProtection) );
  { TODO : se ha veramente curato? }
  aCharS.SkillManager.Broadcast(msg_healDone, false,TrpgAura(Self), Output ) ; // broadcast source a tutte le Skill hit. dall'aura risale alla skill
  AuraManager.fchar.SkillManager.Broadcast(msg_healed, false,TrpgAura(Self), Output ) ; // broadcast target a tutte le Skill hitted. dall'aura risale alla skill

  aCharS.AuraManager.Broadcast(msg_healDone, false,TrpgAura(Self), Output ) ; // broadcast source a tutte le Skill hit. dall'aura risale alla skill
  AuraManager.Broadcast(msg_healed, false,TrpgAura(Self), Output ) ; // broadcast target a tutte le Skill hitted. dall'aura risale alla skill
 // il broadcast informa tutte le auree del drophealth per attivare eventuali auree trigger. Tipicamente il warrior quando
 // scende sotto una certa percentuale di maxhealth attiva delle resistenze
 // Output può essere usato anch per un jump veloce all'inizio della procedure per replicare il danno
  FromActiveSkill.Target := AuraManager.fChar; // IMPORTANTE per aoe
  inherited;

end;
procedure THeal.DieAndRestore;
begin
//
end;
procedure THeal.Timer(interval: integer);
begin
  inherited; // trpgAura setta subito adead se duration <= 0
  if State = adead then DieAndRestore;

  //State:= '!dead';


end;
procedure THeal.Input (msg: TmsgManager; value: string );
begin
//
end;
(*************************************************************************
         TNaturalProtection       TNaturalProtection      TNaturalProtection      TNaturalProtection
         TNaturalProtection       TNaturalProtection      TNaturalProtection      TNaturalProtection
         TNaturalProtection       TNaturalProtection      TNaturalProtection      TNaturalProtection

(*************************************************************************)
constructor TNaturalProtection.create( params: string; fromSkill: TRpgActiveSkill )  ;

begin
  inherited;
  category:= 'outhealing';    // la duration (10 secondi) è già settata da trpgaura
  auraName:= 'natural.protection';      // v è la percentuale da aggiungere a inHealing
  Behaviour:= 'onload';
  MaxStack:= 1;
  FExprParser1 := TExpressionParser.Create ;
  nv          := StrToFloat (v);

end;
destructor TNaturalProtection.destroy ;
begin
  FExprParser1.Free;
  inherited;
end;
procedure TNaturalProtection.Load;
var
aCharT,aCharS: TEntity ;
NaturalProtection: double;
aa:Pointer;
DiffPerc: Double;
Absorb: Double;

begin
(* es. aggiunge 5% a outhealing per 10 secondi  *)
(* ,a=natural.protection,v=r1,d=10000 *)

  // questa è l'applicazione sul singolo target.
  // NaturalProtection è un effetto Dummy. Al termine, rimette a posto outhealing
  // 'v' è già stata caricata da TrpgAura.create

  if Cancel then Exit;

  //aCharS:= TEntity(apActiveSkill.aChar);                        // versione non pointer
//  aCharT := FromActiveSkill.Target;
  aCharT := AuraManager.fChar; // FromActiveSkill.Target;
  aCharT.AuraManager.outhealing := aCharT.AuraManager.outhealing + nv;



  (* Nv è l'unico datao da salvare per poi ripristinarlo nella .DieAndRestore *)

  (* Setto i valori onload della NaturalProtectionth del Target *)


  Initialized:= true;
  State:= aDone;
  inherited;

end;
procedure TNaturalProtection.DieAndRestore;
var
aCharT: TEntity;
begin
  aCharT := AuraManager.fChar; // FromActiveSkill.Target;
//  aCharT := FromActiveSkill.Target;
  aCharT.AuraManager.outhealing :=  aCharT.AuraManager.Outhealing - nv;
  inherited;

end;
procedure TNaturalProtection.Timer(interval: integer);
begin
  inherited; // trpgAura setta subito adead se duration <= 0
  if State = adead then DieAndRestore;

  //State:= '!dead';


end;
procedure TNaturalProtection.Input (msg: TmsgManager; value: string );
begin
//
end;

(*************************************************************************
         TGodsGift       TGodsGift      TGodsGift      TGodsGift
         TGodsGift       TGodsGift      TGodsGift      TGodsGift
         TGodsGift       TGodsGift      TGodsGift      TGodsGift

(*************************************************************************)
constructor TGodsGift.create( params: string; fromSkill: TRpgActiveSkill )  ;

begin
  inherited;
  category:= 'inchealing';    // la duration (10 secondi) è già settata da trpgaura
  auraName:= 'gods^gif';      // v è la percentuale da aggiungere a incHealing
  Behaviour:= 'onload';
  MaxStack:= 1;
  FExprParser1 := TExpressionParser.Create ;
  nv          := StrToFloat (v);

end;
destructor TGodsGift.destroy ;
begin
  FExprParser1.Free;
  inherited;
end;
procedure TGodsGift.Load;
var
aCharT,aCharS: TEntity ;
NaturalProtection: double;
aa:Pointer;
DiffPerc: Double;
Absorb: Double;

begin
(* es. aggiunge 5% a outhealing per 10 secondi  *)
(* ,a=natural.protection,v=r1,d=10000 *)

  // questa è l'applicazione sul singolo target.
  // NaturalProtection è un effetto Dummy. Al termine, rimette a posto outhealing
  // 'v' è già stata caricata da TrpgAura.create
  if Cancel then Exit;


  //aCharS:= TEntity(apActiveSkill.aChar);                        // versione non pointer
  aCharT := AuraManager.fChar; // FromActiveSkill.Target;
//  aCharT := FromActiveSkill.Target;
  aCharT.AuraManager.Inchealing := aCharT.AuraManager.Inchealing + nv;



  (* Nv è l'unico dato da salvare per poi ripristinarlo nella .DieAndRestore *)

  (* Setto i valori onload della NaturalProtectionth del Target *)


  Initialized:= true;
  State:= aDone;
  inherited;

end;
procedure TGodsGift.DieAndRestore;
begin
  AuraManager.inchealing :=  AuraManager.inchealing - nv;
  inherited;

end;
procedure TGodsGift.Timer(interval: integer);
begin
  inherited; // trpgAura setta subito adead se duration <= 0
  if State = adead then DieAndRestore;

  //State:= '!dead';


end;
procedure TGodsGift.Input (msg: TmsgManager; value: string );
begin
//
end;
(*************************************************************************
         BLESSING OF THE KINDRED      BLESSING OF THE KINDRED     BLESSING OF THE KINDRED
         BLESSING OF THE KINDRED      BLESSING OF THE KINDRED     BLESSING OF THE KINDRED
         BLESSING OF THE KINDRED      BLESSING OF THE KINDRED     BLESSING OF THE KINDRED

(**************************************************************************)
constructor TBlessingOfTheKindred.create( params: string; fromSkill: TRpgActiveSkill )  ;
begin
  inherited;
  category:= 'buff';
  auraName:= 'blessing.of.the.kindred';
  Behaviour:= 'onload';
  MaxStack:= 1;
  nv := StrToFloat(v);
end;
destructor TBlessingOfTheKindred.destroy ;
begin
  inherited;
end;
procedure TBlessingOfTheKindred.Load;
var
aCharT: TEntity ;

begin
  (*es. health +8% *)
  (* a=blessing.of.the.kindred,v=8,d=300000 *)
  if Cancel then Exit;

//  aCharT := FromActiveSkill.Target;
  aCharT := AuraManager.fChar; // FromActiveSkill.Target;


  (* Salvo tutti i dati in entrata per poi ripristinarli nella .DieAndRestore *)
  fhealth := Perc (nv, aCharT.Health ); // nv è stato calcolato nella create

  (* Setto i valori onload *)

  aCharT.Health  := aCharT.Health   + fhealth ;

  Initialized:= true;
  State:= aDone;
  inherited;

end;
procedure TBlessingOfTheKindred.DieAndRestore;
var
aChar: TEntity;
begin
  // riptistino oldvalue MAI percentuale sempre fisso
  aChar := AuraManager.fChar; // FromActiveSkill.Target;

  aChar.Health := aChar.Health -fHealth ;
  inherited;

end;
procedure TBlessingOfTheKindred.Timer(interval: integer);
begin
  inherited; // trpAura setta subito !dead se duration <= 0
  if State = adead then DieAndRestore;
end;
procedure TBlessingOfTheKindred.Input (msg: TmsgManager; value: string );

begin
inherited;

end;
(*************************************************************************
         DEBUFF ALL MATERIES      DEBUFF ALL MATERIES     DEBUFF ALL MATERIES
         DEBUFF ALL MATERIES      DEBUFF ALL MATERIES     DEBUFF ALL MATERIES
         DEBUFF ALL MATERIES      DEBUFF ALL MATERIES     DEBUFF ALL MATERIES

(**************************************************************************)
constructor TDebuffAllMasteries.create( params: string; fromSkill: TRpgActiveSkill )  ;
begin
  inherited;
  category:= 'singlecurse';
  auraName:= 'debuff.all.masteries';
  Behaviour:= 'onload';
  MaxStack:= 1;
  nv := StrToInt(v);
  AuraShow:= true;
end;
destructor TDebuffAllMasteries.destroy ;
begin
  inherited;
end;
procedure TDebuffAllMasteries.Load;
var
aCharT: TEntity ;
Rest: Double;

begin
 (*  a=DebuffAllMasteries,v=-2,d=20000 *)

  // qui è già stato assegnato nel party o nel radious dal brain.
  // questa è l'applicazione sul singolo target come sè stessi

  if Cancel then Exit;


//  aCharT := FromActiveSkill.Target;
  aCharT := AuraManager.fChar; // FromActiveSkill.Target;

  (* Salvo tutti i dati in entrata per poi ripristinarli nella .DieAndRestore *)

  fMfire := abs(nv);
  fmearth := abs(nv);
  fmlight :=  abs(nv);
  fmphysical := abs(nv);
  fmwater := abs(nv);
  fmdark := abs(nv);
  fmwind := abs(nv);


  (* Setto i valori onload *)

  aCharT.mfire := aCharT.mfire  -fmfire;
  if aCharT.mfire < 0 then begin
    Rest  := Abs(aCharT.mfire);
    aCharT.mfire := 0;
    fmfire := fmfire - Rest;
  end;

  aCharT.mearth := aCharT.mearth  -fmearth;
  if aCharT.mearth < 0 then begin
    Rest  := Abs(aCharT.mearth);
    aCharT.mearth := 0;
    fmearth := fmearth - Rest;
  end;

  aCharT.mlight := aCharT.mlight  -fmlight;
  if aCharT.mlight < 0 then begin
    Rest  := Abs(aCharT.mlight);
    aCharT.mlight := 0;
    fmlight := fmlight - Rest;
  end;

  aCharT.mphysical := aCharT.mphysical  -fmphysical;
  if aCharT.mphysical < 0 then begin
    Rest  := Abs(aCharT.mphysical);
    aCharT.mphysical := 0;
    fmphysical := fmphysical - Rest;
  end;

  aCharT.mwater := aCharT.mwater  -fmwater;
  if aCharT.mwater < 0 then begin
    Rest  := Abs(aCharT.mwater);
    aCharT.mwater := 0;
    fmwater := fmwater - Rest;
  end;

  aCharT.mdark := aCharT.mdark  -fmdark;
  if aCharT.mdark < 0 then begin
    Rest  := Abs(aCharT.mdark);
    aCharT.mdark := 0;
    fmdark := fmdark - Rest;
  end;

  aCharT.mwind := aCharT.mwind  -fmwind;
  if aCharT.mwind < 0 then begin
    Rest  := Abs(aCharT.mwind);
    aCharT.mwind := 0;
    fmwind := fmwind - Rest;
  end;




  Initialized:= true;
  State:= aDone;
  inherited;

end;
procedure TDebuffAllMasteries.DieAndRestore;
var
aChar: TEntity;
begin
  // riptistino oldvalue MAI percentuale sempre fisso
  aChar := AuraManager.fChar; // FromActiveSkill.Target;

  aChar.mfire := aChar.mfire +fMfire;
  aChar.mearth := aChar.mearth +fMearth;
  aChar.mlight := aChar.mlight +fMlight;
  aChar.mphysical := aChar.mphysical +fMphysical;
  aChar.mwater := aChar.mwater +fMwater;
  aChar.mdark := aChar.mdark +fMdark;
  aChar.mwind := aChar.mwind +fMwind;

  inherited;

end;
procedure TDebuffAllMasteries.Timer(interval: integer);
begin
  inherited; // trpAura setta subito !dead se duration <= 0
  if State = adead then DieAndRestore;
end;
procedure TDebuffAllMasteries.Input (msg: TmsgManager; value: string );

begin
inherited;

end;

(*************************************************************************
         DAMNATION      DAMNATION     DAMNATION
         DAMNATION      DAMNATION     DAMNATION
         DAMNATION      DAMNATION     DAMNATION

(**************************************************************************)
constructor TDamnation.create( params: string; fromSkill: TRpgActiveSkill )  ;
begin
  inherited;
  category:= 'singlecurse';
  auraName:= 'damnation';
  Behaviour:= 'onload';
  MaxStack:= 1;
end;
destructor TDamnation.destroy ;
begin
  inherited;
end;
procedure TDamnation.Load;
var
tsTmp: Tstringlist;
aCharT: TEntity ;
Rest: Double;

begin
 (*es. attack -2% attack and Masteries and resistances -30 per 20 secondi *)
 (*  a=damnation,v=-2@-30,d=20000 *)

  // qui è già stato assegnato nel party o nel radious dal brain.
  // questa è l'applicazione sul singolo target come sè stessi

  if Cancel then Exit;


//  aCharT := FromActiveSkill.Target;
  aCharT := AuraManager.fChar; // FromActiveSkill.Target;

  TsTmp:= Tstringlist.Create ;
  TsTmp.Delimiter := '@';
  TsTmp.DelimitedText := v;

  (* Salvo tutti i dati in entrata per poi ripristinarli nella .DieAndRestore *)
  fattack := Abs(  Perc (Abs(StrtoFloat(tsTmp[0])), aCharT.attack ));

  fMfire := abs(StrtoFloat(tsTmp[1]));
  fmearth := abs(StrtoFloat(tsTmp[1]));
  fmlight :=  abs(StrtoFloat(tsTmp[1]));
  fmphysical := abs(StrtoFloat(tsTmp[1]));
  fmwater := abs(StrtoFloat(tsTmp[1]));
  fmdark := abs(StrtoFloat(tsTmp[1]));
  fmwind := abs(StrtoFloat(tsTmp[1]));

  frfire := abs(StrtoFloat(tsTmp[1]));
  frearth := abs(StrtoFloat(tsTmp[1]));
  frlight :=  abs(StrtoFloat(tsTmp[1]));
  frphysical := abs(StrtoFloat(tsTmp[1]));
  frwater := abs(StrtoFloat(tsTmp[1]));
  frdark := abs(StrtoFloat(tsTmp[1]));
  frwind := abs(StrtoFloat(tsTmp[1]));

  (* Setto i valori onload *)

  aCharT.attack  := aCharT.attack  -fattack;
  if aCharT.attack < 0 then begin
    Rest  := Abs(aCharT.attack);
    aCharT.attack := 0;
    fattack := fattack - Rest;
  end;

  aCharT.mfire := aCharT.mfire  -fmfire;
  if aCharT.mfire < 0 then begin
    Rest  := Abs(aCharT.mfire);
    aCharT.mfire := 0;
    fmfire := fmfire - Rest;
  end;

  aCharT.mearth := aCharT.mearth  -fmearth;
  if aCharT.mearth < 0 then begin
    Rest  := Abs(aCharT.mearth);
    aCharT.mearth := 0;
    fmearth := fmearth - Rest;
  end;

  aCharT.mlight := aCharT.mlight  -fmlight;
  if aCharT.mlight < 0 then begin
    Rest  := Abs(aCharT.mlight);
    aCharT.mlight := 0;
    fmlight := fmlight - Rest;
  end;

  aCharT.mphysical := aCharT.mphysical  -fmphysical;
  if aCharT.mphysical < 0 then begin
    Rest  := Abs(aCharT.mphysical);
    aCharT.mphysical := 0;
    fmphysical := fmphysical - Rest;
  end;

  aCharT.mwater := aCharT.mwater  -fmwater;
  if aCharT.mwater < 0 then begin
    Rest  := Abs(aCharT.mwater);
    aCharT.mwater := 0;
    fmwater := fmwater - Rest;
  end;

  aCharT.mdark := aCharT.mdark  -fmdark;
  if aCharT.mdark < 0 then begin
    Rest  := Abs(aCharT.mdark);
    aCharT.mdark := 0;
    fmdark := fmdark - Rest;
  end;

  aCharT.mwind := aCharT.mwind  -fmwind;
  if aCharT.mwind < 0 then begin
    Rest  := Abs(aCharT.mwind);
    aCharT.mwind := 0;
    fmwind := fmwind - Rest;
  end;




  aCharT.rfire := aCharT.rfire  -frfire;
  if aCharT.rfire < 0 then begin
    Rest  := Abs(aCharT.rfire);
    aCharT.rfire := 0;
    frfire := frfire - Rest;
  end;

  aCharT.rearth := aCharT.rearth  -frearth;
  if aCharT.rearth < 0 then begin
    Rest  := Abs(aCharT.rearth);
    aCharT.rearth := 0;
    frearth := frearth - Rest;
  end;

  aCharT.rlight := aCharT.rlight  -frlight;
  if aCharT.rlight < 0 then begin
    Rest  := Abs(aCharT.rlight);
    aCharT.rlight := 0;
    frlight := frlight - Rest;
  end;

  aCharT.rphysical := aCharT.rphysical  -frphysical;
  if aCharT.rphysical < 0 then begin
    Rest  := Abs(aCharT.rphysical);
    aCharT.rphysical := 0;
    frphysical := frphysical - Rest;
  end;

  aCharT.rwater := aCharT.rwater  -frwater;
  if aCharT.rwater < 0 then begin
    Rest  := Abs(aCharT.rwater);
    aCharT.rwater := 0;
    frwater := frwater - Rest;
  end;

  aCharT.rdark := aCharT.rdark  -frdark;
  if aCharT.rdark < 0 then begin
    Rest  := Abs(aCharT.rdark);
    aCharT.rdark := 0;
    frdark := frdark - Rest;
  end;

  aCharT.rwind := aCharT.rwind  -frwind;
  if aCharT.rwind < 0 then begin
    Rest  := Abs(aCharT.rwind);
    aCharT.rwind := 0;
    frwind := frwind - Rest;
  end;


  TsTmp.Free;
  Initialized:= true;
  State:= aDone;
  inherited;

end;
procedure TDamnation.DieAndRestore;
var
aChar: TEntity;
begin
  // riptistino oldvalue MAI percentuale sempre fisso
  aChar := AuraManager.fChar; // FromActiveSkill.Target;

  aChar.mfire := aChar.mfire +fMfire;
  aChar.mearth := aChar.mearth +fMearth;
  aChar.mlight := aChar.mlight +fMlight;
  aChar.mphysical := aChar.mphysical +fMphysical;
  aChar.mwater := aChar.mwater +fMwater;
  aChar.mdark := aChar.mdark +fMdark;
  aChar.mwind := aChar.mwind +fMwind;

  aChar.rfire := aChar.rfire + frfire;
  aChar.rearth := aChar.rearth + frearth;
  aChar.rlight := aChar.rlight + frlight;
  aChar.rphysical := aChar.rphysical + frphysical;
  aChar.rwater := aChar.rwater + frwater;
  aChar.rdark := aChar.rdark + frdark;
  aChar.rwind := aChar.rwind + frwind;

  aChar.attack := aChar.attack + fattack ;
  inherited;

end;
procedure TDamnation.Timer(interval: integer);
begin
  inherited; // trpAura setta subito !dead se duration <= 0
  if State = adead then DieAndRestore;
end;
procedure TDamnation.Input (msg: TmsgManager; value: string );

begin
inherited;

end;
procedure TRpgBrain.StopAllCasting (aChar: TEntity; IgnoreMove: boolean );
var
i: Integer;
begin
 { TODO : oppure jump. skill tree= movement??? }
  for i := 0 to lstActiveSkills.Count -1  do begin
    if lstActiveSkills.Items [i].fChar = aChar then begin // solo di quel TEntity
      if (lstActiveSkills.Items [i].Skill.SkillName = 'move')  and ( IgnoreMove = False) then begin
        if IgnoreMove then begin
          lstActiveSkills.Items [i].state := sDead;
          if Assigned(FOnCharAbortSkill)  then  FOnCharAbortSkill (aChar, lstActiveSkills.Items [i]);
        end
        else begin
          lstActiveSkills.Items [i].state := sDead;
          if Assigned(FOnCharAbortSkill)  then  FOnCharAbortSkill (aChar, lstActiveSkills.Items [i]);
          if Assigned(FOnCharStopMove)  then  FOnCharStopMove (aChar, aChar.Cx, aChar.Cy);   { TODO : bug: oldcx e oldcy fanno parte del TEntity }
        end;

      end
      else if (lstActiveSkills.Items [i].Skill.SkillName <> 'move')  then begin
          if Assigned(FOnCharAbortSkill)  then  FOnCharAbortSkill (aChar, lstActiveSkills.Items [i]);
          lstActiveSkills.Items [i].state := sDead;
      end;

    end;

  end;
end;
(*************************************************************************
        SILENCED     SILENCED    SILENCED
        SILENCED     SILENCED    SILENCED
        SILENCED     SILENCED    SILENCED

(**************************************************************************)
constructor Tsilenced.create( params: string; fromSkill: TRpgActiveSkill )  ;
begin
  inherited;
  category:= 'debuff';
  auraName:= 'silenced';
  Behaviour:= 'onload';
  MaxStack:= 1;
  AuraShow:= true;

  if Auramanager.Immunitysilence > 0 then Cancel:= True;

end;
destructor Tsilenced.destroy ;
begin
  inherited;
end;
procedure Tsilenced.Load;
var
aCharT: TEntity ;

begin
  (*es. silence 7000ms *)
  (* a=silenced,d=3000 *)
  if Cancel then Exit;

  if not ((AuraManager.immunityALl > 0) or (AuraManager.immunitysilence >0 )) then begin


    inc(AuraManager.Silenced );



    Initialized:= true;
    State:= aDone;
    inherited;

  end;
end;
procedure Tsilenced.DieAndRestore;
begin
  // riptistino oldvalue MAI percentuale sempre fisso

    Dec (AuraManager.Silenced );
  inherited;

end;
procedure Tsilenced.Timer(interval: integer);
begin
  inherited; // trpAura setta subito !dead se duration <= 0
  if State = adead then DieAndRestore;
end;
procedure Tsilenced.Input (msg: TmsgManager; value: string );

begin
inherited;

end;
(*************************************************************************
        ABSORB.SHIELD     ABSORB.SHIELD    ABSORB.SHIELD
        ABSORB.SHIELD     ABSORB.SHIELD    ABSORB.SHIELD
        ABSORB.SHIELD     ABSORB.SHIELD    ABSORB.SHIELD

(**************************************************************************)
constructor TAbsorbShield.create( params: string; fromSkill: TRpgActiveSkill )  ;
begin
  inherited;
  Timed       := false;  // NON viene processata la duration
  category:= 'buff';
  auraName:= 'absorb.shield';
  Behaviour:= 'waitforexaust';
  MaxStack:= 1;
  AuraShow:= true;

end;
destructor TAbsorbShield.destroy ;
begin
  inherited;
end;
procedure TAbsorbShield.Load;
var
aCharT: TEntity ;

begin
  (* a=AbsorbShield,v=ma*0.25 *)
  if Cancel then Exit;

  FExprParser1 := TExpressionParser.Create;
  FExprParser1.DefineVariable('ma', @auramanager.fchar.mlight  );
  FExprParser1.AddExpression(v);

  AuraManager.AbsorbAll := RoundTo (FExprParser1.EvaluateCurrent,-2);
  FExprParser1.Free;



    Initialized:= true;
    State:= aDone;
    inherited;

end;
procedure TAbsorbShield.DieAndRestore;
begin
  // riptistino oldvalue MAI percentuale sempre fisso

  inherited;  // <--- rimuove il bmp

end;
procedure TAbsorbShield.Timer(interval: integer);
begin
  inherited; // trpAura setta subito !dead se duration <= 0
end;
procedure TAbsorbShield.Input (msg: TmsgManager; value: string );

begin
  if (msg = msg_death) and (value = auraname) then begin   //  <--- proviene da SchoolDamage.load se è terminato qualsiasi scudo
    State:= aDead;                                         // cadono tutti gli scudi. non è possibile sapere il dettaglio per ora
    DieAndRestore;   // <--- rimuove il bmp vedi sopra
  end;

  inherited;

end;
(*************************************************************************
        TRIGGER DIVINE PUNISHMENT     TRIGGER DIVINE PUNISHMENT
        TRIGGER DIVINE PUNISHMENT     TRIGGER DIVINE PUNISHMENT
        TRIGGER DIVINE PUNISHMENT     TRIGGER DIVINE PUNISHMENT

(**************************************************************************)
constructor TTriggerDivinePunishment.create( params: string; fromTalent: pRpgTalentDB; manager: TAuraManager)  ;
var
TsTmp: tstringlist;
begin
  inherited;
  Timed       := false;  // NON viene processata la duration

  category:= 'buff';
  auraName:= 'trigger.attack.speed';
  Behaviour:= 'trigger';
  MaxStack:= 1;

  Persistent:= true;
  //AuraShow:= false; // diventa true l'aura singola speed.attack
  Active:= false;

  TsTmp:= Tstringlist.Create ;
  TsTmp.Delimiter := '@';
  TsTmp.DelimitedText := v;
  LowHealth :=  StrToFloat(tstmp[0]);
  AttackSpeed :=  StrToFloat(tstmp[1]);
  TsTmp.Free;

end;
destructor TTriggerDivinePunishment.destroy ;
begin
  inherited;
end;
procedure TTriggerDivinePunishment.Load;

begin
  (* a=TriggerDivinePunishment,v=30@50  sotto il 30% di health, incrementa deccd di 50% *)



  Initialized:= true;
  State:= aDone;
  inherited;

end;
procedure TTriggerDivinePunishment.DieAndRestore;
begin
  // riptistino oldvalue MAI percentuale sempre fisso

  inherited;  // <--- rimuove il bmp

end;
procedure TTriggerDivinePunishment.Timer(interval: integer);
begin
  inherited; // trpAura setta subito !dead se duration <= 0
end;
procedure TTriggerDivinePunishment.Input (msg: TmsgManager; value: string );
var
perc: double;
aGenericAura: TrpgAura;
aDivinePunishment: TDivinePunishment;
Neighbours: Tobjectlist<TEntity>;
i: integer;
output: string;
begin                                   { TODO : or Hit }

  if (msg = msg_Damaged) then begin   //  <--- proviene da SchoolDamage.load se è terminato qualsiasi scudo o da heal

    if Not Active then begin

        Active:= true;                                                // attackspeed è figlia di TriggerDivinePunishment
        aGenericAura :=  AuraManager.IsAuraLoaded  ( 'divine.punishment' ); // Non si sommano gli effetti di attack.speed
        if aGenericAura <> nil  then agenericAura.Input (msg_stack,'1') else
        begin
          aDivinePunishment:= TDivinePunishment.Create('a=divine.punishment,v='+ Inttostr(trunc(nv))  , self, AuraManager );
          auramanager.lstAura.Add(aDivinePunishment);
        end;

   end;

  end;


  inherited;

end;

(*************************************************************************
        TRIGGER ATTACK SPEED     TRIGGER ATTACK SPEED    TRIGGER ATTACK SPEED
        TRIGGER ATTACK SPEED     TRIGGER ATTACK SPEED    TRIGGER ATTACK SPEED
        TRIGGER ATTACK SPEED     TRIGGER ATTACK SPEED    TRIGGER ATTACK SPEED

(**************************************************************************)
constructor TTriggerAttackSpeed.create( params: string; fromTalent: pRpgTalentDB; manager: TAuraManager)  ;
var
TsTmp: tstringlist;
begin
  inherited;
  Timed       := false;  // NON viene processata la duration

  category:= 'buff';
  auraName:= 'trigger.attack.speed';
  Behaviour:= 'trigger';
  MaxStack:= 1;

  Persistent:= true;
  //AuraShow:= false; // diventa true l'aura singola speed.attack
  Active:= false;

  TsTmp:= Tstringlist.Create ;
  TsTmp.Delimiter := '@';
  TsTmp.DelimitedText := v;
  LowHealth :=  StrToFloat(tstmp[0]);
  AttackSpeed :=  StrToFloat(tstmp[1]);
  TsTmp.Free;

end;
destructor TTriggerAttackSpeed.destroy ;
begin
  inherited;
end;
procedure TTriggerAttackSpeed.Load;

begin
  (* a=TriggerAttackSpeed,v=30@50  sotto il 30% di health, incrementa deccd di 50% *)



  Initialized:= true;
  State:= aDone;
  inherited;

end;
procedure TTriggerAttackSpeed.DieAndRestore;
begin
  // riptistino oldvalue MAI percentuale sempre fisso

  inherited;  // <--- rimuove il bmp

end;
procedure TTriggerAttackSpeed.Timer(interval: integer);
begin
  inherited; // trpAura setta subito !dead se duration <= 0
end;
procedure TTriggerAttackSpeed.Input (msg: TmsgManager; value: string );
var
perc: double;
aGenericAura: TrpgAura;
aAttackSpeed: TAttackSpeed;
Neighbours: Tobjectlist<TEntity>;
i: integer;
output: string;
begin
  perc := (AuraManager.fchar.ch * 100) / AuraManager.fchar.health ;

  if (msg = msg_Damaged) then begin   //  <--- proviene da SchoolDamage.load se è terminato qualsiasi scudo o da heal

    if Not Active then begin

      if perc <= Lowhealth then begin
        Active:= true;                                                // attackspeed è figlia di triggerattackspeed
        aGenericAura :=  AuraManager.IsAuraLoaded  ( 'attackspeed' ); // Non si sommano gli effetti di attack.speed
        if aGenericAura <> nil  then exit else
        begin

          perc := (AuraManager.fchar.ch * 100) / AuraManager.fchar.health ;
          nv:= (AttackSpeed * AuraManager.fchar.Brain.RpgOptions.fthread_interval) / 100;
          aAttackSpeed:= TAttackSpeed.Create('a=attackspeed,v='+ Inttostr(trunc(nv))  , self, AuraManager );
          auramanager.lstAura.Add(aAttackSpeed);
        end;

        if radious > 0 then begin

          (* qui non sono stati fatti i check per i target che vengono fatti con cancel in create *)
          Neighbours:= TObjectList<TEntity>.Create(false); // molta attenzione, è false per evitare il delete
          //problema immunitàImmunity per sD o frezze sotto pray   per cui vanno fatte nel create
          AuraManager.fchar.Brain.getneighbours (auramanager.fchar , radious, Friendly, false, Neighbours );
                //problema immunitàImmunity per sD o frezze sotto pray   per cui vanno fatte nel create

          for I := 0 to Neighbours.Count -1 do begin
            if Neighbours[i]= AuraManager.fChar then Continue;

              aAttackSpeed:= TAttackSpeed.Create('a=attackspeed,v='+Inttostr(trunc(nv))  , self, Neighbours[i].AuraManager  );  // passo il manager corretto
              Neighbours[i].AuraManager.AddDirectAura (aAttackSpeed);
            end;
          Neighbours.Free;

        end;
      end;
   end;

  end

  else if (msg = msg_healed) then begin
    if  Active then begin
      if perc > Lowhealth then begin
        Active:= false;
        Output:= 'attackspeed';
        AuraManager.Broadcast(msg_death, false, TrpgAura(self), output );
      end;
    end;
  end;

  inherited;

end;

(*************************************************************************
         ATTACK SPEED      ATTACK SPEED     ATTACK SPEED
         ATTACK SPEED      ATTACK SPEED     ATTACK SPEED
         ATTACK SPEED      ATTACK SPEED     ATTACK SPEED

(**************************************************************************)
constructor TAttackSpeed.create( params: string; fromAura: TRpgAura; Manager: TAuraManager )  ;
begin
  inherited;
  Timed       := false;  // NON viene processata la duration
  category:= 'buff';
  auraName:= 'attack.speed';
  Behaviour:= 'onload';
  MaxStack:= 1;
  nv := StrToFloat(v);
  AuraShow:=true;
  Persistent:=true;
end;
destructor TAttackSpeed.destroy ;
begin
  inherited;
end;
procedure TAttackSpeed.Load;
var
aCharT: TEntity ;

begin
  (*es. Speed -25% *)
  (* a=AttackSpeed,v=2500,d=3000,applychance=50 *)
  if Cancel then Exit;





    (* Salvo tutti i dati in entrata per poi ripristinarli nella .DieAndRestore *)
    fdeccd := trunc(nv);

    (* Setto i valori onload *)

    AuraManager.fChar.SkillManager.decCd := AuraManager.fChar.SkillManager.decCd + fdeccd;

    Initialized:= true;
    State:= aDone;
    inherited;

end;
procedure TAttackSpeed.DieAndRestore;
begin
  // riptistino oldvalue MAI percentuale sempre fisso

  AuraManager.fChar.SkillManager.decCd := AuraManager.fChar.SkillManager.decCd - fdeccd;
  inherited;

end;
procedure TAttackSpeed.Timer(interval: integer);
begin
  inherited; // trpAura setta subito !dead se duration <= 0
  if State = adead then DieAndRestore;
end;
procedure TAttackSpeed.Input (msg: TmsgManager; value: string );

begin

  if (msg = msg_death) and (value = auraname) then begin   //  <--- proviene da trigger.attack.speed e dice che lowhelath è tornata sopra il 30%
    State:= aDead;
    DieAndRestore;   // <--- rimuove il bmp vedi sopra
  end;

  inherited;

end;

(*************************************************************************
         SLOWED      SLOWED     SLOWED
         SLOWED      SLOWED     SLOWED
         SLOWED      SLOWED     SLOWED

(**************************************************************************)
constructor TSlowed.create( params: string; fromSkill: TRpgActiveSkill )  ;
begin
  inherited;
  category:= 'buff';
  auraName:= 'slowed';
  Behaviour:= 'onload';
  MaxStack:= 1;
  nv := StrToFloat(v);
  if Auramanager.ImmunitySlowed > 0 then Cancel:= True;

end;
destructor TSlowed.destroy ;
begin
  inherited;
end;
procedure TSlowed.Load;
var
aCharT: TEntity ;

begin
  (*es. Speed -25% *)
  (* a=Slowed,v=25,d=3000,applychance=50 *)
  if Cancel then Exit;

  if not ((AuraManager.immunityALl > 0) or (AuraManager.immunitySlowed > 0)) then begin


    //  aCharT := FromActiveSkill.Target;
    aCharT := AuraManager.fChar; // FromActiveSkill.Target;


    (* Salvo tutti i dati in entrata per poi ripristinarli nella .DieAndRestore *)
    fcs := Perc (nv, aCharT.speed ); // nv è stato calcolato nella create

    (* Setto i valori onload *)

    aCharT.cs  := aCharT.cs   - fcs ;

    Initialized:= true;
    State:= aDone;
    inherited;

  end;
end;
procedure TSlowed.DieAndRestore;
begin
  // riptistino oldvalue MAI percentuale sempre fisso

  auramanager.fchar.CS := auramanager.fchar.cs + fcs;
  inherited;

end;
procedure TSlowed.Timer(interval: integer);
begin
  inherited; // trpAura setta subito !dead se duration <= 0
  if State = adead then DieAndRestore;
end;
procedure TSlowed.Input (msg: TmsgManager; value: string );

begin
inherited;

end;
(*************************************************************************
         REVIVE      REVIVE     REVIVE
         REVIVE      REVIVE     REVIVE
         REVIVE      REVIVE     REVIVE

(**************************************************************************)
constructor TRevive.create( params: string; fromSkill: TRpgActiveSkill )  ;
begin
  inherited;
  category:= 'buff';
  auraName:= 'revive';
  Behaviour:= 'onload';
  MaxStack:= 1;
  nv := StrToFloat(v);
end;
destructor TRevive.destroy ;
begin
  inherited;
end;
procedure TRevive.Load;
var
aCharT: TEntity ;

begin
  (*es. Revive col 10% di health *)
  (* a=revive,v=10 *)
  if Cancel then Exit;

  aCharT := AuraManager.fChar; // FromActiveSkill.Target;


  (* Salvo tutti i dati in entrata per poi ripristinarli nella .DieAndRestore *)

  (* Setto i valori onload *)

  aCharT.State := 'cidle'; // non passo dalla setCH
  aCharT.Fcs := ( StrToFloat(v) * aCharT.Health ) / 100;
  Initialized:= true;
  State:= aDone;
  inherited;

end;
procedure TRevive.DieAndRestore;
begin
  // riptistino oldvalue MAI percentuale sempre fisso
  inherited;


end;
procedure TRevive.Timer(interval: integer);
begin
  inherited; // trpAura setta subito !dead se duration <= 0
  if State = adead then DieAndRestore;
end;
procedure TRevive.Input (msg: TmsgManager; value: string );

begin
inherited;

end;
(*************************************************************************
         IMMUNITY      IMMUNITY     IMMUNITY
         IMMUNITY      IMMUNITY     IMMUNITY
         IMMUNITY      IMMUNITY     IMMUNITY

(**************************************************************************)
constructor TImmunity.create( params: string; fromSkill: TRpgActiveSkill )  ;
begin
(*es. a=immunity,v=fire,d=4000 *)
(* a=immunity,v=slowed,d=4000 *)
  inherited;
  category:= 'buff';
  auraName:= 'immunity';
  Behaviour:= 'onload';
  MaxStack:= 1;

  fImmunityStun:=0;
  fImmunitySilence:=0;
  fImmunityDisarm:=0;
  fImmunitySlowed:=0;
  fImmunityAll:=0;
  fImmunityFire:=0;
  fImmunityearth:=0;
  fImmunitylight:=0;
  fImmunityphysical:=0;
  fImmunitywater:=0;
  fImmunitydark:=0;
  fImmunitywind:=0;
end;
destructor TImmunity.destroy ;
begin
  inherited;
end;
procedure TImmunity.Load;
var
ts: TStringList;
i: integer;
begin
(*es. a=immunity,v=fire,d=4000 *)
(* a=immunity,v=slowed@earth,d=4000 *)
  if Cancel then Exit;         { TODO : settare state aDead }

  ts:= Tstringlist.Create ; ts.StrictDelimiter := True; ts.Delimiter := '@';
  ts.DelimitedText := v;

  (* Salvo tutti i dati in entrata per poi ripristinarli nella .DieAndRestore *)
  for I := 0 to ts.Count -1 do begin

    if ts[i] = 'stun' then  inc(fImmunityStun);
    if ts[i] = 'silence' then  inc(fImmunitySilence );
    if ts[i] = 'disarm' then inc( fImmunityDisarm );
    if ts[i] = 'slowed' then  inc(fImmunitySlowed);
    if ts[i] = 'all' then  inc(fImmunityAll);
    if ts[i] = 'fire' then   inc(fImmunityFire);
    if ts[i] = 'earth' then   inc(fImmunityearth);
    if ts[i] = 'light' then    inc(fImmunitylight);
    if ts[i] = 'physical' then    inc(fImmunityphysical);
    if ts[i] = 'water' then    inc(fImmunitywater);
    if ts[i] = 'dark' then    inc(fImmunitydark);
    if ts[i] = 'wind' then    inc(fImmunitywind);

  end;

  ts.Free;

  (* Setto i valori onload *)
    AuraManager.ImmunityStun := fImmunityStun + AuraManager.ImmunityStun ;
    AuraManager.ImmunitySilence := fImmunitySilence + AuraManager.ImmunitySilence ;
    AuraManager.ImmunityDisarm := fImmunityDisarm + AuraManager.ImmunityDisarm ;
    AuraManager.ImmunitySlowed := fImmunitySlowed + AuraManager.ImmunitySlowed ;
    AuraManager.ImmunityAll := fImmunityAll + AuraManager.ImmunityAll ;
    AuraManager.ImmunityFire := fImmunityFire + AuraManager.ImmunityFire ;
    AuraManager.ImmunityEarth := fImmunityEarth + AuraManager.ImmunityEarth ;
    AuraManager.ImmunityLight := fImmunityLight + AuraManager.ImmunityLight ;
    AuraManager.ImmunityPhysical := fImmunityPhysical + AuraManager.ImmunityPhysical ;
    AuraManager.ImmunityWater := fImmunityWater + AuraManager.ImmunityWater ;
    AuraManager.ImmunityDark := fImmunityDark + AuraManager.ImmunityDark ;
    AuraManager.ImmunityWind := fImmunityWind + AuraManager.ImmunityWind ;

(*
    AuraManager.ImmunityStun := fImmunityStun or AuraManager.ImmunityStun ;
    AuraManager.ImmunitySilence := fImmunitySilence or AuraManager.ImmunitySilence ;
    AuraManager.ImmunityDisarm := fImmunityDisarm or AuraManager.ImmunityDisarm ;
    AuraManager.ImmunitySlowed := fImmunitySlowed or AuraManager.ImmunitySlowed ;
    AuraManager.ImmunityAll := fImmunityAll or AuraManager.ImmunityAll ;
    AuraManager.ImmunityFire := fImmunityFire or AuraManager.ImmunityFire ;
    AuraManager.ImmunityEarth := fImmunityEarth or AuraManager.ImmunityEarth ;
    AuraManager.ImmunityLight := fImmunityLight or AuraManager.ImmunityLight ;
    AuraManager.ImmunityPhysical := fImmunityPhysical or AuraManager.ImmunityPhysical ;
    AuraManager.ImmunityWater := fImmunityWater or AuraManager.ImmunityWater ;
    AuraManager.ImmunityDark := fImmunityDark or AuraManager.ImmunityDark ;
    AuraManager.ImmunityWind := fImmunityWind or AuraManager.ImmunityWind ;

*)
  (* Non Setto le auree realtive Dead. Quelle auree quando agiscono troveranno l'immunità *)

  Initialized:= true;
  State:= aDone;
  inherited;

end;
procedure TImmunity.DieAndRestore;
begin
  // riptistino oldvalue MAI percentuale sempre fisso
    AuraManager.ImmunityStun :=  AuraManager.ImmunityStun -fImmunityStun;
    AuraManager.ImmunitySilence := AuraManager.ImmunitySilence -fImmunitySilence ;
    AuraManager.ImmunityDisarm :=  AuraManager.ImmunityDisarm -fImmunityDisarm ;
    AuraManager.ImmunitySlowed := AuraManager.ImmunitySlowed - fImmunitySlowed;
    AuraManager.ImmunityAll :=  AuraManager.ImmunityAll -fImmunityAll;
    AuraManager.ImmunityFire := AuraManager.ImmunityFire -fImmunityFire;
    AuraManager.ImmunityEarth :=  AuraManager.ImmunityEarth -fImmunityEarth;
    AuraManager.ImmunityLight :=  AuraManager.ImmunityLight -fImmunityLight;
    AuraManager.ImmunityPhysical := AuraManager.ImmunityPhysical -fImmunityPhysical;
    AuraManager.ImmunityWater :=  AuraManager.ImmunityWater -fImmunityWater;
    AuraManager.ImmunityDark :=  AuraManager.ImmunityDark -fImmunityDark;
    AuraManager.ImmunityWind :=  AuraManager.ImmunityWind -fImmunityWind;
                   { TODO : fare le properties }
    (* Mentre immunity era attiva qualche silenced potrebbe essere morto di suo e avere fatto -1 *)
    if AuraManager.ImmunityStun < 0 then AuraManager.ImmunityStun :=0;
    if AuraManager.ImmunitySilence < 0 then AuraManager.ImmunitySilence :=0;
    if AuraManager.ImmunityDisarm < 0 then AuraManager.ImmunityDisarm :=0;
    if AuraManager.ImmunitySlowed < 0 then AuraManager.ImmunitySlowed :=0;
    if AuraManager.ImmunityAll < 0 then AuraManager.ImmunityAll :=0;
    if AuraManager.ImmunityFire < 0 then AuraManager.ImmunityFire :=0;
    if AuraManager.ImmunityEarth < 0 then AuraManager.ImmunityEarth :=0;
    if AuraManager.ImmunityLight < 0 then AuraManager.ImmunityLight :=0;
    if AuraManager.ImmunityPhysical < 0 then AuraManager.ImmunityPhysical :=0;
    if AuraManager.ImmunityWater < 0 then AuraManager.ImmunityWater :=0;
    if AuraManager.ImmunityDark < 0 then AuraManager.ImmunityDark :=0;
    if AuraManager.ImmunityWind < 0 then AuraManager.ImmunityWind :=0;

(*
    AuraManager.ImmunityStun := fImmunityStun xor AuraManager.ImmunityStun ;
    AuraManager.ImmunitySilence := fImmunitySilence xor AuraManager.ImmunitySilence ;
    AuraManager.ImmunityDisarm := fImmunityDisarm xor AuraManager.ImmunityDisarm ;
    AuraManager.ImmunitySlowed := fImmunitySlowed xor AuraManager.ImmunitySlowed ;
    AuraManager.ImmunityAll := fImmunityAll xor AuraManager.ImmunityAll ;
    AuraManager.ImmunityFire := fImmunityFire xor AuraManager.ImmunityFire ;
    AuraManager.ImmunityEarth := fImmunityEarth xor AuraManager.ImmunityEarth ;
    AuraManager.ImmunityLight := fImmunityLight xor AuraManager.ImmunityLight ;
    AuraManager.ImmunityPhysical := fImmunityPhysical xor AuraManager.ImmunityPhysical ;
    AuraManager.ImmunityWater := fImmunityWater xor AuraManager.ImmunityWater ;
    AuraManager.ImmunityDark := fImmunityDark xor AuraManager.ImmunityDark ;
    AuraManager.ImmunityWind := fImmunityWind xor AuraManager.ImmunityWind ;

*)  inherited;

end;
procedure TImmunity.Timer(interval: integer);
begin
  inherited; // trpAura setta subito !dead se duration <= 0
  if State = adead then DieAndRestore;
end;
procedure TImmunity.Input (msg: TmsgManager; value: string );

begin
inherited;

end;

(*************************************************************************
         FREE      FREE     FREE
         FREE      FREE     FREE
         FREE      FREE     FREE

(**************************************************************************)
constructor TFree.create( params: string; fromSkill: TRpgActiveSkill )  ;
begin
(*es. a=Free,v=fire,d=4000 *)
(* a=Free,v=slowed,d=4000 *)
  inherited;
  category:= 'buff';
  auraName:= 'free';
  Behaviour:= 'onload';
  MaxStack:= 1;

end;
destructor TFree.destroy ;
begin
  inherited;
end;
procedure TFree.Load;
var
ts: TStringList;
i: integer;
begin
(*es. a=Free,v=fire,d=4000 *)
(* a=Free,v=slowed@earth,d=4000 *)
  if Cancel then Exit;

  ts:= Tstringlist.Create ; ts.StrictDelimiter := True; ts.Delimiter := '@';
  ts.DelimitedText := v;

  (* Non devo salvare nulla. *)

  (* Setto i valori onload *)

  for I := 0 to ts.Count -1 do begin

    if ts[i] = 'all' then  begin
      AuraManager.fChar.AuraManager.Stunned := 0;
      AuraManager.fChar.AuraManager.Silenced := 0;
      AuraManager.fChar.AuraManager.Disarmed := 0;
      AuraManager.fChar.AuraManager.Slowed := 0;
    end;

    if ts[i] = 'stun' then  AuraManager.fChar.AuraManager.Stunned := 0;
    if ts[i] = 'silence' then  AuraManager.fChar.AuraManager.Silenced := 0;
    if ts[i] = 'disarm' then  AuraManager.fChar.AuraManager.Disarmed := 0;
    if ts[i] = 'slowed' then  AuraManager.fChar.AuraManager.Slowed := 0;

  end;

  ts.Free;

  Initialized:= true;
  State:= aDone;
  inherited;

end;
procedure TFree.DieAndRestore;
begin
  // riptistino oldvalue MAI percentuale sempre fisso
//  inherited;


end;
procedure TFree.Timer(interval: integer);
begin
  inherited; // trpAura setta subito !dead se duration <= 0
  if State = adead then DieAndRestore;
end;
procedure TFree.Input (msg: TmsgManager; value: string );

begin
inherited;

end;
(*************************************************************************
         PRAY      PRAY     PRAY
         PRAY      PRAY     PRAY
         PRAY      PRAY     PRAY

(**************************************************************************)
constructor TPray.create( params: string; fromSkill: TRpgActiveSkill )  ;
begin
(*es. pray,v=25 *)
(* +25% CP non deve superare power *)
  inherited;
  category:= 'buff';
  auraName:= 'pray';
  Behaviour:= 'onload';
  MaxStack:= 1;
  FExprParser1 := TExpressionParser.Create ;

end;
destructor TPray.destroy ;
begin
  FExprParser1.Free;
  inherited;
end;
procedure TPray.Load;
begin
(*es. a=pray,v=maxpower*0.25 *)
  if Cancel then Exit;


  (* Non devo salvare nulla. *)

  (* Setto i valori onload *)
  FExprParser1.DefineVariable('maxpower', @AuraManager.fChar.fpower );
  FExprParser1.ClearExpressions;
  FExprParser1.AddExpression(v);

  (* Non devo salvare nulla *)

  (* Setto i valori onload della CP del Target *)

  AuraManager.fChar.CP := AuraManager.fChar.CP  + RoundTo (FExprParser1.EvaluateCurrent,-2);;  // chiama la SetCP


  Initialized:= true;
  State:= aDone;
  inherited;

end;
procedure TPray.DieAndRestore;
begin
  // riptistino oldvalue MAI percentuale sempre fisso


end;
procedure TPray.Timer(interval: integer);
begin
  inherited; // trpAura setta subito !dead se duration <= 0
  if State = adead then DieAndRestore;
end;
procedure TPray.Input (msg: TmsgManager; value: string );

begin
inherited;

end;
(*************************************************************************
         DRAINPOWER      DRAINPOWER     DRAINPOWER
         DRAINPOWER      DRAINPOWER     DRAINPOWER
         DRAINPOWER      DRAINPOWER     DRAINPOWER

(**************************************************************************)
constructor TDrainPower.create( params: string; fromSkill: TRpgActiveSkill )  ;
begin
(* a=drainpower,v=ma*2,applychance=25 *)
(* +il power guafagnato non deve superare il maxpower, quindi uso setCP *)
  inherited;
  category:= '';
  auraName:= 'drainpower';
  Behaviour:= 'onload';
  MaxStack:= 1;
  FExprParser1 := TExpressionParser.Create ;

end;
destructor TDrainPower.destroy ;
begin
  FExprParser1.Free;
  inherited;
end;
procedure TDrainPower.Load;
var
tmpCP: double;
Drained,MaxDrained: double;
begin
(* a=drainpower,v=ma*2,applychance=25 *)
  if Cancel then Exit;


  (* Non devo salvare nulla. *)

  (* Setto i valori onload *)
  // devo controllare che quel valore id Power sia disponibile sul target, altrimenti sottraggo fino a 0.
  FExprParser1.DefineVariable('ma', @AuraManager.fChar.fpower );
  FExprParser1.ClearExpressions;
  FExprParser1.AddExpression(v);

  (* Non devo salvare nulla *)

  (* Setto i valori onload della CP del Target *)

  // il Source deve ricevere la quantità rubata effettiva quindi la devo calcolare
  MaxDrained := RoundTo (FExprParser1.EvaluateCurrent,-2);
  tmpCP := AuraManager.fChar.CP  - MaxDrained;
  if tmpCP < 0 then begin
    Drained:= AuraManager.fChar.CP - Abs(tmpCP);     // ottengo il power effettivamente drained
  end;
  // Setto il target
  AuraManager.fChar.CP := AuraManager.fChar.CP - Drained;

  // Setto il Source
  FromActiveSkill.Source.CP :=FromActiveSkill.Source.CP + Drained; // la SetCP si occupa di non sforare fpower


  Initialized:= true;
  State:= aDone;
  inherited;

end;
procedure TDrainPower.DieAndRestore;
begin
  // riptistino oldvalue MAI percentuale sempre fisso


end;
procedure TDrainPower.Timer(interval: integer);
begin
  inherited; // trpAura setta subito !dead se duration <= 0
  if State = adead then DieAndRestore;
end;
procedure TDrainPower.Input (msg: TmsgManager; value: string );

begin
inherited;

end;
(*************************************************************************
         LIGHT OF HEALING      LIGHT OF HEALING     LIGHT OF HEALING
         LIGHT OF HEALING      LIGHT OF HEALING     LIGHT OF HEALING
         LIGHT OF HEALING      LIGHT OF HEALING     LIGHT OF HEALING

(**************************************************************************)
constructor TLightOfHealing.create( params: string; fromSkill: TRpgActiveSkill )  ;
begin
(* es. cura di 700 e per 6 secondi ogni 2 secondi cura di 700 *)
(*a=light.of.healing,v=ma,d=6000  2% crit chance*)
  inherited;
  category:= 'pheal';
  auraName:= 'light.of.healing';
  Behaviour:= 'tick';
  MaxStack:= 1;
  FExprParser1 := TExpressionParser.Create ;

end;
destructor TLightofHealing.destroy ;
begin
  FExprParser1.Free;
  inherited;
end;
procedure TLightOfHealing.Load;
var
Heal: double;
begin

  if Cancel then Exit;


  (* Non devo salvare nulla. *)

  (* Setto i valori onload *)
  FExprParser1.DefineVariable('ma', @FromActiveSkill.Source.fmlight   );
  FExprParser1.ClearExpressions;
  FExprParser1.AddExpression(v);

  Heal := RoundTo (FExprParser1.EvaluateCurrent,-2);
  Heal :=  Heal + (( heal *  AuraManager.Inchealing  ) / 100); // l'outgoing è calcolato al momento della creazione

  { TODO : qui si può inserire un aura che asorbe healing in entrata e usare l'outgoing del source in tempio reale }

  (* Non devo salvare i dati in entrata per poi ripristinarli nella .DieAndRestore *)

  (* Setto i valori onload della health del Target *)

  AuraManager.fChar.CH := AuraManager.fChar.CH  + Heal;  // chiama la SetCH


  Initialized:= true;
  State:= aActive;
  inherited;

end;
procedure TLightOfHealing.onTick;     { TODO : qui e sotto 2% crit chance }
var
Heal: double;
begin

  FExprParser1.DefineVariable('ma', @FromActiveSkill.Source.fmlight  );
  FExprParser1.ClearExpressions;
  FExprParser1.AddExpression(v);

  Heal := RoundTo (FExprParser1.EvaluateCurrent,-2);
  Heal :=  Heal + (( heal *  AuraManager.Inchealing  ) / 100);

  AuraManager.fChar.CH := AuraManager.fChar.CH  + Heal;  // chiama la SetCH

end;
procedure TLightOfHealing.DieAndRestore;
begin
  // riptistino oldvalue MAI percentuale sempre fisso
  inherited;

end;
procedure TLightOfHealing.Timer(interval: integer);
begin
  inherited; // trpAura setta subito !dead se duration <= 0
  if State = adead then DieAndRestore;
end;
procedure TLightOfHealing.Input (msg: TmsgManager; value: string );

begin
inherited;

end;
(*************************************************************************
         SHADOW.PAIN      SHADOW.PAIN     SHADOW.PAIN
         SHADOW.PAIN      SHADOW.PAIN     SHADOW.PAIN
         SHADOW.PAIN      SHADOW.PAIN     SHADOW.PAIN

(**************************************************************************)
constructor TShadowPain.create( params: string; fromSkill: TRpgActiveSkill )  ;
begin
(* es. cura di 700 e per 6 secondi ogni 2 secondi cura di 700 *)
(*a=light.of.healing,v=ma,d=6000  2% crit chance*)
  inherited;
  category:= 'PSD';
  auraName:= 'shadow.pain';
  Behaviour:= 'tick';
  MaxStack:= 1;
  FExprParser1 := TExpressionParser.Create ;
  AuraShow:= true;
end;
destructor TShadowPain.destroy ;
begin
  FExprParser1.Free;
  inherited;
end;
procedure TShadowPain.Load;
var
ASD: TSchoolDamage;

begin

  if Cancel then Exit;

  (* Non devo salvare nulla. *)

  (* Setto i valori onload *)
  (* Ad ogni tick genero una SD*)
  ASD:= Tschooldamage.create( fparams, fromActiveSkill);  // passo la activeskill che ha generato il periodic
  ASD.Periodic := true;
  AuraManager.AddDirectAura(ASD);

  { TODO : qui si può inserire un aura che asorbe healing in entrata e usare l'outgoing del source in tempio reale }

  (* Non devo salvare i dati in entrata per poi ripristinarli nella .DieAndRestore *)

  (* Setto i valori onload della health del Target *)


  Initialized:= true;
  State:= aActive;
  inherited;

end;
procedure TShadowPain.onTick;     { TODO : qui e sotto 2% crit chance }
var
ASD: TSchoolDamage;
begin
  (* Ad ogni tick genero una SD*)
  ASD:= Tschooldamage.create( fparams, fromActiveSkill) ; // passo la activeskill che ha generato il periodic
  ASD.periodic:= true;
  AuraManager.AddDirectAura(ASD);

end;
procedure TShadowPain.DieAndRestore;
begin
  // riptistino oldvalue MAI percentuale sempre fisso
  inherited;

end;
procedure TShadowPain.Timer(interval: integer);
begin
  inherited; // trpAura setta subito !dead se duration <= 0
  if State = adead then DieAndRestore;
end;
procedure TShadowPain.Input (msg: TmsgManager; value: string );

begin
inherited;

end;
(*************************************************************************
         DIVINE LIGHT      DIVINE LIGHT     DIVINE LIGHT
         DIVINE LIGHT      DIVINE LIGHT     DIVINE LIGHT
         DIVINE LIGHT      DIVINE LIGHT     DIVINE LIGHT

(**************************************************************************)
constructor TDivineLight.create( params: string; fromSkill: TRpgActiveSkill )  ;
begin
(* es. l'ultimo tick cura per il doppio *)
(*a=divine.light,v=ma*0.7,d=4000,tick=1000*)
  inherited;
  category:= 'pheal';
  auraName:= 'divine.light';
  Behaviour:= 'tick';
  MaxStack:= 1;
  FExprParser1 := TExpressionParser.Create ;

end;
destructor TDivineLight.destroy ;
begin
  FExprParser1.Free;

  inherited;
end;
procedure TDivineLight.Load;
var
Heal: double;
begin

  if Cancel then Exit;

  (* Non devo salvare nulla. *)

  (* Setto i valori onload *)
  FExprParser1.DefineVariable('ma', @FromActiveSkill.Source.fmlight  );
  FExprParser1.ClearExpressions;
  FExprParser1.AddExpression(v);

  Heal := RoundTo (FExprParser1.EvaluateCurrent,-2);
  Heal :=  Heal + (( heal *  AuraManager.Inchealing  ) / 100); // l'outgoing è calcolato al momento della creazione

  { TODO : qui si può inserire un aura che asorbe healing in entrata e usare l'outgoing del source in tempio reale }

  (* Non devo salvare i dati in entrata per poi ripristinarli nella .DieAndRestore *)

  (* Setto i valori onload della health del Target *)

  AuraManager.fChar.CH := AuraManager.fChar.CH  + Heal;  // chiama la SetCH


  Initialized:= true;
  State:= aActive;
  inherited;

end;
procedure TDivineLight.onTick;     { l'ultimo Tick cura del doppio }
var
Heal: double;
begin

  FExprParser1.DefineVariable('ma', @FromActiveSkill.Source.fmlight  );
  FExprParser1.ClearExpressions;
  FExprParser1.AddExpression(v);

  Heal := RoundTo (FExprParser1.EvaluateCurrent,-2);
  Heal :=  Heal + (( heal *  AuraManager.Inchealing  ) / 100);

  if Abs ( duration  - MaxDuration  ) <= Tick then begin // ultimo Tick
    Heal := Heal * 2;            //.. l'ultimo non passa perchè muore prima
  end;


  AuraManager.fChar.CH := AuraManager.fChar.CH  + Heal;  // chiama la SetCH

end;
procedure TDivineLight.DieAndRestore;
begin
  // riptistino oldvalue MAI percentuale sempre fisso
  inherited;

end;
procedure TDivineLight.Timer(interval: integer);
begin
  inherited; // trpAura setta subito !dead se duration <= 0
  if State = adead then DieAndRestore;
end;
procedure TDivineLight.Input (msg: TmsgManager; value: string );

begin
inherited;

end;

(*************************************************************************
         DIVINE PUNISHMENT     DIVINE PUNISHMENT    DIVINE PUNISHMENT
         DIVINE PUNISHMENT     DIVINE PUNISHMENT    DIVINE PUNISHMENT
         DIVINE PUNISHMENT     DIVINE PUNISHMENT    DIVINE PUNISHMENT

(**************************************************************************)
constructor TDivinePunishment.create(params: string; fromAura: TRpgAura;  Manager: TAuraManager)  ;   // l'aura viene  creata da un'altra aura
begin
  inherited;
  category:= 'singleblessing';
  auraName:= 'divine.punishment';
  Behaviour:= 'onload';
  MaxStack:= 5;
end;
destructor TDivinePunishment.destroy ;
begin
  inherited;
end;
procedure TDivinePunishment.Load;
var
OldValue: double;

begin
 (*es. attack -11 resistenze light per 15 secondi *)
 (*  a=divine.punishment,v=11,d=r1 *)

  // qui è già stato assegnato nel party o nel radious dal brain.
  // questa è l'applicazione sul singolo target come sè stessi

  if Cancel then Exit;

  (* Salvo tutti i dati in entrata per poi ripristinarli nella .DieAndRestore *)
//    ...si somma e si risomma
  OldValue:= frLight;
  frlight := ( StrtoFloat(v) * Stack);

  (* Setto i valori onload *)

  AuraManager.fChar.rlight   := AuraManager.fChar.rlight  + oldValue - frlight;

  Initialized:= true;
  State:= aDone;
  inherited;

end;
procedure TDivinePunishment.DieAndRestore;
var
aChar: TEntity;
begin
  // riptistino oldvalue MAI percentuale sempre fisso
  AuraManager.fChar.rlight := AuraManager.fChar.rlight + frlight;
  inherited;


end;
procedure TDivinePunishment.Timer(interval: integer);
begin
  inherited; // trpAura setta subito !dead se duration <= 0
  if State = adead then DieAndRestore;
end;
procedure TDivinePunishment.Input (msg: TmsgManager; value: string );
begin
inherited;
    (* il controllo dello stack è già avvenuto nella renewDuration o nella addStack *)
    if msg = msg_stack then begin
      //frlight := StrToFloat(v) * Stack;
      Load;
    end;

end;



  (*
  esempioo: il talento disciple reward ha applicato l'aura disciple reward settando nel svalue a,n,d.
  Ora si attiva questa aura che deve aggiungere una ulteriore aura. il nome di questa aura è in a=, il valore
  e la duration in n,d.
  In questo caso l'aura è resistances.l'effect di resistances è Apply Aura: Resist All. Sull'evento executeauras poi
  resistance incrementerà le resistenze.
  *)

(*  THEATER *)
(*  THEATER *)
(*  THEATER *)
(*  THEATER *)
(*  THEATER *)

procedure TrpgBrain.Map(const WorldX: Single; const WorldY: Single; out DisplayX: Integer; out DisplayY: Integer);
begin

//  if FGrid = gsSquare then begin

//  DisplayX:= round((VirtualWidth  * WorldX) / LOCAL_CELLSX);
//  DisplayY:= round((VirtualHeight * WorldY) / LOCAL_CELLSY);

//  end
  if FGrid = gsHex then begin
                                                                                  // sugli hex devo correggere per portarlo al centro
    DisplayX:= GethexDrawPoint ( aHexCellSize, round(WorldX), round(WorldY)).x    +  (aHexCellSize.SmallWidth div 2);
    DisplayY:= GethexDrawPoint ( aHexCellSize, round(WorldX), round(WorldY)).y    +  (aHexCellSize.Height  div 2);
  end;
end;
procedure TrpgBrain.UnMap(const DisplayX: Integer; const DisplayY: Integer; out WorldX: Single;  out WorldY: Single);
var
  Sum: Single;
  Diff: Single;
  PtPoly: TpointArray7;
  x,y: integer;
  PolyHandle: HRGN;
  inside: boolean;
begin


{  if FGrid  = gsSquare then begin

    if FCellWidth > 0 then begin
      WorldX := DiSplayX div FCellWidth
    end
    else
      WorldX := DisplayX;

    if FCellHeight > 0 then
      WorldY := DiSplayY div FCellHeight
    else
      WorldY := DisplayY;
  end      }
  if FGrid  = gsHex then begin


// LATO SERVER COSI' ma lato server non userà x e y del mouse
  //  worldX := DisplayX * 2/3 / aHexCellSize.Height *2 ;
  //  worldy := DisplayY * 2/3/ aHexCellSize.Height *2;
    //return hex_round(Hex(q, r))  end;  r = y * 2/3 / size
 //   exit;
// LATO CLIENT COSI'
  // se è nel poligono
    inside:= false;
    for x := 0 to LOCAL_CELLSX-1 do begin
      for y := 0 to LOCAL_CELLSY-1 do begin


        PtPoly := GetHexCellPoints( Point(0,0), AHexCellSize , x, y  );

        PolyHandle := CreatePolygonRgn(PtPoly[0],length(Ptpoly),Winding);
        inside     := PtInRegion(PolyHandle,DisplayX,DisplayY);
        DeleteObject(PolyHandle);
        if inside then begin
          worldX:=X;
          worldY:=Y;
          exit;
        end;


      end;

    end;
  end;


end;
procedure TrpgBrain.LoadDefsDB;
var
  i: integer;
  myFile: TextFile;
  aCommaText: string;
  tsDefs: TStringList;
  aDBchar: TrpgCharDB;
  aDBitem: TrpgItemDB;
  aDBSkill: TRpgSkillDB;
  aDBTalent: TRpgTalentDB;
  aDBColor: TrpgColorDB;
begin
  tsDefs:= TstringList.Create ;

// esempio riga
// esempio TsDefs[i]   elemento 0 contiene sempre l'header
// "id","defaultname","attack","defense","stamina","vitality","mfire","mearth","mlight","mphysical","mwater","mdark","mwind","rfire","rearth","rlight","rphysical","rwater","rdark","rwind","crit","critdmg","accuracy","dodge","power","talents","spritename","race","classes","regenhealth","speed",
// 44,"dark_elf_archer",15.0,50.0,10.0,10.0,10.0,10.0,10.0,10.0,10.0,10.0,10.0,10.0,10.0,10.0,10.0,10.0,10.0,10.0,1.0,1.0,1.0,1.0,1.0,"1000=1,1001=1","dark_elf_archer","human","warrior",3,1.0,

  tsDefs.Clear ;
  AssignFile(myFile, DefsDir + 'def_char.csv' );
  FileMode := fmOpenRead;
  Reset(myFile);

  while not Eof(myFile) do begin
    ReadLn(myFile, aCommaText);
    tsDefs.CommaText:=aCommaText;

    if tsDefs[0] = 'id' then continue;


    aDBchar.id                 := StrToInt(TsDefs[0]);
    aDBchar.defaultname        := TsDefs[1];
    aDBchar.attack             := StrToFloat(TsDefs[2]);
    aDBchar.defense            := StrToFloat(TsDefs[3]);
    aDBchar.stamina            := StrToFloat(TsDefs[4]);
    aDBchar.vitality           := StrToFloat(TsDefs[5]);

    aDBchar.mfire              := StrToFloat(TsDefs[6]);
    aDBchar.mearth             := StrToFloat(TsDefs[7]);
    aDBchar.mlight             := StrToFloat(TsDefs[8]);
    aDBchar.mphysical          := StrToFloat(TsDefs[9]);
    aDBchar.mwater             := StrToFloat(TsDefs[10]);
    aDBchar.mdark              := StrToFloat(TsDefs[11]);
    aDBchar.mwind              := StrToFloat(TsDefs[12]);

    aDBchar.masteries [1] :=  StrToFloat(TsDefs[6]);

    aDBchar.rfire              := StrToFloat(TsDefs[13]);
    aDBchar.rearth             := StrToFloat(TsDefs[14]);
    aDBchar.rlight             := StrToFloat(TsDefs[15]);
    aDBchar.rphysical          := StrToFloat(TsDefs[16]);
    aDBchar.rwater             := StrToFloat(TsDefs[17]);
    aDBchar.rdark              := StrToFloat(TsDefs[18]);
    aDBchar.rwind              := StrToFloat(TsDefs[19]);

    aDBchar.crit               := StrToFloat(TsDefs[20]);
    aDBchar.critdmg            := StrToFloat(TsDefs[21]);
    aDBchar.accuracy           := StrToFloat(TsDefs[22]);
    aDBchar.dodge              := StrToFloat(TsDefs[23]);
    aDBchar.power              := StrToFloat(TsDefs[24]);

    aDBchar.talents            := TsDefs[25];
    aDBchar.spritename         := TsDefs[26];
    aDBchar.race               := TsDefs[27];
    aDBchar.classes            := TsDefs[28];
    aDBchar.regenhealth        := StrToInt(TsDefs[29]);

    fDefChar.Add(@aDBchar);

  end;

  CloseFile(myFile);

// esempio riga
// esempio TsDefs[i]   elemento 0 contiene sempre l'header
//"id","defaultname","attack","defense","stamina","vitality","mfire","mearth","mlight","mphysical","mwater","mdark","mwind","rfire","rearth","rlight","rphysical","rwater","rdark","rwind","crit","critdmg","accuracy","dodge","power","talents","spritename","race","classes","regenhealth",
//1,"albero",15.0,50.0,15.0,50.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,".","albero","human","warrior",3,

  tsDefs.Clear ;
  AssignFile(myFile, DefsDir + 'def_item.csv' );
  FileMode := fmOpenRead;
  Reset(myFile);

  while not Eof(myFile) do begin
    ReadLn(myFile, aCommaText);
    tsDefs.CommaText:=aCommaText;

    if tsDefs[0] = 'id' then continue;


    aDBitem.id                 := StrToInt(TsDefs[0]);
    aDBitem.defaultname        := TsDefs[1];
    aDBitem.attack             := StrToFloat(TsDefs[2]);
    aDBitem.defense            := StrToFloat(TsDefs[3]);
    aDBitem.stamina            := StrToFloat(TsDefs[4]);
    aDBitem.vitality           := StrToFloat(TsDefs[5]);

    aDBitem.mfire              := StrToFloat(TsDefs[6]);
    aDBitem.mearth             := StrToFloat(TsDefs[7]);
    aDBitem.mlight             := StrToFloat(TsDefs[8]);
    aDBitem.mphysical          := StrToFloat(TsDefs[9]);
    aDBitem.mwater             := StrToFloat(TsDefs[10]);
    aDBitem.mdark              := StrToFloat(TsDefs[11]);
    aDBitem.mwind              := StrToFloat(TsDefs[12]);

    aDBitem.rfire              := StrToFloat(TsDefs[13]);
    aDBitem.rearth             := StrToFloat(TsDefs[14]);
    aDBitem.rlight             := StrToFloat(TsDefs[15]);
    aDBitem.rphysical          := StrToFloat(TsDefs[16]);
    aDBitem.rwater             := StrToFloat(TsDefs[17]);
    aDBitem.rdark              := StrToFloat(TsDefs[18]);
    aDBitem.rwind              := StrToFloat(TsDefs[19]);

    aDBitem.crit               := StrToFloat(TsDefs[20]);
    aDBitem.critdmg            := StrToFloat(TsDefs[21]);
    aDBitem.accuracy           := StrToFloat(TsDefs[22]);
    aDBitem.dodge              := StrToFloat(TsDefs[23]);
    aDBitem.power              := StrToFloat(TsDefs[24]);

    aDBitem.talents            := TsDefs[25];
    aDBitem.spritename         := TsDefs[26];
    aDBitem.race               := TsDefs[27];
    aDBitem.classes            := TsDefs[28];
    aDBitem.regenhealth        := StrToInt(TsDefs[29]);

    DefItem.Add(@aDBitem);

  end;

  CloseFile(myFile);




// esempio riga
// esempio TsDefs[i]   elemento 0 contiene sempre l'header
//"id","talentname","effects","tree","rankinfo1","rankinfo2","spritename","race","classes","loadpriority","descr","descrr1","descrr2",
//1003,"healmore","replacevalue,heal.one,r1","talent","ma*1.5,ma*1.6,ma*1.7,ma*1.8","","healmore","","priest",1,"aumenta le cure fornite da Heal del r1","150%,160%,170%,180%","",
//1004,"silencemore","replaceduration,silence,r1","talent","3500,4000,4500,5000","","silencemore","","priest",1,"aumenta la durata di silence di r1 secondi","3.5,4,4.5,5","",

  tsDefs.Clear ;
  AssignFile(myFile, DefsDir + 'def_talent.csv' );
  FileMode := fmOpenRead;
  Reset(myFile);




  while not Eof(myFile) do begin
    ReadLn(myFile, aCommaText);
    tsDefs.CommaText:=aCommaText;

    if tsDefs[0] = 'id' then continue;


    aDBTalent.id                := StrToInt(TsDefs[0]);
    aDBTalent.talentName        := TsDefs[1];
    aDBTalent.effects           := TsDefs[2];
    aDBTalent.tree              := TsDefs[3];
    aDBTalent.rankinfo1         := TsDefs[4];
    aDBTalent.rankinfo2         := TsDefs[5];
    aDBTalent.spritename        := TsDefs[6];
    aDBTalent.race              := TsDefs[7];
    aDBTalent.classes           := TsDefs[8];

    aDBTalent.LoadPriority      := StrToInt(TsDefs[9]);
    aDBTalent.descr             := TsDefs[10];
    aDBTalent.descrr1           := TsDefs[11];
    aDBTalent.descrr2           := TsDefs[12];


    DefTalent.Add(@aDBTalent);

  end;

  CloseFile(myFile);

// esempio TsDefs[i]   elemento 0 contiene sempre l'header
//"power","kind","skillname","id","aftercast","casttime","cooldown","school","mechanic","range","channeling","accuracy","crit","requiredaura","requirednoaura","requiredhealth","classes","icon","spritename","descr",
//0,"singlecurse","shadow.pain",162,"a=shadow.pain,v=ma*0.5,d=10000,tick=1000",1000,14000,"dark",".",5,0,0,1.0,"","","","ira","shadow.pain","blessing.of.fortune","Ogni secondo infligge il 50% dei danni dark. Dura 6 secondi.",

  tsDefs.Clear ;
  AssignFile(myFile, DefsDir + 'def_skill.csv' );
  FileMode := fmOpenRead;
  Reset(myFile);




  while not Eof(myFile) do begin
    ReadLn(myFile, aCommaText);
    tsDefs.CommaText:=aCommaText;

    if tsDefs[0] = 'power' then continue;

    aDBSkill.power             := StrToInt(TsDefs[0]);
    aDBSkill.kind              := TsDefs[1];
    aDBSkill.SkillName         := TsDefs[2];
    aDBSkill.id                := StrToInt(TsDefs[3]);
    aDBskill.afterCast         := TsDefs[4];

    aDBSkill.casttime          := StrToInt(TsDefs[5]);
    aDBSkill.cooldown          := StrToInt(TsDefs[6]);
    aDBSkill.school            := TsDefs[7];


    aDBSkill.mechanic          := TsDefs[8];
    aDBSkill.range             := StrToInt(TsDefs[9]);
    aDBSkill.channeling        := StrToInt(TsDefs[10]);
    aDBSkill.accuracy          := StrToInt(TsDefs[11]);
    aDBSkill.crit              := StrToFloat(TsDefs[12]);

    aDBSkill.requiredAura      := TsDefs[13];
    aDBSkill.requiredNOAura    := TsDefs[13];
    aDBSkill.requiredHealth    := TsDefs[15];
    aDBSkill.classes           := TsDefs[16];

    aDBSkill.icon              := TsDefs[17];
    aDBSkill.spritename        := TsDefs[18];
    aDBSkill.descr             := TsDefs[19];

    DefSkill.Add(@aDBSkill);

  end;

  CloseFile(myFile);




// esempio TsDefs[i]   elemento 0 contiene sempre l'header
//"id","slabel","schoolcolor",
//1,"physical",16776960,
//2,"holy",7078373,


  tsDefs.Clear ;
  AssignFile(myFile, DefsDir + 'def_color.csv' );
  FileMode := fmOpenRead;
  Reset(myFile);




  while not Eof(myFile) do begin
    ReadLn(myFile, aCommaText);
    tsDefs.CommaText:=aCommaText;

    if tsDefs[0] = 'id' then continue;

    aDBColor.id                := StrToInt(TsDefs[0]);
    aDBColor.slabel            := TsDefs[1];
    aDBColor.schoolColor       := StrToInt(TsDefs[2]);

    DefColor.Add(@aDBColor);

  end;

  CloseFile(myFile);
  tsDefs.Free;


end;
end.

