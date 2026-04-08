---
doc_type: "reference"
version: "1.0.0"
source: "PokerGFX User Manual v3.2.0"
url: "https://www.pokergfx.io/downloads/user-manual.pdf"
created: "2026-02-25"
---

# PokerGFX 매뉴얼 v3.2.0 — UI 요소 공식 설명 참조

> **용도**: PRD-0004의 Element Catalog 설명 보완 참조용. 각 요소의 공식 설명은 매뉴얼 원문 인용.

---

## System Status Icons (Main Window)

| PRD ID | 요소명 | 매뉴얼 공식 설명 | 매뉴얼 페이지 |
|--------|--------|----------------|:----------:|
| M-03 | CPU Indicator | "The icons on the left indicate CPU and GPU usage. If they turn red, usage is too high for the Server to operate reliably." | p.34 |
| M-04 | GPU Indicator | "The icons on the left indicate CPU and GPU usage. If they turn red, usage is too high for the Server to operate reliably." | p.34 |
| M-05 | RFID Status (Green) | "RFID Reader is operating normally." | p.34 |
| M-05 | RFID Status (Grey) | "PokerGFX Server is establishing a secure link with the RFID Reader." | p.34 |
| M-05 | RFID Status (Blue) | "RFID Reader is operating normally, however there are playing cards on the table that have not yet been registered." | p.34 |
| M-05 | RFID Status (Black) | "RFID Reader is operating normally, however more than one card of the same rank and suit has been detected. This indicates a card registration error, or cards from more than one deck on the table at the same time." | p.34 |
| M-05 | RFID Status (Magenta) | "RFID Reader is operating normally, however duplicate cards have been detected on the table." | p.34 |
| M-05 | RFID Status (Orange) | "RFID Reader is connected but not responding. May indicate an overloaded CPU or USB link, which could be caused by too many webcams or no table power." | p.34 |
| M-05 | RFID Status (Red) | "RFID Reader is not connected." | p.34 |
| N/A | Secure Delay Icon | "The icon to the right indicates whether Secure Delay is enabled." | p.34 |

## Settings (전역 설정)

| PRD ID | 요소명 | 매뉴얼 공식 설명 | 매뉴얼 페이지 |
|--------|--------|----------------|:----------:|
| M-07 | Lock Toggle | "Click the Lock symbol next to the Settings button to password protect the Settings Window." | p.33 |
| N/A | Settings Reset | "Hold the CTRL key while starting the Server to reset all settings to their default values." | p.33 |

## Sources 탭 (S-*)

| PRD ID | 요소명 | 매뉴얼 공식 설명 | 매뉴얼 페이지 |
|--------|--------|----------------|:----------:|
| S-01 | Device Table | "The Sources tab contains a list of available video sources. These include USB cameras, video capture cards installed in the system and NDI sources detected on the local network." | p.35 |
| S-02 | Add Network Camera | "Network cameras can't be auto detected, so to configure one of these as a source click the 'Add network camera' button, scroll down to the new camera at end of the Sources list and enter the stream URL for the camera by clicking in the 'Input / Format / URL' column." | p.35 |
| S-01 (Device col) | Device Name | "To assign to a video source a meaningful, custom name (eg 'Flop Cam'), click on the name of the device in the 'Device' column and enter a new name." | p.35 |
| S-01 (Format col) | Input Format | "To select the video format, click on the 'Input / Format' column." | p.35 |
| S-03 | Device Settings | "To edit the properties of the video source, click on the 'Settings' keyword. A properties window will open enabling additional camera settings to be changed." | p.35 |
| S-01 (Left/Right col) | Single Source Select | "To select a single video source as the display background, click both the Left and Right columns for the desired source." | p.35 |
| S-08 | Split Screen | "To select a split screen view, select the left-hand window by clicking in the Left column for one source, and the Right column for a different source." | p.35 |
| S-07 | Cycle Mode | "To display video sources in rotation, select 'Cycle' mode instead of 'Static'. Enter the number of seconds that each video source should be displayed in the 'Cycle' column. A value of zero will exclude that source from the rotation." | p.35 |
| S-10 | Follow Board | "When 'Follow Board' is enabled, the video will switch to the community card close-up for a few seconds whenever flop, turn or river cards are dealt." | p.36 |
| S-05 | Board Cam Hide GFX | "If the 'Hide GFX' option is enabled, all player graphics will be made invisible while the board cam is active." | p.36 |
| N/A | Linger on Board | "The Linger on Board setting sets the number of seconds the board cam is active before returning to the next view." | p.36 |
| S-09 | Follow Players | "When 'Follow Players' is enabled: If Action Tracker is enabled, the video will switch to ensure that the player whose turn it is to act is always displayed." | p.37 |
| N/A | Post Bet | "The 'Post Bet' option determines what happens at the end of each betting round: Player / Default / Board" | p.37 |
| N/A | Post Hand | "The 'Post Hand' option determines what happens at the end of the hand: Default / Player / Winner" | p.37 |
| S-08 | Heads Up Split Screen | "When 'Heads Up Split Screen' is enabled: When play is heads up, and both players are covered by separate cameras, a split screen view showing each player will automatically be displayed." | p.37 |
| S-16 | Camera Transitions / Crossfade | "When the 'Crossfade' setting is zero, camera sources transition with a hard cut. Setting this value to a higher value between 0.1 and 2.0 causes sources to crossfade, resulting in a softer, more fluid transition." | p.38 |
| S-15 | Board Sync | "Delays the detection of community cards by the specified number of milliseconds. This can be used to compensate for the problem where community card graphics are displayed before the cards are shown being dealt on video." | p.38 |
| S-13 | External Switcher | "When using a camera source for video capture from an external vision switcher, select this capture device using the 'External Switcher Source' dropdown box. This disables the built-in multi-camera switching features." | p.38 |
| S-17 | Audio Input | "Select the desired audio capture device and volume. The Sync setting adjusts the timing of the audio signal to match the video, if required." | p.38 |
| S-11 / S-12 | Chroma Key | "Chroma key is supported by outputting graphics on a solid colour background (usually blue or green). To enable chroma key, enable the 'Chroma Key' checkbox then repeatedly click the 'Background Key Colour' button until the desired colour is selected." | p.39 |
| O-05 | Key & Fill | "Key & Fill is supported on specific Blackmagic devices that support external keying including the Decklink Duo 2, Quad 2, 8K Pro & 4K Extreme 12G." | p.39 |
| S-14 | ATEM Control | "PokerGFX can control a Blackmagic ATEM Video Switcher to automatically switch camera inputs to follow the action." | p.40 |

