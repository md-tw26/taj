; Taj POS - Windows installer (Inno Setup 6).
;
; ONE script serves every version: all version-specific values are injected by CI
; through ISCC /D defines, e.g.
;
;   ISCC.exe /DAppVersion=1.2.0-beta.2 ^
;            /DSourceDir=D:\a\taj\taj\build\windows\x64\runner\Release ^
;            windows\installer.iss
;
; Defines:
;   AppName    Display name (default below, overridable with /DAppName=)
;   AppId      FIXED installer id (GUID). It must NEVER change: Inno Setup keys
;              upgrades/uninstalls off it, so a new GUID would mean a second,
;              parallel installation instead of an upgrade.
;   AppExe     Executable base name = BINARY_NAME in windows/CMakeLists.txt
;   AppVersion Full version string, e.g. "1.2.0-beta.2" (CI passes the git tag
;              without the leading "v"; branch builds fall back to pubspec)
;   SourceDir  Path to the built "Release" folder (exe + dlls + data + assets)

#ifndef AppName
  #define AppName "Taj POS"
#endif
#ifndef AppId
  #define AppId "{{840A13CD-A13E-4998-ABC4-6F02B21FC581}"
#endif
#ifndef AppExe
  #define AppExe "taj"
#endif
#ifndef AppVersion
  #error "AppVersion is required: pass it as ISCC /DAppVersion=<version> (git tag without the leading v)"
#endif
#ifndef SourceDir
  #error "SourceDir is required: pass it as ISCC /DSourceDir=<path to the flutter Release folder>"
#endif

; VersionInfoVersion must be numeric-only ("x.x.x.x"; missing parts are padded
; with zeros, extra parts ignored). Inno Setup rejects our "-beta.2" prerelease
; suffix, so truncate the string at the first "-" or "+" (SemVer prerelease /
; build metadata). In pubspec versions the "+N" build number always follows the
; "-beta.N" segment, so cutting at "-" alone would already be enough; the extra
; "+" cut keeps plain versions like "1.2.0+4" working too.
#define VersionCutHyphen Pos("-", AppVersion) > 0 ? Pos("-", AppVersion) : Len(AppVersion) + 1
#define VersionCutPlus Pos("+", AppVersion) > 0 ? Pos("+", AppVersion) : Len(AppVersion) + 1
#define AppVersionNumeric Copy(AppVersion, 1, Min(VersionCutHyphen, VersionCutPlus) - 1)

[Setup]
AppId={#AppId}
AppName={#AppName}
AppVersion={#AppVersion}
AppPublisher=md-tw26
AppPublisherURL=https://github.com/md-tw26/taj
AppSupportURL=https://github.com/md-tw26/taj/issues
AppUpdatesURL=https://github.com/md-tw26/taj/releases
VersionInfoVersion={#AppVersionNumeric}
DefaultDirName={autopf}\{#AppName}
DefaultGroupName={#AppName}
DisableProgramGroupPage=yes
PrivilegesRequired=admin
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
MinVersion=10.0
SetupIconFile=runner\resources\app_icon.ico
UninstallDisplayIcon={app}\{#AppExe}.exe
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
OutputDir=Output
OutputBaseFilename={#AppExe}-setup-{#AppVersion}

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Files]
Source: "{#SourceDir}\*"; DestDir: "{app}"; Flags: recursesubdirs ignoreversion

[Icons]
Name: "{group}\{#AppName}"; Filename: "{app}\{#AppExe}.exe"
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\{#AppExe}.exe"
Name: "{group}\Uninstall {#AppName}"; Filename: "{uninstallexe}"

[Run]
Filename: "{app}\{#AppExe}.exe"; Description: "{cm:LaunchProgram,{#AppName}}"; Flags: nowait postinstall skipifsilent

[UninstallDelete]
Type: filesandordirs; Name: "{app}"
