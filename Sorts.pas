unit Sorts;

interface

uses
  System.SysUtils,
  Windows,
  DateUtils,
  IOUtils;
// *****//
// Types//
// *****//

type
  PtBrig = ^TBrigadeNode;
  PtConstr = ^TConstrNode;
  PtComp = ^TCompareNode;
  PtTemp = ^TTempNode;
  TListData = (brigadeData, constrData);
  TTypes = (int, curr, rl, str, date);
  TFields = (name, code, spec, prior, memcnt, sqDev, price, addr, area,
    stDateToDo, brigCode, stDate);
  TString = string[20];
  TConstrArr = array of PtConstr;
  TBrigArr = array of PtBrig;

  TConstrInf = record
    constrCode: Integer;
    constrAddr: TString;
    constrSpec: TString;
    constrArea: Real;
    constrStDateToDo: TdateTime;
    constrPriority: String[1];
    constrBrigadCode: Integer;
    constrStDate: TdateTime;
    constrPrice: Currency;
  end;

  TBrigInf = record
    brigCode: Integer;
    brigName: TString;
    brigSpec: TString;
    brigMemCnt: Integer;
    brigSqDev: Real;
    brigPrice: Currency;
  end;

  TCFile = File of TConstrInf;
  TBFile = File of TBrigInf;
  TTFile = TextFile;

  TCompareNode = record
    int: Integer;
    str: TString;
    curr: Currency;
    rl: Real;
    date: TdateTime;
  end;

  TTempNode = record
    case TListData of
      brigadeData:
        (inf: TBrigInf);
      constrData:
        (inf1: TConstrInf);
  end;

  TBrigadeNode = record
    brigInf: TBrigInf;
    next: PtBrig;
  end;

  TConstrNode = record
    constrInf: TConstrInf;
    next: PtConstr;
  end;

  // **********//
  // Procedures//
  // **********//
function CompareConstrElems(const field: TFields; const constrElem: PtConstr;
  const elemToComp: PtComp): Integer;

function CompareBrigElems(const field: TFields; const brigElem: PtBrig;
  const elemToComp: PtComp): Integer;

procedure InitSortElemBrig(var tempElem: PtComp; const fields: TFields;
  const brigElem: PtBrig);

procedure InitSortElemConstr(var tempElem: PtComp; const fields: TFields;
  var constrElem: PtConstr);

function MergeSortConstr(var startArr: TConstrArr; const fields: TFields;
  const TypeSort: Integer): TConstrArr;

function MergeSortBrig(var startArr: TBrigArr; const fields: TFields;
  const TypeSort: Integer): TBrigArr;
procedure OutputElem(var elem; const data: TListData);

implementation

procedure OutputElem(var elem; const data: TListData);
begin
  case data of

    brigadeData:
      begin
        write('|', PtBrig(elem).brigInf.brigCode:5, '|');
        write(PtBrig(elem).brigInf.brigName:13, '|');
        write(PtBrig(elem).brigInf.brigSpec:14, '|');
        write(PtBrig(elem).brigInf.brigMemCnt:11, '|');
        write(PtBrig(elem).brigInf.brigSqDev:14:1, '|');
        Writeln(PtBrig(elem).brigInf.brigPrice:9:2, '|');
        Writeln('|***********************************************************************|');
      end;
    constrData:
      begin
        write('|', PtConstr(elem).constrInf.constrCode:5, '|');
        write(PtConstr(elem).constrInf.constrAddr:28, '|');
        write(PtConstr(elem).constrInf.constrSpec:16, '|');
        write(PtConstr(elem).constrInf.constrArea:10:2, '|');
        if (PtConstr(elem).constrInf.constrStDateToDo = 0) then
          write('<<Пусто>>':11, '|')
        else
          write(dateToStr(PtConstr(elem).constrInf.constrStDateToDo):10, '|');
        write(PtConstr(elem).constrInf.constrPriority:10, '|');
        if (PtConstr(elem).constrInf.constrBrigadCode = -1) then
          write('<<Пусто>>':11, '|')
        else
          write(PtConstr(elem).constrInf.constrBrigadCode:11, '|');
        if (PtConstr(elem).constrInf.constrStDate = 0) then
          write('<<Пусто>>':11, '|')
        else
          write(dateToStr(PtConstr(elem).constrInf.constrStDate):10, '|');
        Writeln(PtConstr(elem).constrInf.constrPrice:9:3, '|');
        Writeln('|**********************************************************************************************************************|');
      end;
  end;
end;

procedure Trim(var str: TString);
var
  i: Integer;
begin
  i := 1;
  while i <= Length(str) do
    if str[i] = ' ' then
      delete(str, i, 1)
    else
      inc(i);
end;

