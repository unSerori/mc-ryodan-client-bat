@echo off
chcp 65001
cls

rem 身内向けサーバのクライアント構築用バッチスクリプト 
:: 1. MODなど必要なリソースを取得 
:: 2. MODローダを実行してインストールしてもらう 
:: 3. 起動構成を作成する 

rem カレントフォルダへ移動 
cd %~dp0

rem 定数を宣言 
:: バージョン 
set VERSION=1.21.4
:: modローダ 
set MOD_LOADER=fabric
set _MOD_LOADER=_%MOD_LOADER%
:: プロファイルのタイトル 
set PROFILE_TITLE=mc-ryodan
:: バージョンID 
set "LAST_VERSION_ID=fabric-loader-0.16.10-1.21.4"
:: プロファイルファイルのパス 
set "LAUNCHER_PROFILES_JSON_FILE_PATH=%USERPROFILE%\AppData\Roaming\.minecraft\launcher_profiles.json"

rem msg 
echo MinecraftクライアントMODと起動構成のセットアップを開始します...
@REM timeout /t 2 > nul
echo Minecraftランチャーを終了したら何かキーを押してください...
pause>nul

rem 必要なフォルダの作成 
:: てんぷフォルダ 
if exist .\tmp\ rd /s /q .\tmp\
mkdir .\tmp\
:: dl
if not exist .\dl\ mkdir .\dl\

rem mc folをコピー 
set profile_fol=.minecraft_%VERSION%%_MOD_LOADER%_%PROFILE_TITLE%
:: 既存のフォルダがあった場合、バックアップをとって続行するか中断するか 
setlocal enabledelayedexpansion
if exist "%USERPROFILE%\AppData\Roaming\%profile_fol%" (
  choice /c YN /m "すでに%profile_fol%が存在します  バックアップを作成し、処理を続行しますか？または中断する"
  :: 早期ブレーク 
  if errorlevel 2 goto end
  :: 時刻文字列の作成 
  call :get_date_str
  set "date_str=!errorlevel!"
  call :get_time_str
  set "time_str=!errorlevel:~1!"
  
  :: バックアップ 
  ren "%USERPROFILE%\AppData\Roaming\%profile_fol%" "%profile_fol%_bu_!date_str!!time_str!"
)
endlocal
:: コピー 
xcopy /Y /E /I /H .minecraft_\ "%USERPROFILE%\AppData\Roaming\%profile_fol%"

rem MODのDL 
for /f "eol=# usebackq tokens=* delims=" %%A in ("links\%VERSION:.=_%\mods.list") do (
  setlocal enabledelayedexpansion
  set "url=%%A"
  set "url=!url:%%=%%%%!"
  call :for_dl_mod "!url!"
  endlocal && set "url=%url%"
)

rem 影シェーダのDL 
for /f "eol=# usebackq tokens=* delims=" %%A in ("links\%VERSION:.=_%\shaders.list") do (
  setlocal enabledelayedexpansion
  set "url=%%A"
  set "url=!url:%%=%%%%!"
  call :for_dl_shader "!url!"
  endlocal && set "url=%url%"
)


rem ローダ実行用のJavaのセットアップ 
for /f "usebackq tokens=* delims=" %%A in ("links\%VERSION:.=_%\openjdk.txt") do set openjdk_url=%%A
call :dl "%openjdk_url%"
call :unzip "%openjdk_url%"

rem MOD LoaderのDL 
for /f "usebackq tokens=* delims=" %%A in ("links\%VERSION:.=_%\ml.txt") do set ml_url=%%A
call :dl "%ml_url%"

rem MOD Loaderの実行を促す 
call :exec_ml "%ml_url%"

rem 起動構成を作成 

rem profileのバックアップ 
setlocal enabledelayedexpansion
if exist "%LAUNCHER_PROFILES_JSON_FILE_PATH%" (
  :: 時刻文字列の作成 
  call :get_date_str
  set "date_str=!errorlevel!"
  call :get_time_str
  set "time_str=!errorlevel:~1!"

  echo F | xcopy /Y /H "%LAUNCHER_PROFILES_JSON_FILE_PATH%" "%USERPROFILE%\AppData\Roaming\.minecraft\launcher_profiles_bu_!date_str!!time_str!.json" > nul
)
endlocal

rem jqでJSONファイル編集 
call :add_profile_jq

rem jqでicon設定
call :base64_icon_jq

rem msg
cls
echo セットアップが正常に終了しました！　  

rem end=============================================================================
:end
:: Press any key to continue . . . 
echo 何かキーを押してセットアップを終了してください... 
pause>nul
rd /s /q .\tmp\
exit /b

rem サブルーチン 

rem 時刻文字列の作成
:get_date_str
  set date_adjusted=%date:/=%
exit /b %date_adjusted%

rem 時刻文字列の作成
:get_time_str
  set zpd_time=%time: =0%
  set time_no_fraction=%zpd_time:~0,8%
  set time_adjusted=%time_no_fraction::=%
