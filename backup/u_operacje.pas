unit u_operacje;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, ExtCtrls,
  StdCtrls, Menus, Buttons, LazFileUtils,
  u_parametry, u_sprawdzacz,  u_tmimage, u_ramka,  u_odtwarzacz, uoprogramie, windows;



  const MAX_OBR=50; //maxymalna dozwolona liczba obrazkow - powyzej tego - gruba przesada....; wymog formalnu; operacyjnie stosuję zmienna MAX_OBR_OD

  Type

  TtabSek = array[1..MAX_OBR] of SmallInt; //typ dla tablicy zawierajacej sekwencję (kolejnosc) wyswietlania obrazkow w OD

  { TFOperacje }

  TFOperacje = class(TForm)
    BRMinus: TButton;
    BEMinus: TButton;
    BRPlus: TButton;
    BEPlus: TButton;
    Button1: TButton;
    Button2: TButton;
    BRebuildAll: TButton;
    BPodp: TButton;
    BAgain: TButton;
    BNextCwicz: TButton;
    CBRamka: TCheckBox;
    CBEkran: TCheckBox;
    LRGrayness: TLabel;
    LNazwa: TLabel;
    LEGrayness: TLabel;
    Panel1: TPanel;
    Panel2: TPanel;
    SpeedBtnGraj: TSpeedButton;
    SpeedBtn2: TSpeedButton;
    SpeedBtn1: TSpeedButton;
    TimerBlokGraj: TTimer;
    Timer5sek: TTimer;
    TimerNazwa: TTimer;
    TimerKlawisze: TTimer;
    TimerLosuj: TTimer;
    MainMenu1: TMainMenu;
    MenuItem6: TMenuItem;
    OProgramie: TMenuItem;
    Parametry: TMenuItem;
    SLinia: TShape;
    procedure BAgainClick(Sender: TObject);
    procedure BEMinusClick(Sender: TObject);
    procedure BEPlusClick(Sender: TObject);
    procedure BRMinusClick(Sender: TObject);
    procedure BRPlusClick(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure CBRamkaChange(Sender: TObject);
    procedure CBEkranChange(Sender: TObject);
    procedure Naczytaj();
    procedure BNextCwiczClick(Sender: TObject);
    procedure BPodpClick(Sender: TObject);
    procedure BRebuildAllClick(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure OProgramieClick(Sender: TObject);
    procedure ParametryClick(Sender: TObject);
    procedure SpeedBtnGrajClick(Sender: TObject);
    procedure Timer5sekTimer(Sender: TObject);
    procedure TimerBlokGrajTimer(Sender: TObject);
    procedure TimerKlawiszeTimer(Sender: TObject);
    procedure TimerLosujTimer(Sender: TObject);
    procedure TimerNazwaTimer(Sender: TObject);
    procedure TimWzorzecPaint(Sender: TObject);
    procedure UstawEkranStartowy;
    procedure LosujUmiescObrazek();
    procedure RebuildAll();
    procedure OdegrajPolecenie(delay: Byte);
    procedure PokazUkryjBGrajOnWavExistsDependent();
  private
    function dostosujSpeedBtnGrajHeight():SmallInt;
  public
    tabOb   : array[1..MAX_OBR] of TMojImage;  //tablica na obrazki
    TImWzorzec: TMojImage;                        //obrazek-wzorzec na gorze okranu (w OG = Obszar Górny)
    idWylos : Integer;                            //id wylosowanego obrazka
    nrWylos : Integer;                            //numer (index w tablicy tabOb) wylosowanego obrazka
    liczbaObrWKatalogu : Integer;                 //Liczba obrazkow wczytanych z dysku do katalogu
    SLiniaTop_original : Integer; //Taka wartosc, jak okreslono podczas wymiarowamia na FOperacjeOnShow(); bedzie potrzebna,bo czasami polozenie SLinii moze sie zmieniac.... (gdy duzy obrazek i tylko jeden wiersz)
    procedure PokazKlawisze();
    procedure UkryjKlawisze();
    procedure DajNagrode();
    procedure DajNagane();
    procedure GrajKomentarz(katalog:String; opoznienie:SmallInt);

    procedure GrajZle(opoznienie:SmallInt);
    procedure GrajDing(opoznienie:SmallInt);
    function  DajLosowaSekwencje():TtabSek;
    procedure GenerujPojemnikNaWzorzec();
    procedure PokazNazwePodObrazkiem();

    procedure UstawDefaultowyKolorRamki_Ekranu_Napisu();
    procedure DostosujKoloryPozostalychObiektow();

  end;



Function skib_InvertColor(const myColor: TColor): TColor; (* Daje kolor 'odwrotny' do zadanego - potrzebne pry rysowaniu ramek widocznych na nieznanym background'dzie *)

var
  FOperacje: TFOperacje;
  Ramka      : TRamka;           //Ramka na polozenie Obrazka; bedzie wystawiac Lapke
  Sprawdzacz : TSprawdzacz;      //na sprawdzanie na MouseUp na obrazku, a potem się ten obiekt odpytuje


CONST
    PELNA_WERSJA = TRUE;         //na etapie kompilacji okreslam czy pelna czy demo
    JESTEM_W_105 = FALSE;        //zeby nie grac, gdy jestem w 1.05
VAR

    MAX_OBR_OD :SmallInt;        //maxymalna dozwolona liczba obrazkow w Obszarze Dolnym (jak za duzo, to dziecko nie da rady...); zalezy tez od PELNA_WERSJA=True/False

    SciezkaZasoby  : string;     //katalog z zasobami w biezacym katalogu programu
    MPlayer : TMediaPlayerSki;   //do odgrywania nagrod

    komciePath,
    oklaskiPath, tadaPath : String;  //sciezki do plikow dzwiekowych

implementation

{$R *.lfm}

{ TFOperacje }

function skib_InvertColor(const myColor: TColor): TColor;
(* Daje kolor 'odwrotny' do zadanego - potrzebne pry rysowaniu ramek widocznych na nieznanym background'dzie *)
Begin
  if (myColor = clDefault) or (myColor = clGray) then
    result := clBlack //doswiadczalnie
  else  //znalezione w Internecie:
    result := TColor(Windows.RGB(255 - GetRValue(myColor), 255 - GetGValue(myColor), 255 - GetBValue(myColor)));
End;


procedure TFOperacje.GenerujPojemnikNaWzorzec();
(* Generuje 'pojemnik' na obrazek-wzorzec na gorze ekranu. *)
(* Nie wypelnia trescia (to gdzie indziej).                *)
Begin
  TImWzorzec := TMojImage.WlasnyCreate_Generic(); //'pojemnik' na obrazek-wzorzec
  TImWzorzec.Parent := FOperacje;

  if Screen.Height <= 768 then //walka o kazdy piksel ... ;) 2020-05-02
    TImWzorzec.Top := 20
  else
    TImWzorzec.Top := 30;

End;


var raR,raG,raB: integer;  //ramkaRGB
var ekR,ekG,ekB: integer;  //ekranRGB
procedure TFOperacje.BRPlusClick(Sender: TObject);
var kolor : integer;
begin
    raR := raR+1;
    raG := raG+1;
    raB := raB+1;
    kolor:=RGB(raR, raG, raB);
    Ramka.Brush.color := kolor;
    LRGrayness.Caption:=IntToStr(raR);
end;

procedure TFOperacje.Button3Click(Sender: TObject);
begin
    SpeedBtnGraj.SendToBack();
end;


procedure TFOperacje.BRMinusClick(Sender: TObject);
var kolor:integer;
begin
    raR := raR-1;
    raG := raG-1;
    raB := raB-1;
    kolor:=RGB(raR, raG, raB);
    Ramka.Brush.color := kolor;
    LRGrayness.Caption:=IntToStr(raR);
end;

procedure TFOperacje.BEPlusClick(Sender: TObject);
var kolor:integer;
begin
    ekR := ekR+1;
    ekG := ekG+1;
    ekB := ekB+1;
    kolor:=RGB(ekR, ekG, ekB);
    FOperacje.color := kolor;
    LEGrayness.Caption:=IntToStr(ekR);
end;


procedure TFOperacje.BEMinusClick(Sender: TObject);
var kolor:integer;
begin
    ekR := ekR-1;
    ekG := ekG-1;
    ekB := ekB-1;
    kolor:=RGB(ekR, ekG, ekB);
    FOperacje.Color := kolor;
    LEGrayness.Caption:=IntToStr(ekR);
end;


procedure TFOperacje.CBRamkaChange(Sender: TObject);
begin
  if CBRamka.Checked then begin
    Ramka.Brush.Color:=RGB(raR,raG,raB);
    BRPlus.Enabled :=True;
    BRMinus.Enabled:=True;
    LRGrayness.Caption:=IntToStr(raR);
  end
  else begin
    BRPlus.Enabled :=False;
    BRMinus.Enabled:=False;
    //Ramka dostosowuje sie do akt. koloru FOperascje:
    //Ramka.UstawKolorObramowania(FOperacje.Color);
    //Ramka.Brush.Color := Ramka.Pen.Color; //na potrzeby WybierzObrazek - zmiana tla Ramki - 2019.09.29
  end;
end;

procedure TFOperacje.CBEkranChange(Sender: TObject);
begin
  if CBEkran.Checked then begin
    FOperacje.Color:=RGB(ekR,ekG,ekB);
    BEPlus.Enabled :=True;
    BEMinus.Enabled:=True;
    LEGrayness.Caption:=IntToStr(ekR);
  end
  else begin
    BEPlus.Enabled :=False;
    BEMinus.Enabled:=False;
    //Kolor FOperacje na czarny:
    FParametry.ComboBoxKolor.ItemIndex := 9;
    FParametry.ComboBoxKolorChange(FParametry.ComboBoxKolor);
    //zeby ramka pozostala jaka byla:
    if CBRamka.Checked then begin
      Ramka.Brush.color := RGB(raR, raG, raB);
    end;
  end;
end;

procedure TFOperacje.FormShow(Sender: TObject);
var robTop: SmallInt;
Begin
  GenerujPojemnikNaWzorzec(); //powstanie obiekt o nazwie TImWzorzec - niszczony/generowany w kazdym cyklu
  {}
  UstawEkranStartowy();
  (* Obiekty potrzebne do dzialania: *)
  Sprawdzacz := TSprawdzacz.Create();

  //Ile pikseli Ramka od gory - walczymy o kazdy piksel ;) :
  robTop := 30;
  if Screen.Height <= 768 then robTop := 20;
  Ramka := TRamka.WlasnyCreate(30,robTop,200,200);  //Ramka do wkladania przez dziecko zgadywanego obrazka
  (**)
  UstawDefaultowyKolorRamki_Ekranu_Napisu();
  FParametry.ComboBoxKolor.ItemIndex:=3; //kosmetyka - zeby na Fparametry.ComboBoxColor bylo widoczne, ze defaultowy
  (**)
  Ramka.Parent := FOperacje;
  MPlayer := TMediaPlayerSki.WlasnyCreate();
  (**)
  liczbaObrWKatalogu := FParametry.FListBox1.Count;
  Naczytaj(); //naczytanie obrazków+wiele innych
  UkryjKlawisze();
  BPodp.Visible:=FParametry.CBPodp.Checked;
End; (* FormShow() *)

procedure TFOperacje.OProgramieClick(Sender: TObject);
begin
  FOprogramie.Top  := (FOperacje.Height - FOprogramie.Height) div 2;
  FOprogramie.Left := (FOperacje.Width  - FOprogramie.Width)  div 2;
  FOprogramie.ShowModal;
end;



procedure TFOperacje.ParametryClick(Sender: TObject);
(* Pokazanie formy FParametry *)
begin
  FParametry.Top  := Top + 20;
  FParametry.Left := Left + 8;
  FParametry.ShowModal;
end;


procedure TFOperacje.TimerKlawiszeTimer(Sender: TObject);
(* pokazanie klawiszy nawigacyjnych *)
Begin
  PokazKlawisze();
  TimerKlawisze.Enabled := False;
End;


procedure TFOperacje.TimerLosujTimer(Sender: TObject);
(* Losowanie obrazka, wyswietlenie wylosowanego, odblokowanie ewentualnego odgrywania co 5 sek (ostanie na potrzeby WybierzObrazek - 2019.12.20)*)
Begin
  LosujUmiescObrazek();
  BPodp.Visible := FParametry.CBPodp.Checked;
  Timer5sek.Enabled := Fparametry.CBAutomat.Checked;
  TimerLosuj.Enabled := False;
End;

procedure TFOperacje.TimerNazwaTimer(Sender: TObject);
(* pokazanie nazwy pod Wzorcem *)
Begin
  PokazNazwePodObrazkiem();
  TimerNazwa.Enabled:=false;
End;



type
  TGraphicControlAccess = class(TGraphicControl)
end;
procedure TFOperacje.TimWzorzecPaint(Sender: TObject);
begin
  inherited Paint();
  with TGraphicControlAccess(TImWzorzec).Canvas do  begin
    Brush.Style := bsClear;
    Pen.Color   := clRed;
    Rectangle(ClientRect);
  end;
end;

procedure TFOperacje.Button1Click(Sender: TObject);
var i:integer;
begin
  for i:=1 to TMojImage.liczbaOb do begin
    tabOb[i].Destroy();
  end;
end;

procedure TFOperacje.RebuildAll();
(* Zniszczenie i Odbudowa wszystkich obrazkow *)
var liczZbO : SmallInt;      //licznosc zbioru obrazkow;
    i,k : Integer;
    Sek : array[1..MAX_OBR] of SmallInt; //na losowa sekwencje pokazywania obrazkow
Begin
  Screen.Cursor:=crHourGlass;
  //likwidacja tego co na górze:
  TImWzorzec.Destructor_Generic();
  //Likwidacja i odbudowa tego co nad dole:
  for i:=1 to TMojImage.liczbaOb do
    tabOb[i].Destroy();

  (************** Kreowanie obrazkow w OD: ***********************************)
  {}
  //Przywracamy (ewentualnie) zmienionę SLinie.Top - jest to istotne, bo od SLinia.Top zalezy wymiarowanie w pionie(!)
  SLinia.Top := SLiniaTop_original;
  {}
  liczZbO := FParametry.DajLicznoscZbioru(Zbior);
  k:=1;
  for i:=0 to liczbaObrWKatalogu-1 do begin
    if i in Zbior then begin  //kreowanie pojedynczego Obrazka (z wymiarowaniem)
      tabOb[k] := TMojImage.WlasnyCreate_ze_Skalowaniem(FParametry.FListBox1, i, liczZbO);
      k:=k+1;
    end;
  end;


  //Rozlozenie obrazkow na FOperacje:
  //przygotowanie 'sekwencji' w jakiej ma nastapic wyswietlenie
  sek := DajLosowaSekwencje();
  //rozmieszczenie obrazkow:
  TMojImage.RozmiescObrazki_v2(tabOb, sek);
  //Pokazanie na formie:
  for i:=1 to TMojImage.liczbaOb do tabOb[i].Parent := FOperacje;
 (**************** koniec kreowania*************************************)

   Screen.Cursor:=crDefault;
End;  (* RebuildAll *)


procedure TFOperacje.PokazKlawisze();
(* Pokazanie klawiszy po cwiczeniu *)
Begin
  BNextCwicz.Visible:= True;
  BAgain.Visible    := True;
End;

procedure TFOperacje.UkryjKlawisze();
(* Ukrycie klawiszy przed i w trakcie cwiczeniea (= po Zwyciestwie) *)
Begin
  BPodp.Visible := False;
  BNextCwicz.Visible:= False;
  BAgain.Visible    := False;
End;


function TFOperacje.DajLosowaSekwencje(): TtabSek;
(* ******************************************************************************************************************** *)
(* Zwraca tablice 'shadow' dla tabOb, pokazujaca w jakiej kolejnosci w OD maja byc wyswietlane obiekty tabOb (obrazki)  *)
(* np. Result[3]=5 oznacza, że 3-cim obrazkiem w OD ma byc 5-ty element tablicy tabOb (czyli obrazek zawarty w tabOb[5] *)
(* ******************************************************************************************************************** *)
var i:SmallInt;
    los : SmallInt;
    sek : TtabSek; //sekwencja w jakiej ma nastapic wyswietlenie
    ZbDozw : set of 1..MAX_OBR;
Begin
  ZbDozw:=[];
  for i:=1 to TMojImage.liczbaOb do ZbDozw:=ZbDozw+[i];
  for i:=1 to TMojImage.liczbaOb do begin
    Repeat
      los := 1 +Random(TMojImage.liczbaOb);
    Until los in ZbDozw;
    sek[i]:=los;
    ZbDozw:=ZbDozw-[los];
  end;
  Result := sek;
End;   (* Function *)

procedure TFOperacje.BRebuildAllClick(Sender: TObject);
begin
  RebuildAll();
end;


procedure TFOperacje.PokazUkryjBGrajOnWavExistsDependent();
(* Blokuje BGraj jesli na dysku nie istnieje odpowiedni plik vaw *)
(* Bierze rowniez po uwage stosowne ustawienia na FParametry.    *)
var plikWava : string;
Begin
  plikWava := tabOb[idWylos].DajEwentualnyPlikWav();
  if not FileExists(SciezkaZasoby+plikWava) then begin
    SpeedBtnGraj.Enabled := False;
    PokazNazwePodObrazkiem(); //jak nie ma dzwieku, to niech przynajmniej wypisze nazwe/polecenie....
  end
  //jezeli plik dzwiekowy istnieje, to stosuj takie zasady jak okreslono w Settingsach:
  else begin
    FParametry.CBOdgrywajChange(nil);
  end;
End;



procedure TFOperacje.Naczytaj();
Begin
  UkryjKlawisze();
  RebuildAll();
  LosujUmiescObrazek();
  Sprawdzacz.Resetuj();
  BPodp.Visible := FParametry.CBPodp.Checked;
End;

procedure TFOperacje.BNextCwiczClick(Sender: TObject);
var i:SmallInt;
    sek : TtabSek; //sekwencja w jakiej ma nastapic wyswietlenie
Begin
  //Aktywacja wylaczonych handlerow + 'sprzatanie':
  UkryjKlawisze();
  SpeedBtnGraj.Visible:=False; // j.w.;
  TImWzorzec.Destructor_Generic();   //usuwam obrazkek-wzorzec
  LNazwa.Visible := False;           //znika podpis pod obrazkiem (if any)
  Ramka.JestLapka := False;   //gdyby byla...
  Ramka.Visible   := False;   //j.w.
  Sprawdzacz.Resetuj();
  for i:=1 to TMojImage.liczbaOb do begin
     tabOb[i].inArea := False;
     tabOb[i].WlaczHandlery();
     tabOb[i].JestLapka:=False;   //gdyby 'jakos' byla...
     tabOb[i].Cursor := crDefault;
  end;
  //Przygotowanie 'sekwencji' w jakiej ma nastapic wyswietlenie:
  sek := DajLosowaSekwencje();
  //Wyswietlenie sekwencji obrazkow:
  TMojImage.RozmiescObrazki_v2(tabOb, sek);
  //Wylosowanie i pokazanie wylosowanego w OG (lekkie opoznienie - efekciarstwo ;)):
  TimerLosuj.Enabled := True;
End;

procedure TFOperacje.BAgainClick(Sender: TObject);
(* Powtorzenie cwiczenia (ma byc identycznie, czyli nie przeprowadzam losowania) *)
(* Wszystkie obrazki wracaja na swoje miejsca. Nie dobieram nowych obrazkow(!)   *)
var i : SmallInt;
Begin
  UkryjKlawisze();
  BPodp.Visible := FParametry.CBPodp.Checked; //powinien pozostac
  Sprawdzacz.Resetuj();
  for i:=1 to TMojImage.liczbaOb do begin
    With tabOb[i] do begin
      inArea := False;
      Left := tabOb[i].getXo();
      Top  := tabOb[i].getYo();
      WypozycjonujLPodpis();
      JestLapka := False;    //Jakby byla jakas Lapka, to gaszę
      WlaczHandlery();
    end;

  end;
  Ramka.JestLapka := False;  //gaszę, gdyby byla Lapka

  if FParametry.CBOdgrywaj.Checked then
    OdegrajPolecenie(1);

  //Ponowne odgrywanie co 5 sek (if any):
  Timer5sek.Enabled := Fparametry.CBAutomat.Checked;
  if Fparametry.CBAutomat.Checked then
    Timer5sekTimer(BAgain);  //parametr, zeby funkcja wywolywana wiedziala co z tym zrobic - lekko opozni granie
End;


procedure TFOperacje.SpeedBtnGrajClick(Sender: TObject);
(* Odegranie nazwy obrazka (if any) *)
Begin
  if not FParametry.CBOdgrywaj.Checked then Exit;
  OdegrajPolecenie(0);
  //blokuję na chwilę, zeby nie klikal jak wsciekly.. :
  SpeedBtnGraj.Enabled := False;
  TimerBlokGraj.Enabled:= True;
End;

procedure TFOperacje.OdegrajPolecenie(delay: Byte);
(* Odegranie nazwy obrazka=polecenia (if any); delay - wielokrotnosc 750 ms *)
var plikWava : string;
Begin
  plikWava := tabOb[idWylos].DajEwentualnyPlikWav();
  MPlayer.Play(SciezkaZasoby+plikWava,delay);
End;

procedure TFOperacje.Timer5sekTimer(Sender: TObject);
Begin
  if FOperacje.BNextCwicz.Visible then Exit;  //Nie gram, jesli w trybie po "zwyciestwie"
  if ((Sender=FParametry) or (Sender=BAgain)) then
    OdegrajPolecenie(1)    //weszlismy z Fparametry lub BAgain - wypada troche odczekac..
  else
    OdegrajPolecenie(0);
End;

procedure TFOperacje.TimerBlokGrajTimer(Sender: TObject);
(* Odblokowanie mozliwosci naciskania klawisza do odgrywania (zeby nie klikal jak wsciekly...)  *)
Begin
  SpeedBtnGraj.Enabled := True;
  TimerBlokGraj.Enabled:= False;
End;

procedure TFOperacje.BPodpClick(Sender: TObject);
(* Udzielenie podpowiedzi - wystawienie Lapek na Ramce i wlasciwym Obrazku *)
(* (dziala takze jak switch on/off                                         *)
Begin
  tabOb[nrWylos].JestLapka := not tabOb[nrWylos].JestLapka; //ramka wokol zgadywanego obrazka
  Ramka.JestLapka  := not Ramka.JestLapka; //na gornej Ramce

  With tabOb[nrWylos] do begin
    if JestLapka and (not inArea) then
      PotrzasnijBezWskazu();
  end;
End;

procedure TFOperacje.Button2Click(Sender: TObject);
begin
  if TMojImage.liczbaOb>0 then
    tabOb[TMojImage.liczbaOb].Destroy();
end;

procedure TFOperacje.FormCreate(Sender: TObject);
Begin
  if PELNA_WERSJA then  //ograniczenie 'marketingowe'
    MAX_OBR_OD := 15
  else
    MAX_OBR_OD := 4;
  {}
  nrWylos := -1; //inicjacyjne, zeby sprawdzenie w LosujUmiescObrazek() zadzialalo jak trzeba (True)

End;

procedure TFOperacje.UstawEkranStartowy;
Begin
  FParametry.ComboBoxKolorChange(nil); //wymuszenie defaultowego (=czarnego) koloru FOperacje
  //
  FOperacje.Top := 1; //zeby FOperacje byla w miare na gorze bylo
  //Forma na wiekszosc ekranu :
  FOperacje.Width := Trunc(0.98*Screen.Width);
  FOperacje.Height:= Trunc(0.93*Screen.Height); //bylo 93 92
  FOperacje.Left  := (Screen.Width-Width) div 2 -2;

  SLinia.Left := 0;
  //SLinia.Top  := 1*(FOperacje.Height div 2); //tak bylo do 2020-04-28
  SLinia.Top  := trunc(43/100*FOperacje.Height);
  SLiniaTop_original := SLinia.Top;  //zapamietanie na stale, bo czasem moze sie zmieniac i trzeba miec skąd przywrocic...
  SLinia.Width:= FOperacje.Width;

  //Pozycjonowanie klawiszy; BAgain jest klawiszem 'wzorcowym' :

  BAgain.Height := Trunc(1.5*Bagain.Height);   //dla WybierzObrazek troche powiekszam - 2019.12.20
  BAgain.Width  := Trunc(1.5*Bagain.Width);

  BAgain.Top := SLinia.Top - BAgain.Height-2;;
  BAgain.Left:= FOperacje.Width - BAgain.Width -2;

  BNextCwicz.Height:=BAgain.Height;
  BNextCwicz.Width :=BAgain.Width;

  BPodp.Height:=BAgain.Height;
  BPodp.Width :=BAgain.Width div 3;

  BNextCwicz.Left := FOperacje.Width - BNextCwicz.Width -2;
  BNextCwicz.Top  := BAgain.Top - BAgain.Height -1;

  BPodp.Left := FOperacje.Width - Bpodp.Width -2;
  BPodp.Top  := BNextCwicz.Top - BNextCwicz.Height -1;

  //Zeby TShape nie mrugal (blinking, flickering) za bardzo, kiedy przesuwany :
  FOperacje.DoubleBuffered:=True;
  (**)
  Randomize;
End; (*Procedure*)

procedure TFOperacje.LosujUmiescObrazek();
(* ************************************************************************************ *)
(* Wylosowanie                obrazka do zgadywania.                                    *)
(* Umieszczenie ramki na wylosowany obrazek                                             *)
(* Sposrod obrazkow NA DOLE EKRANU losuję jeden. (NIE LOSUJEMY Z KATALOGU!!!)           *)
(* Ewentualne odegranie pliku z nazwa obrazka.                                          *)
(* ************************************************************************************ *)
var x,y : Integer;   //pomocnicze, dla zwiekszenia czytelnosci
    los : SmallInt;  //indeks wylosowanego obrazka
    odstep: Integer; //odstep miedzy klawiszem z glosnikiem a ramką na obrazek
Begin
  {Losowanie obrazka ze zmiejszeniemm p-stwa wylosowania tego samego:}
  los := 1+ Random(TMojImage.liczbaOb);  //+1 bo Random(x) generuje w przedziale  0=< liczba <x
  if los=nrWylos then //sprawdzenie, czy nie taki sam jak poprzednio wylosowany
    los := 1+ Random(TMojImage.liczbaOb);
  if los=nrWylos then //j.w.
    los := 1+ Random(TMojImage.liczbaOb);
  nrWylos := los;    //poprzednio wylosowany staje sie aktualnie wylosowanym; system-wide - przyda sie...
  {}
  idWylos := tabOb[nrWylos].getIdOb(); //system-wide, przyda sie w innych modulach

  //Pokazanie wylosowanego obrazka w Ramce w OG:
  GenerujPojemnikNaWzorzec(); //powstanie obiekt o nazwie TImWzorzec (niszczony/odnawiany w kazdym cyklu)

  TImWzorzec.Picture := tabOb[nrWylos].Picture;

  TImWzorzec.Proportional:= tabOb[nrWylos].Proportional;
  TImWzorzec.Stretch     := tabOb[nrWylos].Stretch;
  TImWzorzec.Center      := tabOb[nrWylos].Center;

  TImWzorzec.Width  := SpeedBtnGraj.Width; // zmiana na potrzeby WybierzObrazek 2019.10.01tabOb[nrWylos].Width;
  TImWzorzec.Height := tabOb[nrWylos].Height;
  TImWzorzec.Left   := FOperacje.Width div 2 - TImWzorzec.Width - 20;

  TImWzorzec.Visible := FALSE;  //->ukrywam - przerobka  WybierzObrazek 2019.09.30

  {nowe 2019.10.30:}
  //Dazymy to tego, zeby 'kompleks' ["BitBtnGraj + Ramka"] lezal centralnie (w poziomie) na Foperacje:
  Ramka.UstalWidthHeight(tabOb[nrWylos]);  //wielkosc Ramki ustalamy na pdst. obrazka, ktory ma do niej trafic
  SpeedBtnGraj.Top   := Ramka.Top;
  SpeedBtnGraj.Height:= dostosujSpeedBtnGrajHeight();

  odstep := 1*(SpeedBtnGraj.Width div 2);
  x := (FOperacje.Width - (SpeedBtnGraj.Width + odstep + Ramka.Width)) div 2;
  SpeedBtnGraj.Left := x;
  y :=  TImWzorzec.Top;
  Ramka.PolozNaXY(x+SpeedBtnGraj.Width + odstep, y);
  Ramka.Visible := True;
  SpeedBtnGraj.Visible := True;

  //Dzieki tym 2 'bezsensownym' instrukcom podobiekt Lapka bedzie mial 'bojowe' wspolrzedne - wykorzystywane w funkcki TMojImage.ObrazekJestWOkregu(...) (troche trick...):
  Ramka.JestLapka:=True;
  Ramka.JestLapka:=False;
  {}
  SLinia.SendToBack(); //bo przy b.duzych obrazkach moze zaslaniac...
  {}
  //Ewentualne odegranie nazwy wylosowanego obrazka (jesli stowarzyszony plikWav istnieje):
  if not JESTEM_W_105 then begin //nie gram gdy jestem w pracy...
    if FParametry.CBOdgrywaj.Checked then begin
      OdegrajPolecenie(1);             //odegra, albo cisza :)
    end;
  end;

  //Podpis pod obrazkiem (jego nazwa):
  if Fparametry.CBNazwa.Checked then
    TimerNazwa.Enabled:=True
  else
    LNazwa.Visible:=False;
  {}
  //Wstawka, jesli nie ma pliku z dzwiekiem, blokujemy BGraj, pokazujemy napis:
  PokazUkryjBGrajOnWavExistsDependent();
  //
End; (* Procedure *)


function TFOperacje.dostosujSpeedBtnGrajHeight():SmallInt;
(* *********************************************************************** *)
(* Zwraca wysokosc SpeddBtnGraj dostposowana do wielkosci Ramki na obrazek *)
(* Najczesciej ta sama wartosc, co wysokosc Ramki;                         *)
(* Wyjatek: b.duzy obrazek (=1 wiersz, nie pomniejszany) - wtedy mniej,    *)
(* zeby bylo mniejsce na ewentualne polecenie w formie pisemnej-> LNazwa   *)
(* *********************************************************************** *)

var wynik : SmallInt;
Begin
  IF
    (TMojImage.IleWierszy(TMojImage.liczbaOb)=1) and
    (not FParametry.CBShrink.Checked) and
    (FParametry.CBNazwa.Checked)
  THEN
    wynik := trunc(90/100*Ramka.Height)
  ELSE
    wynik := Ramka.Height;
  {}
  Result := wynik;
End;

procedure TFOperacje.DajNagrode();
(* ************************************************************* *)
(* Odegranie (losowej) nagrody z podkatalogu 'Zasoby/komentarze' *)
(* Par. 'opoznienie' - ile opoznic granie (wielokrotnosc 750 ms) *)
(* ************************************************************* *)
Begin
  if FParametry.RBNoAward.Checked then begin
    Exit;
  end;
  if FParametry.RBOkrzyk.Checked then begin
    MPlayer.Play(tadaPath,1);
    Exit;
  end;
  if FParametry.RBOklaski.Checked then begin
    MPlayer.Play(oklaskiPath,1);
    Exit;
  end;
  IF FParametry.RBPochwala.Checked then begin
    GrajKomentarz(komciePath+'pozytywy',1);
  End;  //IF
End; (* Procedure *)


procedure TFOperacje.DajNagane();
(* Odegranie, ze zle - jesli polozy w Ramce niewlasciwy obrazek *)
Begin
  if FParametry.RBNegNo.Checked then Exit;
  GrajKomentarz(komciePath+'negatywy',1);
End;

procedure TFOperacje.GrajKomentarz(katalog: String; opoznienie: SmallInt);
(* Odegranie nagany/ badz nagrody = jednego z plikow w 'katalog' *)
var
  plik: String;
  sl  : TStringList;
  los : Integer;
  liczbaPlikow:Integer;
Begin
  if JESTEM_W_105 then Exit; //nie gram gdy jestem w pracy...
    sl := FindAllFiles(katalog, 'x*.wav', True); //x z przodu - taki wzorzec nazwy przyjalem (rowniez0 dla plikow z naganą - np. 'x03-nie-probuj-dalej.wav'
    Try
      liczbaPlikow:=sl.Count;
      los := 1+Random(liczbaPlikow);
      try     //musi byc wewnetrzny try z pustym except, bo jak nie ma plikow w sl, to zgalaszany jest wyjatek, ktory przebija sie do usera...
        plik:= sl.Strings[los-1]; // -1 bo indeksowanie jest od 0 zera
        MPlayer.Play(plik,opoznienie);
      except
      end;
    Finally
      sl.Free; //BARDZO WAZNE !!!!!! bo memory leaks
    End;
End;

procedure TFOperacje.GrajZle(opoznienie:SmallInt);
Begin
  MPlayer.Play(komciePath+'zle.wav',opoznienie);
End;

procedure TFOperacje.GrajDing(opoznienie:SmallInt);
Begin
  MPlayer.Play(komciePath+'ding.wav',opoznienie);
End;


procedure TFOperacje.PokazNazwePodObrazkiem();
(* Pod Ikoną z glosnikiem pokazuje polecenie z nim zwiazane (=nazwe obrazka) *)
var rob:string;
    dx : smallint; //czy nie zachodzi na Ramke
Begin
  With SpeedBtnGraj do begin
    rob:=ExtractFileNameOnly( FOperacje.tabOb[FOperacje.nrWylos].DajEwentualnyPlikWav() ); //daje z roszerz. *.wav, wiec ucinam
    LNazwa.Caption := rob;
    LNazwa.Top := Top+Height+1;
    LNazwa.Visible:=True;  //Visible MUSI byc przed LNazwa.Width, bo inaczej źle zmierzy szerokosc LNazwa'y...
    LNazwa.Left:= Left-((LNazwa.Width div 2) - (Width div 2));

    //ewentualna korekta, jesli LNazwa nachodzi na Ramka (moze sie zdarzyc przy duzych obrazkach i 'przycietym' w pionie SpeedBtnGraj
    if Lnazwa.Left+LNazwa.Width >= Ramka.Left-10 then begin
      dx := Lnazwa.Left+LNazwa.Width - Ramka.Left;
      LNazwa.Left := LNazwa.Left-dx-10;
    end;

  End;
End; (* Procedure *)

procedure TFOperacje.UstawDefaultowyKolorRamki_Ekranu_Napisu();
(* ***************************************************** *)
(* Kolory - odcienie szarosci dobrane przez Konsultantke *)
(* Ramka nie ma miec obramowania(!)                      *)
(* ***************************************************** *)
var kolor : Integer;
Begin
  kolor:=RGB(170, 170, 170);
  FOperacje.color := kolor;
  kolor:=RGB(224, 224, 224);
  Ramka.Brush.color := kolor;
  //Ustawienie obramowania Ramki tak, zeby go de facto nie bylo...;) :
  Ramka.Pen.Color := FOperacje.Color;
  (**)
  FOperacje.LNazwa.Font.Color := clBlack;
  (**)
  DostosujKoloryPozostalychObiektow();
End;

procedure TFOperacje.DostosujKoloryPozostalychObiektow();
(* Wywolywana w odpowiedzi na zmiane Tła (ekran); Nie Dotyczy Ramki(!) *)
(* tylko pozostalych obiektow (=ewentualne podpowiedzi-lapki).         *)
(* Zmieny kolorow ww. obiektow, tak, zeby mozna nadal bylo je widac.   *)
var i: SmallInt;
Begin
 for i := 1 to TMojImage.liczbaOb do
   if FOperacje.tabOb[i].JestLapka then
     FOperacje.tabOb[i].UstawKolorObramowaniaLapki(FOperacje.Color);
End;

Begin
  //Okreslenie polozenia plikow z nagrodami:
  komciePath := GetCurrentDir(*UTF8*)+'\Zasoby\komentarze\';
  oklaskiPath:= komciePath+'oklaski.wav';
  //dzwiek 'tada':
  tadaPath   := oklaskiPath;
  if FileExists(*UTF8*)('C:\Windows\Media\tada.wav') then
    tadaPath := 'C:\Windows\Media\tada.wav'
  else
  if FileExists(*UTF8*)('D:\Windows\Media\tada.wav') then
    tadaPath := 'D:\Windows\Media\tada.wav'  //dalej nie szukam, zostaje tadaPath=oklaskiPath
End.