## Outputs 탭 (O-*)

| PRD ID | 요소명 | 매뉴얼 공식 설명 | 매뉴얼 페이지 |
|--------|--------|----------------|:----------:|
| O-01 | Size / Frame Rate | "Select the desired resolution and frame rate of the video output." | p.42 |
| N/A | Video Preview | "Sends the live and/or delayed video feed to an additional video display attached to the graphics card." | p.42 |
| N/A | Audio Preview | "Sends the live and/or delayed audio feed matching the above video previews to any of the standard Windows audio output devices." | p.42 |
| O-04 | Output Device | "Sends the live and/or delayed video and audio feed to a Blackmagic Decklink device output (if installed), or to an NDI stream on the local network. NOTE: This option is only available with an Enterprise license." | p.42 |
| O-05 / O-07 | Key & Fill (output) | "When an output device that supports external keying is selected, the 'Key & Fill' checkbox is enabled. Activating this feature causes separate key & fill signals to be sent to 2 SDI connectors on the device." | p.43 |
| O-14 | Virtual Camera | "Sends the video and audio feed (live OR delayed, depending on this setting) to the POKERGFX VCAM virtual camera device, for use by 3rd party streaming software such as OBS or XSplit." | p.43 |
| O-02 | 9x16 Vertical | "PokerGFX supports vertical video natively by enabling the '9x16 Vertical' checkbox in the Outputs settings tab. With vertical video enabled you can stream POV-style content complete with graphics and secure delay." | p.43 |
| N/A (Future) | Secure Delay (toggle) | "This feature causes a security delay to be introduced to the live video stream. For example, to delay the stream by 20 minutes, enter the value '20'. Start the delay by clicking the 'Secure Delay' checkbox." | p.44 |
| N/A | When Secure Delay active | "(1) The padlock indicator will lock and turn green (2) The live preview window shows hole cards DOWN, but the delayed output shows hole cards UP. (3) The live preview is safe for real time display at the venue" | p.44 |
| N/A | Auto Delay | "This feature will turn secure delay on as soon as the first hand is detected, then stop it after a period of inactivity. To enable, set the 'Auto' box to the number of minutes of inactivity." | p.45 |
| N/A | Delay Countdown | "When a secure delay is started, a countdown clock is displayed to viewers that indicates when the video will start." | p.45 |
| N/A | Dynamic Delay | "The Dynamic Delay feature automatically skips tourney breaks during a delayed stream by starting with a much longer delay which is progressively reduced every time there's a break." | p.46 |
| O-16 | Twitch ChatBot | "PokerGFX includes a fully functional ChatBot that is compatible with the Twitch video streaming service. Commands: !event, !blinds, !players, !delay, !chipcount, !cashwin, !payouts, !vpip, !pfr" | p.47 |