function TrimCompare(str1, str2: TString): Integer;
var
  i: Integer;
begin
  Trim(str1);
  Trim(str2);

  if (str1 = str2) then
    result := 0
  else if (str1 < str2) then
    result := 1
  else
    result := -1;

end;

function CompareConstrElems(const field: TFields; const constrElem: PtConstr;
  const elemToComp: PtComp): Integer;
begin
  case field of

    addr:
      begin
        result := TrimCompare(AnsiUpperCase(elemToComp.str),
          AnsiUpperCase(constrElem.constrInf.constrAddr));
      end;
    code:
      begin

        if (elemToComp.int = constrElem.constrInf.constrCode) then
          result := 0
        else if (elemToComp.int < constrElem.constrInf.constrCode) then
          result := 1
        else
          result := -1

      end;

    spec:

      begin
        result := TrimCompare(AnsiUpperCase(elemToComp.str),
          AnsiUpperCase(constrElem.constrInf.constrSpec));
      end;

    area:

      begin
        if (elemToComp.rl = constrElem.constrInf.constrArea) then
          result := 0
        else if (elemToComp.rl < constrElem.constrInf.constrArea) then
          result := 1
        else
          result := -1;
      end;

    stDate:
      begin
        result := CompareDate(constrElem.constrInf.constrStDate,
          elemToComp.date);
      end;

    price:
      begin
        if (elemToComp.curr = constrElem.constrInf.constrPrice) then
          result := 0
        else if (elemToComp.curr < constrElem.constrInf.constrPrice) then
          result := 1
        else
          result := -1;
      end;
    stDateToDo:
      begin
        result := CompareDate(constrElem.constrInf.constrStDateToDo,
          elemToComp.date);
      end;
    brigCode:
      begin
        if (elemToComp.int = constrElem.constrInf.constrBrigadCode) then
          result := 0
        else if (elemToComp.int < constrElem.constrInf.constrBrigadCode) then
          result := 1
        else
          result := -1;
      end;
    prior:
      begin
        if (elemToComp.str = constrElem.constrInf.constrPriority) then
          result := 0
        else if (elemToComp.str < constrElem.constrInf.constrPriority) then
          result := 1
        else
          result := -1;
      end;
  end;
end;

function CompareBrigElems(const field: TFields; const brigElem: PtBrig;
  const elemToComp: PtComp): Integer;
begin
  case field of

    name:
      begin
        result := TrimCompare(elemToComp.str, brigElem.brigInf.brigName)
      end;
    code:
      begin

        if (elemToComp.int = brigElem.brigInf.brigCode) then
          result := 0
        else if (elemToComp.int < brigElem.brigInf.brigCode) then
          result := 1
        else
          result := -1

      end;

    spec:

      begin
        result := TrimCompare(AnsiUpperCase(elemToComp.str),
          AnsiUpperCase(brigElem.brigInf.brigSpec));
      end;

    memcnt:

      begin
        if (elemToComp.int = brigElem.brigInf.brigMemCnt) then
          result := 0
        else if (elemToComp.int < brigElem.brigInf.brigMemCnt) then
          result := 1
        else
          result := -1;
      end;

    sqDev:
      begin
        if (elemToComp.rl = brigElem.brigInf.brigSqDev) then
          result := 0
        else if (elemToComp.rl < brigElem.brigInf.brigMemCnt) then
          result := 1
        else
          result := -1;
      end;

    price:
      begin
        if (elemToComp.curr = brigElem.brigInf.brigPrice) then
          result := 0
        else if (elemToComp.curr < brigElem.brigInf.brigPrice) then
          result := -1
        else
          result := 1;
      end;

  end;
end;

procedure InitSortElemBrig(var tempElem: PtComp; const fields: TFields;
  const brigElem: PtBrig);
begin

  case fields of
    code:
      tempElem.int := brigElem.brigInf.brigCode;
    name:
      tempElem.str := brigElem.brigInf.brigName;
    spec:
      tempElem.str := brigElem.brigInf.brigSpec;
    memcnt:
      tempElem.int := brigElem.brigInf.brigMemCnt;
    sqDev:
      tempElem.rl := brigElem.brigInf.brigSqDev;
    price:
      tempElem.curr := brigElem.brigInf.brigPrice;
  end;

end;

procedure InitSortElemConstr(var tempElem: PtComp; const fields: TFields;
  var constrElem: PtConstr);