:: 040000など、頭が0の場合消えてしまうので1を付与して返す
:: 呼び出し側の責任: 呼び出し側は%errorlevel:~1%まで行うこと
exit /b 1%time_adjusted%

rem MODのDLfor処理 
:for_dl_mod
:: %文字などはここで処理するのではなく、callでのサブルーチン処理にしている都合上呼び出し側で行う 
:: 呼び出し側の責任: 以下のコードでエスケープする必要がある 
::setlocal enabledelayedexpansion
::set "url=%%A"
::set "url=!url:%%=%%%%!"
::endlocal && set "url=%url%"
:: 遅延展開される場所ならendlocalする前に呼び出す、そうでないなら外側でもいい 
  rem 変数 
  :: url
  set "url=%~1"
  :: DLされるファイル名 
  set "fn=%~nx1"

  rem DL
  curl -L -o "%USERPROFILE%\AppData\Roaming\%profile_fol%\mods\%fn%" "%url%"
exit /b

rem MODのDLfor処理 
:for_dl_shader
:: %文字などはここで処理するのではなく、callでのサブルーチン処理にしている都合上呼び出し側で行う 
:: 呼び出し側の責任: 以下のコードでエスケープする必要がある 
::setlocal enabledelayedexpansion
::set "url=%%A"
::set "url=!url:%%=%%%%!"
::endlocal && set "url=%url%"
:: 遅延展開される場所ならendlocalする前に呼び出す、そうでないなら外側でもいい 
  rem 変数 
  :: url
  set "url=%~1"
  :: DLされるファイル名 
  set "fn=%~nx1"

  rem DL
  curl -L -o "%USERPROFILE%\AppData\Roaming\%profile_fol%\shaderpacks\%fn%" "%url%"
exit /b

rem JDKやMODローダのDL処理 
:dl
  if not exist "./dl/%~nx1" (
    curl -L -o "./dl/%~nx1" "%~1"
  )
exit /b

rem ZIP解凍 
:unzip
  powershell -command "Expand-Archive -Path './dl/%~nx1' -DestinationPath './dl/jdk' -Force"
exit /b

rem MODローダの実行 
:exec_ml
  rem 解凍済みのJDK一覧を取得 /b 不要な情報を除外 /a:d-h dはディレクトリ、-hは隠しファイル以外を表示 /o:-n アルファベット順にソート 
  dir /b /a:d-h /o:-n .\dl\jdk\ > .\tmp\unzip_jdk_path.list

  rem 最新のJDKパスを取得 
  set "latest_jdk_path="
  for /f "tokens=* delims=" %%A in (.\tmp\unzip_jdk_path.list) do (
    :: パスを取得 
    set "latest_jdk_path=%%A"
    :: 一週目で即ブレーク 
    goto found_jdk
  )
  :found_jdk

  rem 同じ手順でmodローダのパスパスを取得 
  dir /b /a:-d-r-s-h /o:-n .\dl\%MOD_LOADER%* > .\tmp\ml_path.list
  set "latest_ml_path="
  for /f "tokens=* delims=" %%A in (.\tmp\ml_path.list) do (
    set "latest_ml_path=%%A"
    goto found_ml
  )
  :found_ml

  rem msg
  call :%MOD_LOADER%_installer_msg

  rem 実行 
  call "./dl/jdk/%latest_jdk_path%/bin/java.exe" -jar "./dl/%latest_ml_path%"
exit /b

rem fabric installer msg
:fabric_installer_msg
  cls
  echo ====================================================================
  echo 自動的に開かれたMODローダのインストーラで以下の設定をしてください
  echo ====================================================================
  echo:
  echo 1. 「クライアント」タブを選択（初期状態） 
  echo 2. Minecraft バージョン: %VERSION% 
  echo 3. ローダバージョン: 最新のまま触らない 
  echo 4. インストール先: そのまま触らない（マイクラのインストール場所をカスタムしているならそこ） 
  echo 5. 起動攻勢を作成のチェックボックス: チェックしたまま触らない 
  echo 6. 「インストール」ボタンを押す 
  echo 7. 処理が始まるので少し待つ（；～；))),,,³₃ 
  echo 8. 終了したら、 
  echo     - 「OK」ボタンを押し「正常にインストールされました」ウィンドウを閉じる 
  echo     - 「×」ボタンを押し「Fabricセットアッププログラム」ウィンドウを閉じる 
  echo:
exit /b

rem forge installer msg
:forge_installer_msg
  cls
  echo ====================================================================
  echo 自動的に開かれたMODローダのインストーラで以下の設定をしてください
  echo ====================================================================
  echo:
  echo 1. 「Install client」を選択（初期状態） 
  echo 2. インストール先: そのまま触らない（マイクラのインストール場所をカスタムしているならそこ） 
  echo 4. 「OK」ボタンを押す 
  echo 5. 処理が始まるので少し待つ 
  echo 6. Completeしたら「OK」ボタンでウィンドウを閉じる 
  echo:
exit /b