## Secure Delay 상세

| 항목 | 매뉴얼 공식 설명 | 매뉴얼 페이지 |
|------|----------------|:----------:|
| 기능 개요 | "This feature causes a security delay to be introduced to the live video stream. For example, to delay the stream by 20 minutes, enter the value '20'. Start the delay by clicking the 'Secure Delay' checkbox." | p.44 |
| 활성 상태 (1) | "The padlock indicator will lock and turn green" | p.44 |
| 활성 상태 (2) | "The live preview window shows hole cards DOWN, but the delayed output shows hole cards UP." | p.44 |
| 활성 상태 (3) | "The live preview is safe for real time display at the venue" | p.44 |
| Auto Delay | "This feature will turn secure delay on as soon as the first hand is detected, then stop it after a period of inactivity. To enable, set the 'Auto' box to the number of minutes of inactivity." | p.45 |
| Delay Countdown | "When a secure delay is started, a countdown clock is displayed to viewers that indicates when the video will start." | p.45 |
| Dynamic Delay | "The Dynamic Delay feature automatically skips tourney breaks during a delayed stream by starting with a much longer delay which is progressively reduced every time there's a break." | p.46 |
| Secure Delay Folder | "Click the 'Secure Delay Folder' button to specify a storage folder on a different drive. These files occupy approximately 50 GB of space for a video size of 1920 x 1080." | p.60 |
| Unknown cards blink | "When Secure Delay is enabled, the live preview window always displays hole cards down. When this option is enabled, cards that have not been scanned are indicated by blinking." | p.52 |

## GFX 탭 공통 (G-*)

### 레이아웃 설정

| PRD ID | 요소명 | 매뉴얼 공식 설명 | 매뉴얼 페이지 |
|--------|--------|----------------|:----------:|
| G-01 | Board Position | "Position of the Board graphic (shows community cards, pot size and optionally blind levels). Choices are LEFT, CENTRE and RIGHT. The Board is always positioned at the bottom of the display." | p.48 |
| G-02 | Player Layout (Horizontal) | "players are arranged horizontally along the bottom of the display, board cards centred above players." | p.48 |
| G-02 | Player Layout (Vert/Bot/Spill) | "Players are arranged vertically starting from the bottom left corner of the display. When the left side is full, players fill up from the bottom right corner." | p.48 |
| G-02 | Player Layout (Vert/Bot/Fit) | "Players are arranged vertically starting from the bottom left corner of the display. If necessary, players are reduced in size to ensure they all fit on the left hand side." | p.48 |
| G-02 | Player Layout (Vert/Top/Spill) | "Players are arranged vertically starting from the top left corner." | p.48 |
| G-02 | Player Layout (Vert/Top/Fit) | "same as Vert/Bot/Fit but from top" | p.48 |
| G-07 | Heads Up Layout L/R | "Overrides the player layout when players are heads-up. In this mode, the board graphic is positioned at the bottom centre of the display with each player positioned either side." | p.48 |
| G-09 | Heads Up Custom Y | "Use this to specify the vertical position of player graphics when Heads Up layout is active." | p.48 |
| G-06 | Leaderboard Position | "Selects the position of the Leaderboard graphic." | p.49 |
| G-03 | X Margin | "This setting controls the size of the horizontal margins. Valid values are between 0 and 1. When in any vertical layout mode, larger values cause all graphics to move towards the centre of the display." | p.49 |
| G-04 / G-05 | Y Margin (Top & Bottom) | "This setting controls the size of the vertical margins. Valid values are between 0 and 1. Larger values cause all graphics to move towards the centre of the display." | p.49 |

### 스킨 및 미디어

| PRD ID | 요소명 | 매뉴얼 공식 설명 | 매뉴얼 페이지 |
|--------|--------|----------------|:----------:|
| N/A | Skin Editor | "Open the Skin Editor" | p.49 |
| N/A | Media Folder | "Configures the location of the Media folder, which contains player photos and other videos." | p.49 |

### 애니메이션

| PRD ID | 요소명 | 매뉴얼 공식 설명 | 매뉴얼 페이지 |
|--------|--------|----------------|:----------:|
| N/A | Transition In Animation | "Method and speed used to transition players on to the display. Select from Slide, Fade, Pop and Expand." | p.49 |
| N/A | Transition Out Animation | "Method and speed used to transition players off the display. Select from Slide, Fade, Pop and Expand." | p.49 |

### 텍스트 및 스폰서

