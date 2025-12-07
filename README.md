Countdown Timer Ring

A minimalist, visually-focused countdown timer for Windows 10/11 built with PowerShell and WinForms. Features a circular progress ring that fills with dark red as time elapses, with a clean, unobtrusive interface that reveals controls only on hover.

# Features

    Visual Countdown Ring: Dark red ring fills clockwise as time progresses

    Minimal Interface: Controls hide when not in use, appearing only on mouse hover

    Always on Top: Window stays above other applications

    Adjustable Transparency: 40% opacity default (configurable)

    Tone on Complete:  Default off (configurable)

    Resizable Window: Can be sized down to 100×125 pixels (TODO - consider 64 x 90)

    Simple Input: Set countdown time in minutes only

Prerequisites

    Windows 10 or 11

    PowerShell 5.1 or higher (included with Windows)

Installation

    Download the script, this is meant to be a standalone no install required tool

# Save as: CountdownTimer.ps1

Run the script:

    Right-click the script file and select "Run with PowerShell"

    Or run from PowerShell terminal .\CountdownTimer.ps1

# If blocked by execution policy (optional):

Run once to allow script execution in current session
```
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
```
Usage

    Set Time: Enter minutes in the input field (default: 5)

    Start Timer: Click "Start" - the ring will begin filling with dark red

    Stop Early: Click "Stop" to reset the timer

    Move Window: Hover to reveal controls, drag the title bar or ring area

    Resize: Drag any window edge or corner

Interface Behavior

    Normal State: Only the countdown ring is visible

    Hover State: Move mouse over window to reveal:

          Bottom: Control panel with time input and buttons

    Auto-hide: Controls disappear 500ms after mouse leaves

# Configuration

The script includes several adjustable parameters at the top of the file:
powershell

## Colors (RGB values)
```
$bgColor = [System.Drawing.Color]::FromArgb(30, 30, 30)        # Background
$ringBgColor = [System.Drawing.Color]::FromArgb(60, 60, 60)    # Empty ring
$ringFillColor = [System.Drawing.Color]::FromArgb(139, 0, 0)   # Filling ring (dark red)
```
## Window Properties
```
  $form.Opacity = 0.6                     # Transparency (0.0-1.0)
  $form.TopMost = $true                   # Always on top
  $form.MinimumSize = New-Object System.Drawing.Size(100, 125)  # Min window size
```

## Hover Behavior
```
$hideTimer.Interval = 500               # Delay before hiding controls (ms)
$titleBar.Height = 8                    # Title bar height when visible
```

## Customization Examples
Change Ring Color (e.g., to blue):
  ```
$ringFillColor = [System.Drawing.Color]::FromArgb(0, 120, 215)  # Windows blue
 ```
Increase Transparency:
```
$form.Opacity = 0.4  # Even more transparent
```
Adjust Hover Delay:
```
$hideTimer.Interval = 1000  # 1 second delay before hiding
```
# Technical Details
Architecture

    Language: PowerShell 5.1+

    GUI Framework: Windows Forms (WinForms)

    Graphics: GDI+ for custom drawing

    Timer: System.Windows.Forms.Timer (UI thread-safe)

Key Components

    Update-Display Function: Handles ring drawing with anti-aliasing

    Real-time Calculation: Uses system clock for accurate timing

    Hover Management: Timer-based show/hide logic

    Resource Management: Proper bitmap disposal to prevent memory leaks

## File Structure

CountdownTimer.ps1
├── Initialization (Add-Type, variable setup)
├── Form Creation (borderless, transparent, always-on-top)
├── Drawing Function (Update-Display with GDI+)
├── Timer Logic (real-time countdown calculation)
├── UI Controls (input, buttons, hover panels)
├── Event Handlers (mouse, resize, timer ticks)
└── Cleanup (resource disposal)

# Troubleshooting

"Script execution is disabled"	Run Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
Ring doesn't update	Ensure PowerShell is running with appropriate permissions
Controls don't appear on hover	Check mouse is over the form, not just borders
Window can't be moved	Hover first to show title bar, then drag
Close button too small at high DPI	Adjust $closeButton.Size and font in script

Development Notes
Why PowerShell + WinForms?

    Zero dependencies: Runs on any Windows machine

    Single file: No installation or compilation needed

    Rapid prototyping: Easy to modify and test

    Lightweight: Minimal resource usage

Design Decisions

    No Pause Feature: Kept interface simple, focused on start/stop

    Minutes Only: Simplified input validation and user experience

    Silent Completion: Avoids interruptions in work/meetings

    Hover-to-Reveal: Maximizes screen real estate for the timer display

Contributing

    Fork the repository

    Create a feature branch (git checkout -b feature/improvement)

    Test changes thoroughly

    Commit changes (git commit -am 'Add some feature')

    Push to branch (git push origin feature/improvement)

    Create a Pull Request

Areas for Improvement

    Preset timer buttons (1, 5, 10, 15 minutes)

    Better system tray integration

    Multiple timer instances

    Better handling of very large or small sizes

    Export as standalone executable
