unit SpecialFunction;

interface

uses System.SysUtils,
  DateUtils, Sorts;

procedure SpecialFunc(const constrHead: ptConstr; const brigHead: ptBrig);

implementation

type
  TDatesArr = array of TDate;

procedure InitStartArrays(const constrHead: ptConstr; const brigHead: ptBrig;
  var ConstrArr: TConstrArr; var BrigArr: TBrigArr);
var
  i: integer;
  tempConstr: ptConstr;
  tempBrig: ptBrig;
begin
  SetLength(ConstrArr, constrHead.constrInf.constrBrigadCode);
  SetLength(BrigArr, brigHead.brigInf.brigMemCnt);
  tempConstr := constrHead.next;
  i := 0;
  while tempConstr <> nil do
  begin
    ConstrArr[i] := tempConstr;
    inc(i);
    tempConstr := tempConstr.next;
  end;
  tempBrig := brigHead.next;
  i := 0;
  while tempBrig <> nil do
  begin
    BrigArr[i] := tempBrig;
    inc(i);
    tempBrig := tempBrig.next;
  end;

end;

procedure FindSpecBoarders(var arr; typeData: TlistData;
  var startIndex, finishIndex: integer);
begin
  case typeData of
    brigadeData:
      begin
        while (finishIndex <> High(TConstrArr(arr))) and
          (TConstrArr(arr)[finishIndex + 1].constrInf.constrSpec = TConstrArr
          (arr)[startIndex].constrInf.constrSpec) do
          inc(finishIndex);
      end;
    constrData:
      begin
        while (finishIndex <> High(TBrigArr(arr))) and
          (TBrigArr(arr)[finishIndex + 1].brigInf.brigSpec = TBrigArr(arr)
          [startIndex].brigInf.brigSpec) do
          inc(finishIndex);
      end;
  end;
end;

Function FindSpec(var BrigArr: TBrigArr; const Spec: TString): integer;
var
  i: integer;
  flag: boolean;
begin
  i := Low(BrigArr);
  Result := -1;
  flag := True;
  for i := Low(BrigArr) to High(BrigArr) do
  begin
    if (BrigArr[i].brigInf.brigSpec = Spec) and (flag) then
    begin
      Result := i;
      flag := false;
    end;

  end;
end;

Function RoundUpper(var op1, op2: real): integer;
begin
  if Frac(op1 / op2) <> 0 then
    Result := Trunc(op1 / op2) + 1
  else
    Result := Trunc(op1 / op2);
end;

procedure OutputResults(const ConstrArr: TConstrArr; const BrigArr: TBrigArr;
  const table: array of integer; const startDates: TDatesArr);
var
  i: integer;
begin
  for i := Low(table) to High(table) do
  begin
    ConstrArr[i].constrInf.constrBrigadCode := BrigArr[table[i]]
      .brigInf.brigCode;
    ConstrArr[i].constrInf.constrStDate := startDates[i];
    ConstrArr[i].constrInf.constrPrice :=
      RoundUpper(ConstrArr[i].constrInf.constrArea,
      BrigArr[table[i]].brigInf.brigSqDev) * BrigArr[table[i]]
      .brigInf.brigPrice;
  end;
end;

procedure MainLogicSpec(var ConstrArr: TConstrArr; var BrigArr: TBrigArr);
var
  tempStart, tempFin, tempBrig: TDate;
  datesStart: TDatesArr;
  table: Array Of integer;
  i, j, k: integer;
  tempsqDev: real;

  function FindFinDate(const startDate: TDate;
    const brigNum, constrNum: integer): TDate;
  var
    Date: TDate;
  begin
    Date := startDate;
    Result := IncDay(Date, RoundUpper(ConstrArr[constrNum].constrInf.constrArea,
      BrigArr[brigNum].brigInf.brigSqDev))
  end;

  function CheckIsProper(const tempDate: TDate;
    const tablePos, currBrig: integer): boolean;
  begin
    Result := false;
    if tempDate < datesStart[tablePos] then
      Result := True
    else if tempDate = datesStart[tablePos] then
    begin
      if (BrigArr[currBrig].brigInf.brigSqDev > BrigArr[table[tablePos]]
        .brigInf.brigSqDev) then
      begin
        if FindFinDate(datesStart[tablePos], table[tablePos], tablePos) <>
          FindFinDate(tempStart, currBrig, tablePos) then
          Result := True;
      end
      else if (BrigArr[currBrig].brigInf.brigSqDev < BrigArr[table[tablePos]]
        .brigInf.brigSqDev) then
      begin
        if FindFinDate(datesStart[tablePos], table[tablePos], tablePos)
          = FindFinDate(tempStart, currBrig, tablePos) then
          Result := True;
      end

    end;

  end;