| PRD ID | 요소명 | 매뉴얼 공식 설명 | 매뉴얼 페이지 |
|--------|--------|----------------|:----------:|
| G-13 | Vanity | "Custom text displayed on the Board Card / Pot graphic." | p.49 |
| G-13 | Replace Vanity | "When this option is enabled, the name of the currently active game variant will be displayed instead of the Vanity text." | p.49 |
| G-10 | Leaderboard Logo | "Displays a sponsor logo at the top of the Leaderboard. NOTE: Pro only." | p.50 |
| G-11 | Board Logo | "Displays a sponsor logo to the side of the Board. NOTE: Pro only." | p.50 |
| G-12 | Strip Logo | "Displays a sponsor logo at the left-hand end of the Strip. NOTE: Pro only." | p.50 |

### 블라인드 및 리더보드 표시

| PRD ID | 요소명 | 매뉴얼 공식 설명 | 매뉴얼 페이지 |
|--------|--------|----------------|:----------:|
| N/A | Show Blinds | "Blinds and Antes will be displayed for 10 seconds: Never / Every Hand / New Level / With Strip" | p.50 |
| N/A | Show Hand # Blinds | "Whether to display the hand number when blinds are shown." | p.50 |
| N/A | Show leaderboard after each hand | "Automatically show chip counts, and other player statistics in leaderboard between hands." | p.50 |
| N/A | Show player stats in ticker | "Automatically insert updated player chip counts and other statistics in the scrolling ticker at the top or bottom of the display, after each hand." | p.50 |
| N/A | Add Seat # | "Automatically display the physical seat number in front of the player name in the player graphic." | p.50 |

### 카드 공개 및 폴드 처리

| PRD ID | 요소명 | 매뉴얼 공식 설명 | 매뉴얼 페이지 |
|--------|--------|----------------|:----------:|
| G-14 | Reveal Players | "Determines when players are shown: Immediate / On Action / After Bet / On Action + Next" | p.50 |
| G-16 | Reveal Cards (Immediate) | "Hole cards are shown as soon as the player graphic appears." | p.51 |
| G-16 | Reveal Cards (After Action) | "Hole cards are shown after the player's first action." | p.51 |
| G-16 | Reveal Cards (End of Hand) | "Hole cards are shown when all betting for the hand has finished." | p.51 |
| G-16 | Reveal Cards (Showdown Cash) | "Reveals cards of players if they win the hand, or are the first aggressor on the last betting round." | p.51 |
| G-16 | Reveal Cards (Showdown Tourney) | "Reveals cards per Showdown-Cash PLUS cards of all players still in the hand if there's at least one all-in." | p.51 |
| G-16 | Reveal Cards (Never) | "Hole cards are never shown." | p.51 |
| G-15 | How to show a Fold (Immediate) | "Player is removed immediately." | p.51 |
| G-15 | How to show a Fold (Delayed) | "Player graphic displays 'Fold', then disappears after a few seconds." | p.51 |

### Outs 및 액션 표시

| PRD ID | 요소명 | 매뉴얼 공식 설명 | 매뉴얼 페이지 |
|--------|--------|----------------|:----------:|
| N/A | Show Outs | "When play is heads up, all cards remaining in the deck that could improve the worst player's hand are displayed. Never / Heads Up / Heads Up All In" | p.51 |
| N/A | Outs Position | "Display Outs either on the left or right hand side of the screen." | p.51 |
| N/A | True Outs | "When enabled, mucked cards are counted when computing pot equity and outs. Disabling this option causes mucked cards to be ignored, so theoretical pot equity and outs are displayed instead." | p.51 |
| N/A | Indent Action Player | "When this option is enabled, the 'Action On' player is indented towards the centre of the screen." | p.52 |
| N/A | Clear previous action | "When the action returns to a player after a bet or raise, the previous action is cleared and 'x TO CALL' or 'OPTION' is displayed." | p.52 |
| N/A | Heads Up History | "When players are heads-up, a graphic element appears that shows a history of all actions made by the heads up players in the current hand." | p.52 |
| N/A | Allow Rabbit Hunting | "When a hand has finished that didn't go to a showdown, additional cards placed on the community card antenna will show as 'rabbit hunt' cards." | p.52 |

### 칩 카운트 및 통화 표시

