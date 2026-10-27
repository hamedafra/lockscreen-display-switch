# Lockscreen Display Switch

Switch your active monitor with **Win+P on the Windows 11 lock / sign-in screen**, which recent
Windows 11 builds no longer support.

- **Lock screen:** `Win+P` toggles between *PC screen only* and *Second screen only*. The sign-in
  box follows to the screen that stays on.
- **Signed in:** `Win+P` opens the normal Windows projection menu, unchanged.

[فارسی](#فارسی)

## Install

1. Download this repository (**Code → Download ZIP**) and extract it, or `git clone` it.
2. Double-click **`Install.cmd`** and accept the administrator prompt.

The installer:

- builds `DisplaySwitch.exe` from [`src/DisplaySwitch.cs`](src/DisplaySwitch.cs) using the C# compiler
  that ships with Windows (.NET Framework 4.x); there is no prebuilt binary to trust
- backs up the original Windows `DisplaySwitch.exe` (and its language files) to
  `C:\Program Files\LockscreenDisplaySwitch\original\`
- puts the new `DisplaySwitch.exe` in `C:\Windows\System32\`

> **After a Windows update:** if Win+P stops working on the lock screen, Windows probably restored
> its own file. Run `Install.cmd` again; it refreshes the backup with the updated original.

## Uninstall

Double-click **`Uninstall.cmd`**. It puts the original Windows file back, restores its permissions
and its owner (TrustedInstaller), and removes the program folder and logs.

## Antivirus warning

Windows Defender (and other antivirus) will likely flag the installed file, typically as
**`Trojan:Win32/AccessibilityEscalation`**. This is a false positive, but an understandable one:
replacing a system binary that the lock screen can launch (`sethc.exe`, `Magnify.exe`,
`DisplaySwitch.exe`, …) with an **unsigned** executable that then runs as `SYSTEM` is exactly the
shape of a classic privilege-escalation backdoor. Defender matches that *pattern*, not the contents
of this code.

Why this project trips it, while the real Windows file never does:

- it puts an executable that Microsoft did **not** sign into `C:\Windows\System32\`
- that executable is designed to run as `SYSTEM` from the lock screen

Everything the program does is in [`src/DisplaySwitch.cs`](src/DisplaySwitch.cs) (about a hundred
lines) — read it, and build it yourself with the installer, so you are not trusting a binary from
anyone. To use it anyway you must consciously allow it: in **Windows Security → Virus & threat
protection → Protection history**, choose **Allow** on the detection, or add an exclusion. If you are
not comfortable doing that, don't install this.

## How it works

When you press Win+P on the lock screen, Winlogon starts `C:\Windows\System32\DisplaySwitch.exe` as
`SYSTEM`. In current Windows 11 builds the menu crashes there, inside `DUI70.dll`. Older
`DisplaySwitch.exe` versions crash the same way, so swapping in an old copy doesn't help.

This replacement draws no UI. It calls the Windows display API (`SetDisplayConfig`) directly:

| Started as | Arguments | Action |
|---|---|---|
| `SYSTEM` (lock screen) | none | toggles *PC screen only* ⇄ *Second screen only* |
| signed-in user | none | starts the original Windows `DisplaySwitch.exe` (normal menu) |
| anyone | `/internal` `/external` `/extend` `/clone` | applies that mode directly |

Each run adds a line to `C:\ProgramData\LockscreenDisplaySwitch\switch.log`.

## Notes and caveats

- **This modifies a Windows system file.** Back up anything important. The uninstaller restores the
  original, and `sfc /scanfile=C:\Windows\System32\DisplaySwitch.exe` can also repair it.
- The program runs as `SYSTEM` on the lock screen. It does nothing except change the display mode,
  and its source is about a hundred lines. Read it before you install.
- Tested on Windows 11 (build 26300) with two monitors, using DisplayPort and HDMI.
- "PC screen only" and "Second screen only" are Windows' own terms. Which physical monitor counts
  as "first" is decided by Windows.

## Build manually

```powershell
powershell -ExecutionPolicy Bypass -File scripts\build.ps1   # output: bin\DisplaySwitch.exe
```

## License

[MIT](LICENSE)

---

## فارسی

با این برنامه می‌توانید روی **صفحه‌ی قفل و ورود ویندوز ۱۱** با `Win+P` مانیتور فعال را عوض کنید.
نسخه‌های جدید ویندوز ۱۱ دیگر این کار را پشتیبانی نمی‌کنند.

- **روی صفحه‌ی قفل:** `Win+P` بین «فقط صفحه‌ی اول» و «فقط صفحه‌ی دوم» جابه‌جا می‌کند و کادر ورود
  هم به همان صفحه می‌رود.
- **بعد از ورود:** `Win+P` همان منوی همیشگی ویندوز را باز می‌کند.

**نصب:** فایل **`Install.cmd`** را اجرا کنید و دسترسی Administrator را تأیید کنید.

**حذف:** فایل **`Uninstall.cmd`** را اجرا کنید. فایل اصلی ویندوز با دسترسی‌ها و مالک اصلی‌اش
برمی‌گردد.

**بعد از آپدیت ویندوز:** اگر `Win+P` روی صفحه‌ی قفل از کار افتاد، `Install.cmd` را دوباره اجرا کنید.

⚠️ این برنامه یکی از فایل‌های سیستمی ویندوز را عوض می‌کند. قبل از نصب کد آن را بخوانید. کد کوتاه
است و در [`src/DisplaySwitch.cs`](src/DisplaySwitch.cs) قرار دارد.

### هشدار آنتی‌ویروس

به احتمال زیاد Windows Defender فایل نصب‌شده را به‌عنوان تهدید علامت می‌زند، معمولاً با نام
**`Trojan:Win32/AccessibilityEscalation`**. این یک **هشدار اشتباه (false positive)** است، ولی
بی‌دلیل نیست: عوض کردن یک فایل سیستمی که از صفحه‌ی قفل قابل اجراست (مثل `sethc.exe` یا
`DisplaySwitch.exe`) با یک فایل **بدون امضا** که بعد با دسترسی `SYSTEM` اجرا می‌شود، دقیقاً شکل یک
روش نفوذ کلاسیک است. Defender همین **الگو** را می‌شناسد، نه محتوای این کد را. فایل‌های اصلی و
امضاشده‌ی ویندوز هیچ‌وقت علامت نمی‌خورند؛ فقط چون برنامه‌ی ما امضا ندارد این اتفاق می‌افتد.

تمام کاری که برنامه می‌کند در [`src/DisplaySwitch.cs`](src/DisplaySwitch.cs) است (حدود صد خط). خودتان
بخوانیدش و با نصب‌کننده روی سیستم خودتان بسازید، تا به فایل آماده‌ی کسی اعتماد نکنید. برای استفاده
باید آگاهانه اجازه بدهید: در **Windows Security ← Virus & threat protection ← Protection history**
روی هشدار گزینه‌ی **Allow** را بزنید یا فایل را در Exclusions بگذارید. اگر با این کار راحت نیستید،
نصبش نکنید.