begin

  case fields of
    code:
      tempElem.int := constrElem.constrInf.constrCode;
    addr:
      tempElem.str := constrElem.constrInf.constrAddr;
    spec:
      tempElem.str := constrElem.constrInf.constrSpec;
    price:
      tempElem.curr := constrElem.constrInf.constrPrice;
    area:
      tempElem.rl := constrElem.constrInf.constrArea;
    brigCode:
      tempElem.int := constrElem.constrInf.constrBrigadCode;
    prior:
      tempElem.str := constrElem.constrInf.constrPriority;
    stDate:
      tempElem.date := constrElem.constrInf.constrStDate;
    stDateToDo:
      tempElem.date := constrElem.constrInf.constrStDateToDo;
  end;

end;

function MergeSortConstr(var startArr: TConstrArr; const fields: TFields;
  const TypeSort: Integer): TConstrArr;
var
  n, m: Integer;
  LeftArr, RightArr: TConstrArr;
  function MergeConstr(var LeftArr, RightArr: TConstrArr): TConstrArr;
  var
    resArr: TConstrArr;
    i, j, k, temp: Integer;
  var
    compElem: PtComp;
  begin
    new(compElem);
    SetLength(resArr, Length(LeftArr) + Length(RightArr));
    i := 0;
    j := 0;
    for k := 0 to Length(resArr) - 1 do
    begin
      if (i < Length(LeftArr)) then
        InitSortElemConstr(compElem, fields, LeftArr[i]);
      if TypeSort = 1 then
      begin
        if (j = Length(RightArr)) or
          ((i < Length(LeftArr)) and ((CompareConstrElems(fields, RightArr[j],
          compElem) = 1) or (CompareConstrElems(fields, RightArr[j], compElem)
          = 0))) then
        begin
          resArr[k] := LeftArr[i];
          inc(i);
        end
        else
        begin
          resArr[k] := RightArr[j];
          inc(j);
        end;
      end
      else
      begin
        if (j = Length(RightArr)) or
          ((i < Length(LeftArr)) and ((CompareConstrElems(fields, RightArr[j],
          compElem) = -1) or (CompareConstrElems(fields, RightArr[j], compElem)
          = 0))) then
        begin
          resArr[k] := LeftArr[i];
          inc(i);
        end
        else
        begin
          resArr[k] := RightArr[j];
          inc(j);
        end;
      end;
    end;
    result := resArr;
    dispose(compElem);
  end;

begin
  if Length(startArr) = 1 then
    result := startArr
  else
  begin
    n := Length(startArr);
    m := n div 2;
    LeftArr := Copy(startArr, 0, m);
    RightArr := Copy(startArr, m, n - m);
    LeftArr := MergeSortConstr(LeftArr, fields, TypeSort);
    RightArr := MergeSortConstr(RightArr, fields, TypeSort);
    result := MergeConstr(LeftArr, RightArr);
  end;

end;

function MergeSortBrig(var startArr: TBrigArr; const fields: TFields;
  const TypeSort: Integer): TBrigArr;
var
  n, m: Integer;
  LeftArr, RightArr: TBrigArr;
  function MergeBrig(var LeftArr, RightArr: TBrigArr): TBrigArr;
  var
    resArr: TBrigArr;
    i, j, k, temp: Integer;
  var
    compElem: PtComp;
  begin
    new(compElem);
    SetLength(resArr, Length(LeftArr) + Length(RightArr));
    i := 0;
    j := 0;
    for k := 0 to Length(resArr) - 1 do
    begin
      if (i < Length(LeftArr)) then
        InitSortElemBrig(compElem, fields, LeftArr[i]);
      if TypeSort = 1 then
      begin
        if (j = Length(RightArr)) or
          ((i < Length(LeftArr)) and ((CompareBrigElems(fields, RightArr[j],
          compElem) = 1) or (CompareBrigElems(fields, RightArr[j], compElem)
          = 0))) then
        begin
          resArr[k] := LeftArr[i];
          inc(i);
        end
        else
        begin
          resArr[k] := RightArr[j];
          inc(j);
        end;
      end
      else
      begin
        if (j = Length(RightArr)) or
          ((i < Length(LeftArr)) and ((CompareBrigElems(fields, RightArr[j],
          compElem) = -1) or (CompareBrigElems(fields, RightArr[j], compElem)
          = 0))) then
        begin
          resArr[k] := LeftArr[i];
          inc(i);
        end
        else
        begin
          resArr[k] := RightArr[j];
          inc(j);
        end;
      end;
    end;
    result := resArr;
    dispose(compElem);
  end;

begin
  if Length(startArr) = 1 then
    result := startArr
  else
  begin
    n := Length(startArr);
    m := n div 2;
    LeftArr := Copy(startArr, 0, m);
    RightArr := Copy(startArr, m, n - m);
    LeftArr := MergeSortBrig(LeftArr, fields, TypeSort);
    RightArr := MergeSortBrig(RightArr, fields, TypeSort);
    result := MergeBrig(LeftArr, RightArr);
  end;

end;

end.