| PRD ID | 요소명 | 매뉴얼 공식 설명 | 매뉴얼 페이지 |
|--------|--------|----------------|:----------:|
| N/A | Max BB multiple | "Whether to show Big Blind multiples in the chip count display." | p.50 |
| N/A | Chipcount Precision (Exact) | "Exact Amount: Exact number of chips." | p.52 |
| N/A | Chipcount Precision (Smart) | "Smart Amount: Large amounts are automatically abbreviated with 'k' and 'M'." | p.52 |
| N/A | Chipcount Precision (Smart+) | "Smart Amount extra precision: same but with up to 3 decimal places." | p.52 |
| N/A | Currency Symbol | "When this option is enabled, all chip amounts are displayed with the local currency symbol." | p.52 |
| N/A | Trailing Currency Symbol | "Displays the currency symbol to the right of the amount, instead of to the left." | p.52 |
| N/A | Divide all amounts by 100 | "Causes all chip amounts to be divided by 100 before display. This permits the use of very small denomination chips." | p.52 |
| N/A | Show Chipcount % | "Shows each player's stack on the Leaderboard as a percentage of total chips on the table." | p.53 |
| N/A | How to display amounts | "Display chip counts, pots and bets in the player element as chips, BB multiple or both." | p.53 |
| N/A | Display Side Pot Amount | "When a player is all-in, and there is side action, PokerGFX can display both the main and side pot separated by a '/'" | p.53 |
| N/A | Limit raises to Effective stack size | "If a player makes a bet that exceeds the size of the largest stack of any other player active in the hand, the bet will be limited to the size of the largest stack." | p.53 |

### 리더보드 및 Strip

| PRD ID | 요소명 | 매뉴얼 공식 설명 | 매뉴얼 페이지 |
|--------|--------|----------------|:----------:|
| N/A | Score Strip | "The Strip is a graphical element that's displayed across the top of the screen showing players and their chip counts. Select from 'Off', 'Stack' or 'Winnings'." | p.53 |
| N/A | Order Strip by | "Players in the Strip can be ordered either by physical seating order or chip count order." | p.53 |
| N/A | Show eliminated players in Strip | "When enabled, players with a zero chip count will still be displayed in the Strip (but these players will be greyed-out)." | p.53 |
| N/A | Show knockout rank | "Displays the rank of eliminated players on the chip count display." | p.53 |
| N/A | Show as Eliminated | "Displays the message ELIMINATED on a player graphic if that player's stack is reduced to zero." | p.53 |
| N/A | Show eliminated players in Leaderboard | "When enabled, players that have left the table or been eliminated are displayed using the alternate colour." | p.53 |

### Action Clock

| PRD ID | 요소명 | 매뉴얼 공식 설명 | 매뉴얼 페이지 |
|--------|--------|----------------|:----------:|
| N/A | Action Clock | "PokerGFX will automatically display the number of seconds players have left to act whenever the timer reaches the number of seconds specified in the Graphics Settings -> Action Clock setting." | p.54 |

## System 탭 (Y-*)

| PRD ID | 요소명 | 매뉴얼 공식 설명 | 매뉴얼 페이지 |
|--------|--------|----------------|:----------:|
| Y-24 | Check for Updates | "Force the Server to check to see if there's a software update available." | p.58 |
| Y-15 | Action Tracker Kiosk | "When the Server starts, Action Tracker is automatically started on the same PC on the secondary display in kiosk mode. In this mode, AT cannot be closed or minimised, and the Video and Delay Insert consoles are disabled." | p.58 |
| Y-22 | Auto Start | "Automatically start the PokerGFX Server when Windows starts. Useful for unattended installations." | p.58 |
| Y-13 | Allow Action Tracker access | "'Track the action' can only be started from Action Tracker if this option is enabled. When disabled, Action Tracker may still be used but only in Auto mode." | p.58 |
| Y-16 | MultiGFX | "Forces PokerGFX to sync to another primary PokerGFX running on a different, networked computer, making it possible to generate multiple live and delayed video streams with different graphics, from the same table." | p.58 |
| Y-17 | Sync Stream | "When in MultiGFX mode, forces secure delay to start and stop in synchronization with the primary server." | p.58 |
| Y-18 | Sync Skin | "Causes the secondary MultiGFX server skin to auto update from the skin that is currently active on the primary server." | p.58 |
| Y-19 | No Cards | "Enable this on the primary MultiGFX server as an additional layer of security. When enabled, no hole card information will be shared with any secondary server." | p.58 |
| Y-21 | Ignore Name Tags | "When enabled, player ID tags are ignored; player names are entered manually in Action Tracker." | p.59 |
| Y-05 | UPCARD antennas read hole cards | "Enables all antennas configured for reading UPCARDS in STUD games to also detect hole cards when playing any flop or draw game." | p.59 |
| Y-06 | Disable Muck in AT mode | "Causes the muck antenna to be disabled when in Action Tracker mode." | p.59 |
| N/A | Secure Delay Folder | "Click the 'Secure Delay Folder' button to specify a storage folder on a different drive. These files occupy approximately 50 GB of space for a video size of 1920 x 1080." | p.60 |
| Y-12 | Export Folder | "When the Developer API is enabled, use this to specify the location for writing the JSON hand history files." | p.60 |
| Y-14 | Action Tracker Predictive Bet Input | "Action Tracker will auto-complete bets and raises based on the initial digits entered, min raise amount and stack size." | p.60 |
| Y-01 | Table Name | "Enter an optional name for this table. This is required when using MultiGFX mode, or there are multiple tables connected to the same local area network." | p.60 |
| Y-02 | Table Password | "Password for this table. Anyone attempting to use Action Tracker with this table will be required to enter this password." | p.60 |
| Y-04 | Calibrate Table | "Perform the once-off table calibration procedure, which 'teaches' the table about its physical configuration." | p.60 |
| Y-09 | Table Diagnostics | "Displays a diagnostic window that displays the physical table configuration along with how many cards are currently detected on each antenna." | p.60 |
| N/A | Setup WIFI | "Configure WIFI settings on the RFID Reader." | p.60 |
| Y-03 | Reset | "Resets the RFID Reader connection, as if PokerGFX had been closed and restarted." | p.60 |

