# Countdown Timer Ring - PowerShell WinForms
# Save as: CountdownTimer.ps1

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Timer state variables
$timer = $null
$script:totalSeconds = 0
$script:remainingSeconds = 0
$script:isRunning = $false
$script:startTime = [DateTime]::Now

# Colors
$bgColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
$ringBgColor = [System.Drawing.Color]::FromArgb(60, 60, 60)
$ringFillColor = [System.Drawing.Color]::FromArgb(139, 0, 0)
$controlColor = [System.Drawing.Color]::FromArgb(70, 70, 70)
$titleBarColor = [System.Drawing.Color]::FromArgb(50, 50, 50)

# Create main form with THIN BORDER for resizing
$form = New-Object System.Windows.Forms.Form
$form.Size = New-Object System.Drawing.Size(300, 400)
$form.MinimumSize = New-Object System.Drawing.Size(100, 125)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "Sizable"
$form.BackColor = $bgColor
$form.Opacity = 0.6
$form.TopMost = $true
$form.ControlBox = $false

# Variables for dragging
$script:mouseDown = $false
$script:lastLocation = $null

# Create custom title bar (hidden by default) - MUCH SHORTER
$titleBar = New-Object System.Windows.Forms.Panel
$titleBar.Dock = "Top"
$titleBar.Height = 8  # CHANGED: Reduced to ~10% of original (was 30)
$titleBar.BackColor = $titleBarColor
$titleBar.Visible = $false  # Initially hidden

# REMOVED: Title label completely (no text needed)

# Close button - smaller and positioned for new height
$closeButton = New-Object System.Windows.Forms.Button
$closeButton.Text = "✕"
$closeButton.Size = New-Object System.Drawing.Size(20, 8)  # CHANGED: Smaller to fit
$closeButton.Location = New-Object System.Drawing.Point(280, 0)  # CHANGED: Positioned at top right
$closeButton.FlatStyle = "Flat"
$closeButton.BackColor = [System.Drawing.Color]::FromArgb(80, 80, 80)
$closeButton.ForeColor = [System.Drawing.Color]::White
$closeButton.FlatAppearance.BorderSize = 0
$closeButton.Font = New-Object System.Drawing.Font("Arial", 6)  # CHANGED: Smaller font
$closeButton.Add_Click({ $form.Close() })
$titleBar.Controls.Add($closeButton)

# Make the title bar draggable to move the window
$titleBar.Add_MouseDown({
    param($sender, $e)
    if ($e.Button -eq [System.Windows.Forms.MouseButtons]::Left) {
        $script:mouseDown = $true
        $script:lastLocation = $e.Location
    }
})

$titleBar.Add_MouseMove({
    param($sender, $e)
    if ($script:mouseDown) {
        $newX = $form.Left + ($e.X - $script:lastLocation.X)
        $newY = $form.Top + ($e.Y - $script:lastLocation.Y)
        $form.Location = New-Object System.Drawing.Point($newX, $newY)
    }
})

$titleBar.Add_MouseUp({
    param($sender, $e)
    $script:mouseDown = $false
})

# PictureBox for drawing the ring
$pictureBox = New-Object System.Windows.Forms.PictureBox
$pictureBox.Dock = "Fill"
$pictureBox.BackColor = $bgColor

# Make the picture box draggable too (when controls are visible)
$pictureBox.Add_MouseDown({
    param($sender, $e)
    if ($titleBar.Visible -and $e.Button -eq [System.Windows.Forms.MouseButtons]::Left) {
        $script:mouseDown = $true
        $script:lastLocation = $e.Location
    }
})

$pictureBox.Add_MouseMove({
    param($sender, $e)
    if ($titleBar.Visible -and $script:mouseDown) {
        $newX = $form.Left + ($e.X - $script:lastLocation.X)
        $newY = $form.Top + ($e.Y - $script:lastLocation.Y)
        $form.Location = New-Object System.Drawing.Point($newX, $newY)
    }
})

$pictureBox.Add_MouseUp({
    param($sender, $e)
    $script:mouseDown = $false
})

