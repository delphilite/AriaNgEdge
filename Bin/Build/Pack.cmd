del /q AriaNgEdge-Win32.7z
7za a AriaNgEdge-Win32.7z ..\Win32\AriaNg.exe
IF NOT EXIST AriaNgEdge-Win32.7z goto Error1

del /q AriaNgEdge-Win64.7z
7za a AriaNgEdge-Win64.7z ..\Win64\AriaNg.exe
IF NOT EXIST AriaNgEdge-Win64.7z goto Error1

goto End

:Error2
color 04
echo Pack Error!
goto End

:End
color 0a
echo Pack Done!
pause