## Action Tracker 인터페이스

### Auto Mode 요소

| PRD ID | 요소명 | 매뉴얼 공식 설명 | 매뉴얼 페이지 |
|--------|--------|----------------|:----------:|
| N/A (AT 전용) | Table Health | "Indicates the quality of the link between the Server and the table. Yellow or red means that cards are not being tracked accurately." | p.84 |
| N/A (AT 전용) | Network Health | "Indicates the quality of the link between the Server and the Tracker. Yellow or red means that updates will be delayed or lost." | p.84 |
| N/A (AT 전용) | Stream Indicator | "Green indicates that Secure Delay is active." | p.84 |
| N/A (AT 전용) | Record Indicator | "Green indicates that recording is active; Grey indicates recording is not active." | p.84 |
| N/A (AT 전용) | Game Variant | "Switch between game variants (Hold'Em, Omaha etc)." | p.85 |
| N/A (AT 전용) | Director Console | "Opens a new window that shows a graphical layout of the physical table and the status of each player." | p.85 |
| N/A (AT 전용) | Statistics Console | "Opens a new window that shows player chip counts and statistics." | p.85 |
| N/A (AT 전용) | Close Tracker | "Shut down the Tracker application." | p.85 |
| N/A (AT 전용) | Window Size | "Action Tracker is designed for use on a touch tablet, and always starts in full screen mode. To facilitate use on a standard PC, touch the 'Window Size' icon to shrink the window to a smaller size." | p.85 |
| N/A (AT 전용) | Register Deck | "Touch this icon to start the Playing Card registration procedure." | p.85 |
| N/A (AT 전용) | Community Cards | "Display of any community cards that have been dealt." | p.85 |
| N/A (AT 전용) | Track The Action | "Switch into bet tracking mode." | p.86 |
| N/A (AT 전용) | Player Status Icon | "The player icon turns red to indicate a player is sitting in that seat, and grey when the seat is vacant. A card graphic will appear to indicate that a player has been dealt cards." | p.86 |
| N/A (AT 전용) | Player additional actions | Delete / Move Seat / Sit Out / Change Name / Leaderboard Name / Photo / Country | p.86 |

### GFX Console 요소

| PRD ID | 요소명 | 매뉴얼 공식 설명 | 매뉴얼 페이지 |
|--------|--------|----------------|:----------:|
| N/A (AT 전용) | Seat | "Displays a list of active players by seat number, with chip counts." | p.98 |
| N/A (AT 전용) | Stack | "Displays player chip counts, sorted in descending order. If the 'Rank' option is enabled, eliminated players are also displayed in order of elimination." | p.98 |
| N/A (AT 전용) | VPIP% | "Displays VPIP (Voluntary Put In Pot) = pre-flop calls divided by total hands played, as a percentage." | p.98 |
| N/A (AT 전용) | PFR% | "Displays Pre Flop Raise% = number of pre-flop raises divided by total hands played, as a percentage." | p.98 |
| N/A (AT 전용) | AGRfq% | "Aggression Frequency% = number of bets & raises divided by the total number of bets, raises, calls and folds." | p.98 |
| N/A (AT 전용) | WTSD% | "Displays Went To Showdown% = number of times went to showdown divided by flops seen, as a percentage." | p.98 |
| N/A (AT 전용) | WIN | "Displays net winnings / losses for each player (cash game only). Effectively the same as each player's stack less their buy-ins." | p.98 |
| N/A (AT 전용) | Field | "Displays the number of entrants in a tourney, and players remaining. Use the REMAIN and TOTAL buttons to enter the correct player numbers." | p.98 |
| N/A (AT 전용) | Payouts | "[Pro only] Displays a list of all player payouts." | p.98 |
| N/A (AT 전용) | PIP | "Forces display of the Picture In Picture (PIP) feature." | p.99 |
| N/A (AT 전용) | Ticker | "Touch this button and enter a message to display the scrolling ticker. Your message will scroll from right to left across the display." | p.99 |

