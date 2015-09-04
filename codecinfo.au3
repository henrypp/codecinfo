#cs

Name: Codec Info
Author: [Nuker-Hoax]
	
Based on original version Codec-Control [ http://www.autoitscript.com/forum/index.php?showtopic=64045 ]

Версия 1.2 (14.01.10)
 * Небольшое изменение размеров главного окна
 
Версия 1.1 (03.01.10)
 * Добавлен пункт "Открыть папку файла"
 * Добавлен пункт "Открыть ключ реестра"
 * Добавлен пункт "Искать в Google"
 * Добавлена ссылка на топик с Codec-Control
 * Изменён внешний вид программы
 * Переделаны некоторые участки кода
 
Версия 1.0 (24.10.09)
 * Первая публичная версия

#ce

#NoTrayIcon

#include "GUIConstants.au3"
#include "GUIListView.au3"
#include "WinAPI.au3"
#include "WindowsConstants.au3"

Global $DShowListView, $filter_version[1], $DShowEnum[1], $DShowRead1[1], $DShowRead2[1], $DShowRead3[1], $DShowRead4[1], $DShowRead5[1], $DShowListViewItem[999], $DisDShow = ":"
Global $aSubItemSet[1][5] = [[-1]]

$Debug_LB = False

Global $application = "Codec Info"
Global $version = "1.2"

Global $main_dlg = GUICreate($application &" "& $version, 750, 490)
GUISetIcon(@ScriptFullPath, -1, $main_dlg)

DllCall("uxtheme.dll", "none", "SetThemeAppProperties", "int", 1)

Global $close_btn = GUICtrlCreateButton("Выйти", 642, 457, 100, 25, "", 131072)

GUICtrlCreateTab(10, 10, 730, 438)

GUICtrlCreateTabItem("Список фильтров")
Global $refresh_btn = GUICtrlCreateButton("Обновить", 10, 457, 100, 25, "", 131072)

$DShowListView = GUICtrlCreateListView("", 13, 35, 724, 410)
	
$menu = GUICtrlCreateContextMenu($DShowListView)
$codec_place_item = GUICtrlCreateMenuItem("Открыть папку файла", $menu)
$codec_reg_open = GUICtrlCreateMenuItem("Открыть ключ реестра", $menu)
$codec_find_item = GUICtrlCreateMenuItem("Искать в Google", $menu)
GUICtrlCreateMenuItem("", $menu)
$codec_on_item = GUICtrlCreateMenuItem("Включить выбранный кодек", $menu)
$codec_off_item = GUICtrlCreateMenuItem("Отключить выбранный кодек", $menu)
GUICtrlCreateMenuItem("", $menu)
$file_properties_item = GUICtrlCreateMenuItem("Свойства файла", $menu)

GUICtrlCreateTabItem("О программе")
GUICtrlCreateGroup("", 20, 35, 710, 400)
GUICtrlCreateIcon(@ScriptFullPath, -1, 30, 60, 32, 32)
GUICtrlCreateLabel($application &" "& $version, 75, 60, 300, 15)
GUICtrlCreateLabel("Copyright © 2009 [Nuker-Hoax]", 75, 80, 300, 15)

GUICtrlCreateLabel("Based on original version Codec-Control 1.5:", 75, 120, 300, 15)
$cc_link = GUICtrlCreateLabel("http://www.autoitscript.com/forum/index.php?showtopic=64045", 75, 140, 330, 15)
GUICtrlSetCursor(-1, 0)
GUICtrlSetFont(-1, 8.5, 400, 4)
GUICtrlSetColor(-1, 0x0000FF)

GUICtrlCreateLabel("Russian Autoit script community:", 75, 180, 300, 15)
$forum_link = GUICtrlCreateLabel("http://autoit-script.ru/index.php?action=forum", 75, 200, 330, 15)
GUICtrlSetCursor(-1, 0)
GUICtrlSetFont(-1, 8.5, 400, 4)
GUICtrlSetColor(-1, 0x0000FF)

_GUICtrlListView_AddColumn($DShowListView, "Фильтр", 200)
_GUICtrlListView_AddColumn($DShowListView, "Версия", 120)
_GUICtrlListView_AddColumn($DShowListView, "Путь к фильтру", 120)
_GUICtrlListView_AddColumn($DShowListView, "CLSID", 120)
_GUICtrlListView_AddColumn($DShowListView, "Статус", 75)

_GenerateDShow()
GUISetState(@SW_SHOW)

While 1
	$msg = GUIGetMsg()
		Select
			Case $msg = $GUI_EVENT_CLOSE or $msg = $close_btn
				Exit
			Case $msg = $cc_link
				ShellExecute("http://www.autoitscript.com/forum/index.php?showtopic=64045")
			Case $msg = $forum_link
				ShellExecute("http://autoit-script.ru/index.php?action=forum")
			Case $msg = $refresh_btn
				codec_refresh_info()
			Case $msg = $file_properties_item
				$selected = StringSplit(GUICtrlRead(GUICtrlRead($DShowListView)), '|', 1)
				If FileExists($selected[3]) Then
					DllCall("shell32.dll", "int", "SHObjectProperties", "hwnd", 0, "dword", 0x00000002, "wstr", $selected[3], "wstr", 0)
				Else
					MsgBox(16, "Ошибка", "Файла не существует или фильтр отключен")
				EndIf
			Case $msg = $codec_on_item
				$selected = StringSplit(GUICtrlRead(GUICtrlRead($DShowListView)), '|', 1)
				If StringLeft($selected[4], 1) = ":" Then
					$trimmedstring = StringTrimLeft($selected[4], 1)
					RegWrite("HKCR\CLSID\{083863F1-70DE-11d0-BD40-00A0C911CE86}\Instance\" & $trimmedstring, "CLSID", "REG_SZ", $trimmedstring)
					codec_refresh_info()
				EndIf
			Case $msg = $codec_off_item
				$selected = StringSplit(GUICtrlRead(GUICtrlRead($DShowListView)), '|', 1)
				If StringLeft($selected[4], 1) <> ":" Then
					RegWrite("HKCR\CLSID\{083863F1-70DE-11d0-BD40-00A0C911CE86}\Instance\" & $selected[4], "CLSID", "REG_SZ", ":" & $selected[4])
					codec_refresh_info()
				EndIf
			Case $msg = $codec_place_item
				$selected = StringSplit(GUICtrlRead(GUICtrlRead($DShowListView)), '|', 1)
				Run("explorer.exe /select," & '"'& $selected[3] &'"')
			Case $msg = $codec_find_item
				$selected = StringSplit(GUICtrlRead(GUICtrlRead($DShowListView)), '|', 1)
				ShellExecute("http://www.google.ru/search?hl=ru&lr=lang_ru&q="& $selected[1])
			Case $msg = $codec_reg_open
				$selected = StringSplit(GUICtrlRead(GUICtrlRead($DShowListView)), '|', 1)
				Local $Clsid
				If StringLeft($selected[4], 1) = ":" Then
					$Clsid = StringTrimLeft($selected[4], 1)
				Else
					$Clsid = $selected[4]
				EndIf
				_RegOpenKey("HKCR\CLSID\"& $Clsid)
      EndSelect
Wend

Func codec_refresh_info()
	$get_selected = _GUICtrlListView_GetSelectedIndices($DShowListView, True)
	_GenerateDShow()
	For $D = 1 To $get_selected[0]
		_GUICtrlListView_SetItemSelected($DShowListView, $get_selected[$D])
	Next
EndFunc

Func _GenerateDShow()
	Local $B = 1
	_GUICtrlListView_DeleteAllItems($DShowListView)
	While 1
		ReDim $DShowEnum[$B+1]
		$DShowEnum[$B] = RegEnumKey("HKCR\CLSID\{083863F1-70DE-11d0-BD40-00A0C911CE86}\Instance", $B)
		If @error <> 0 then ExitLoop
		$B = $B + 1
	WEnd
	$DShowEnum[0] = $B-1
	ReDim $DShowRead1[$B]
	ReDim $DShowRead2[$B]
	ReDim $DShowRead3[$B]
	ReDim $DShowRead4[$B]
	ReDim $DShowRead5[$B]
	ReDim $filter_version[$B]
	For $C = 1 To $DShowEnum[0]
		$DShowRead1[$C] = RegRead("HKCR\CLSID\{083863F1-70DE-11d0-BD40-00A0C911CE86}\Instance\" & $DShowEnum[$C], "FriendlyName")
		$DShowRead2[$C] = RegRead("HKCR\CLSID\{083863F1-70DE-11d0-BD40-00A0C911CE86}\Instance\" & $DShowEnum[$C], "CLSID")
		$DShowRead3[$C] = RegRead("HKCR\CLSID\" & $DShowRead2[$C] &"\InprocServer32", "")
		$DShowRead4[$C] = RegRead("HKCR\CLSID\{083863F1-70DE-11d0-BD40-00A0C911CE86}\Instance\" & $DShowEnum[$C], "CLSID")
		
		If StringInStr($DShowRead2[$C], ":", 2) = 0 Then
			$DShowRead2[$C] = "Включен"
		Else
			$DShowRead2[$C] = "Отключен"
		EndIf
		
		$filter_version[$C] = FileGetVersion($DShowRead3[$C])
		If $filter_version[$C] = "0.0.0.0" Then $filter_version[$C] = "Неизвестно"
		$DShowListViewItem[$C] = GUICtrlCreateListViewItem($DShowRead1[$C] & "|" & $filter_version[$C] &"|"& $DShowRead3[$C] &"|"& $DShowRead4[$C] &"|"& $DShowRead2[$C], $DShowListView)
		$set_image = GUICtrlSetImage(-1, $DShowRead3[$C], -1, 0)
		If $set_image = 0 Then GUICtrlSetImage(-1, @ScriptFullPath, -1, 0)
	Next
EndFunc

Func _RegOpenKey($sRegKey)
	Local $Computer
	
	Dim $sKey = StringTrimLeft(RegRead("HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Applets\Regedit", "LastKey"), 12)
	
	If @OSVersion = "WIN_7" or "WIN_VISTA" or "WIN_2008" or "WIN_2008R2" Then $Computer = "Computer\"
	If @OSVersion = "WIN_2000" or "WIN_XP" or "WIN_2003" Then $Computer = "My Computer\"

	$sKey = ReplaceA($sRegKey)
	If Not KeyExists($sKey) Then Return 0
		ProcessClose("regedit.exe")
		RegWrite("HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Applets\Regedit", "LastKey", "REG_SZ", $Computer & $sKey)
		Run("regedit.exe")
EndFunc

Func ReplaceA($sString)
	$sLeft = StringLeft($sString, 4)
	$sRight = StringTrimLeft($sString, 4)
	If $sLeft = "HKLM" Then Return "HKEY_LOCAL_MACHINE" & $sRight
	If $sLeft = "HKCU" Then Return "HKEY_CURRENT_USER" & $sRight
	If $sLeft = "HKCR" Then Return "HKEY_CLASSES_ROOT" & $sRight
	If $sLeft = "HKCC" Then Return "HKEY_CURRENT_CONFIG" & $sRight
	Return $sString
EndFunc

Func KeyExists($sKey)
	RegRead($sKey, "")
	If @error = 1 Or @error = 2 Or @error = 3 Then Return 0
	Return 1
EndFunc