begin
  SetLength(datesStart, length(ConstrArr));
  SetLength(table, length(ConstrArr));
  BrigArr := MergeSortBrig(BrigArr, area, 0);
  ConstrArr := MergeSortConstr(ConstrArr, area, 0);
  ConstrArr := MergeSortConstr(ConstrArr, StdatetoDo, 1);
  ConstrArr := MergeSortConstr(ConstrArr, prior, 1);
  for i := low(datesStart) to High(datesStart) do
    datesStart[i] := 0;

  for i := Low(ConstrArr) to High(ConstrArr) do
  begin

    table[i] := 0;
    for j := Low(BrigArr) to High(BrigArr) do
    begin
      tempStart := ConstrArr[i].constrInf.constrStDateToDo;
      for k := Low(table) to i - 1 do
      begin
        if (table[k] = j) and ((datesStart[k] < FindFinDate(tempStart, j, i)) or
          ((FindFinDate(datesStart[k], j, k) >= tempStart) and
          (datesStart[k] < FindFinDate(tempStart, j, i)))) then
        begin
          tempStart := FindFinDate(datesStart[k], j, k);
        end;
      end;
      if tempStart <= ConstrArr[i].constrInf.constrStDateToDo then
        tempStart := ConstrArr[i].constrInf.constrStDateToDo;

      if datesStart[i] = 0 then
      begin
        table[i] := j;
        datesStart[i] := tempStart;
      end
      else
      begin
        if CheckIsProper(tempStart, i, j) then
        begin
          table[i] := j;
          datesStart[i] := tempStart;
        end
      end;

    end;
  end;
  OutputResults(ConstrArr, BrigArr, table, datesStart);
end;

procedure OutputNotRegistered(const ConstrArr: TConstrArr);
var
  flag: boolean;
  i: integer;
begin
  flag := false;
  for i := Low(ConstrArr) to High(ConstrArr) do
  begin
    if (ConstrArr[i].constrInf.constrBrigadCode = -1) or
      (DaysBetween(ConstrArr[i].constrInf.constrStDate,
      ConstrArr[i].constrInf.constrStDateToDo) >= 10) then
    begin
      flag := True;
    end;
  end;
  if flag then
  begin
    writeln('Список объектов, на которые не удалось распределить бригады:');
    writeln;
    for i := Low(ConstrArr) to High(ConstrArr) do
    begin
      if (ConstrArr[i].constrInf.constrBrigadCode = -1) or
        (DaysBetween(ConstrArr[i].constrInf.constrStDate,
        ConstrArr[i].constrInf.constrStDateToDo) >= 10) then
      begin
        OutputElem(ConstrArr[i], constrData);
      end;
    end
  end
  else
    writeln('Спецфункция успешно применена ко всем объектам.');
  writeln(' Нажмите Enter. ');
  readln;

end;

procedure SpecialFunc(const constrHead: ptConstr; const brigHead: ptBrig);

var
  ConstrArrStart, ConstrArrMain: TConstrArr;
  BrigArrStart, BrigArrMain: TBrigArr;
  strtIndexC, finIndexC, strtIndexB, finIndexB: integer;
  i: integer;

  procedure InitMainArrays();
  var
    i: integer;
  begin
    for i := strtIndexB to finIndexB do
    begin
      BrigArrMain[i - strtIndexB] := BrigArrStart[i];
    end;
    for i := strtIndexC to finIndexC do
    begin
      ConstrArrMain[i - strtIndexC] := ConstrArrStart[i];
    end;
  end;

begin
  InitStartArrays(constrHead, brigHead, ConstrArrStart, BrigArrStart);

  BrigArrStart := MergeSortBrig(BrigArrStart, Spec, 1);
  ConstrArrStart := MergeSortConstr(ConstrArrStart, Spec, 1);

  strtIndexC := 0;
  finIndexC := 0;
  strtIndexB := 0;
  finIndexB := 0;

  while strtIndexC <= High(ConstrArrStart) do
  begin;
    FindSpecBoarders(ConstrArrStart, constrData, strtIndexC, finIndexC);
    strtIndexB := FindSpec(BrigArrStart, ConstrArrStart[strtIndexC]
      .constrInf.constrSpec);
    finIndexB := strtIndexB;
    if strtIndexB <> -1 then
    begin
      FindSpecBoarders(BrigArrStart, brigadeData, strtIndexB, finIndexB);
      SetLength(BrigArrMain, finIndexB - strtIndexB + 1);
      SetLength(ConstrArrMain, finIndexC - strtIndexC + 1);
      InitMainArrays();
      MainLogicSpec(ConstrArrMain, BrigArrMain);
    end;
    strtIndexC := finIndexC + 1;
    finIndexC := strtIndexC;

  end;
  OutputNotRegistered(ConstrArrStart);
end;

end.