### Hand Pre-Start 요소

| PRD ID | 요소명 | 매뉴얼 공식 설명 | 매뉴얼 페이지 |
|--------|--------|----------------|:----------:|
| N/A (AT 전용) | SETTINGS button | "Enter the Event Name, Ante Type, Number of Blinds, Game Type (Cash Game, Feature Table, Final Table, Sit N Go), Game Variant, and Payouts." | p.87 |
| N/A (AT 전용) | Ante/Blind amounts | "Ensure the Ante and Blind amounts are correct" | p.87 |
| N/A (AT 전용) | CAP box | "Bets across all streets may be capped by entering a value in the CAP box" | p.87 |
| N/A (AT 전용) | BUTTON BLIND | "A BUTTON BLIND (common in Short Deck Hold'Em games) may be configured." | p.88 |
| N/A (AT 전용) | 7-DEUCE box | "entering a value in the 7-DEUCE box will cause that amount to be deducted from every losing player in the hand when a hand is won by a player that has 7-2" | p.88 |
| N/A (AT 전용) | BOMB POT box | "when a value is entered in the BOMB POT box, the value of the bomb pot is deducted from each players stack at the start of the hand" | p.88 |
| N/A (AT 전용) | SINGLE/DOUBLE/TRIPLE board | "Select a SINGLE, DOUBLE or TRIPLE board." | p.88 |
| N/A (AT 전용) | Min Chip | "Enter the value of the lowest denomination chip on the table into the 'Min Chip' box. This ensures that split pots are rounded correctly." | p.88 |
| N/A (AT 전용) | Player buttons 1-10 | "Enter player names by touching the player buttons numbered 1-10." | p.89 |
| N/A (AT 전용) | Chip count buttons | "Ensure the starting chip count for each player is accurate. Enter chip counts by touching the orange button below each player." | p.89 |
| N/A (AT 전용) | Position arrows | "Use the Position arrow buttons to move the Dealer Button, Small Blind and Big Blind to the correct seats." | p.89 |
| N/A (AT 전용) | STRADDLE buttons | "Enter any additional blind bets by touching the green STRADDLE buttons." | p.89 |
| N/A (AT 전용) | GO button | "When all the information is correct, touch the 'GO' button to start the hand." | p.91 |

### During Hand 요소

| PRD ID | 요소명 | 매뉴얼 공식 설명 | 매뉴얼 페이지 |
|--------|--------|----------------|:----------:|
| N/A (AT 전용) | Fold button | "If the player folds, touch the 'Fold' button" | p.92 |
| N/A (AT 전용) | Call button | "If the player calls, touch the 'Call' button" | p.92 |
| N/A (AT 전용) | Bet/Raise To button | "If the player makes a bet or raise, touch the 'Bet/Raise To' button and enter the amount. Raise amounts are always entered as the total 'raise to' amount, not the size of the additional bet." | p.92 |
| N/A (AT 전용) | All In button | "If the player goes all in, touch the 'All In' button." | p.92 |
| N/A (AT 전용) | UNDO button | "If you touch the wrong button in error or enter an incorrect amount, touch the 'UNDO' arrow button to undo the most recent action." | p.92 |
| N/A (AT 전용) | MISS DEAL button | "Touch the 'MISS DEAL' button to return the hand to the Pre-Start screen. All stacks and positions will be restored as if no actions had occurred." | p.92 |
| N/A (AT 전용) | Hide GFX button | "Touch the 'Hide GFX' button to temporarily hide on screen graphics while using the Back Arrow button to undo errors." | p.92 |
| N/A (AT 전용) | Next Hand button | "Touch the 'Next Hand' button to clear the graphic overlay and advance the dealer, small and big blinds ready for the next hand." | p.93 |
| N/A (AT 전용) | Adjust Stack button | "Touch the 'Adjust Stack' button to manually update the chip count for the current player." | p.93 |
| N/A (AT 전용) | Tag Hand button | "To mark the current hand as a favourite, touch the 'Tag Hand' button. Enter a note for the hand, and the Tag Hand button turns yellow." | p.93 |

### Director Console

| PRD ID | 요소명 | 매뉴얼 공식 설명 | 매뉴얼 페이지 |
|--------|--------|----------------|:----------:|
| N/A (AT 전용) | Director Console 개요 | "The Director console shows a graphical representation of the action at the table and allows the operator to manually control the switching of video sources by temporarily overriding the auto camera switching features." | p.100 |
| N/A (AT 전용) | OVL button | "Touching the OVL button at the top of the console toggles Overlay mode. Overlay mode is designed to be superimposed on a live birds-eye camera view of the table." | p.100 |

