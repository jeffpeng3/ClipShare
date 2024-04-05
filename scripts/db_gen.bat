@echo off
setlocal enabledelayedexpansion

call flutter pub run build_runner build --delete-conflicting-outputs
set input_file="..\.dart_tool\build\generated\clipshare\lib\db\app_db.floor.g.part"
set output_file="..\lib\db\app_db.floor.g.dart"
set added_line=part of 'app_db.dart';
echo %added_line% > %output_file%
type %input_file% >> %output_file%
echo move file finished.

endlocal