# Timer display function with error handling
function Update-Display {
    param([float]$progress = 0)
    
    try {
        if ($pictureBox.Width -le 0 -or $pictureBox.Height -le 0) {
            return
        }
        
        # Ensure progress is between 0 and 1
        if ($progress -lt 0) { $progress = 0 }
        if ($progress -gt 1) { $progress = 1 }
        
        # Create new bitmap
        $newBitmap = New-Object System.Drawing.Bitmap([Math]::Max(1, $pictureBox.Width), [Math]::Max(1, $pictureBox.Height))
        $graphics = [System.Drawing.Graphics]::FromImage($newBitmap)
        $graphics.SmoothingMode = "AntiAlias"
        $graphics.Clear($bgColor)
        
        # Calculate ring dimensions (minimum 50 pixels)
        $size = [Math]::Max(50, [Math]::Min($pictureBox.Width, $pictureBox.Height) * 0.8)
        
        $penWidth = $size * 0.1
        $x = ($pictureBox.Width - $size) / 2
        $y = ($pictureBox.Height - $size) / 2
        
        # Draw background ring
        $bgPen = New-Object System.Drawing.Pen($ringBgColor, $penWidth)
        $graphics.DrawEllipse($bgPen, $x, $y, $size, $size)
        $bgPen.Dispose()
        
        # Draw progress arc if any
        if ($progress -gt 0) {
            $fillPen = New-Object System.Drawing.Pen($ringFillColor, $penWidth)
            $sweepAngle = 360 * $progress
            $graphics.DrawArc($fillPen, $x, $y, $size, $size, -90, $sweepAngle)
            $fillPen.Dispose()
        }
        
        $graphics.Dispose()
        
        # Safely swap bitmaps
        $oldBitmap = $pictureBox.Image
        $pictureBox.Image = $newBitmap
        
        # Dispose old bitmap after new one is assigned
        if ($oldBitmap -ne $null) {
            $oldBitmap.Dispose()
        }
        
        # Force immediate redraw
        $pictureBox.Refresh()
        
    } catch {
        Write-Host "Error in Update-Display: $_"
    }
}

# Create timer
$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 100

# Timer tick event with proper script-scoped variables
$timer.Add_Tick({
    if ($script:isRunning -and $script:totalSeconds -gt 0) {
        try {
            # 1. GET CURRENT TIME from the system
            $currentTime = [DateTime]::Now
            
            # 2. SUBTRACT from the recorded start time
            $elapsedTime = ($currentTime - $script:startTime).TotalSeconds
            
            # 3. CALCULATE progress and remaining time
            $progress = $elapsedTime / $script:totalSeconds
            $script:remainingSeconds = $script:totalSeconds - $elapsedTime
            
            if ($script:remainingSeconds -le 0) {
                # Timer completed
                $script:remainingSeconds = 0
                $progress = 1
                $script:isRunning = $false
                $timer.Stop()
                
                # Timer completed notification
                [System.Media.SystemSounds]::Beep.Play()
                
                # Update UI
                $btnStart.Enabled = $true
                $btnStop.Enabled = $false
                $txtTime.Enabled = $true
            }
            
            # 4. UPDATE DISPLAY with the calculated progress
            Update-Display -progress $progress
            
        } catch {
            Write-Host "ERROR in timer tick: $_"
        }
    }
})

# Create controls panel (hidden by default)
$panel = New-Object System.Windows.Forms.Panel
$panel.Dock = "Bottom"
$panel.Height = 120
$panel.BackColor = $controlColor
$panel.Visible = $false

# Time input
$label = New-Object System.Windows.Forms.Label
$label.Text = "Minutes:"
$label.ForeColor = [System.Drawing.Color]::White
$label.Location = New-Object System.Drawing.Point(20, 15)
$label.Size = New-Object System.Drawing.Size(80, 20)
$panel.Controls.Add($label)

$txtTime = New-Object System.Windows.Forms.TextBox
$txtTime.Location = New-Object System.Drawing.Point(100, 12)
$txtTime.Size = New-Object System.Drawing.Size(80, 20)
$txtTime.Text = "5"
$txtTime.BackColor = [System.Drawing.Color]::FromArgb(50, 50, 50)
$txtTime.ForeColor = [System.Drawing.Color]::White
$panel.Controls.Add($txtTime)

# Buttons - Stacked vertically
$btnStart = New-Object System.Windows.Forms.Button
$btnStart.Location = New-Object System.Drawing.Point(20, 40)
$btnStart.Size = New-Object System.Drawing.Size(160, 30)
$btnStart.Text = "Start"
$btnStart.BackColor = [System.Drawing.Color]::FromArgb(80, 80, 80)
$btnStart.ForeColor = [System.Drawing.Color]::White
$btnStart.FlatStyle = "Flat"
$panel.Controls.Add($btnStart)

$btnStop = New-Object System.Windows.Forms.Button
$btnStop.Location = New-Object System.Drawing.Point(20, 75)
$btnStop.Size = New-Object System.Drawing.Size(160, 30)
$btnStop.Text = "Stop"
$btnStop.Enabled = $false
$btnStop.BackColor = [System.Drawing.Color]::FromArgb(80, 80, 80)
$btnStop.ForeColor = [System.Drawing.Color]::White
$btnStop.FlatStyle = "Flat"
$panel.Controls.Add($btnStop)

# ========== SIMPLIFIED HOVER LOGIC ==========
# Create a timer for delayed hiding
$hideTimer = New-Object System.Windows.Forms.Timer
$hideTimer.Interval = 500
$hideTimer.Enabled = $false