## Appendix: 매뉴얼 주요 기능 설명 (탭 미분류)

### Secure Delay

매뉴얼 p.44-46에 걸쳐 상세 설명됨. Outputs 탭에서 설정. 딜레이 시간(분) 입력 후 Secure Delay 체크박스로 활성화.

- Live preview: 홀카드 DOWN (실시간 venue 표시용으로 안전)
- Delayed output: 홀카드 UP (방송 출력)
- padlock icon이 잠기며 녹색으로 변함
- Auto Delay: 첫 핸드 감지 시 자동 활성, 지정 시간 비활성 후 자동 종료
- Delay Countdown: 딜레이 시작 시 시청자에게 카운트다운 표시
- Dynamic Delay: 토너먼트 브레이크 자동 스킵 (긴 딜레이로 시작 → 매 브레이크마다 단축)

### Skin System

매뉴얼 p.64-79에 걸쳐 설명됨. Skin Editor는 별도 창으로 실행.

- Skin Editor: Player, Board, Action Clock, Field & Blinds 그래픽 편집
- Fonts: 커스텀 폰트 지원
- Chroma Keying: 반투명 스킨의 크로마키 처리
- UHD 4K (3840 x 2160): 4K 스킨 지원
- Size Adjustment: 스킨 크기 조정
- Ticker Editor: 하단/상단 스크롤 텍스트 편집
- Player/Board/Action Clock/Field & Blinds Editor: 각 GFX 요소 편집
- Colour Adjustment: 색상 조정
- Circular Player Photos: 원형 플레이어 사진 지원
- Support for Mixed Games: 혼합 게임 스킨 지원
- Custom Animations: 커스텀 애니메이션 지원
- Leaderboard Editor: 리더보드 편집
- Strip Editor: Strip 그래픽 편집
- Outs Editor: Outs 그래픽 편집
- History Editor: Heads Up History 그래픽 편집
- Cards / Card Backs: 카드 디자인 편집
- Flags Importer: 국가 국기 이미지 임포트
- Split Screen Divider: 화면 분할선 편집
- Language Editor: UI 텍스트 다국어 편집

### Auto Camera Switching

매뉴얼 p.36-37에 설명됨. Sources 탭에서 설정.

- Follow Board: 커뮤니티 카드 딜 시 보드 카메라로 자동 전환 (Linger 시간 후 복귀)
- Follow Players: Action Tracker 활성 시 액션 중인 플레이어 카메라로 자동 전환
- Post Bet: 각 베팅 라운드 종료 후 카메라 동작 (Player / Default / Board)
- Post Hand: 핸드 종료 후 카메라 동작 (Default / Player / Winner)
- Heads Up Split Screen: 헤즈업 시 두 플레이어를 동시에 보여주는 화면 분할 자동 전환
- Crossfade: 소스 전환 시 하드 컷(0) 또는 크로스페이드(0.1~2.0) 설정
- External Switcher 사용 시: 내장 자동 전환 기능이 비활성화됨

### MultiGFX

매뉴얼 p.101-103에 설명됨. System 탭에서 설정.

- 동일한 테이블에서 다른 그래픽으로 여러 개의 Live/Delayed 비디오 스트림 생성 가능
- Primary PokerGFX 서버에 다른 컴퓨터의 Secondary 서버를 동기화
- Sync Stream: Secure Delay 시작/종료를 Primary와 동기화
- Sync Skin: Secondary 서버 스킨을 Primary에서 자동 업데이트
- No Cards: Primary에서 Secondary로 홀카드 정보 공유 차단 (보안 강화)
- Table Icon colour codes (p.103): 각 테이블 상태를 색상 아이콘으로 표시
- High Availability (p.104): 고가용성 설정

### Twitch ChatBot

매뉴얼 p.47에 설명됨. Outputs 탭 Twitch Integration 섹션에서 설정.

"PokerGFX includes a fully functional ChatBot that is compatible with the Twitch video streaming service."

지원 명령어:
- `!event` — 이벤트 이름
- `!blinds` — 현재 블라인드 레벨
- `!players` — 참가자 수
- `!delay` — 현재 Secure Delay 시간
- `!chipcount` — 칩 카운트
- `!cashwin` — 현금 게임 수익
- `!payouts` — 페이아웃 정보
- `!vpip` — VPIP 통계
- `!pfr` — PFR 통계

---

## 변경 이력

| 날짜 | 버전 | 변경 내용 |
|------|------|---------|
| 2026-02-25 | v1.0.0 | 최초 작성 |
