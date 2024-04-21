program YP;

{$APPTYPE CONSOLE}
{$R *.res}

uses
  System.SysUtils,
  Windows,
  DateUtils,
  IOUtils,
  SpecialFunction in 'SpecialFunction.pas',
  Sorts in 'Sorts.pas';

procedure IsValidNum(var value; const Id: TTypes;
  const purpOp: Integer); forward;
procedure SearchBrigElem(const brigHead: PtBrig); forward;
procedure SearchConstrElem(const constrHead: PtConstr); forward;

function InputFileName(): Tstring;
var
  flagcheck: boolean;
  function IsValidName(CheckStr: Tstring): boolean;
  var
    i: Integer;
  begin
    result := true;
    if (CheckStr[1] = ' ') or (Length(CheckStr) = 0) then
      result := false
    else
      for i := 1 to Length(CheckStr) do
      begin
        if (CheckStr[i] <= #31) or (CheckStr[i] = '<') or (CheckStr[i] = '>') or
          (CheckStr[i] = '/') or (CheckStr[i] = '\') or (CheckStr[i] = '|') or
          (CheckStr[i] = ':') or (CheckStr[i] = '?') or (CheckStr[i] = '*') or
          (CheckStr[i] = '"') then
          result := false;
      end;
    if CheckStr[Length(CheckStr)] = ' ' then
      result := false;

  end;

begin
  flagcheck := false;
  Writeln('Введите название файла');
  repeat
    readln(result);
    if not IsValidName(result) then
      Writeln('Имя файла введено некорректно. Пожалуйста повторите попытку')
    else
      flagcheck := true;
  until flagcheck;
end;

procedure OpenFileBrigForReading(var FBrigs: TBFile; const filePath: String);
begin
  Assign(FBrigs, filePath + '\Brigades');
{$I-}
  Reset(FBrigs);
{$I+}
  If IOResult <> 0 Then
    Rewrite(FBrigs);

end;
procedure OpenFileBrigForWriting(var FBrigs: TBFile; const filePath: String);
begin
  Assign(FBrigs, filePath + '\Brigades');
    Rewrite(FBrigs);

end;

procedure OpenFileConstrForWriting(var FConstr: TCFile; const filePath: String);
begin
  Assign(FConstr, filePath + '\Constructions');
    Rewrite(FConstr);

end;
procedure OpenFileConstrForReading(var FConstr: TCFile; const filePath: String);
begin
  Assign(FConstr, filePath + '\Constructions');
{$I-}
  Reset(FConstr);
{$I+}
  If IOResult <> 0 Then
    Rewrite(FConstr);

end;

procedure OpenFileSF(var FResultSf: TTFile; const filePath: String);
begin
  Assign(FResultSf, filePath + '\Results');
  Rewrite(FResultSf);
end;
//
procedure WriteInTextFile(const constrHead: PtConstr; const brigHead: PtBrig;
  const FResultSf: TTFile);
var
  tempConstr: PtConstr;
  tempBrig: PtBrig;
  flag: boolean;
begin
  tempBrig := brigHead.next;

  Writeln(FResultSf, 'Информация о распределении бригад по объектам':45);
  Writeln(FResultSf, 'Дата: ' + DateToStr(Now) + ' ' + TimeToStr(Now):18);

  while tempBrig <> nil do
  begin
  tempConstr := constrHead.next;
    Writeln(FResultSf,
      '----------------------------------------------------':51);
    flag := false;
    Writeln(FResultSf, 'Код бригады: ':30, tempBrig.brigInf.brigCode:21, '|');
    Writeln(FResultSf, 'Имя бригады: ':30, tempBrig.brigInf.brigName:21, '|');
    Writeln(FResultSf, 'Специализация бригады: ':30,
      tempBrig.brigInf.brigSpec:21, '|');
    Writeln(FResultSf, 'Количество рабочих бригады: ':30,
      tempBrig.brigInf.brigName:21, '|');
    Writeln(FResultSf, 'Выработка бригады в день: ':30,
      tempBrig.brigInf.brigSqDev:21:4, '|');
    Writeln(FResultSf, 'Стоимость дня работы бригады: ':30,
      tempBrig.brigInf.brigPrice:21:4, '|');
    Writeln(FResultSf,
      '****************************************************':51);
    Writeln(FResultSf, 'Информация о распределении данной бригады':51, '|');
    Writeln(FResultSf,
      '****************************************************':51);
    Writeln(FResultSf,
      'Список объектов, на которых работает данная бригада':51, '|');
    Writeln(FResultSf,
      '****************************************************':51);

    while tempConstr <> nil do
    begin
      if tempConstr.constrInf.constrBrigadCode = tempBrig.brigInf.brigCode then
      begin
        flag := true;
        Writeln(FResultSf, 'Код объекта: ':30,
          tempConstr.constrInf.constrCode:21, '|');
        Writeln(FResultSf, 'Адрес объекта: ':30,
          tempConstr.constrInf.constrAddr:21, '|');
        Writeln(FResultSf, 'Дата начала работы: ':30,
          DateToStr(tempConstr.constrInf.constrStDate):21, '|');
        Writeln(FResultSf, 'Стоимость всей работы: ':30,
          tempConstr.constrInf.constrPrice:21:4, '|');
        Writeln(FResultSf,
          '****************************************************':50);
      end;
      tempConstr := tempConstr.next;
    end;

    if flag = false then
      Writeln(FResultSf,
        'Данная бригада не распределена ни на один объект':51, '|');
    Writeln(FResultSf,
      '----------------------------------------------------':51);

    Writeln(FResultSf);
    Writeln(FResultSf);

    tempBrig := tempBrig.next;
  end;
  Close(FResultSf);
end;

procedure WriteInConstrFile(const constrHead: PtConstr; const FConstr: TCFile);
var
  temp: PtConstr;
begin
  temp := constrHead;
  while temp <> nil do
  begin
    write(FConstr, temp.constrInf);
    temp := temp.next;
  end;
  Close(FConstr);
end;

procedure WriteInBrigFile(const brigHead: PtBrig; const FBrig: TBFile);
var
  temp: PtBrig;
begin
  temp := brigHead;
  while temp <> nil do
  begin
    write(FBrig, temp.brigInf);
    temp := temp.next;
  end;
  Close(FBrig);
end;

procedure ReadInConstrList(var constrHead, constrTail: PtConstr;
  const FConstr: TCFile);
var
  temp: PtConstr;
begin
  if FileSize(FConstr) <> 0 then
  begin
    read(FConstr, constrHead.constrInf);
    temp := constrHead;
    temp.next := nil;
    while not Eof(FConstr) do
    begin
      new(temp.next);
      read(FConstr, temp.next.constrInf);
      temp := temp.next;
    end;
    temp.next := nil;
    constrTail := temp;
  end;
  Close(FConstr);
end;

procedure ReadInBrigList(var brigHead: PtBrig; const FBrig: TBFile);
var
  temp: PtBrig;
begin
  if FileSize(FBrig) <> 0 then
  begin
    read(FBrig, brigHead.brigInf);
    temp := brigHead;
    temp.next := nil;
    while not Eof(FBrig) do
    begin
      new(temp.next);
      read(FBrig, temp.next.brigInf);
      temp := temp.next;
    end;
    temp.next := nil;
  end;
  Close(FBrig);
end;

function IsDirectoryExist(const typeDirectory: Integer): boolean;
begin
  case typeDirectory of
    0:
      begin
        if not(DirectoryExists(GetCurrentDir() + '\Sessions')) then
        begin
          CreateDir(GetCurrentDir() + '\Sessions');

          result := false;
        end
        else
          result := true;
      end;
    1:
      begin
        if not(DirectoryExists(GetCurrentDir() + '\SpecFuncResults')) then
        begin
          CreateDir(GetCurrentDir() + '\SpecFuncResults');

          result := false;
        end
        else
          result := true;
      end;
  end;

end;

procedure ChooseSession(var realPath: String; var freadB, freadC: boolean;
  const typeDirectory: Integer);
const
  directoryNames: array [0 .. 1] of Tstring = ('\Sessions', '\SpecFuncResults');
var
  foldersPaths: array of string;
  resultNum: Integer;
  resultStr: Tstring;
  flagcheck: boolean;
  path: String;
begin
  resultNum := 0;
  flagcheck := true;
  SetLength(foldersPaths, Length(TDirectory.GetDirectories(GetCurrentDir() +
    directoryNames[typeDirectory])));
  for path in TDirectory.GetDirectories
    ((GetCurrentDir() + directoryNames[typeDirectory])) do
  begin
    foldersPaths[resultNum] := path;
    Writeln(resultNum + 1, ' <--> ', ExtractFileName(path));
    inc(resultNum);
  end;
  if (Length(foldersPaths) = 0) then
  begin
    Writeln('Файлов для чтения не существует.');
    freadC := false;
    freadB := false;
    resultStr := InputFileName;

    CreateDir(GetCurrentDir() + directoryNames[typeDirectory] + '\' +
      resultStr);

    realPath := GetCurrentDir() + directoryNames[typeDirectory] + '\' +
      resultStr;
  end
  else
  begin
    Writeln('Выберите номер директории, с которой хотите работать или введите 0, чтобы создать новую');
    while flagcheck do
    begin
      freadB := true;
      freadC := true;
      readln(resultStr);
      if (resultStr >= '1') and (resultStr <= IntToStr(Length(foldersPaths)))
      then
      begin
        flagcheck := false;
        realPath := foldersPaths[StrToInt(resultStr) - 1];
      end
      else if (resultStr = '0') then
      begin
        resultStr := InputFileName;
        CreateDir(GetCurrentDir() + directoryNames[typeDirectory] + '\' +
          resultStr);

        realPath := GetCurrentDir() + directoryNames[typeDirectory] + '\' +
          resultStr;
        Writeln('Данная информация была связана с директорией ', resultStr,
          ' в директории', copy(directoryNames[typeDirectory], 0,
          Length(directoryNames[typeDirectory]) - 1));
        flagcheck := false;
      end
      else
        Writeln('Данные введены неверно. Повторите попытку');
    end;
  end;
end;

procedure CheckSessions(var realPath: String; var freadC, freadB: boolean;
const typeDirectory: Integer);
begin
  if IsDirectoryExist(typeDirectory) then
    ChooseSession(realPath, freadB, freadC, typeDirectory);
end;

procedure OutputBrigHeadList;
begin
  Writeln('|-----------------------------------------------------------------------|');
  Writeln('|                             Список бригад                             |');
  Writeln('|-----|-------------|--------------|-----------|--------------|---------|');
  Writeln('| Код |     Имя     | Cпециализация|Кол-во раб.|Выраб. м2/день|Стоимость|');
  Writeln('|-----|-------------|--------------|-----------|--------------|---------|');
end;

procedure OutputBrigList(const brigHead: PtBrig);
var
  temp: PtBrig;
begin
  temp := brigHead.next;
  OutputBrigHeadList;
  while temp <> nil do
  begin
    OutputElem(temp, brigadeData);
    temp := temp.next;
  end;
  Writeln('|-----------------------------------------------------------------------|');
end;

procedure OutputConstrHeadList;
begin
  Writeln('|----------------------------------------------------------------------------------------------------------------------|');
  Writeln('|                                               Список объектов                                                        |');
  Writeln('|-----|----------------------------|----------------|----------|----------|----------|-----------|---------------------|');
  Writeln('| Код |            Адрес           | Cпециализация  |Площадь\м2|Необх.дата|Приоритет |Код Бригады|Дата Начала|Стоимость|');
  Writeln('|-----|----------------------------|----------------|----------|----------|----------|-----------|-----------|---------|');
end;

procedure OutputConstrList(const constrHead: PtConstr);
var
  temp: PtConstr;
begin
  temp := constrHead.next;
  OutputConstrHeadList;
  while temp <> nil do
  begin
    OutputElem(temp, constrData);
    temp := temp.next;
  end;
  Writeln('|----------------------------------------------------------------------------------------------------------------------|');
end;

procedure ClearScreen(const OriginX, OriginY: Integer; CountSize: Integer);
var
  stdout: THandle;
  csbi: TConsoleScreenBufferInfo;
  ConsoleSize: DWORD;
  NumWritten: DWORD;
  Origin: TCoord;
begin
  stdout := GetStdHandle(STD_OUTPUT_HANDLE);
  Win32Check(stdout <> INVALID_HANDLE_VALUE);
  Win32Check(GetConsoleScreenBufferInfo(stdout, csbi));
  if CountSize <= 0 then
    CountSize := csbi.dwSize.Y;
  ConsoleSize := csbi.dwSize.X * CountSize;
  Origin.X := OriginX;
  Origin.Y := OriginY;
  Win32Check(FillConsoleOutputCharacter(stdout, ' ', ConsoleSize, Origin,
    NumWritten));
  Win32Check(SetConsoleCursorPosition(stdout, Origin));
end;

procedure InitLists(var brigadeHead: PtBrig;
  var constrHead, constrTail: PtConstr);
begin
  new(brigadeHead);
  with brigadeHead^.brigInf do
  begin
    brigCode := 1;
    brigName := '';
    brigSpec := '';
    brigMemCnt := 0;
    brigSqDev := 0;
    brigPrice := 0;
  end;
  brigadeHead.next := nil;
  new(constrHead);
  constrTail := constrHead;
  with constrHead^.constrInf do
  begin
    constrCode := 1;
    constrAddr := '';
    constrSpec := '';
    constrArea := 0;
    constrStDateToDo := 0;
    constrPriority := '';
    constrBrigadCode := 0;
    constrStDate := 0;
    constrPrice := 0;

  end;
  constrHead.next := nil;
end;

function IsValDate(var tryString: Tstring; const purpOp: Integer): boolean;
var
  err, i: Integer;
  year, month, day: word;

begin
  err := 0;
  i := 1;

  Trim(tryString);
  result := false;
  val(copy(tryString, 1, 2), day, err);
  if (err = 0) and (tryString[3] = '.') and (tryString[6] = '.') then
  begin
    val(copy(tryString, 4, 2), month, err);
    if err = 0 then
    begin
      val(copy(tryString, 7, 10), year, err);
      if (err = 0) and IsValidDate(year, month, day) and (year >= 1900) then
        result := true;
    end;
  end;

end;

procedure InputDate(var date: TdateTime; const purpOp: Integer);
var
  tryString: Tstring;
  flag: boolean;
begin
  Writeln('Формат даты:  дд.мм.гггг');
  readln(tryString);
  flag := true;
  if not((purpOp = 1) and (tryString = '')) then
  begin
    while not((IsValDate(tryString, purpOp)) and (flag)) do
    begin
      Writeln('Дата введена неверно. Повторите попытку');
      readln(tryString);
      if (tryString = '') and (purpOp = 1) then
        flag := true;
    end;
    if (flag = true) then
      date := StrToDate(tryString);
  end;
end;

procedure IsValidNum(var value; const Id: TTypes; const purpOp: Integer);
var
  tryString: Tstring;
  flag: boolean;
  function ValElem: Integer;
  var
    err: Integer;
  begin
    case Id of
      int:
        begin
          val(tryString, Integer(value), err);
          err := Ord((Integer(value) <= 0) or (err = 1));
        end;
      curr:
        begin
          val(tryString, Currency(value), err);
          err := Ord((Currency(value) <= 0) or (err = 1));
        end;
      rl:
        begin
          val(tryString, Real(value), err);
          err := Ord((Real(value) <= 0) or (err = 1));
        end;
    end;
    result := err;
  end;

begin
  readln(tryString);
  flag := true;
  if not((purpOp = 1) and (tryString = '')) then
    while (flag) and (ValElem <> 0) do
    begin
      Writeln('Неверный ввод. Повторите попытку');
      readln(tryString);
      if ((purpOp = 1) and (tryString = '')) then
        flag := false;
    end;
end;

procedure SelectOption(var fEndProc: boolean);
var
  flagcheck: boolean;
  resultString: string[10];
begin
  flagcheck := true;

  while flagcheck do
  begin
    readln(resultString);
    if Length(resultString) = 1 then
    begin
      case resultString[1] of
        '1':
          begin
            ClearScreen(0, 0, -1);
            fEndProc := false;
            flagcheck := false;
          end;

        '0':
          begin
            ClearScreen(0, 0, -1);
            fEndProc := true;
            flagcheck := false;
          end
      else
        begin
          Writeln('Неверный ввод. Повторите попытку');
        end;

      end;
    end
    else
    begin
      Writeln('Неверный ввод. Повторите попытку');
    end;
  end;
end;

procedure CheckPriority(var resultString: Tstring; const purpOp: Integer);
var
  flag: boolean;
begin
  flag := false;
  if (purpOp = 0) then
    while not((resultString[1] <= '2') and (resultString[1] >= '0') and
      (Length(resultString) < 2)) do
    begin
      Writeln('Данные введены неверно. Повторите попытку');
      readln(resultString);
    end
  else
    while not(flag) do
    begin
      if (resultString = '') or
        ((resultString[1] <= '2') and (resultString[1] >= '0') and
        (Length(resultString) < 2)) then
        flag := true
      else
      begin
        Writeln('Данные введены неверно. Повторите попытку');
        readln(resultString);
      end;

    end
end;

procedure InputInfoConstr(var newElem: PtConstr; var fStopInput: boolean;
  const purpOp: Integer);
var
  resultString: Tstring;

begin

  if purpOp = 0 then
  begin
    Writeln('Код объекта: ', newElem.constrInf.constrCode);
    Writeln('________________________________________________');
  end
  else
  begin
    OutputElem(newElem, constrData);
  end;

  Writeln('Введите адрес объекта');
  if purpOp = 0 then
  begin
    readln(newElem.constrInf.constrAddr);
    ClearScreen(0, 1, 3);
    Writeln('Адрес объекта: ', newElem.constrInf.constrAddr);
    Writeln('________________________________________________');
  end
  else
  begin
    readln(resultString);
    if resultString <> '' then
      newElem.constrInf.constrAddr := resultString;
    ClearScreen(0, 1, -1);
    OutputElem(newElem, constrData);
  end;

  Writeln('Введите специализацию объекта');
  if purpOp = 0 then
  begin
    readln(newElem.constrInf.constrSpec);
    ClearScreen(0, 2, 3);
    Writeln('Специализация объекта: ', newElem.constrInf.constrSpec);
    Writeln('________________________________________________');
  end
  else
  begin
    readln(resultString);
    if resultString <> '' then
      newElem.constrInf.constrSpec := resultString;
    ClearScreen(0, 1, -1);
    OutputElem(newElem, constrData);
  end;

  Writeln('Введите площадь объекта:');

  IsValidNum(newElem.constrInf.constrArea, rl, purpOp);
  if purpOp = 0 then
  begin
    ClearScreen(0, 3, -1);
    Writeln('Площадь объекта: ', newElem.constrInf.constrArea:4:2);
    Writeln('________________________________________________');
  end
  else
  begin
    ClearScreen(0, 1, -1);
    OutputElem(newElem, constrData);
  end;

  Writeln('Введите дату, с которой можно начинать работы ');
  InputDate(newElem.constrInf.constrStDateToDo, purpOp);
  if purpOp = 0 then
  begin
    ClearScreen(0, 4, -1);
    Writeln('Необходимая дата начала работы на объекте: ',
      DateToStr(newElem.constrInf.constrStDateToDo));
    Writeln('________________________________________________');
  end
  else
  begin
    ClearScreen(0, 1, -1);
    OutputElem(newElem, constrData);
  end;

  Writeln('Введите приоритет срочности объекта: ', #10, 'по убыванию   0 -- 2');
  readln(resultString);
  CheckPriority(resultString, purpOp);
  newElem.constrInf.constrPriority := resultString;
  if (purpOp = 0) then
  begin
    ClearScreen(0, 5, -1);
    Writeln('Приоритет объекта: ', newElem.constrInf.constrPriority);
    Writeln('________________________________________________');
  end
  else
  begin
    ClearScreen(0, 1, -1);
    OutputElem(newElem, constrData);
  end;

  if purpOp = 0 then
  begin
    ClearScreen(0, 6, 1);
    newElem.constrInf.constrBrigadCode := 0;
    Writeln('Код назначенной бригады: <<Пусто>>');
    Writeln('________________________________________________');
  end
  else
  begin
    Writeln('Введите код назначенной бригады :');
    IsValidNum(newElem.constrInf.constrBrigadCode, int, purpOp);
    ClearScreen(0, 1, -1);
    OutputElem(newElem, constrData);
  end;

  if purpOp = 0 then
  begin
    ClearScreen(0, 7, 1);
    newElem.constrInf.constrStDate := 0;
    Writeln('Фактическая дата начала работы: <<Пусто>>');
    Writeln('________________________________________________');
  end
  else
  begin
    Writeln('Введите фактическую дату начала работ:');
    InputDate(newElem.constrInf.constrStDate, purpOp);
    ClearScreen(0, 1, -1);
    OutputElem(newElem, constrData);
  end;

  if purpOp = 0 then
  begin
    ClearScreen(0, 8, 1);
    newElem.constrInf.constrPrice := 0;
    Writeln('Стоимость работы: <<Пусто>>');
    Writeln('________________________________________________');
    Writeln('Вы хотите добавить данный объект в список', #10,
      '1 -- Да                 0 -- Нет');

    SelectOption(fStopInput);
  end
  else
  begin
    Writeln('Введите стоимость работ:');
    IsValidNum(newElem.constrInf.constrPrice, curr, purpOp);
    ClearScreen(0, 1, -1);
    OutputElem(newElem, constrData);
  end;

end;

procedure InputInfoBrig(var newElem: PtBrig; var fStopInput: boolean;
  const purpOp: Integer);
var
  resultString: Tstring;
begin

  if purpOp = 0 then
  begin
    Writeln('Код бригады: ', newElem.brigInf.brigCode);
    Writeln('________________________________________________');
  end
  else
    OutputElem(newElem, brigadeData);

  Writeln('Введите имя бригады');
  if purpOp = 0 then
  begin
    readln(newElem.brigInf.brigName);
    ClearScreen(0, 1, 3);
    Writeln('Имя бригады: ', newElem.brigInf.brigName);
    Writeln('________________________________________________');
  end
  else
  begin
    readln(resultString);
    if resultString <> '' then
      newElem.brigInf.brigName := resultString;
    ClearScreen(0, 1, -1);
    OutputElem(newElem, brigadeData);
  end;

  Writeln('Введите специализацию бригады');
  if purpOp = 0 then
  begin
    readln(newElem.brigInf.brigSpec);
    ClearScreen(0, 2, 3);
    Writeln('Специализация бригады: ', newElem.brigInf.brigSpec);
    Writeln('________________________________________________');
  end
  else
  begin
    readln(resultString);
    if resultString <> '' then
      newElem.brigInf.brigSpec := resultString;
    ClearScreen(0, 1, -1);
    OutputElem(newElem, brigadeData);
  end;

  Writeln('Введите количество членов бригады');
  if purpOp = 0 then
  begin
    IsValidNum(newElem.brigInf.brigMemCnt, int, 0);
    ClearScreen(0, 3, -1);
    Writeln('Количество членов бригады: ', newElem.brigInf.brigMemCnt);
    Writeln('________________________________________________');
  end
  else
  begin
    IsValidNum(newElem.brigInf.brigMemCnt, int, 1);
    ClearScreen(0, 1, -1);
    OutputElem(newElem, brigadeData);
  end;

  Writeln('Введите выработку бригады в м2/день');
  if purpOp = 0 then
  begin
    IsValidNum(newElem.brigInf.brigSqDev, rl, 0);
    ClearScreen(0, 4, -1);
    Writeln('Выработка бригады в день: ', newElem.brigInf.brigSqDev:4:2);
    Writeln('________________________________________________');
  end
  else
  begin
    IsValidNum(newElem.brigInf.brigSqDev, rl, 1);
    ClearScreen(0, 1, -1);
    OutputElem(newElem, brigadeData);
  end;
  Writeln('Введите стоимость дня работы бригады');
  if purpOp = 0 then
  begin
    IsValidNum(newElem.brigInf.brigPrice, curr, 0);
    ClearScreen(0, 5, -1);
    Writeln('Стоимость дня работы: ', newElem.brigInf.brigPrice:4:2);
    Writeln('________________________________________________');
    Writeln('Вы хотите добавить данный объект в список', #10,
      '1 -- Да                 0 -- Нет');

    SelectOption(fStopInput);
  end
  else
  begin
    IsValidNum(newElem.brigInf.brigPrice, curr, 1);
    ClearScreen(0, 1, -1);
    OutputElem(newElem, brigadeData);
  end;

end;

procedure AddElemToBrigList(var brigadeHead: PtBrig);
var
  temp: PtBrig;
  newElem: PtBrig;
  fStopInput: boolean;

begin
  new(newElem);
  repeat
    newElem.brigInf.brigCode := brigadeHead.brigInf.brigCode;
    InputInfoBrig(newElem, fStopInput, 0);
    if not fStopInput then
    begin
      temp := brigadeHead.next;
      new(brigadeHead.next);
      brigadeHead.next.next := temp;

      with brigadeHead.next.brigInf do
      begin
        brigCode := newElem.brigInf.brigCode;
        brigName := (newElem.brigInf.brigName);
        brigSpec := newElem.brigInf.brigSpec;
        brigMemCnt := newElem.brigInf.brigMemCnt;
        brigSqDev := newElem.brigInf.brigSqDev;
        brigPrice := newElem.brigInf.brigPrice;
      end;
      inc(brigadeHead.brigInf.brigMemCnt);
      inc(brigadeHead.brigInf.brigCode);
      Writeln('Хотите продолжить?', #10, '1 -- Да                 0 -- Нет');
      SelectOption(fStopInput);
    end
    else
    begin
      Writeln('Хотите начать заново?', #10, '1 -- Да                 0 -- Нет');
      SelectOption(fStopInput);
    end;

  until fStopInput;
  dispose(newElem);
end;

procedure AddElemToConstrList(const constrHead: PtConstr;
  var constrTail: PtConstr);
var
  newElem: PtConstr;
  fStopInput: boolean;
begin
  new(newElem);
  repeat
    newElem.constrInf.constrCode := constrHead.constrInf.constrCode;
    InputInfoConstr(newElem, fStopInput, 0);
    if not fStopInput then
    begin
      new(constrTail.next);
      constrTail := constrTail.next;
      constrTail.next := nil;
      inc(constrHead.constrInf.constrBrigadCode);
      inc(constrHead.constrInf.constrCode);
      with constrTail.constrInf do
      begin
        constrCode := newElem.constrInf.constrCode;
        constrAddr := newElem.constrInf.constrAddr;
        constrSpec := newElem.constrInf.constrSpec;
        constrArea := newElem.constrInf.constrArea;
        constrStDateToDo := newElem.constrInf.constrStDateToDo;
        constrPriority := newElem.constrInf.constrPriority;
        constrBrigadCode := newElem.constrInf.constrBrigadCode;
        constrStDate := newElem.constrInf.constrStDate;
        constrPrice := newElem.constrInf.constrPrice;
      end;
      Writeln('Хотите продолжить?', #10, '1 -- Да                 0 -- Нет');
      SelectOption(fStopInput);
    end
    else
    begin
      Writeln('Хотите начать заново?', #10, '1 -- Да                 0 -- Нет');
      SelectOption(fStopInput);
    end;

  until fStopInput;
  dispose(newElem);
end;

procedure InputSearchElem(var tempElem: PtComp; const Fields: TFields;
  data: TListData);
begin
  Writeln('Введите элемент, который хотите найти');
  if (Fields = addr) or (Fields = name) or (Fields = spec) then
    readln(tempElem.str)
  else if (Fields = code) or (Fields = brigCode) or (Fields = memcnt) then
    IsValidNum(tempElem.int, int, 0)
  else if (Fields = area) or (Fields = sqDev) then
    IsValidNum(tempElem.rl, rl, 0)
  else if (Fields = stDate) or (Fields = stDateToDo) then
    InputDate(tempElem.date, 0)
  else
    IsValidNum(tempElem.curr, curr, 0);

end;

procedure InitSearch(var Fields: TFields; var listType: TListData);
var
  flagcheck: boolean;
  resultString: Tstring;
begin
  flagcheck := true;
  case listType of

    brigadeData:
      begin
        Writeln('Введите значение поля, с которым хотите произвести данную процедуру:');
        Writeln('1 -- Код бригады', #10, '2 -- Имя бригады', #10,
          '3 -- Специализация бригады', #10, '4 -- Стоимость работы бригады',
          #10, '5 -- Количество работников бригады', #10,
          '6 -- Выработка бригады');
        while flagcheck do
        begin
          readln(resultString);
          if Length(resultString) = 1 then
          begin
            case resultString[1] of
              '1':
                begin
                  ClearScreen(0, 0, -1);
                  Fields := code;
                  flagcheck := false;
                end;

              '2':
                begin
                  ClearScreen(0, 0, -1);
                  Fields := name;
                  flagcheck := false;
                end;

              '3':
                begin
                  ClearScreen(0, 0, -1);
                  Fields := spec;
                  flagcheck := false;
                end;
              '4':
                begin
                  ClearScreen(0, 0, -1);
                  Fields := price;
                  flagcheck := false;
                end;
              '5':
                begin
                  ClearScreen(0, 0, -1);
                  Fields := memcnt;
                  flagcheck := false;
                end;
              '6':
                begin
                  ClearScreen(0, 0, -1);
                  Fields := sqDev;
                  flagcheck := false;
                end;
            else
              begin
                Writeln('Неверный ввод. Повторите попытку');
              end;

            end;
          end
          else
          begin
            Writeln('Неверный ввод. Повторите попытку');
          end;
        end;
      end;
    constrData:
      begin
        Writeln('Введите значение поля, с которым хотите произвести данную процедуру');
        Writeln('1 -- Код объекта', #10, '2 -- Адрес объекта', #10,
          '3 -- Специализация объекта', #10, '4 -- Стоимость работы на объекте',
          #10, '5 -- Площадь объекта', #10,
          '6 -- Дата с которого можно начать работы', #10,
          '7 -- Дата начала работы', #10, '8 -- Код назначенной бригады', #10,
          '9 -- Приоритет работы');
        while flagcheck do
        begin
          readln(resultString);
          if Length(resultString) = 1 then
          begin
            case resultString[1] of
              '1':
                begin
                  ClearScreen(0, 0, -1);
                  Fields := code;
                  flagcheck := false;
                end;

              '2':
                begin
                  ClearScreen(0, 0, -1);
                  Fields := addr;
                  flagcheck := false;
                end;

              '3':
                begin
                  ClearScreen(0, 0, -1);
                  Fields := spec;
                  flagcheck := false;
                end;

              '4':
                begin
                  ClearScreen(0, 0, -1);
                  Fields := price;
                  flagcheck := false;
                end;

              '5':
                begin
                  ClearScreen(0, 0, -1);
                  Fields := area;
                  flagcheck := false;
                end;

              '6':
                begin
                  ClearScreen(0, 0, -1);
                  Fields := stDateToDo;
                  flagcheck := false;
                end;

              '7':
                begin
                  ClearScreen(0, 0, -1);
                  Fields := stDate;
                  flagcheck := false;
                end;

              '8':
                begin
                  ClearScreen(0, 0, -1);
                  Fields := brigCode;
                  flagcheck := false;
                end;
              '9':
                begin
                  ClearScreen(0, 0, -1);
                  Fields := prior;
                  flagcheck := false;
                end;
            else
              begin
                Writeln('Неверный ввод. Повторите попытку');
              end;

            end;
          end
          else
          begin
            Writeln('Неверный ввод. Повторите попытку');
          end;
        end;
      end;
  end;
end;

procedure SearchBrigElem(const brigHead: PtBrig);
var
  tempBrig: PtBrig;
  tempElem: PtComp;
  Fields: TFields;
  flagFound: boolean;
  data: TListData;
begin
  new(tempElem);
  data := brigadeData;
  InitSearch(Fields, data);
  InputSearchElem(tempElem, Fields, data);
  flagFound := false;
  tempBrig := brigHead;
  OutputBrigHeadList;
  while tempBrig.next <> nil do
  begin
    if CompareBrigElems(Fields, tempBrig.next, tempElem) = 0 then
    begin
      OutputElem(tempBrig.next, brigadeData);
      flagFound := true;
    end;
    tempBrig := tempBrig.next;
  end;
  if not flagFound then
    Writeln('|                          Элемент не найден                            |');
  Writeln('|-----------------------------------------------------------------------|');
  dispose(tempElem);
end;

procedure SearchConstrElem(const constrHead: PtConstr);
var
  tempConstr: PtConstr;
  tempElem: PtComp;
  Fields: TFields;
  flagFound: boolean;
  data: TListData;
begin
  new(tempElem);
  data := constrData;
  InitSearch(Fields, data);
  InputSearchElem(tempElem, Fields, data);
  flagFound := false;
  tempConstr := constrHead;
  OutputConstrHeadList;
  while tempConstr.next <> nil do
  begin
    if CompareConstrElems(Fields, tempConstr.next, tempElem) = 0 then
    begin
      OutputElem(tempConstr.next, constrData);
      flagFound := true;
    end;
    tempConstr := tempConstr.next;
  end;
  if not flagFound then
    Writeln('|                                                    Элемент не найден                                                 |');
  Writeln('|----------------------------------------------------------------------------------------------------------------------|');
  dispose(tempElem);
end;

Procedure Search(const brigHead: PtBrig; const constrHead: PtConstr);
var
  flagcheck: boolean;
  resultString: Tstring;
begin
  flagcheck := true;
  Writeln('Введите список для поиска: ', #10, '1 -- Список бригад', #10,
    '2 -- Список объектов');
  while flagcheck do
  begin
    readln(resultString);
    if Length(resultString) = 1 then
    begin
      case resultString[1] of
        '1':
          begin
            ClearScreen(0, 0, -1);
            SearchBrigElem(brigHead);
            flagcheck := false;
          end;

        '2':
          begin
            ClearScreen(0, 0, -1);
            SearchConstrElem(constrHead);
            flagcheck := false;
          end
      else
        begin
          Writeln('Неверный ввод. Повторите попытку');
        end;

      end;
    end
    else
    begin
      Writeln('Неверный ввод. Повторите попытку');
    end;
  end;
end;

procedure InitAdd(var brigHead: PtBrig; var constrHead: PtConstr;
  var constrTail: PtConstr);
var
  flagcheck: boolean;
  resultString: Tstring;
begin
  Writeln('Введите номер списка для добавления элементов: ', #10,
    '1 -- Список бригад', #10, '2 -- Список объектов');
  flagcheck := true;

  while flagcheck do
  begin
    readln(resultString);
    if Length(resultString) = 1 then
    begin
      case resultString[1] of
        '1':
          begin
            ClearScreen(0, 0, -1);

            AddElemToBrigList(brigHead);

            flagcheck := false;
          end;

        '2':
          begin
            ClearScreen(0, 0, -1);
            AddElemToConstrList(constrHead, constrTail);
            flagcheck := false;
          end
      else
        begin
          Writeln('Неверный ввод. Повторите попытку');
        end;

      end;
    end
    else
    begin
      Writeln('Неверный ввод. Повторите попытку');
    end;
  end;
end;

procedure SearchConstrElemByCode(var flagFound: boolean;
  const constrHead: PtConstr; var constrTemp: PtConstr; var tempElem: PtComp);
begin
  constrTemp := constrHead;
  Writeln('Введите код элемента, с которым вы хотите провести данную операцию :');
  IsValidNum(tempElem.int, int, 0);
  while (constrTemp.next <> nil) and (not flagFound) do
  begin
    if CompareConstrElems(code, constrTemp.next, tempElem) = 0 then
    begin
      OutputElem(constrTemp.next, constrData);
      flagFound := true;
    end
    else
      constrTemp := constrTemp.next;
  end;
end;

procedure DeleteConstrElem(var constrHead: PtConstr);
var
  resultString: Tstring;
  constrTemp, temp2: PtConstr;
  fStopInput, flagcheck, flagFound: boolean;
  tempElem: PtComp;
begin
  new(tempElem);
  flagcheck := true;
  fStopInput := false;
  while not fStopInput do
  begin
    flagFound := false;
    constrTemp := constrHead;
    SearchConstrElemByCode(flagFound, constrHead, constrTemp, tempElem);
    ClearScreen(0, 0, -1);
    if (not flagFound) then
    begin
      Writeln('Данный элемент невозможно удалить', #10, '0 -- Ок');
      SelectOption(fStopInput);
    end
    else
    begin
      OutputElem(constrTemp.next, constrData);
      Writeln('Уверены, что хотите удалить данный объект из списка?', #10,
        '1 -- Да    0 -- Нет');
      while flagcheck do
      begin
        readln(resultString);
        if Length(resultString) = 1 then
        begin
          case resultString[1] of
            '1':
              begin
                dec(constrHead.constrInf.constrBrigadCode);
                ClearScreen(0, 0, -1);
                flagcheck := false;
                temp2 := constrTemp.next;
                if temp2.constrInf.constrCode = constrHead.constrInf.
                  constrCode - 1 then
                  dec(constrHead.constrInf.constrCode);
                constrTemp.next := constrTemp.next.next;
                dispose(temp2);
              end;

            '0':
              begin
                ClearScreen(0, 0, -1);
                flagcheck := false;
              end
          else
            begin
              Writeln('Неверный ввод. Повторите попытку');
            end;

          end;
        end
        else
        begin
          Writeln('Неверный ввод. Повторите попытку');
        end;
      end;
      Writeln('Хотите продолжить?', #10, '1 -- Да    0 -- Нет');
      SelectOption(fStopInput);
      flagcheck := true;
    end;

  end;
  dispose(tempElem);
end;

procedure SearchBrigElemByCode(var flagFound: boolean; const brigHead: PtBrig;
  var brigTemp: PtBrig; var tempElem: PtComp);

begin
  brigTemp := brigHead;
  Writeln('Введите код элемента, c которым вы хотите провести данную операцию ');
  IsValidNum(tempElem.int, int, 0);
  while (brigTemp.next <> nil) and (not flagFound) do
  begin
    if CompareBrigElems(code, brigTemp.next, tempElem) = 0 then
    begin
      flagFound := true;

    end
    else
      brigTemp := brigTemp.next;
  end;
end;

procedure DeleteBrigElem(var brigHead: PtBrig; const constrHead: PtConstr);
var
  resultString: Tstring;
  brigTemp, temp2: PtBrig;
  fStopInput, flagcheck, flagFound, flagFound2: boolean;
  tempElem: PtComp;
  constrTemp: PtConstr;
begin
  new(tempElem);
  flagcheck := true;
  fStopInput := false;
  constrTemp := constrHead;
  while not fStopInput do
  begin
    flagFound := false;
    flagFound2 := false;
    SearchBrigElemByCode(flagFound, brigHead, brigTemp, tempElem);
    if flagFound then
    begin
      tempElem.int := brigTemp.next.brigInf.brigCode;
      while (constrTemp.next <> nil) and (not flagFound2) do
      begin
        if CompareConstrElems(brigCode, constrTemp.next, tempElem) = 0 then
        begin
          OutputElem(brigTemp.next, brigadeData);
          flagFound2 := true;
        end
        else
          constrTemp := constrTemp.next;
      end;
    end;
    ClearScreen(0, 0, -1);
    if (not flagFound) or (flagFound2) then
    begin
      Writeln('Данный элемент невозможно удалить', #10, '0 -- Ок');
      SelectOption(fStopInput);
    end
    else
    begin
      OutputElem(brigTemp.next, brigadeData);
      Writeln('Уверены, что хотите удалить данную бригаду из списка?', #10,
        '1 -- Да    0 -- Нет');
      while flagcheck do
      begin
        readln(resultString);
        if Length(resultString) = 1 then
        begin
          case resultString[1] of
            '1':
              begin
                dec(brigHead.brigInf.brigMemCnt);
                ClearScreen(0, 0, -1);
                flagcheck := false;
                temp2 := brigTemp.next;
                if temp2.brigInf.brigCode = brigHead.brigInf.brigCode - 1 then
                  dec(brigHead.brigInf.brigCode);
                brigTemp.next := brigTemp.next.next;
                dispose(temp2);
              end;

            '0':
              begin
                ClearScreen(0, 0, -1);
                flagcheck := false;
              end
          else
            begin
              Writeln('Неверный ввод. Повторите попытку');
            end;

          end;
        end
        else
        begin
          Writeln('Неверный ввод. Повторите попытку');
        end;
      end;
      Writeln('Хотите продолжить?', #10, '1 -- Да    0 -- Нет');
      SelectOption(fStopInput);
      flagcheck := true;
    end;

  end;
  dispose(tempElem);
end;

procedure InitDel(var brigHead: PtBrig; var constrHead: PtConstr;
  var constrTail: PtConstr);
var
  flagcheck: boolean;
  resultString: Tstring;
begin

  Writeln('Введите номер списка для удаления элементов: ', #10,
    '1 -- Список бригад', #10, '2 -- Список объектов');

  flagcheck := true;

  while flagcheck do
  begin
    readln(resultString);
    if Length(resultString) = 1 then
    begin
      case resultString[1] of
        '1':
          begin
            ClearScreen(0, 0, -1);

            DeleteBrigElem(brigHead, constrHead);

            flagcheck := false;
          end;

        '2':
          begin
            ClearScreen(0, 0, -1);

            DeleteConstrElem(constrHead);

            flagcheck := false;
          end
      else
        begin
          Writeln('Неверный ввод. Повторите попытку');
        end;

      end;
    end
    else
    begin
      Writeln('Неверный ввод. Повторите попытку');
    end;
  end;
end;

procedure InitShowLists(const brigHead: PtBrig; const constrHead: PtConstr);
var
  resultString: Tstring;
  flagcheck: boolean;

begin
  Writeln('Введите номер списка для просмотра элементов: ', #10,
    '1 -- Список бригад', #10, '2 -- Список объектов');
  flagcheck := true;

  while flagcheck do
  begin
    readln(resultString);
    if Length(resultString) = 1 then
    begin
      case resultString[1] of
        '1':
          begin
            ClearScreen(0, 0, -1);
            OutputBrigList(brigHead);
            flagcheck := false;
          end;

        '2':
          begin
            ClearScreen(0, 0, -1);
            OutputConstrList(constrHead);
            flagcheck := false;
          end
      else
        begin
          Writeln('Неверный ввод. Повторите попытку');
        end;

      end;
    end
    else
    begin
      Writeln('Неверный ввод. Повторите попытку');
    end;
  end;
end;

Procedure SortBrigList(var brigHead: PtBrig; TypeSort: Integer);
var
  runner1, runner2, temp, temp3, temp4: PtBrig;
  Fields: TFields;
  data: TListData;
  temp2: PtComp;
begin
  new(temp2);
  data := brigadeData;
  InitSearch(Fields, data);
  runner1 := brigHead;
  while runner1.next <> nil do
  begin
    runner2 := runner1.next;
    temp := runner1;
    InitSortElemBrig(temp2, Fields, runner1.next);
    while runner2.next <> nil do
    begin
      if TypeSort = 1 then
      begin
        if CompareBrigElems(Fields, runner2.next, temp2) = -1 then
        begin
          temp := runner2;
          InitSortElemBrig(temp2, Fields, temp.next);
        end;
      end
      else if TypeSort = 0 then
      begin
        if CompareBrigElems(Fields, runner2.next, temp2) = 1 then
        begin
          temp := runner2;
          InitSortElemBrig(temp2, Fields, temp.next);
        end;
      end;
      runner2 := runner2.next;
    end;

    if (runner1 <> temp) then
    begin
      temp4 := runner1.next;
      runner1.next := temp.next;
      temp.next := temp.next.next;
      runner1.next.next := temp4;
      if brigHead.next = temp4 then
        brigHead.next := runner1.next;
    end;

    runner1 := runner1.next;
  end;
  dispose(temp2);
end;

Procedure SortConstrList(var constrHead: PtConstr; TypeSort: Integer);
var
  runner1, runner2, temp, temp3, temp4: PtConstr;
  Fields: TFields;
  data: TListData;
  temp2: PtComp;
begin
  new(temp2);
  data := constrData;
  InitSearch(Fields, data);
  runner1 := constrHead;
  while runner1.next <> nil do
  begin
    runner2 := runner1.next;
    temp := runner1;
    InitSortElemConstr(temp2, Fields, runner1.next);
    while runner2.next <> nil do
    begin
      if TypeSort = 1 then
      begin
        if CompareConstrElems(Fields, runner2.next, temp2) = -1 then
        begin
          temp := runner2;
          InitSortElemConstr(temp2, Fields, temp.next);
        end;
      end
      else if (TypeSort = 0) then
      begin
        if CompareConstrElems(Fields, runner2.next, temp2) = 1 then
        begin
          temp := runner2;
          InitSortElemConstr(temp2, Fields, temp.next);
        end;
      end;
      runner2 := runner2.next;
    end;

    if (runner1 <> temp) then
    begin
      temp4 := runner1.next;
      runner1.next := temp.next;
      temp.next := temp.next.next;
      runner1.next.next := temp4;
      if constrHead.next = temp4 then
        constrHead.next := runner1.next;
    end;

    runner1 := runner1.next;
  end;
  dispose(temp2);
end;

procedure Sort(var brigHead: PtBrig; var constrHead: PtConstr);
var
  flagcheck: boolean;
  resultString: Tstring;
  procedure InitTypeSort(const TypeData: TListData);
  var
    resultString: Tstring;
    flagcheck: boolean;
  begin
    Writeln('Как вы хотите отсортировать список?', #10,
      '1 -- по возрастанию     0 -- по убыванию');
    flagcheck := true;

    while flagcheck do
    begin
      readln(resultString);
      if Length(resultString) = 1 then
      begin
        case resultString[1] of
          '1':
            begin
              ClearScreen(0, 0, -1);
              if TypeData = brigadeData then
                SortBrigList(brigHead, 1)
              else
                SortConstrList(constrHead, 1);
              flagcheck := false;
            end;

          '0':
            begin
              ClearScreen(0, 0, -1);
              if TypeData = brigadeData then
                SortBrigList(brigHead, 0)
              else
                SortConstrList(constrHead, 0);
              flagcheck := false;
            end
        else
          begin
            Writeln('Неверный ввод. Повторите попытку');
          end;

        end;
      end
      else
      begin
        Writeln('Неверный ввод. Повторите попытку');
      end;
    end;
  end;

begin
  flagcheck := true;
  Writeln('Введите список для поиска: ', #10, '1 -- Список бригад', #10,
    '2 -- Список объектов');
  while flagcheck do
  begin
    readln(resultString);
    if Length(resultString) = 1 then
    begin
      case resultString[1] of
        '1':
          begin
            ClearScreen(0, 0, -1);
            InitTypeSort(brigadeData);
            flagcheck := false;
          end;

        '2':
          begin
            ClearScreen(0, 0, -1);
            InitTypeSort(constrData);
            flagcheck := false;
          end
      else
        begin
          Writeln('Неверный ввод. Повторите попытку');
        end;

      end;
    end
    else
    begin
      Writeln('Неверный ввод. Повторите попытку');
    end;
  end;
end;

procedure EditBrigList(const brigHead: PtBrig);
var
  flagFound, fStopInput, flagcheck: boolean;
  tempElem, brigTemp: PtBrig;
  compElem: PtComp;
  resultString: Tstring;
begin
  new(tempElem);
  new(compElem);
  flagcheck := true;
  fStopInput := false;
  while not fStopInput do
  begin
    flagFound := false;
    SearchBrigElemByCode(flagFound, brigHead, brigTemp, compElem);
    ClearScreen(0, 0, -1);
    if flagFound then
    begin
      Writeln('Для пропуска поля нажмите Enter');
      tempElem.brigInf := brigTemp.next.brigInf;
      InputInfoBrig(tempElem, fStopInput, 1);
      Writeln('Уверены, что хотите изменить параметры данной бригады?', #10,
        '1 -- Да    0 -- Нет');
      while flagcheck do
      begin
        readln(resultString);
        if Length(resultString) = 1 then
        begin
          case resultString[1] of
            '1':
              begin
                ClearScreen(0, 0, -1);
                flagcheck := false;
                brigTemp.next.brigInf := tempElem.brigInf;
              end;

            '0':
              begin
                ClearScreen(0, 0, -1);
                flagcheck := false;
              end
          else
            begin
              Writeln('Неверный ввод. Повторите попытку');
            end;

          end;
        end
        else
        begin
          Writeln('Неверный ввод. Повторите попытку');
        end;
      end;
      Writeln('Хотите продолжить?', #10, '1 -- Да    0 -- Нет');
      SelectOption(fStopInput);
      flagcheck := true;
    end
    else
    begin
      ClearScreen(0, 0, -1);
      Writeln('Данный элемент невозможно изменить', #10, '0 -- Ок');
      SelectOption(fStopInput);
    end

  end;

  dispose(tempElem);
  dispose(compElem);
end;

procedure EditConstrList(const constrHead: PtConstr);
var
  flagFound, fStopInput, flagcheck: boolean;
  tempElem, constrTemp: PtConstr;
  compElem: PtComp;
  resultString: Tstring;
begin
  new(tempElem);
  new(compElem);
  flagcheck := true;
  fStopInput := false;
  while not fStopInput do
  begin
    flagFound := false;
    SearchConstrElemByCode(flagFound, constrHead, constrTemp, compElem);
    ClearScreen(0, 0, -1);
    if flagFound then
    begin
      Writeln('Для пропуска поля нажмите Enter');
      tempElem.constrInf := constrTemp.next.constrInf;
      InputInfoConstr(tempElem, fStopInput, 1);
      Writeln('Уверены, что хотите изменить параметры данной бригады?', #10,
        '1 -- Да    0 -- Нет');
      while flagcheck do
      begin
        readln(resultString);
        if Length(resultString) = 1 then
        begin
          case resultString[1] of
            '1':
              begin
                ClearScreen(0, 0, -1);
                flagcheck := false;
                constrTemp.next.constrInf := tempElem.constrInf;
              end;

            '0':
              begin
                ClearScreen(0, 0, -1);
                flagcheck := false;
              end
          else
            begin
              Writeln('Неверный ввод. Повторите попытку');
            end;

          end;
        end
        else
        begin
          Writeln('Неверный ввод. Повторите попытку');
        end;
      end;
      Writeln('Хотите продолжить?', #10, '1 -- Да    0 -- Нет');
      SelectOption(fStopInput);
      flagcheck := true;
    end
    else
    begin
      ClearScreen(0, 0, -1);
      Writeln('Данный элемент невозможно изменить', #10, '0 -- Ок');
      SelectOption(fStopInput);
    end

  end;
  dispose(tempElem);
  dispose(compElem);
end;

procedure InitEditLists(const brigHead: PtBrig; const constrHead: PtConstr);
var
  resultString: Tstring;
  flagcheck: boolean;

begin
  Writeln('Введите номер списка для изменения элементов: ', #10,
    '1 -- Список бригад', #10, '2 -- Список объектов');
  flagcheck := true;

  while flagcheck do
  begin
    readln(resultString);
    if Length(resultString) = 1 then
    begin
      case resultString[1] of
        '1':
          begin
            ClearScreen(0, 0, -1);
            EditBrigList(brigHead);
            flagcheck := false;
          end;

        '2':
          begin
            ClearScreen(0, 0, -1);
            EditConstrList(constrHead);
            flagcheck := false;
          end
      else
        begin
          Writeln('Неверный ввод. Повторите попытку');
        end;

      end;
    end
    else
    begin
      Writeln('Неверный ввод. Повторите попытку');
    end;
  end;
end;

procedure CreateMenu(var brigHead: PtBrig;
  var constrHead, constrTail: PtConstr);
var
  fstop, freadC, freadB, flagRead: boolean;
  fileConstr: TCFile;
  fileBrig: TBFile;
  fileTSf: TTFile;
  filePath: String;

  procedure MenuManager(var fEndProc, flagRead: boolean);
  var
    resultString: Tstring;
    flagcheck, fstopInput2: boolean;
  begin
    fstopInput2 := false;
    Writeln('Выберите пункт меню: ');
    flagcheck := true;
    while flagcheck do
    begin
      readln(resultString);
      if Length(resultString) = 1 then
      begin
        case resultString[1] of
          '1':
            begin
              ClearScreen(0, 0, -1);
              flagcheck := false;
              if (not flagRead) or not(freadB and freadC) then
              begin
                CheckSessions(filePath, freadC, freadB, 0);
                OpenFileBrigForReading(fileBrig, filePath);
                OpenFileConstrForReading(fileConstr, filePath);
                ReadInConstrList(constrHead, constrTail, fileConstr);
                ReadInBrigList(brigHead, fileBrig);
                Writeln('Данные сессии успешно связаны. Нажмите Enter');
                flagRead := true;
              end
              else
                Writeln('Данные файлов уже прочитаны');
              readln;
              ClearScreen(0, 0, -1);
            end;

          '2':
            begin
              ClearScreen(0, 0, -1);
              flagcheck := false;
              InitShowLists(brigHead, constrHead);
              Writeln('Нажмите Enter');
              readln;
              ClearScreen(0, 0, -1);
            end;
          '3':
            begin
              ClearScreen(0, 0, -1);
              flagcheck := false;
              Sort(brigHead, constrHead);
              ClearScreen(0, 0, -1);
            end;
          '4':
            begin
              ClearScreen(0, 0, -1);
              flagcheck := false;
              Search(brigHead, constrHead);
              readln;
              ClearScreen(0, 0, -1);
            end;
          '5':
            begin
              ClearScreen(0, 0, -1);
              flagcheck := false;
              if not flagRead then
              begin
                Writeln('Данные файлов не были прочтены.', #10,
                  'В случае попытки чтения из файла, добавленные данные могут быть перезаписаны. Продолжить?',
                  #10, '0 -- нет   1 -- да');
                SelectOption(fstopInput2);
              end;
              if not fstopInput2 then
                InitAdd(brigHead, constrHead, constrTail);
              Writeln('Нажмите Enter');
              ClearScreen(0, 0, -1);
            end;
          '6':
            begin
              ClearScreen(0, 0, -1);
              flagcheck := false;
              InitDel(brigHead, constrHead, constrTail);
              ClearScreen(0, 0, -1);
            end;
          '7':
            begin
              ClearScreen(0, 0, -1);
              flagcheck := false;
              InitEditLists(brigHead, constrHead);
              ClearScreen(0, 0, -1);
            end;
          '8':
            begin
              ClearScreen(0, 0, -1);
              flagcheck := false;
              SpecialFunc(constrHead, brigHead);
              CheckSessions(filePath, freadC, freadB, 1);
              OpenFileSF(fileTSf, filePath);
              WriteInTextFile(constrHead, brigHead, fileTSf);
              ClearScreen(0, 0, -1);
            end;
          '9':
            begin
              ClearScreen(0, 0, -1);
              fEndProc := false;
              flagcheck := false;
              Writeln('Спасибо, что использовали данное приложение');
              readln;
            end
        else
          begin
            Writeln('Неверный ввод. Повторите попытку');
          end;

        end;
      end
      else if copy(resultString, 1, 2) = '10' then
      begin
        ClearScreen(0, 0, -1);
        flagcheck := false;
        CheckSessions(filePath, freadC, freadB, 0);
        OpenFileBrigForWriting(fileBrig, filePath);
        OpenFileConstrForWriting(fileConstr, filePath);
        WriteInConstrFile(constrHead, fileConstr);
        WriteInBrigFile(brigHead, fileBrig);
        fEndProc := false;
        ClearScreen(0, 0, -1);
        Writeln('Спасибо, что использовали данное приложение');
        readln;

        ClearScreen(0, 0, -1);
      end
      else
      begin
        Writeln('Неверный ввод. Повторите попытку');
      end;
    end;

  end;

begin
  freadC := false;
  freadB := false;
  flagRead := false;
  fstop := true;
  while fstop do
  begin
    Writeln('Меню:                                       |');
    Writeln('1.Прочитать данные из файла                 |');
    Writeln('2.Просмотреть списки                        |');
    Writeln('3.Сортировать данные                        |');
    Writeln('4.Поиск данных                              |');
    Writeln('5.Добавить данные в список                  |');
    Writeln('6.Удалить данные из списка                  |');
    Writeln('7.Редактировать данные                      |');
    Writeln('8.Распределение бригад по объектам          |');
    Writeln('9.Выйти                                     |');
    Writeln('10.Сохранить и выйти                        |');
    Writeln('*********************************************');
    MenuManager(fstop, flagRead);
  end;
end;

var
  brigHead: PtBrig;
  constrHead, constrTail: PtConstr;
  startArr: TbrigArr;

begin
  InitLists(brigHead, constrHead, constrTail);
  CreateMenu(brigHead, constrHead, constrTail);
  // SetLength(startArr, 4);
  // new(startArr[2]);
  // with startArr[2].brigInf do
  // begin
  // brigCode:=1;
  // end;
  // new(startArr[0]);
  // with startArr[0].brigInf do
  // begin
  // brigcode:=3;
  // end;
  // new(startArr[3]);
  // with startArr[3].brigInf do
  // begin
  // brigcode:=7;
  // end;
  // new(startArr[1]);
  // with startArr[1].brigInf do
  // begin
  // brigcode:=5;
  // end;
  // startArr := MergesortBrig(startArr, code, 1);
  // // StartArr:=MergesortConstr(StartArr,Code,1);
  // for var i := 0 to 3 do
  // begin
  // with startArr[i].brigInf do
  // Writeln(brigCode);
  // end;

end.