# Function to show controls
function Show-Controls {
    $titleBar.Visible = $true
    $panel.Visible = $true
    $hideTimer.Stop()
}

# Function to start hiding controls (with delay)
function Start-HideTimer {
    $hideTimer.Start()
}

# Timer tick to hide controls
$hideTimer.Add_Tick({
    $titleBar.Visible = $false
    $panel.Visible = $false
    $hideTimer.Stop()
})

# Mouse enter events - show controls immediately
$form.Add_MouseEnter({ Show-Controls })
$pictureBox.Add_MouseEnter({ Show-Controls })
$titleBar.Add_MouseEnter({ Show-Controls })
$panel.Add_MouseEnter({ Show-Controls })

# Mouse leave events - start hide timer
$form.Add_MouseLeave({ Start-HideTimer })
$pictureBox.Add_MouseLeave({ Start-HideTimer })
$titleBar.Add_MouseLeave({ Start-HideTimer })
$panel.Add_MouseLeave({ Start-HideTimer })

# Also handle mouse events for controls inside the panel
foreach ($control in $panel.Controls) {
    $control.Add_MouseEnter({ Show-Controls })
    $control.Add_MouseLeave({ Start-HideTimer })
}

# Also handle mouse events for controls inside the title bar
foreach ($control in $titleBar.Controls) {
    $control.Add_MouseEnter({ Show-Controls })
    $control.Add_MouseLeave({ Start-HideTimer })
}
# ========== END OF SIMPLIFIED HOVER LOGIC ==========

# Button event handlers
$btnStart.Add_Click({
    if ($script:isRunning) {
        return
    }
    
    # Parse minutes input
    $minutesInput = $txtTime.Text.Trim()
    
    # Try parsing as minutes only
    if ($minutesInput -match "^\d+$") {
        $script:totalSeconds = [int]$minutesInput * 60
    }
    else {
        [System.Windows.Forms.MessageBox]::Show("Please enter minutes as a whole number (e.g., 5)", "Invalid Input")
        return
    }
    
    if ($script:totalSeconds -le 0) {
        [System.Windows.Forms.MessageBox]::Show("Time must be greater than 0 minutes", "Invalid Input")
        return
    }
    
    # Start timer
    $script:remainingSeconds = $script:totalSeconds
    $script:isRunning = $true
    $script:startTime = [DateTime]::Now
    
    $btnStop.Enabled = $true
    $btnStart.Enabled = $false
    $txtTime.Enabled = $false
    
    # Immediate display update when starting
    Update-Display -progress 0
    
    $timer.Start()
})

$btnStop.Add_Click({
    $script:isRunning = $false
    $timer.Stop()
    
    $btnStop.Enabled = $false
    $btnStart.Enabled = $true
    $txtTime.Enabled = $true
    
    Update-Display -progress 0
})

# Form resize event
$form.Add_Resize({
    # Adjust close button position when form resizes (stays top right)
    $closeButton.Left = $form.ClientSize.Width - $closeButton.Width - 10
    
    # Adjust button widths to fit panel width
    $panelWidth = $panel.Width
    $btnStart.Width = [Math]::Max(75, $panelWidth - 40)
    $btnStop.Width = [Math]::Max(75, $panelWidth - 40)
    $txtTime.Left = [Math]::Max(100, ($panelWidth - 80) / 2)
    $label.Left = $txtTime.Left - 80
    
    if ($script:totalSeconds -gt 0 -and $script:isRunning) {
        # Use the same real-time calculation for consistency
        $elapsedTime = ([DateTime]::Now - $script:startTime).TotalSeconds
        $progress = $elapsedTime / $script:totalSeconds
        Update-Display -progress $progress
    } else {
        Update-Display -progress 0
    }
})

# Add all controls to form
$form.Controls.Add($pictureBox)
$form.Controls.Add($panel)
$form.Controls.Add($titleBar)

# Set the order so PictureBox is behind everything
$form.Controls.SetChildIndex($pictureBox, 0)
$form.Controls.SetChildIndex($panel, 1)
$form.Controls.SetChildIndex($titleBar, 2)

# Initial display
Update-Display -progress 0

# Handle form closing to clean up resources
$form.Add_FormClosing({
    if ($timer -ne $null) {
        $timer.Stop()
        $timer.Dispose()
    }
    
    if ($hideTimer -ne $null) {
        $hideTimer.Stop()
        $hideTimer.Dispose()
    }
    
    # Clean up bitmap
    if ($pictureBox.Image -ne $null) {
        try {
            $pictureBox.Image.Dispose()
        } catch {
            # Ignore disposal errors on close
        }
    }
})

# Show form
[System.Windows.Forms.Application]::Run($form)