rem jqでJSONファイル編集 
:add_profile_jq
  rem 必要な情報を取得 
  :: uuidを生成 
  for /f "usebackq" %%A in (`powershell -Command "[Guid]::NewGuid()"`) do set uuid=%%A
  set "uuid=%uuid:-=%"
  :: created
    :: グリニッジ標準時での日付を取得 
    for /f "usebackq" %%A in (`powershell -Command "(Get-Date).ToUniversalTime().ToString('yyyy-MM-dd')"`) do set utc_date=%%A
    :: グリニッジ標準時での時刻を取得 
    for /f "usebackq" %%A in (`powershell -Command "(Get-Date).ToUniversalTime().ToString('HH:mm:ss.fff')"`) do set utc_time=%%A
    :: 日付時刻を結合 
    set created=%utc_date%T%utc_time%Z
  :: gameDir
  set "game_dir=%USERPROFILE:\=\\%\\AppData\\Roaming\\%profile_fol%"
  :: icon
  set "icon=Enchanting_Table"
  :: lastUsed
  set "last_used=1970-01-01T00:00:00.000Z"
  :: lastVersionId
  :: 定数LAST_VERSION_IDを利用 
  :: name
  set "name=%VERSION%%_MOD_LOADER%_%PROFILE_TITLE%"
  :: type
  set type=custom

  rem jqでJSON編集 
  :: jqのDL 
  for /f "usebackq tokens=* delims=" %%A in ("links\%VERSION:.=_%\jq.txt") do set jq_url=%%A
  call :dl "%jq_url%"
  :: jqでキーバリューを追加 
  set "json_path=%LAUNCHER_PROFILES_JSON_FILE_PATH%"
  .\dl\jq-windows-amd64.exe ^
    ".profiles.[\"%uuid%\"] = {\"created\":\"%created%\",\"gameDir\":\"%game_dir%\",\"icon\":\"%icon%\",\"lastUsed\":\"%last_used%\",\"lastVersionId\":\"%LAST_VERSION_ID%\",\"name\":\"%name%\",\"type\":\"%type%\"}" ^
    "%json_path%" --indent 2 1> ".\tmp\launcher_profiles.json"
  :: エラーハンドリング if-errorlevel構文はn以上のときという条件なのででかい値からハンドルする 
  if errorlevel 1 (
      set el=%errorlevel%
      cls
      echo 起動構成の作成でエラーが発生しました: jqのエラー 
      echo errorlevel: %el% 
      echo このバッチスクリプトファイルの作成者に伝えてください... 
      goto end
  )
  :: エラーなく完成したjsonファイルを元のファイルの場所に上書き移動 
  move /y ".\tmp\launcher_profiles.json" "%json_path%" > nul
  echo new profile id: %uuid%
exit /b

rem jqでicon設定
:base64_icon_jq
  rem iconをbase64に変換
  set "input_icon_path=./assets/server-icon.png"
  certutil -encode "%input_icon_path%" ".\tmp\icon.base64"

  rem base64であることを示す文字列で整列 data:image/png;base64,
  .\dl\jq-windows-amd64.exe ^
    ".profiles.[\"%uuid%\"].icon |= \"data:image/png;base64,\"" ^
    "%LAUNCHER_PROFILES_JSON_FILE_PATH%" --indent 2 1> ".\tmp\launcher_profiles.json"
  :: エラーハンドリング if-errorlevel構文はn以上のときという条件なのででかい値からハンドルする 
  if errorlevel 1 (
      set el=%errorlevel%
      cls
      echo 起動構成の作成でエラーが発生しました: jqのエラー 
      echo errorlevel: %el% 
      echo このバッチスクリプトファイルの作成者に伝えてください... 
      goto end
  )
  :: エラーなく完成したjsonファイルを元のファイルの場所に上書き移動 
  move /y ".\tmp\launcher_profiles.json" "%json_path%"

  rem 一行ずつ読み込んで追加
  setlocal enabledelayedexpansion
  for /f "tokens=* delims=" %%a in (.\tmp\icon.base64) do (
    :: 一行を取得 
    set "line=%%a"

    :: 開始終了行など不要な行は追加しない 
    if not "!line!"=="-----BEGIN CERTIFICATE-----" if not "!line!"=="-----END CERTIFICATE-----" (
      :: 追記
      .\dl\jq-windows-amd64.exe ^
        ".profiles.[\"%uuid%\"].icon += \"!line!\"" ^
        "%LAUNCHER_PROFILES_JSON_FILE_PATH%" --indent 2 1> ".\tmp\launcher_profiles.json"
      :: エラーハンドリング if-errorlevel構文はn以上のときという条件なのででかい値からハンドルする 
      if errorlevel 1 (
          set el=%errorlevel%
          cls
          echo 起動構成の作成でエラーが発生しました: jqのエラー 
          echo errorlevel: %el% 
          echo このバッチスクリプトファイルの作成者に伝えてください... 
          goto end
      )
      :: エラーなく完成したjsonファイルを元のファイルの場所に上書き移動 
      move /y ".\tmp\launcher_profiles.json" "%json_path%"
    )
  )
  endlocal
exit /b
