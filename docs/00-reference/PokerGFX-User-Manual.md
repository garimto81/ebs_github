# PokerGFX RFID Video Poker Table — User Manual

> Version 3.2.0 | © PokerGFX LLC 2011-2025 | www.pokergfx.io

---

## Table of Contents

- **Table of Contents**
- **Introduction**
  - Evaluation Mode
  - License Tiers
  - Feature Summary
  - Common Usage Scenarios
- **Supported Hardware**
  - Performance & Recommended PC Specifications
  - USB Webcams
  - Capture Devices
  - Network cameras
  - NDI sources and outputs
- **Getting Started**
  - Software Installation
  - RFID Reader Module
  - Calibrate Table
  - Assign a Table Name & Password
  - Register Playing Cards
  - Check Deck
- **Playing a Game**
  - Tag Player (Optional)
  - During the Game
  - Game Graphics
  - Player Photos
  - Player Country Flags
  - Switching between different games
  - Additional Notes for Specific Games
  - Video Preview
  - Recording a Game
  - Supported recording modes
  - Splitting the recording into individual hands
- **Action Clock**
- **Settings**
  - System Status Icons
  - Sources
  - Auto Camera Switching
  - Camera Transitions
  - Board Sync
  - Using an External Switcher
  - Audio Input
  - External Keying
  - Remote Control of ATEM TV Video Switchers
  - Outputs
  - Vertical Video (9x16)
  - Secure Delay
  - Auto Delay
  - Delay Countdown
  - Dynamic Delay
  - Twitch Integration
  - Graphics (GFX 1, GFX 2 & GFX 3)
  - PIP Remote Display
  - System
- **Commentary Booth**
- **Stream Deck**
- **Skins**
  - Fonts
  - Chroma Keying semi-transparent skins
  - UHD 4K (3840 x 2160) skins
  - Size Adjustment
  - Ticker Editor
  - Player, Board, Action Clock, Field & Blinds Editor
  - Colour Adjustment
  - Circular Player Photos
  - Support for Mixed Games
  - Custom Animations
  - Leaderboard Editor
  - Strip Editor
  - Outs Editor
  - History Editor
  - Cards
  - Card Backs
  - Flags Importer
  - Split Screen Divider
  - Language Editor
- **Action Tracker**
  - Installing Action Tracker
  - The Interface
  - Hand Pre-Start
  - During the Hand
  - Run It Twice or Three times
  - Double & Triple Boards
  - Chops
  - The Nit Game
  - Adjusting Chip Counts & Cumulative Winnings
  - Keyboard Shortcuts
  - Payouts
  - GFX Console
  -  Player statistics are calculated over every hand played since the current game
  - Delayed Commentary Stats & GFX
  - Director Console
- **MultiGFX**
  - Limitations and requirements for MultiGFX mode
  - Table Icon colour codes
  - High Availability
- **Studio**
  - **Pro Software License Required
  - Introduction
  - Using the Studio
  - Video Player
  - Video Library
  - Playlist
  - Hand Editor
  - Event Editor
  - Rendering the Video
- **FCC WARNING**
- **IC Caution**

---


## Introduction

PokerGFX is a powerful video titling software suite that generates real time poker graphics for video overlay. Used with the RFID Reader, it will automatically detect hole and community cards with no human intervention – however it can also be used with a conventional ‘hole cam’ table by entering card information manually.

In RFID mode, a USB cable (or WIFI link for completely wireless operation) connects the table to a Windows computer which runs the PokerGFX Server software. The server communicates with the table to track the movement of RFID-enabled playing cards between players, and converts this information to a graphical display which is superimposed on video of the game.

Tracking of betting action is possible by having the dealer or another observer enter player actions, using a convenient touch screen wireless tablet interface or by using a mouse/keyboard. In this mode, all graphics required for a TV broadcast or livestream are generated in real time.

Game video and player actions can be recorded for post-production and streamed live with an optional delay.

All technology is completely invisible to players, and special RFID-enabled playing cards have exactly the same look and feel as high quality acetate style cards.

### Evaluation Mode

PokerGFX requires a USB security dongle for normal use. The dongle can be plugged into the RFID Reader or an available USB on your PC, & is automatically detected when PokerGFX is connected to an RFID table. When purchased without an RFID Reader for use with a hole cam table or in MultiGFX Secondary mode, the dongle is shipped as a separate item, and must be plugged into the PC running PokerGFX at all times.

If no dongle is detected, PokerGFX runs in evaluation mode. In this mode, no features are restricted however the software will shut down after 10 minutes.

### License Tiers

PokerGFX has three separate licenses: Basic, Pro, Enterprise Basic - This license is intended for hobbyists looking to stream a home game for friends and family. Any kind of commercial use of this license is strictly prohibited.

Pro - This license is required for licensees broadcasting or streaming from stand-alone card rooms and card clubs not located within a casino. This license unlocks all PokerGFX features with the exception of Live API Access and SDI/NDI Output.

Enterprise - For media teams who need full-feature production tools for serious broadcasting and streaming work. This license unlocks all features in the PokerGFX Software Suite. Note: This license is required for any licensee who produces broadcasts or streams relating to poker tours, online poker platforms, or poker rooms located inside a casino. Also required for any licensee who manages and/or produces poker events for third parties. **All Basic features are included with a Pro License, and all Basic & Pro features are included with an Enterprise License.

### Feature Summary


> **RFID Technology**

- Operates with an RFID enabled table or a conventional hole cam table
- Guaranteed 100% accurate read rate of all cards on the table < 0.7 secs
(Omaha), < 0.4 secs (Hold’Em)
- Connection via USB, WIFI or both (auto failover to WIFI if the USB cable is
unplugged)
- Strong encryption protects link between RFID Reader and PokerGFX
- Hole cards can be stacked in any orientation
- No additional thickness added to table
- Standard or double size hole card reading area for each player

> **Game**

- Texas Hold'Em, 6 Plus (Short Deck) Hold’Em, Omaha, Omaha Hi/Lo, Pineapple,
5 Card Omaha, 5 Card Omaha Hi/Lo, Courchevel, Courchevel Hi/Lo, 6 Card Omaha, 6 Card Omaha Hi/Lo, 5 Card Draw, 2-7 Lowball Draw, 2-7 Lowball Triple Draw, A-5 Lowball Triple Draw, Badugi, Badeucy, Badacey, Seven Card Stud, Seven Card Stud Hi/Lo, Razz (Pro version)
- Fixed Limit, No Limit, Pot Limit, Capped Games
- Cash Games & Tournaments supported
- Unlimited levels, blinds (0, 1, 2 and 3 blind games) and straddles. Standard,
button and BB antes. Button blind
- Bomb Pots
- ‘Run It Twice’
- The Nit (stand up) game
- Single, Double & Triple boards
- Player ID cards auto track player position
- No interference to normal game play

> **Video**

- GPU hardware accelerated video mixing and graphics rendering and encoding
- Up to 2160p UHD resolution
- Frame rates up to 60 fps
- Vertical video (9x16) format supported
- Mixing of up to 16 video sources supported
- Adjustable cross-fading between sources
- Most USB webcams supported
- Built in configuration for all webcam property adjustments
- Support for NDI sources
- HD/UHD capture cards supported including Blackmagic Intensity & Decklink
- Network cameras (http, rtsp etc) supported
- Automatic camera switching follows the action
- Automatic Flop Cam switching
- Static and camera cycle modes
- Automatic camera switching control of Blackmagic ATEM video switchers (Pro
version)
- Split and full screen layouts
- Automatic split screen when Heads Up
- Green, blue, yellow and magenta background support for external chroma key
- Key & fill output supported by Blackmagic devices for external keying
- Live preview, full screen and secondary displays supported
- Multiple simultaneous live and delayed program out to Blackmagic Design
Decklink devices and NDI streams (Enterprise version)
- Audio sync adjustment

> **Recording**

- H264/MP4 video format
- All hand information stored in a database for later review and post production
- Split feature chops up a saved game into individual video files for each hand

> **Graphics**

- Hole cards, community cards & pot equity displayed with no human
intervention required
- Multiple hole cards reveal modes (Immediate, After Action, End of Hand,
Showdown-Tourney, Showdown-Cash, Never)
- Bets, calls, raises & pot size displayed in Action Tracker mode
- Chip count and player statistics (VPIP%, PFR%, AGRfq%, WTSD%, Cumulative
Cash Win, Payouts) display in Action Tracker mode
- Fully customizable scrolling ticker
- Auto highlight of winning cards
- Outs shown for drawing players (True and Theoretical)
- Player position (SB, BB, UTG, HJ, CUT, BTN etc)
- Skin system in the Pro version allows fully customizable player and board
graphics, fonts & styles
- Multilingual support – customization of all on-screen text (Pro version)
- Player photos (Pro version)
- Player country flags (Pro version)
- Choice of multiple transitions: Slide, Pop, Expand, Fade (in & out)
- Transition type per graphic element (Pro version)
- Payouts for final tables (Pro version)
- Configurable transition times (in & out)
- Multiple Horizontal & Vertical player and board layouts to choose from
- Multiple player reveal modes (Immediate, On Action, After 1st Bet)
- Blinds, Ante and Hand Number graphic
- FIELD graphic shows tourney entrants and players remaining
- STRIP graphic shows players and chip counts across the top of the display
- Heads-Up hand history graphic
- Rabbit Hunt graphic
- Configurable 'safe zone' margins
- Support for Elgato Stream Deck to control Leaderboard graphics.

> **Streaming**

- VCAM streaming supports live streaming via OBS, XSplit or other streaming
application to all popular streaming services including YouTube, Twitch and Facebook.
- Live and delayed streams supported
- Delayed stream supports any delay period from 1 minute to several hours
- Dynamic Delay for auto removal of tourney breaks
- Customizable delayed stream countdown logo
- AutoStream feature automatically starts streaming when the first hand is
detected, then shuts the stream down after a configurable period of inactivity
- Media player for inserting pre-recorded video clips into the live stream
- Built-in Twitch ChatBot for automated game information updates to Twitch
viewers (Pro version only)

> **Security**

- All network communication fully encrypted
- Preview window lockout password
- Action tracker remote tablet lockout password
- Settings lockout password
- Settings analysis & recommendations on start up
- Secure Delay feature hides live hole cards when a delayed stream is running

> **Picture In Picture**

- Live screen capture from tourney clock in between hands
- Configurable time displayed
- Configurable size, border, location & opacity
- Auto show after each hand, or manual show from Action Tracker

> **Action Tracker**

- Separate application used to enter live betting information
- Enter hole cards when not used with the RFID table
- Easy to use interface optimized for wireless touch tablets
- Statistics console showing player chip counts and statistics
- Statistics console displayed in Delayed mode, synced with delayed stream (Pro
version)
- Directors console showing active players
- Remote player name & photo entry supported
- Tag hands with notes during a live game for quick identification in post
- Table status display
Commentary Booth (Pro version)
- Separate application allows remote commentary over the local network
- High quality audio and video preview of gameplay
- Commentator audio and camera overlay in-stream
- Player statistics console with full hand history with the ability for the
commentator to display statistics on stream
- Live or delayed commentary
- 100% network based, no AV cables or infrastructure required
- All communications encrypted for maximum security
Studio(Pro version)
- Review, playback and edit recorded games
- Change the start and stop time of a hand, and the times at which each
individual action occurs within a hand
- Remove unwanted hands
- Add new hands that weren’t originally recorded
- Work with multiple videos and seamlessly move hands between them
- Render graphics over pre-recorded video footage or green screen for chroma
key
- Export hand database to text file

> **MultiGFX**

- Run unlimited multiple copies of PokerGFX from a single table, for multiple
video streams each with their own individual graphics and stream delay settings (requires multiple PokerGFX licenses)

> **Action Clock**

- Stand-alone, lightweight Windows app that is a fully featured shot clock
- Integrates with PokerGFX to show the countdown timer on screen
Live API (Enterprise version)
- Real time JSON data export of hand histories for third party developers and
integration with third party applications

### Common Usage Scenarios

A wide range of configurations are supported to suit many applications, however there are 3 common scenarios for using PokerGFX:

> **GFX + INTERNAL VIDEO**


> **MIX**

Up to 8 cameras are connected directly to the Server PC. PokerGFX automatically switches cameras to follow the action around the table and mixes video internally. No camera operators or external vision mixer required.

PokerGFX adds graphics, records & streams with an optional security delay.

> **GFX + EXTERNAL VIDEO**


> **MIX**

PokerGFX Server generates real time graphics which are keyed onto a live pre-mixed video feed from an external switcher.

PokerGFX can ingest the program feed for internal keying of graphics, or output graphics only for external keying using chroma key or separate key & fill outputs.

PokerGFX can record and stream with an optional security delay.  PokerGFX can control an external Blackmagic

> **ATEM video switcher to automatically follow the**


> **action around the table (Pro license required).**


> **POST**

All cards and player actions for an entire game are recorded in a live database. The Studio feature is then used to fit the hands to the timeline of the final edit of the game video. When the timeline is finished, the graphics are automatically rendered onto the video to produce the final output in post-production.  (Pro license required)

## Supported Hardware


### Performance & Recommended PC Specifications

PokerGFX is fully GPU pipelined, which means all video capture, mixing, encoding and rendering is offloaded onto the graphics card.

Minimum PC requirements will depend greatly upon your intended use of the system. Higher video output sizes and frame rates require more processing power; recording and delayed streaming consume additional resources. Performance is heavily dependent upon the graphics card.

The minimum recommended system specifications for mixing up to 8 sources, streaming with a delay and recording at 4K at 60 fps are as follows:
- Windows 11
- Intel Core i9 13900K CPU
- 32 GB system RAM
- NVIDIA RTX3070 with 8GB RAM
- 1 Tb SSD or M.2 storage with a write-speed of 1500 mb/sec
 The PokerGFX Server, Action Tracker and Commentary Booth applications

> **require Windows 10 or later 64-bit.**

Video sources may be any combination of USB webcams, HD/UHD video capture devices and network cameras. Most Windows DirectShow-compatible devices are supported.

### USB Webcams

Most USB webcams consume too much bandwidth on the USB controller for more than 1 or 2 to work reliably, and are not recommended.

> **For multiple webcams, the Logitech C920 is the only model that has been tested**

and is officially supported. This webcam offers decent picture quality, the widest viewing angle, and MJPEG compression technology that reduces the amount of USB bandwidth required.  For maximum reliability, it is recommended to install multiple USB controller

> **cards in the server PC, and connect no more than 2 webcams to each.**


### Capture Devices

Any video capture device that is compliant with Windows DirectShow WDM may be used, however there is optimized support for Blackmagic Decklink cards, and these are recommended for best reliability and picture quality.  A Blackmagic Decklink Duo 2 card will provide 4 full HD inputs at 1080p60, and

> **is the recommended capture device for broadcast quality systems.**


### Network cameras

Remote network cameras that support RTSP or HTTP streaming protocols are supported and may be used in the same way as any other capture device.

### NDI sources and outputs

NDI (Network Device Interface) is a technology that enables video and audio to be sent and received over a network, eliminating the need for dedicated AV cabling and other infrastructure. It is high quality, frame accurate and suitable for use in a live production environment. NDI is supported by many camera and switcher vendors.

PokerGFX supports NDI natively for both input and output:
- Ensure the external NDI source is active on the local network before starting
PokerGFX Server. Available NDI sources will show up as regular camera sources on the Sources Settings tab.
- [Enterprise] Live or delayed stream output can be sent to NDI receivers on the
local network simply by selecting the ‘NDI Renderer’ option from the ‘Output Device’ dropdown box in the Outputs Settings tab.

## Getting Started


### Software Installation

 See ‘Performance & Minimum PC Specifications’ for information on which

> **versions of Windows can be used with PokerGFX.**

- Download and run the PokerGFX software from:
If you’re using PokerGFX without an RFID table it is recommended that you jump straight to the Action Tracker section near the end of this manual, and then read the Settings section.

### RFID Reader Module

The RFID Reader collects data about the position of RFID enabled playing cards on the table and sends that information to PokerGFX Server.
- Connect power to the RFID Reader via the supplied power adapter.

> **It is essential that you use only the power adapter that is supplied with the**


> **table. Using another adapter, or no adapter at all, will cause the table to**


> **function unreliably and could cause permanent damage.**

- Connect the table to the PokerGFX Server PC with a USB cable.

> **When using a USB Extender, please make sure you use one that requires a**


> **power source. A USB to Ethernet extender is available for purchase on the**


> **website, or can be purchased from 3rd party retailers.**

- Double click the PokerGFX Server icon to start the server application.
 The older version of the Reader Module (v1) was discontinued as of January,

> **2018. This older version of the hardware may no longer work with our updated**


> **software. If you are using a v1 Reader Module, please contact PokerGFX to**


> **arrange a replacement with the new v2 version.**

The V2 RFID Reader can be configured differently depending on your installation requirements:

> **USB**

The RFID Reader connects via a mini USB cable to the PokerGFX Server PC.

> **WIFI**

The RFID Reader connects via WIFI to an access point that is networked with the PokerGFX Server PC. No physical cable required to connect to the PokerGFX Server. (WiFi Readers are no longer available for purchase. All new Readers are USB only.)

> **USB + WIFI**

The RFID Reader connects via a USB cable to the PokerGFX Server PC and is also connected to a WIFI access point. If the USB cable connection is removed or damaged, the RFID Reader will automatically fail over to WIFI mode, and switch back to USB when the USB cable has been restored.(WiFi Readers are no longer available for purchase. All new Readers are USB only.)
- Configure WIFI settings (Optional) - open PokerGFX Server System Settings and
click the ‘Setup WIFI’ button. Enter the WIFI SSID and password, activate the ‘Enable’ checkbox and click the ‘Update’ button. **WiFi will only work on a 2.4

> **GHz band connection.**

 For security, WIFI settings can only be modified while the RFID Reader is

> **connected via USB.**

 Only WIFI networks that are secured with WPA2 are supported.  To protect the integrity of the game, the RFID Reader uses strong

> **encryption when communicating with PokerGFX Server in both USB and**


> **WIFI modes.**

 When operating in WIFI-only mode, remove the USB security key from the RFID Reader and plug it directly into the PokerGFX Server PC. This will prevent PokerGFX from dropping into evaluation mode. Don’t lose the key!

It contains your software license and cannot be replaced.  It is highly recommended that you always connect your USB security key (which contains your PokerGFX license) directly into a USB port on your PC.

After WIFI settings have been configured, click the ‘Reset’ button. When WIFI has been enabled in the RFID Reader:

USB cable connected The RFID Reader will use the USB connection to communicate with the Server. If the USB cable is removed, the RFID Reader will automatically switch to WIFI to ensure the game is not interrupted and no data is lost. When the USB connection is restored, the RFID Reader automatically switches back to USB mode.

> **No USB cable**

WIFI mode only. The RFID Reader will communicate with the Server wirelessly. For completely wireless operation, a USB battery pack can be used to power the RFID Reader.

Approximate run-times on USB battery pack power are as follows (assumes battery is fully charged):

> **Battery Capacity**


> **Run Time**

6,000 mAh 16 hours 15,000 mAh 40 hours

### Calibrate Table

When a table is powered up for the first time, the RFID Reader must be calibrated.

This procedure is necessary to ‘teach’ the RFID Reader about how the table is configured.  Once this procedure is complete, the configuration is stored permanently in the

> **RFID Reader. This means that you never need to carry out the procedure again,**


> **even when re-installing PokerGFX on another computer.**

- Ensure that there are no playing cards on the playing surface.
- In the Server application, click the ‘Settings’ button to reveal the settings panel.
Click the ‘System’ tab. Locate the ‘Calibrate Table’ button and click it.
- You will be asked to place any playing card on each player antenna in turn,
followed by the muck antennas, and finally the board (community card) antennas.

Depending on the hardware configuration of the table, there may be 2-10 player antennas, 1-4 board antennas, 1 or 2 muck antennas and 1-10 player UPCARDS antennas.
- Follow the instructions on screen, and move the card (any playing card) to each
antenna as requested.
- Press the ‘Skip’ button to move to the next antenna group to suit the table
configuration. For example, the software supports up to 10 players, but your table has only been built for 8 players. When the software asks you to move the card to player #9 (which you can’t do since there are only 8), press the ‘Skip’ button.

Players 9 and 10 will be skipped, and the sequence will move on to the muck antennas. Similarly, if only 1 muck antenna has been provided in the table, press the ‘Skip’ button again when prompted to move the card to muck antenna #2, and it will be ignored.
- Each antenna position can be installed as either standard (1 antenna) or double (2
antennas acting together to create a double sized reading area). Ensure the ‘Double Antenna’ checkbox is set accordingly before moving the playing card, as instructed, to the next position.
- Tables can be optionally configured with Player UPCARDS antennas. An UPCARDS
antenna is an optional second antenna for each player, used to automate the reading of player cards that are dealt face up in a STUD game (if UPCARDS antennas are not installed, face up cards must be entered manually using Action Tracker). If UPCARDS antennas are not installed, click ‘Skip’ when prompted to move the card to the PLAYER 1 UPCARDS ANTENNA to finish the calibration procedure.

### Assign a Table Name & Password

This step is optional – locate the ‘Table Name’ and ‘Table Pwd’ boxes in the System Settings tab.
- Assign a name to the table. When Action Tracker is opened in a multi-table
environment, the Table Name allows the user to select the correct table to connect to.
- If a password is specified, users will be required to enter the password when
attempting to connect to the table with Action Tracker.

### Register Playing Cards

Each card in a new deck must be initialized before it can be used. To initialize a new deck of cards:
- Ensure that there are no playing cards on the playing surface.
- Locate the ‘Register Deck’ button and click it.
- Follow the on-screen instructions by placing each card in the deck on a muck
antenna, one at a time.
- The process is complete when all 52 cards have been scanned.
 This procedure only needs to be completed once for each new deck. Once

> **complete, the configuration is stored permanently on the Server. This means**


> **that you never need to carry out the procedure again, unless re-installing**


> **PokerGFX Server on another computer.**

 An unlimited number of decks can be registered at the same time, and cards

> **from any deck can be used interchangeably in a game at any time.**

 Deck registration can also be performed using Action Tracker on a wireless

> **tablet.**


### Check Deck

A previously registered deck can be quickly checked to determine whether any cards are ‘dead’ (stopped responding due to damage or wear).

To check a deck, open Action Tracker, touch/click the CHECK button at the top of the console. A full deck of cards will be displayed. One by one, scan each card in the deck on the community card antenna. As cards are scanned they are dimmed, so by the end of the deck any cards that are still highlighted are dead and need to be replaced.

## Playing a Game


### Tag Player (Optional)

 Checking the ‘Ignore Tags’ box will cause the Server to operate in tag-less mode.

> **In this mode, player ID cards are ignored and it is possible to manually enter**


> **player names using Action Tracker.**

In order for the Server to display the correct player names on the graphic overlay, each player must identify where they are sitting at the table. This is done by issuing an identity card to each player. To make a new player identity card:
- Ensure that there are no cards on either of the Muck positions;
- Locate the input text box in the Server window underneath the ‘Tag Player’
button, and enter the new player’s name;
- Click the ‘Tag Player’ button;
- Place a blank identity card on one of the Muck positions on the playing
surface;
- A beep will sound and the text box will clear. The card has been registered
with the player’s name.  When a player joins a game, he or she must place his or her identity card on the

> **player antenna for a few seconds.**


### During the Game

A few rules must be observed to enable the Server to track the action correctly:
- Players must place their cards on the marked antenna area in front of them
(except when peeking)  Cards should be fanned out or placed side by side as much as possible for

> **best reading performance.**

- Metallic card protectors cannot be used
- Community Cards must be laid out within the rectangular Community Card
area in the center of the playing surface.
- Folded cards must be passed over one of the marked Muck antennas on the
playing surface (this is not required when operating in Action Tracker Mode).  Leave folded cards on the Muck antenna for a second before moving them to

> **the muck pile. Don’t leave folded cards on the Muck antenna as the table can**


> **only reliably detect 2 cards on the Muck antenna at a time.**

 Players’ hole cards, pot equity and community cards will all be automatically

> **displayed on the video feed.**

 To display bets and pots as well, this data must be entered manually ‘as it

> **happens’ using a separate application (see the Action Tracker section).**


> **Alternatively, betting information can be added after the game using the**


> **Studio Feature.**


### Game Graphics

Graphics are displayed according to the ‘Reveal Players’ setting:

> **Setting**


> **Auto Mode**


> **Action Tracker Mode**


> **Immediate**

Players are shown as cards are dealt.

Players are shown as cards are dealt.

> **On Action**

Players are shown as cards are dealt.

Players are shown only when it is their first turn to act.

> **After Bet**

Players are shown after the flop.

Players are shown only after their first bet or call. A player that folds pre-flop will not be shown.
- When a player folds, that player’s graphic is removed from the display.
- If at any point during a hand a player’s pot equity is 100%, the individual cards
that comprise the winning hand are highlighted. This can be toggled in the settings to happen Never, Immediately, At Showdown or Winner All-In, Showdown only

### Player Photos


> **NOTE: This option is only available with a Pro license.**

Player photos may be added to the on-screen graphics using one of two methods:
- Direct image upload. Set up a Media folder if you haven’t already:
- Create a new Media folder that will contain your player images;
- Click the ‘Media Folder’ button in the Graphics settings tab and select the
Media folder.
- Copy your PNG image files into the Media folder. Files can be named by
seat position (player1.png, player2.png, …) OR by player name (smith.png, jones.png, …) When using player names, either the players regular name or ‘Leaderboard Name’ can be used.  Only PNG image files are supported.  The special image file DEFAULT.PNG will be used for any player who

> **doesn’t have an individual image file.**

 The player name button in Action Tracker will take on a rounded

> **appearance to indicate an active photo.**

- Snap a photo with Action Tracker. If you are using Action Tracker on a tablet
or other device that has a built-in camera, simply use Action Tracker to take the photo. See the chapter on Action Tracker for more details.  In your Media Folder, create a sub-folder named ‘Action Tracker Photos’

> **to have Action Tracker photos saved permanently.**


### Player Country Flags


> **NOTE: This option is only available with a Pro license.**

Flags for player countries are displayed on the player and leaderboard graphics. To enable this feature:
- Open Action Tracker, click on the Player Name button;
- Click the COUNTRY button;
- Select the country for that player.

### Switching between different games

PokerGFX supports a wide variety of poker variants. By default, the Server always starts in Texas Hold’Em mode. There are two ways to switch between game variants: 1. Touch the ‘HOLDEM’ button in Action Tracker, or 2. Follow the ‘Tag Player’ procedure to create special Player ID cards with specific names (see table below).

To switch to a game, place one of the ID cards on the muck antenna for a second:

> **Player ID Tag**


> **Name**


> **Game Variant**


> **RED = Pro license only**


> **Type**


> **Auto**


> **Mode**

HOLDEM Texas Hold’Em FLOP YES OMAHA Omaha FLOP YES OMAHAHL Omaha Hi/Lo FLOP YES 6PHOLDEM 6-Plus (Short Deck) Hold’Em (Straight > Trips) FLOP YES 6THOLDEM 6-Plus (Short Deck) Hold’Em (Trips > Straight) FLOP YES PINEAPPL Pineapple, Crazy Pineapple FLOP YES OMAHA5 5 Card Omaha FLOP YES OMAHA5HL 5 Card Omaha Hi/Lo 8 Or Better (Big O) FLOP YES OMAHA6 6 Card Omaha FLOP YES OMAHA6HL 6 Card Omaha Hi/Lo 8 Or Better FLOP YES COUR Courchevel FLOP YES COURHL Courchevel Hi/Lo 8 Or Better FLOP YES 5DRAW 5 Card Draw DRAW NO 27DRAW 2-7 Lowball Draw DRAW NO 27TRIPLE 2-7 Lowball Triple Draw DRAW NO A5TRIPLE A-5 Lowball Triple Draw DRAW NO BADUGI Badugi DRAW NO BADEUCY Badeucy DRAW NO BADACEY Badacey DRAW NO 7STUD Seven Card Stud STUD NO 7STUDHL Seven Card Stud Hi/Lo 8 Or Better STUD NO RAZZ Razz STUD NO The second method may be more convenient in mixed games as the dealer can set the game variant in between rounds.

### Additional Notes for Specific Games

- The MUCK antenna is disabled for all DRAW type games (this is the equivalent
of enabling the ‘AT No Muck’ setting). All folding players must be manually folded using the FOLD button in Action Tracker. Discarded cards do not need to be dragged over the MUCK antenna.
- 6-Plus (Short Deck) Hold’Em uses different hand rankings, where a flush beats
a full house, and trips beats a straight, however there is a sub-variant of the game where a straight beats trips. Both sub-variants are supported and are indicated in Action Tracker as ‘6+ HOLDEM TRIPS > STR’ and ‘6+ HOLDEM STR > TRIPS’ respectively.
- In PINEAPPLE games, discarded cards must be dragged over the MUCK
antenna by the dealer (whether in Auto or Action Tracker mode).
- Unless optional player UPCARDS antennas have been installed in the table,
STUD games require all face up cards to be manually entered in Action Tracker.

Downcards ONLY should be placed on player antennas. As the starting player in a STUD game is determined by the value of exposed player cards, every player upcard must be entered in Action Tracker or placed on a player UPCARDS antenna before a hand, and every subsequent betting round, can start.
- At any time during a STUD hand, Action Tracker can be used to manually enter
every card in the players hand. This might be necessary if a player who makes it to the showdown has not placed their downcards on their antenna correctly.  Player card buttons will illuminate YELLOW in Action Tracker whenever

> **manual entry of any card is needed. In a STUD game, a player card button**


> **will illuminate ORANGE if upcards have been entered or scanned correctly,**


> **but one or more downcards have not been scanned by the player antenna.**


### Video Preview

A live video preview is shown in the main Server window. For security, the preview can be hidden by unchecking the Preview check box.  The Preview window can be password protected by clicking the Lock symbol

> **next to the Preview check box.**


### Recording a Game

- Click the REC (●) button.
- You will be prompted for an empty folder to store the game files. Select or
create an empty folder and click ‘OK’. Recording is now active.
- Click the REC button again to stop recording.
 Each game requires a separate empty folder. All files relating to a single game are stored in the same folder. If recording is interrupted, or stopped for a break,

> **the same game can be resumed simply by selecting the same folder when**


> **restarting the recording.**

 The recording format is MP4, using the H264 codec.

### Supported recording modes

The recording mode can be selected from the ‘Outputs’ settings tab:

Game data only (no video).Typically used for rendering hands in post production where game video has been recorded outside PokerGFX.

Game data with video and GFX. This is the same as the live stream.

Game data with video but no GFX. This is commonly used when the game is streamed live with graphics, but ‘clean’ video is recorded with no graphics.

Graphics are added in post production using the recorded hand data.  When the Secure Delay feature is enabled, the delayed output is recorded.  When Secure Delay is disabled, the live preview output is recorded.

### Splitting the recording into individual hands

A previously recorded game can be split into individual videos for easy searching and playback or upload to social media.
- Record the game as described in the previous section;
- During the game use Action Tracker to tag individual hands of interest (see the
chapter on Action Tracker for more information on how to do this);  Hands can also be tagged by the dealer at the table:
- Create a special player name tag called ‘TAG’ (see the above section on
tagging players for detailed information on how to do this);
- To tag a hand, move the special name tag over the muck antenna for a
second.
- When the game has finished click the REC button again to stop recording;
- Click the ‘Split Recording’ button and select the folder that the game is saved
in;
- To generate files for only tagged hands, enable the ‘Tagged hands only’
checkbox, otherwise every hand played will be generated;
- Click the ‘Start Split’ button.
The Server will generate lots of small video files in the same folder, one for each hand played. Each video file is named according to the hand number, the players in the hand and the cards they had. Clicking on an individual hand file in Windows Explorer will play a small video of the selected hand only.

## Action Clock

Action Clock is an app that can be downloaded separately and run on a low cost Windows tablet. It is a lightweight yet fully featured player shot clock designed to be controlled directly by the dealer. Extremely simple to use with large buttons and a clock display that can be oriented either towards the dealer or towards the players, it only has 4 functions – Start/Reset Clock, Pause Clock, Stop Clock and Add Time.

Action Clock can either be used continuously in turbo games where each player has a maximum amount of time to act, or on an as needed basis when someone ‘calls the clock’ on another player. It is fully configurable, with optional warning sounds.

Action Clock does not require a PokerGFX Server to operate, however when a server is detected on the same local network, the clock status is automatically shared with the Server.

> **NOTE: This feature is only available with a Pro server license.**

In this mode, PokerGFX will automatically display the number of seconds players have left to act whenever the timer reaches the number of seconds specified in the Graphics Settings -> Action Clock setting. The timer is also displayed if the Action Clock ‘Add Time’ button is used.

Action Clock can be downloaded from the videopokertable.net website.

## Settings

Click the ‘Settings’ button to expand the Server window and reveal the Settings tabs.  Hold the CTRL key while starting the Server to reset all settings to their default

> **values.**

 Click the Lock symbol next to the Settings button to password protect the

> **Settings Window.**

 Settings are the same regardless of which Windows user account the Server is

> **run from.**


### System Status Icons

The icons on the left indicate CPU and GPU usage. If they turn red, usage is too high for the Server to operate reliably. Usually this is because you have too many other programs running, or your Server settings are too high. Try reducing the output video size and frame rate, or reduce the number of cameras to lower usage.

The centre icon indicates the status of the link between the Server and the RFID Reader:

> **Green**

RFID Reader is operating normally.

> **Grey**

PokerGFX Server is establishing a secure link with the RFID Reader.

> **Blue**

RFID Reader is operating normally, however there are playing cards on the table that have not yet been registered.

> **Black**

RFID Reader is operating normally, however more than one card of the same rank and suit has been detected. This indicates a card registration error, or cards from more than one deck on the table at the same time.

Magenta RFID Reader is operating normally, however duplicate cards have been detected on the table. This usually indicates a serious configuration problem with the physical layout of antennas or cables causing a single card to appear as if present on multiple antennas at the same time.

> **Orange**

RFID Reader is connected but not responding. May indicate an overloaded CPU or USB link, which could be caused by too many webcams or no table power.

> **Red**

RFID Reader is not connected.

The icon to the right indicates whether Secure Delay is enabled. Secure Delay adds a security delay to your stream and makes it impossible for hole cards to be viewed in real time. See the section on Secure Delay for more information on this feature.

### Sources

The Sources tab contains a list of available video sources. These include USB cameras, video capture cards installed in the system and NDI sources detected on the local network.

Network cameras can’t be auto detected, so to configure one of these as a source click the ’Add network camera’ button, scroll down to the new camera at end of the Sources list and enter the stream URL for the camera by clicking in the ‘Input / Format / URL’ column.
- To assign to a video source a meaningful, custom name (eg ‘Flop Cam’), click
on the name of the device in the ‘Device’ column and enter a new name.
- To select the video format, click on the ‘Input / Format’ column.
 Blackmagic capture devices automatically detect the correct input video

> **format, so the format isn’t selectable for these devices.**

- To edit the properties of the video source, click on the ‘Settings’ keyword. A
properties window will open enabling additional camera settings to be changed.  The properties available will depend on the device.

To select how the video sources are displayed:
- To select a single video source as the display background, click both the Left
and Right columns for the desired source. (An ‘X’ will confirm your selection).  To select one source with a single click, hold down the ‘Shift’ key and click

> **either the ‘Right or ‘Left column.**

- To select a split screen view, select the left-hand window by clicking in the Left
column for one source, and the Right column for a different source.
- To display video sources in rotation, select ‘Cycle’ mode instead of ‘Static’.
Enter the number of seconds that each video source should be displayed in the ‘Cycle’ column. A value of zero will exclude that source from the rotation.  If a hand is in progress and ‘Follow Board’ (see below for information on

> **this feature) has been enabled, the Board Camera is automatically**


> **skipped from the normal cycle sequence, even if a non-zero value has**


> **been entered.**


### Auto Camera Switching

Video source switching can be performed automatically in response to game events.

To configure this ‘follow the action’ feature:
- First, associate each player position with a camera. Select ‘Seat 1’ from the
‘View’ dropdown box, and then select the camera which covers that seat from the box immediately to the right. Repeat this step for each seat, and then if you have a dedicated camera covering the community card area (a ‘flop cam’), select ‘BOARD’ and then the appropriate camera name.  If a player is covered by more than one camera, select the one that

> **provides the best view of that player.**

To activate the feature, first enable the ‘Auto Camera Control’ checkbox then enable one or more of the ‘Follow Players’, ‘Follow Board’ and ‘Heads Up Split Screen’ checkboxes:
- When ‘Follow Board’ is enabled, the video will switch to the community card
close-up for a few seconds whenever flop, turn or river cards are dealt. The number of seconds can be configured in the box next to this checkbox.  If the ‘Hide GFX’ option is enabled, all player graphics will be made

> **invisible while the board cam is active.**

 The Linger on Board setting sets the number of seconds the board cam is

> **active before returning to the next view.**

- When ‘Follow Players’ is enabled: If Action Tracker is enabled, the video will
switch to ensure that the player whose turn it is to act is always displayed. If Auto mode is enabled, the video will switch only if all active players remaining in the hand are covered by the same camera.
- The ‘Post Bet’ option determines what happens at the end of each betting
round (but not at the end of the hand):

Player The view remains on the last action player.

Default The view switches to the default camera.

Board The view switches to the BOARD camera without waiting for board cards to be detected.  This feature is only active for FLOP games. In STUD and

> **DRAW games, the camera always switches to the Default**


> **view at the end of each betting round.**

The ‘Post Hand’ option determines what happens at the end of the hand:

Default The view switches to the default camera.

Player The view remains on the last action player.

Winner The view switches to the winner of the hand. If the pot is split, the view switches to the default camera.
- When ‘Heads Up Split Screen’ is enabled: When play is heads up, and both
players are covered by separate cameras, a split screen view showing each player will automatically be displayed.  The camera configuration can be switched ‘on the fly’ during a game to

> **change the audience’s view of the action at any time.**

To disable a video source, click the ‘ON’ property in the ‘Status’ column. This is useful for disabling video devices that cannot be removed, such as a built-in webcam.

### Camera Transitions

When the ‘Crossfade’ setting is zero, camera sources transition with a hard cut.

Setting this value to a higher value between 0.1 and 2.0 causes sources to crossfade, resulting in a softer, more fluid transition. The value of the setting is time taken for a crossfade to complete, in seconds (ie. higher value is slower).

### Board Sync

Delays the detection of community cards by the specified number of milliseconds.

This can be used to compensate for the problem where community card graphics are displayed before the cards are shown being dealt on video. This phenomenon is caused in some environments with high video latency introduced by external switching and conversion equipment.

### Using an External Switcher

When using a camera source for video capture from an external vision switcher, select this capture device using the 'External Switcher Source' dropdown box. This disables the built-in multi-camera switching features (except when using ATEM control, where an external video switcher can be controlled by PokerGFX).

### Audio Input

Select the desired audio capture device and volume. The Sync setting adjusts the timing of the audio signal to match the video, if required.

### External Keying

2 types of external video keying on the output signal are supported:
- Chroma key is supported by outputting graphics on a solid colour background
(usually blue or green). To enable chroma key, enable the ‘Chroma Key’ checkbox then repeatedly click the ‘Background Key Colour’ button until the desired colour is selected.
- Key & Fill is supported on specific Blackmagic devices that support external
keying including the Decklink Duo 2, Quad 2, 8K Pro & 4K Extreme 12G. To enable this feature, go to the Output Settings tab, select the correct Decklink output device then enable the ‘Key & Fill’ checkbox.  Decklink cards that support more than one channel (Decklink Duo 2, Quad 2

> **& 8K Pro) must be configured to use 2 SDI connectors for the output to be**


> **used for key & fill. Open the Blackmagic Desktop Video application and**


> **select an output channel. Go to the CONNECTORS tab and select the option**


> **that specifies 2 connectors (eg SDI 1 & SDI 2). Save and exit, then restart**


> **PokerGFX.**



### Remote Control of ATEM TV Video Switchers


> **NOTE: This feature is only available with a Pro license.**

PokerGFX can control a Blackmagic ATEM Video Switcher to automatically switch camera inputs to follow the action. This means you retain most auto camera switching features without having to compromise on video quality or number of cameras. Because the switching is done externally with PokerGFX only controlling the switcher rather than mixing multiple camera inputs internally, a large number of cameras can be used without any performance penalty on the server PC.

To configure ATEM control:
- Configure the ATEM switcher normally and ensure it is connected to the local
network with a valid IP address (see the ATEM user manual for instructions on how to do this).
- Install the Blackmagic ATEM Switcher software on the PokerGFX Server PC.
- Start PokerGFX Server, select the Settings -> Sources tab.
- Use the ‘External Switcher Source’ setting to select the capture device the
switcher’s output is connected to so the switcher’s program output is visible in the video preview window.
- Enter the ATEM’s IP address and enable the ‘ATEM Control’ checkbox. The
checkbox will turn green to indicate ATEM control mode is active.
- A list of all camera inputs on the ATEM will be displayed. Configure the auto
camera settings as described in the previous section ‘Auto Camera Switching’:  Clicking on a camera’s name allows the name to be customized (name

> **changes are automatically propagated to the ATEM switcher).**

 Click on the ‘X’ column to make a camera the default view when no action

> **is pending.**

 Configure the Follow Players, Follow Board and Crossfade settings in the

> **right hand side panels (Heads Up split screen is not supported in this**


> **mode).**

 If the 'Board Cam Hide GFX' feature is enabled, on screen graphics will be

> **automatically hidden if the BOARD camera is selected manually by using**


> **ATEM switcher controls, and restored when any other camera is selected.**


### Outputs


> **Size /**


> **Frame**


> **Rate**

Select the desired resolution and frame rate of the video output.  The maximum achievable video settings will be determined by

> **your PC specification. Higher resolutions and frame rates require**


> **more processing power.**

 All video sources will be converted to the size and frame rate

> **specified. Note that Blackmagic Decklink cards do not support**


> **output of every possible combination of size and frame rate.**

 Output video is always progressive; interlaced video output is not

> **supported. Interlaced video sources are always converted to**


> **progressive format.**


> **Video**


> **Preview**

Sends the live and/or delayed video feed to an additional video display attached to the graphics card.

> **Audio**


> **Preview**

Sends the live and/or delayed audio feed matching the above video previews to any of the standard Windows audio output devices.

> **Output**


> **Device**

Sends the live and/or delayed video and audio feed to a Blackmagic Decklink device output (if installed), or to an NDI stream on the local network.

> **NOTE: This option is only available with an Enterprise license.**

 When an output device that supports external keying is selected,

> **the ‘Key & Fill’ checkbox is enabled. Activating this feature causes**


> **separate key & fill signals to be sent to 2 SDI connectors on the**


> **device.**


> **Virtual**


> **Camera**

Sends the video and audio feed (live OR delayed, depending on this setting) to the POKERGFX VCAM virtual camera device, for use by 3rd party streaming software such as OBS or XSplit.

### Vertical Video (9x16)

Vertical video is a mobile phone friendly format supported by YouTube and some other streaming platforms. It’s popular with content creators shooting POV (Point of View) content.

PokerGFX supports vertical video natively by enabling the ‘9x16 Vertical’ checkbox in the Outputs settings tab. With vertical video enabled you can stream POV-style content complete with graphics and secure delay.  When vertical video is enabled, all camera sources are rotated on their side. This

> **allows you to use a regular NDI camera app on your phone held vertically.**

 There are skins in the Skin Download Centre that are optimized for the vertical

> **format. These are typically labelled with ‘POV’ or ‘Vertical’.**

 It’s recommended to disable ‘Board Cam Hide GFX’ in Sources settings, and

> **select the Horizontal player layout in GFX1 settings for the best results.**

 Vertical video is supported on all outputs including the Virtual Camera, however

> **be aware not all hardware supports it (Blackmagic Decklink cards don’t).**


### Secure Delay

This feature causes a security delay to be introduced to the live video stream. For example, to delay the stream by 20 minutes, enter the value ‘20’. Start the delay by clicking the ‘Secure Delay’ checkbox.

As the live stream is stored for playback, a clock below the ‘Secure Delay’ checkbox setting shows the length of the time shifted video.

When Secure Delay is active:
- The padlock indicator will lock and turn green to indicate hole cards are
secure.
- The live preview window shows hole cards DOWN, but the delayed output
shows hole cards UP.
- The live preview is safe for real time display at the venue, showing all action
except hole cards, equities, outs and any other information that might indicate what the hole cards are.
- (Optional) In the live preview, hole cards blink until they have been scanned.
Blinking cards have either not been placed on the antenna by the player, or one or more of the cards is dead and needs replacement.
- Hole cards may be scanned at any time before the end of the hand without
affecting the GFX display. This allows you to offer players the additional security of not scanning their cards until folding or at showdown, and provides the additional benefit that hole cards are displayed from the start of the hand even though they might not be scanned until later.
- Player photos can be added any time before a hand is replayed at the end of
the delay. They will be added to previous hands retrospectively.
- Corrections made by the Action Tracker UNDO key show in the live preview,
but are automatically tidied up before the delayed output, so you don’t need to use the HIDE GFX button.

### Auto Delay

This feature will turn secure delay on as soon as the first hand is detected, then stop it after a period of inactivity. To enable, set the 'Auto' box to the number of minutes of inactivity (zero disables the feature). This is useful in environments where access to the Server is restricted – the only action required to start the secure delay is to start a game.  You should set the inactivity period to a value greater than the longest break in

> **the game, to prevent the stream being stopped before the game has ended.**


### Delay Countdown

When a secure delay is started, a countdown clock is displayed to viewers that indicates when the video will start. To display a custom still image behind the clock, click the ‘Countdown Background’ box and select a background image. The countdown clock can be disabled by unchecking the ‘Countdown’ option.  Selecting a video file from the ‘Countdown Lead-Out Video’ dropdown box will

> **cause that video to play automatically when the delay countdown reaches zero.**

Video files are stored in the Media folder (see the section on Player Photos for

> **more information on how to configure this).**


### Dynamic Delay


> **NOTE: This option is only available with a Pro server license.**

The Dynamic Delay feature automatically skips tourney breaks during a delayed stream by starting with a much longer delay which is progressively reduced every time there's a break.

To use this feature, enable the 'Dynamic Delay' checkbox in Output Settings and enter the starting delay in minutes. The starting delay is the total length of all breaks expected to occur during the stream PLUS the normal security delay you use.

When this mode is active, the 'Secure Delay' value which normally determines the fixed security delay (typically 15 - 30 minutes) becomes the MINIMUM delay. Every time there's a break between hands of greater than 10 minutes, the delay is reduced until the minimum delay value is reached.  Example: You're streaming a tourney that has a 15 minute break every 2 hour level. The stream will last 5 hours, and your 'Secure Delay' setting is 30 minutes.

> **The 'Dynamic Delay' value should be (2 breaks X 15 minutes) + 30 minutes = 60**


> **minutes. Your delay will start at 60 minutes and gradually reduce to 30 minutes**


> **by the end of the session.**

 Dynamic Delay is disabled when Chroma Key is enabled, as it would be

> **impossible to sync externally delayed video to a changing delay.**


### Twitch Integration


> **NOTE: This feature is only available with a Pro server license.**

PokerGFX includes a fully functional ChatBot that is compatible with the Twitch video streaming service. The ChatBot can respond to viewer queries about the game currently in progress. The commands that are supported are: !event Displays the event name !blinds Displays current blinds and antes !players Lists players in seating order !delay Displays the stream delay, in minutes !chipcount Lists all player chip counts, in descending order !cashwin List all player cash game net cumulative winnings (-ve or +ve) !payouts List all tournament payouts !vpip List VPIP% for all players !pfr List Pre Flop Raise% for all players To configure the ChatBot, click the 'Twitch Account' button in Outputs Settings to display the Twitch settings window. Click the 'Twitch Account' button (a web browser will open), and follow the prompts. When the web browser window closes, enter the Twitch Channel name. Click OK to close the Twitch settings window, and enable the checkbox next to the ‘ChatBot’ button. The ChatBot will activate whenever the Secure Delay is started.  All game information displayed by the ChatBot is automatically synced with the

> **delay.**

- Enabling the ‘Channel Title’ checkbox will cause your Twitch channel title to be
automatically updated to match the event name entered in Action Tracker, and the channel game to be set to ‘Poker’.

### Graphics (GFX 1, GFX 2 & GFX 3)

Use these settings to customize the graphic overlay.

> **Board**


> **Position**

Position of the Board graphic (shows community cards, pot size and optionally blind levels). Choices are LEFT, CENTRE and RIGHT. The Board is always positioned at the bottom of the display.

> **Player**


> **Layout**

Select one of 5 layout options, which determine the positioning of player graphics:

Horizontal – players are arranged horizontally along the bottom of the display, board cards centred above players. This setting is optimised for use with the split screen webcam mode.

Vert/Bot/Spill – Players are arranged vertically starting from the bottom left corner of the display. When the left side is full, players fill up from the bottom right corner.

Vert/Bot/Fit – Players are arranged vertically starting from the bottom left corner of the display. If necessary, players are reduced in size to ensure they all fit on the left hand side.

Vert/Top/Spill – Players are arranged vertically starting from the top left corner of the display. When the left side is full, players fill up from the top right corner.

Vert/Top/Fit – Players are arranged vertically starting from the top left corner of the display. If necessary, players are reduced in size to ensure they all fit on the left hand side.  In all vertical layout modes, players are always displayed in

> **clockwise table order starting from the first player to act,**


> **provided the system is running in Action Tracker mode.**


> **Heads Up**


> **layout Left /**


> **Right**

Overrides the player layout when players are heads-up. In this mode, the board graphic is positioned at the bottom centre of the display with each player positioned either side. This layout is great for Heads Up tournaments or final tables where the final 2 heads-up players are relocated so they're on opposite sides of a single camera shot.

> **Heads Up**


> **custom**


> **Y-position**

Use this to specify the vertical position of player graphics when Heads Up layout is active. Handy for productions that use a triple panel view with Heads Up players in the top half of the display and the flop underneath.

> **Leaderboard**


> **Position**

Selects the position of the Leaderboard graphic.

> **Reveal**


> **Players**

Determines when players are shown:

> **Setting**


> **Auto Mode**


> **Action Tracker Mode**


> **Immediate**

Players are shown as cards are dealt.

Players are shown as cards are dealt.

> **On Action**

Players are shown as cards are dealt.

Players are shown only when it is their first turn to act.

> **After Bet**

Players are shown after the flop.

Players are shown only after their first bet or call. A player that folds pre-flop will not be shown.

> **On Action +**


> **Next**

Players are shown as cards are dealt.

Same as ‘On Action’, with the addition that the next player to act is also shown.

> **Skin Editor**

Open the Skin Editor (see the ‘Skins’ section for more information).

Media Folder Configures the location of the Media folder, which contains player photos and other videos.

> **X Margin**

This setting controls the size of the horizontal margins. Valid values are between 0 and 1. When in any vertical layout mode, larger values cause all graphics to move towards the centre of the display.

This is useful for cropping the entire layout into a smaller zone in the centre of the video.

> **Y Margin**


> **(Top &**


> **Bottom)**

This setting controls the size of the vertical margins. Valid values are between 0 and 1. Larger values cause all graphics to move towards the centre of the display.

> **Transition In**


> **Animation**

Method and speed used to transition players on to the display.

Select from Slide, Fade, Pop and Expand.

> **Transition**


> **Out**


> **Animation**

Method and speed used to transition players off the display. Select from Slide, Fade, Pop and Expand.

> **Vanity**

Custom text displayed on the Board Card / Pot graphic.

> **Replace**


> **Vanity**

When this option is enabled, the name of the currently active game variant will be displayed instead of the Vanity text. Useful in mixed games to remind viewers which game is being played.

> **Show Blinds**

Blinds and Antes will be displayed for 10 seconds:

> **Never**

Never.

> **Every Hand**

At the start of every hand.

> **New Level**

Only when the blinds or antes change.

> **With Strip**

Blinds and antes are displayed whenever the Strip is visible.

> **Show Hand #**


> **Blinds**

Whether to display the hand number when blinds are shown.

> **Max BB**


> **multiple**

Whether to show Big Blind multiples in the chip count display. The amount is the maximum BB multiple to show + 1. For example, a value of 21 will cause the BB multiple to be displayed for players with fewer than 21 big blinds. A value of zero disables BB display.

> **Show**


> **leaderboard**


> **after each**


> **hand**

Automatically show chip counts, and other player statistics in between hands. If the PIP feature is also enabled, the PIP is shown when the leaderboard is removed from the display. Click the Configure button to select which statistics to show, for how often and for how long. Enter a value of zero seconds to keep the stats on screen until the start of the next hand.  The PIP is never shown if the leaderboard feature is configured

> **without a timeout.**

 Leaderboard only displays when in Action Tracker mode. Chip

> **counts and statistics are alternately displayed.**


> **Show player**


> **stats in the**


> **ticker after**


> **each hand**

Automatically insert updated player chip counts and other statistics in the scrolling ticker at the top or bottom of the display, after each hand. Click the Configure button to select which information to show.

> **Leaderboard**


> **Logo**

Displays a sponsor logo at the top of the Leaderboard.

> **NOTE: This feature is only available with a Pro license.**


> **Board Logo**

Displays a sponsor logo to the side of the Board.

> **NOTE: This feature is only available with a Pro license.**


> **Strip Logo**

Displays a sponsor logo at the left-hand end of the Strip.

> **NOTE: This feature is only available with a Pro license.**

 This logo is not resized in any way. It's your responsibility to

> **ensure it's the correct size as it affects the layout of many**


> **other on-screen elements.**


> **Add Seat #**

Automatically display the physical seat number in front of the player name in the player graphic.  Chip count and stats displays are not affected by this setting.

> **Reveal Cards**

Determines when hole cards are shown:

> **Immediate**

Hole cards are shown as soon as the player graphic appears.

> **After Action**

Hole cards are shown after the player’s first action (including a fold, if the ‘Fold’ setting is set to ‘Delayed’).

End of Hand Hole cards are shown when all betting for the hand has finished.

> **Showdown**


> **Cash**

Reveals cards of players if they win the hand, or are the first aggressor on the last betting round (or in the case where the last betting round is checked around, the first player to act).

> **Showdown**


> **Tourney**

Reveals cards per Showdown-Cash PLUS cards of all players still in the hand if there’s at least one all-in and there’s no more betting action to the end of the hand.

> **Never**

Hole cards are never shown.

> **How to show**


> **a Fold**

Determines when a folded player’s graphic is removed from the display:

Immediate Player is removed immediately.

> **Delayed**

Player graphic displays ‘Fold’, then disappears after a few seconds.

> **Show Outs**

When play is heads up, all cards remaining in the deck that could improve the worst player’s hand are displayed.

Never Never show Outs Heads Up Show Outs when play is Heads Up Heads Up All In Show Outs when play is Heads Up and a player is All In.  Outs that might result in a tie are included  Runner-runner outs are not included.

Outs Position Display Outs either on the left or right hand side of the screen.

> **True Outs**

When enabled, mucked cards are counted when computing pot equity and outs. Disabling this option causes mucked cards to be ignored, so theoretical pot equity and outs are displayed instead.  Pot equity is calculated as follows:

> **probability of a win + (probability of a tie / # players in the**


> **pot)**

Indent Action When this option is enabled, the ‘Action On’ player is indented towards the centre of the screen.

> **Chipcount**


> **Precision**

Exact Amount Exact number of chips is displayed.

Smart Amount (‘k’ & ‘M’ Large amounts are automatically abbreviated with ‘k’ (x 1,000) and ‘M’ (x 1,000,000).

Smart Amount, extra precision Same as Smart Amount, but with up to 3 decimal places for extra precision.

> **Currency**


> **Symbol**

When this option is enabled, all chip amounts are displayed with the local currency symbol (useful for some cash games).

> **Trailing**


> **Currency**


> **Symbol**

Displays the currency symbol to the right of the amount, instead of to the left.

> **Divide all**


> **amounts by**


> **100**

Causes all chip amounts to be divided by 100 before display. This permits the use of very small denomination chips (0.25, 0.50 etc).

In this mode, enter all chip amounts in Action Tracker in cents (eg. $0.25 would be entered as 25; $10 would be entered as $1000).

> **Show**


> **knockout**


> **rank**

Displays the rank of eliminated players on the chip count display. If Payouts have been entered, payouts for each eliminated player are also displayed.

> **Show as**


> **Eliminated**

Displays the message ELIMINATED on a player graphic if that players stack is reduced to zero.

> **Show**


> **eliminated**


> **players in**


> **Leaderboard**


> **stats**

When disabled, only players still active are displayed in the Leaderboard. When enabled, players that have left the table or been eliminated are displayed using the alternate colour.

> **Heads Up**


> **History**

When players are heads-up, a graphic element appears that shows a history of all actions made by the heads up players in the current hand.

> **Allow Rabbit**


> **Hunting**

When a hand has finished that didn’t go to a showdown, additional cards placed on the community card antenna will show as ‘rabbit hunt’ cards, ie. cards that would have come out had the hand continued.

> **Show**


> **Chipcount %**

Shows each player’s stack on the Leaderboard as a percentage of total chips on the table, unless that player’s Big Blind multiple is shown.

> **How to**


> **display**


> **amounts**

Display chip counts, pots and bets in the player element as chips, BB multiple or both.

> **Unknown**


> **cards blink in**


> **Secure Mode**

When Secure Delay is enabled, the live preview window always displays hole cards down. When this option is enabled, cards that have not been scanned are indicated by blinking.

> **Limit raises**


> **to the**


> **Effective**


> **stack size**

If a player makes a bet (including an ALL IN) that exceeds the size of the largest stack of any other player active in the hand, the bet will be limited to the size of the largest stack. This results in a more accurate representation of the total pot size prior to a call.

> **Move button**


> **after Bomb**


> **Pot**

At the end of each hand, the button and blinds are automatically moved in readiness for the next hand. If this option is disabled, when a Bomb Pot hand finishes the button and blinds are not moved.

> **Show hand**


> **equities**

Hand equities for each player can be displayed either from the start of the hand, or from the end of the first betting round.

> **Display Side**


> **Pot Amount**

When a player is all-in, and there is side action, PokerGFX can display both the main and side pot separated by a “/”

> **Straddle not**


> **on the**


> **button or**


> **UTG is**


> **sleeper**

When disabled, any straddle not considered by be a standard live straddle (that is a straddle placed by UTG, or re-straddled by UTG+1 etc) is treated as a Mississippi straddle. When enabled, these straddles are treated as Sleeper straddles.  A button straddle is always treated as a Mississippi straddle

> **regardless of this setting.**


> **Sleeper**


> **straddle gets**


> **final action**

Determines whether a sleeper straddle gets the final action.

> **Order players**


> **starting**


> **with..**

In flop and draw games, the first player to act will usually be different pre-flop vs post-flop. Players can be arranged on screen starting with either the first player to act for the current round (in which case the order will be changed at the end of the pre-flop betting round), or the first player to act post-flop regardless of the current round, in which case no re-ordering is necessary.

> **Score Strip**

The Strip is a graphical element that’s displayed across the top of the screen showing players and their chip counts. Select from ‘Off’, ‘Stack’ or ‘Winnings’.

> **Order Strip**


> **by**

Players in the Strip can be ordered either by physical seating order or chip count order.

> **Show**


> **eliminated**


> **players**

When enabled, players with a zero chip count will still be displayed in the Strip (but these players will be greyed-out).

> **Clear**


> **previous**


> **action**

When the action returns to a player after a bet or raise, the previous action is cleared and ‘x TO CALL’ or ‘OPTION’ is displayed.

> **Equity &**


> **Outs – Ignore**


> **split pots**

Select whether split pot scenarios are included when displaying Outs and hand equities.  The correct combination of the ‘Rank’, ‘Eliminated’ and ‘Currency’ options are

> **automatically set when one of CASH GAME, SIT N GO, FEATURE TABLE, FINAL**


> **TABLE game types is selected in Action Tracker.**


### PIP Remote Display

A remote computer screen can be shown as a PIP (Picture-in-Picture) on the video output. Use this feature to show viewers a clone of your tournament clock display in between hands.

To enable this feature:
- Install the small capture program on the remote computer by copying
vpt_pipcap.exe from the installation folder. Run it by double-clicking. This program captures the screen output and sends it to the Server.  The remote computer must be connected to the same Local Area Network

> **as the Server.**

- Start the PokerGFX Server and enable the checkbox next to the PIP button.
 The PIP will be displayed automatically every time a hand ends, and will be

> **hidden when a new hand starts. If the Auto Stats feature is enabled, the PIP**


> **will be shown after the Leaderboard is hidden.**

To customize the appearance of the PIP:
- Click the 'Configure' button in the Graphics settings. At the top of the PIP
Editor, an image of the video output is displayed. At the bottom is a clone of the display on the remote computer.
- Select the capture area on the remote computer (by default the full screen is
selected). A yellow rectangle shows the capture area. Click the left mouse button to set the top left corner, then the right button to set the bottom right corner. Both corners can be ‘dragged’ by moving the mouse while a button is held down.
- Select the area on the video output on the top image where you would like
the the display (PIP) to appear. The PIP area is shown with a red rectangle. Use the same mouse buttons to select the PIP area.  Only the height of the PIP can be changed. The width is automatically

> **selected to maintain the same aspect ratio as the capture area on the**


> **remote computer. This ensures the image does not look ‘stretched’.**

- Click 'OK' to save settings and close the editor. Enable the PIP checkbox in the
Graphics settings to turn the feature on.

The appearance and behaviour of the PIP can be modified in the Editor:

> **Max Time**

This setting limits the amount of time the PIP is active when there are long gaps between hands. Setting this value to zero will cause the PIP to show at all times in between hands. A value of 5 will hide the PIP after 5 seconds.

> **Border**

A border of any colour and thickness can be drawn around the PIP area by selecting a non-zero ‘size’ value.

> **Opacity**

Use the slider bar to set the opacity of the PIP. Lower values make the PIP more ‘see through’.

> **Auto Centre**

When enabled, this setting forces the PIP output area to be automatically centred in the video window at all times.

> **Refresh**

Refreshes both the local video and remote computer images.

### System


> **Check for**


> **Updates**

Force the Server to check to see if there’s a software update available.

> **Action**


> **Tracker**


> **Kiosk**

When the Server starts, Action Tracker is automatically started on the same PC on the secondary display in kiosk mode. In this mode, AT cannot be closed or minimised, and the Video and Delay Insert consoles are disabled.

When used in conjunction with a touch enabled display, this is a cost effective and secure way of making AT available without the need for a secondary PC, laptop or tablet.

All in one USB touchscreen displays are perfect for this application, such as the Mimo monitors available from: http://www.mimomonitors.com

> **Auto Start**

Automatically start the PokerGFX Server when Windows starts. Useful for unattended installations.

> **Allow**


> **Action**


> **Tracker**


> **access**

‘Track the action’ can only be started from Action Tracker if this option is enabled. When disabled, Action Tracker may still be used but only in Auto mode - player names can be edited but Action Tracking mode cannot be started.

> **MultiGFX**

Forces PokerGFX to sync to another primary PokerGFX running on a different, networked computer, making it possible to generate multiple live and delayed video streams with different graphics, from the same table. See the chapter on ‘MultiGFX’.

> **Sync**


> **Stream**

When in MultiGFX mode, forces secure delay to start and stop in synchronization with the primary server.

> **Sync Skin**

Causes the secondary MultiGFX server skin to auto update from the skin that is currently active on the primary server.

> **No Cards**

Enable this on the primary MultiGFX server as an additional layer of security. When enabled, no hole card information will be shared with any secondary server.

> **Ignore**


> **Name Tags**

When enabled, player ID tags are ignored; player names are entered manually in Action Tracker.

> **UPCARD**


> **antennas**


> **read hole**


> **cards**


> **draw &**


> **flop**


> **games**

Enables all antennas configured for reading UPCARDS in STUD games to also detect hole cards when playing any flop or draw game, expanding the size of the effective card reading area for each player to include both the regular hole card antenna as well as the UPCARD antenna. When this feature is disabled these antennas are only active during STUD games.

> **Disable**


> **Muck**

Causes the muck antenna to be disabled when in Action Tracker mode. This can make following the action more intuitive when in certain card reveal modes.

> **Secure**


> **Delay**


> **Folder**

By default the files that are generated when the Secure Delay feature is active are stored in the current user’s Windows temporary files folder. These files occupy approximately 50 GB of space for a video size of 1920 x 1080, which can cause a problem if the Windows drive is small or low on space. Click the ‘Secure Delay Folder’ button to specify a storage folder on a different drive.  Only local fixed drives can be selected. Network and removable

> **drives cannot be used.**


> **Export**


> **Folder**

When the Developer API is enabled, use this to specify the location for writing the JSON hand history files.

> **Action**


> **Tracker**


> **Predictive**


> **Bet Input**

Action Tracker will auto-complete bets and raises based on the initial digits entered, min raise amount and stack size. Takes a little getting used to but improves speed and accuracy.

Additional table settings are also available in the ‘System’ tab:

> **Table Name**

Enter an optional name for this table. This is required when using MultiGFX mode, or there are multiple tables connected to the same local area network.

> **Table Pwd**

Password for this table. Anyone attempting to use Action Tracker with this table will be required to enter this password.

> **Calibrate Table**

Perform the once-off table calibration procedure, which ‘teaches’ the table about its physical configuration.

Table Diagnostics Displays a diagnostic window that displays the physical table configuration along with how many cards are currently detected on each antenna.

> **Setup WIFI**

Configure WIFI settings on the RFID Reader.

> **Reset**

Resets the RFID Reader connection, as if PokerGFX had been closed and restarted.

## Commentary Booth


> **NOTE: This option is only available with a Pro license.**

Commentary Booth is a fully integrated commentary solution. It is a separate application that can be installed on any Windows compatible device connected to the same local network as PokerGFX Server. It has the following functionality:
- Provides high quality video and audio of the game for the commentator to
view.
- Mixes commentary audio from a mic attached to the Commentary Booth
computer into the game stream.
- Optionally mixes video from a commentary camera also attached to the
Commentary Booth computer into the game stream in either PIP (Picture in Picture) or full screen mode.
- Displays real time player statistics (chip count, cumulative winnings, VPIP etc)
to the commentator, and allows the commentator to control the display of these leaderboards to viewers in the stream.
- Operates either in Live (game time), Delayed (synced with the secure delay) or
External Delay mode.
- When you're using an external delay device, use this mode to feed player
statistics and hand histories to the Commentary Booth with a delay that can be manually changed at any time to sync with your external delay. This feature operates independently of Secure Delay mode (Secure Delay can be off or even on with a different delay period) and displays only game statistics without video or audio.  Example: Secure Delay is configured for 5 minutes, with an external delay

> **device adding an extra 60 minutes. Configure External Delay mode for 65**


> **minutes for correctly synced statistics of the broadcast stream.**

- Commentary Booth does all this over the local network, with no dedicated AV
cabling to the server required. All video, audio and data is encrypted for maximum security.

To use Commentary Booth, first configure it in PokerGFX Server:
- Select the commentary mode (live, delayed or external delay).
- Enter a password (minimum 10 digits) that will be required for the remote
application to connect.

Download the application to the desktop of the target computer or laptop. After installation, ensure PokerGFX Server is running on the same local network and start the Commentary Booth application. Enter the password in the highlighted dialog box and click the ‘Connect’ button.

## Stream Deck


> **NOTE: This option is only available with a Pro server license.**

An Elgato Stream Deck can be used to remotely control PokerGFX. To enable this feature:
- In System Settings, select the Stream Deck mode (Live or Delayed).
- On the computer where the Stream Deck is connected, download and install
the PokerGFX Stream Deck plugin from https://videopokertable.net/Download.aspx
- The Stream Deck can now be configured by dragging and dropping PokerGFX
Actions onto an empty key.

The actions available are:

Leaderboard Toggle display of the Leaderboard graphic. Drag the action to an unused button then select the type of Leaderboard to display from the selection box.

Hide GFX Toggle all on-screen graphics ON / OFF.

Camera Control Manually switch camera views. Works with both internally mixed sources (cameras connected directly to PokerGFX) and cameras connected via an ATEM switcher when ATEM control is active. Drag this action to an unused button multiple times and the source input names will be populated automatically.

When manually selecting a camera view, the FOLLOW PLAYERS, FOLLOW BOARD and CYCLE camera control features are all disabled and must be re-enabled manually using one of the below buttons.

Follow Players Toggle the FOLLOW PLAYERS feature.

Follow Board Toggle the FOLLOW BOARD feature.

Cycle / Static Camera Switch between CYCLE and STATIC cameras.

Heads-Up Layout Manually toggle Heads Up layout, where the heads up player graphics are moved to the far left and right of the display.

## Skins


> **NOTE: This option is only available with a Pro license.**

A skin is a visual theme for the graphic overlay. It is consistent across all of the individual graphic elements and gives your production an overall ‘look and feel’. Skins contain definitions for all of the graphics, the font, and positioning of each individual element, and are easily transportable as a single file across multiple computers. To use a skin all you have to do is copy the skin file to the server computer and import it.

Access the Skins Manager by clicking the ‘Skin’ button in Graphics settings. The bottom buttons perform various administrative functions:

> **Reset to**


> **Default**

Reset the current skin to default values. This will cause the current skin settings to be overwritten.

> **Export**

Export the current skin to a skin file that can be imported on another computer.

> **Import**

Import a skin file. This will cause the current skin settings to be overwritten.

> **Use**

Save the skin settings and close the Skin Manager. Use this option to test the look of your skin.

> **Discard**

Discard any changes to the current skin and close the Skin Manager. - All prebuilt skins are available in the Downloads section of the PokerGFX website. All Pro and Enterprise users have access to all skins at no additional cost.

The top buttons provide access to the functions which are used to modify the visual look of each graphic element.

### Fonts

Any TrueType font may be used. To use a font, install it on the computer that the skin is being created on, then select it in the font selection window.

Once a font is selected and saved in a skin, that font does not need to be installed on any other computer that the skin will be used on.  To install a font in Windows 10, right-click on the font file and select “Install for

> **all users” from the context menu.**

 Up to 2 fonts can be used in a skin.

### Chroma Keying semi-transparent skins

Some video mixers do not handle semi-transparent graphics well when chroma keying, and semi-transparent images often become partially invisible.

When the ‘Remove Partial Transparency When Chroma Key Enabled’ checkbox is enabled, all semi-transparent portions of images in the skin are made opaque by adjusting the alpha channel only for those areas. This effect is only applied when the Video Sources -> Chroma Key feature is enabled.  This feature does not completely disable transparency; parts of the image which

> **are 100% transparent will remain transparent, preserving the look of**


> **deliberately see-through areas (for example rounded corners).**


### UHD 4K (3840 x 2160) skins

Skins developed before support for 4k video resolution was added were designed to fit a 1920 x 1080 display, and are auto downscaled to fit lower resolutions such as 1280 x 720 as required. These older skins are upscaled when 3840 x 2160 is selected as the video resolution, but this results in an unavoidable loss of quality.

All new skins should be designed to fit a 3840 x 2160 display, which will result in the best possible quality at all resolutions. Skins that contain graphic elements sized to fit 4k should have the ‘Designed for 4K (3840 x 2160)’ checkbox enabled.

### Size Adjustment

Click and drag the ‘Adjust Size’ trackbar to quickly adjust the size of all the graphic elements in the skin without modifying the actual images.

### Ticker Editor

This feature places a horizontal scrolling message on the display. To customize the appearance of the ticker, click the ‘Ticker’ button:
- First select a background image and opacity for the ticker (lower opacity =
more see through). Set the text colour and drop shadow if desired.
- Select the speed at which the text is to scroll from right to left, and the
position of the ticker (top or bottom of the display).
- Enabling the loop option causes the current message to be displayed forever. If
this option is turned off, the ticker will disappear as soon as the message has scrolled across the display once.  Use Action Tracker to enter the message text. Start Action Tracker, open the

> **GFX Console and touch the Ticker button.**


### Player, Board, Action Clock, Field & Blinds Editor

A graphic element comprises multiple text and image elements composited on top of a background image.  Use the ‘In’ and ‘Out’ settings to override the default system-wide transitions for

> **each individual graphic.**

To select a new background image click the ‘Import’ button and select any image file.  Only PNG image files are supported.
- Select an element from the dropdown box in the ‘Element’ panel. A yellow
rectangle highlights the space it occupies.
- To move an element, click and hold the LEFT mouse button and move the
mouse.
- To resize an element, click and hold the RIGHT mouse button and move the
mouse.
- Exact dimensions can be entered in the Left, Top, Width & Height boxes for
pixel accurate sizing and positioning of elements.
- Elements can be positioned relative to any edge of the background image
using the ‘Anchor’ dropdown boxes. This can be useful in maintaining correct positioning when the background image can change size during a game; for example, the player element with a photo is wider than one without. If the photo is positioned to the left of the element, all other elements should be positioned relative to the right hand edge to maintain correct positioning regardless of which background image is displayed.
- When a text element is selected, additional attributes (font, colour, alignment,
margins & drop shadow) can be changed. To hide a text element, deselect the ‘Visible’ checkbox. Hidden text elements are highlighted with a grey rectangle (instead of yellow).
- Individual background images can be added to any text element. Images are
resized to fit the text bounding box. By default the image is displayed whenever there’s text visible in the element, however enabling ‘Triggered by Language Text’ causes the image to be made visible ONLY when specifically enabled in individual language texts. This allows you to show the background image only when a certain action is displayed, for example ‘ALL IN’.  In the Language Editor, to enable an image configured as ‘Triggered by

> **Language Text’, RIGHT-CLICK on the ‘BkImage’ column of the text. The**


> **word ‘Element’ will be displayed to show this mode is active.**

- The hilite colour of a text element may be specified in addition to the standard
colour. The circumstances under which the hilite colour is used depend on which element is selected – for some text elements, the hilite colour is not used at all. The following hilite colours are supported:

> **Element**


> **Text field**


> **Condition**

Player Name, stack, action, position, equity Action is on the player Leaderboard Chip count & Payouts with Rank option enabled Player has been eliminated Strip Name, stack, position, VPIP, PFR Player has been eliminated
- The Z (front to back) position can be specified. Elements with a higher Z value
are rendered in front of elements with a lower Z value. The background image is always located at Z position 0, so an element with a Z value of -1 or lower will display behind the background image.
- The angle button (<) can be used to rotate graphic elements counterclockwise
(negative number) or clockwise (positive number) a specified number of degrees.
- Click OK to save changes or Cancel to discard.
 Player flags are always clipped (cropped) to the bounds of the background

> **image.**


### Colour Adjustment

Clicking the ‘Adjust Colours’ button displays a dialog box that enables adjustment of the red, green and blue levels for every graphic element in the skin with a single click.

This is a handy way of quickly re-colouring a skin to match a specific colour palette without needing to modify the actual images contained in the skin.

### Circular Player Photos

If the ‘Crop player photo to circle’ checkbox is enabled, all player photos will automatically be cropped to a circle that fits wholly inside the bounds of the player photo position in the player graphic.

### Support for Mixed Games

Multiple unique player graphic element layout ‘sets’ can be defined within a single skin, with a specific player layout being automatically selected depending on the game variant being played.

This enables player elements to be optimized according to the display requirements of each game variant without needing to manually load a new skin. PokerGFX supports a large selection of game variants, each variant requiring the display of between 2 (Hold’Em) and 7 (Stud) cards.

The default PokerGFX skin defines 4 layouts (one for each of the 2, 3/4, 5, & 7 card game variants), however it’s possible to define a separate layout for every variant if desired (or even one default layout for all variants).
- Open the Skin Editor and select the game variant from the VARIANT selection
box. The player layout assigned to that game will be displayed in the PLAYER SET selection box.
- Player layout sets may be added modified or deleted with the NEW, EDIT, and
DELETE buttons.
- Select a game variant, then select the desired layout set to have that layout
automatically used whenever the game variant is selected before a hand starts.  The first DEFAULT layout cannot be deleted.  A NEW player layout set will automatically inherit the currently selected

> **layout as a starting configuration.**


### Custom Animations

Many graphic elements support custom animation from a sequence of user supplied PNG images. Custom animations can be used to achieve effects like player graphics ‘unfolding’ onto the screen, and then animating a moving bar while waiting for a player to act. Where supported, up to 3 separate animations can be configured for each element background image:

> **AnimIn**

Custom animation that replaces the default ‘Transition In’ animation (Slide, Pop, Fade, Expand). Runs when the element first appears on screen.  The automatic glint and optional bounce effects that are

> **normally applied after the ‘Trans In’ animation has completed**


> **are disabled when a custom AnimIn animation is enabled.**


> **Loop**

Custom animation that runs continuously while the element is on screen, after AnimIn or the selected ‘Transition In’ animation has completed.

> **AnimOut**

same as AnimIn, but replaces the default ‘Transition Out’ animation.

Runs when the element is removed from the screen.

Custom animations are available for most graphic elements:

> **AnimIn**


> **Loop**


> **AnimOut**


> **Blinds**

Yes Yes Yes

> **Board**

Yes Yes Yes

> **Player**

Yes Yes Yes

> **Action Clock**

Yes Yes Yes

> **Field**

Yes Yes Yes

> **Outs**

No No No

> **Heads Up History**

No No No

> **Leaderboard**

Yes Yes Yes

> **Ticker**

No Yes No To add a LOOP animation to an element:
- Click the IMPORT IMAGE button as if importing a single static background
image;
- Use CTRL or SHIFT-LEFT CLICK to select multiple images that make up the
animation sequence then click OK;
- Once imported, the trackbar to the right of the IMPORT IMAGE button can be
used to scroll through the animation sequence;
- To remove the animation and revert to a single static image, click the IMPORT
IMAGE button and select a single PNG file.

To add an AnimIn or AnimOut animation to an element:
- Click the AnimIn or AnimOut button to show the file selection window;
- Use CTRL or SHIFT-LEFT CLICK to select multiple images that make up the
animation sequence then click OK;
- Once imported, the trackbar to the right of the AnimIn and AnimOut buttons
can be used to scroll through the animation sequence;
- While scrolling the trackbar, clicking the RIGHT mouse button sets the position
at which text elements are revealed (AnimIn) or removed (AnimOut);
- The animation sequence can be removed by clicking the ‘X’ button.
 All images in animation sequences must be PNG format, and the same size as

> **the background image.**

 Animated PNG sequences are assumed to run at 60 frames per second, and are

> **played back to maintain a constant speed regardless of the actual frame rate**


> **used in PokerGFX.**

 PNG frames are imported into the animation sequence in alphabetical order.

### Leaderboard Editor

The Leaderboard editor works in the same way as the Player, Board and Blinds editors, with one notable difference. The Leaderboard element dynamically resizes itself to exactly fit the number of players to be displayed.

The leaderboard element comprises 3 separate images; a header, a repeating section and a footer. The header is composited at the top of the leaderboard, the repeating section is replicated as many times as is necessary to exactly accommodate the number of players to be displayed below that, and finally the footer is added to the bottom.
- Design 3 separate images – header, repeating section and footer. The
repeating section must be sized to fit a single line or player.  These 3 images must be the same width.
- Import these background images one at a time by selecting the type of image
and clicking the ‘Import’ button.
- For the header image position the Title, Game Title and Player Photo
elements. For the repeating image position the Left, Centre, Flag & Right columns, and finally position the footer text on the footer image.

A custom AnimIn sequence will only be enabled when AnimIn sequences are added to all 3 images (header, repeat & footer). It’s not possible to add an AnimIn sequence for only the header and not the repeat section and footer. The same rule applies to AnimOut sequences, but not the Loop animation.

### Strip Editor

The Strip is graphic element that displays all players across the top of the screen along with chip counts and position. It is resized dynamically based on the number of players to be displayed.

The Strip editor is the same as the Player, Board and Blinds editor. The composited element you produce will be replicated in a horizontal row and scaled if necessary to accommodate the number of players to be displayed.

### Outs Editor

The Outs element works in the same way as the Player, Board and Blinds elements, except the Outs element dynamically resizes itself horizontally to exactly fit the number of outs cards that are shown.

The way this is handled in the editor is as follows:
- Edit the background image and position the various elements on it in the same
way as the Player, Board and Ante elements;
- Design your background image to fit exactly 1 playing card, and position the
card element accordingly.

When the graphic is resized, a vertical slice of the entire height of the background image, bounded by the left and right edges of the playing card will be stretched along the x axis to fit the required number of cards. This means the portion of the background image behind, above and below the card element must be uniform along the x axis so the stretch does not appear to distort the image.

If there are so many outs that the resulting image is too wide to fit the display without overlapping other elements, the card images will be scaled down in size so that the overall image fits. If this happens, the smaller cards will be re-positioned on the y axis. There are two positioning options to choose from:
- If the Top setting for the card element is anchored to the top of the
background image, the cards will be centred vertically relative to their original position;
- If the Top setting for the card element is anchored to the bottom of the
background image, the cards will be aligned vertically so the bottom edge is in the same location as the original.

### History Editor

The Heads-Up Hand History graphic is another element that is dynamically resized depending on the number of lines of text to be displayed. It is configured the same way as the Leaderboard element, except it has two repeating sections instead of one, plus a master header and footer. The repeating header section applies to the name of the betting round (Pre-Flop, Flop, Turn, etc), and the repeating detail section applies to the player actions.

### Cards

A skin can contain multiple card sets. A card set consists of 52 fronts or faces, a card back and a special ‘rabbit’ overlay.  The rabbit overlay should be an image the same size as the rest of the card

> **images, with a mainly transparent or semi-transparent background and a bold**

‘X’ or similar symbol to indicate a card is not valid. It is composited on top of

> **another card under certain circumstances.**

Skins commonly contain 1 or 2 card sets (however there’s no limit to the number of sets). Where there are 2 card sets, typically one will contain black and red cards and the other will contain four colour cards.

Create a card set by placing 53 PNG images in an empty folder, named according to the below table.

To import the cards, add a new card set by clicking the ‘Add’ button. Replace the currently selected card set by clicking the ‘Replace’ button.  You can specify a different card set for individual game variants by enabling the

> **‘Override Card Set’ checkbox.**

 All the files with the exact names below must be present.

> **File Name**


> **Description**

as.png Ace of Spades 2s.png 3s.png 4s.png 5s.png 6s.png 7s.png 8s.png 9s.png 10s.png js.png qs.png ks.png ac.png Ace of Clubs 2c.png 3c.png 4c.png 5c.png 6c.png 7c.png 8c.png 9c.png 10c.png jc.png qc.png kc.png ad.png Ace of Diamonds 2d.png 3d.png 4d.png

> **File Name**


> **Description**

5d.png 6d.png 7d.png 8d.png 9d.png 10d.png jd.png qd.png kd.png ah.png Ace of Hearts 2h.png 3h.png 4h.png 5h.png 6h.png 7h.png 8h.png 9h.png 10h.png jh.png qh.png kh.png rabbit.png This card is overlaid on top of cards that are rabbit-hunted or discarded, so it should have a transparent or semi-transparent portion.

### Card Backs

Card backs are displayed briefly when a known card animates on to the display, or when a card is unknown. The default back can be replaced with a custom logo. Click the ‘Card Back’ button and select a valid PNG image file.

### Flags Importer

The Country Flags feature displays the flag of each players country in the player and leaderboard graphic elements, once a country has been selected for the player in Action Tracker.

The default skin contains up to date flags for every country. Use this feature to customize the flag images.
- In an empty folder, place PNG image files that contain the flags of the
countries that will be available for selection. The name of each file is the country name that will appear in Action Tracker (eg. Australia.png is an image of the Australian flag).
- Click the ‘Flags’ button and supply the path to the folder.
 The Flags feature can be used for any affiliation (you might use team names and

> **logos instead of country flags).**

 When a country is assigned to a player in Action Tracker, the ‘with photo’ version of the player graphic element is always enabled (as if a photo was active

> **for that player).**


### Split Screen Divider

This is the graphic that is displayed in the centre of the screen when Heads Up Split Screen mode is active. Normally this would be a thin vertical line to separate the left and right camera views, but can be any screen overlay. Custom animations are supported by selecting a range of PNG files.

### Language Editor

The Language Editor allows you to customize any text that is displayed with your onscreen graphics.
- Click in the ‘Active’ column to change the text.
- By default, the colour of the text is determined by the graphic element in
which it appears. It’s possible to override the colour of individual text items by clicking the ‘ForeCol’ and ‘BackCol’ columns. These colours are used in preference to the graphic element colour setting.  In the default skin, this feature is used to change the colour of the ‘All In’

> **action text (and others), so it’s displayed in a different colour to other**


> **actions.**

- Click a foreground or background colour to remove it.
- Click in the ‘BkImage’ column to add a background image which will be
displayed behind the text. Images are resized to fit the text bounding box and only display when the text is visible. An image added in the Language editor will override an image defined as a text background anywhere else in the skin.  RIGHT-clicking on the ‘BkImage’ column enables the display of a

> **background image that has been added to a text field in an element (for**


> **example, the ACTION field of the PLAYER element) and configured as**


> **‘Triggered by Language Text’.**

- Click ‘Save’ to make your changes permanent.
- Click ‘Cancel’ to discard your changes.
- Click ‘Reset to Default’ to override the current settings with the default ones.
 Some text items contain a ‘#’ symbol. This symbol is automatically replaced with the amount that relates to the text. For example, “All In #” would appear as “All

> **In 1,000” (or whatever the all in amount is). If you don’t wish the amount to**


> **appear, simply omit the ‘#’ symbol from the text.**

 Game variant names use the ‘#’ symbol differently. In these language fields, a ‘#’ is replaced with the betting structure (Fixed Limit, Pot Limit or No Limit). For

> **example, ‘# Hold’Em’ would be displayed as ‘NL Hold’Em’ or ‘Limit Hold’Em’ and**


> **so on, depending on the betting structure that is active.**

Custom symbols from any font can be inserted in any text by inserting a special sequence. By way of example, the '100%' check mark is represented by this sequence: \Webdings,1.4,97\
- The sequence always starts and ends with the backslash character (\).
- The 1st parameter is the name of any font installed on the Windows PC that
PokerGFX Server is running on (note this is independent of the standard skin font embedded in the skin file, so you must ensure the font is installed on the PC that will be in production (as opposed to the PC the skin is created on).

Webdings and Wingdings are good choices as they're always installed with the default Windows 10 installation).
- The 2nd parameter is the size you want the symbol to appear, as a multiple of
the standard size (ie. 1.4 = 1.4x the normal size of the symbol).
- The 3rd parameter is the numerical code for the symbol in the font.
An easy way of figuring out the font and code is to use the 'Insert Symbol' function in Microsoft Word - select 'More symbols', select the font, click on the symbol and the code will be displayed.

## Action Tracker

By default, when used with the RFID table, the PokerGFX Server operates in Auto display mode. This means that all active players are displayed from the start of a hand, and are removed as they fold. Board cards are displayed as they are dealt, along with each player’s pot equity. At the end of the hand the display is cleared ready for the next hand to begin. All of this happens completely automatically, without any need for human assistance.

In Auto mode, the server can’t display any betting or pot information as it has no way of following the action. To create the complete TV style viewing experience, it needs help in the form of the Action Tracker. Action Tracker is also required when using PokerGFX without an RFID table.

Action Tracker is a touch screen application that performs different functions depending on the needs of the person using it:

> **Game Tracker**

Uses the main console of Action Tracker to enter chip counts and betting information as the game progresses, usually on a wireless touch tablet.

If you’re using PokerGFX in stand-alone mode, without an RFID table, Action Tracker is also used to enter hole and community cards.

> **Commentator /**


> **Director**

Uses the Statistics console to monitor chip counts and player statistics in real time. The commentator can also use the Statistics console to display chip counts over the live video at any time, and operate the scrolling ticker.  Action Tracker has a User Interface that has been heavily optimized for fast and convenient input using a touch screen device. While it is possible to operate it

> **with a mouse this is NOT recommended as it is far slower.**


### Installing Action Tracker

The Action Tracker software will run on any Windows 7, 8 or 10 device. The device you use it on depends on the needs of the user. A person using it to follow the action by entering bets, calls and folds might use it on a wireless tablet for portability. A commentator is more likely to run it on a desktop PC or laptop in the commentary booth.

Action Tracker is multi-user and can run on multiple devices simultaneously for any single table. Commentary mode is accessed by opening separate windows from the main application, which can be arranged on single or multiple displays connected to one PC, or across multiple PCs if required.  All devices running Action Tracker must be connected to the same Local Area

> **Network as the computer running PokerGFX Server.**

Installing Action Tracker is extremely simple, as it is fully self contained in a single executable program file (vpt_launcher.exe) which is found in the ‘Remote’ sub-folder of the main installation folder specified during server installation. Simply copy the file to the target computer and double click to run it.

Alternatively, install the full PokerGFX software suite and click the desktop Action Tracker icon to start.  If multiple Servers are running on the local network, a list of available servers

> **will be displayed for selection.**

 Action tracker contains an auto update feature. Once installed, it will

> **automatically update itself to the latest version every time it is started.**

- If the selected table is password protected, enter the password to continue.

### The Interface

The first time Action Tracker is opened it is in Auto mode by default. In this mode it operates mainly as a status display of the system.

![Icon](user-manual-images/page084_img4.png)


![Icon](user-manual-images/page084_img3.png)


![Icon](user-manual-images/page084_img2.png)


![Icon](user-manual-images/page084_img7.png)


![Icon](user-manual-images/page084_img8.png)


![Icon](user-manual-images/page084_img6.png)


![Icon](user-manual-images/page084_img5.png)


![Icon](user-manual-images/page084_img9.png)


![PokerGFX Screenshot](user-manual-images/page084_img1.png)


![Icon](user-manual-images/page084_img11.png)


![UI element](user-manual-images/page084_img12.png)


![UI element](user-manual-images/page084_img10.png)


![UI element](user-manual-images/page084_img16.png)


![Icon](user-manual-images/page084_img14.png)


![Icon](user-manual-images/page084_img15.png)


![UI element](user-manual-images/page084_img13.png)


> **Table Health**

Indicates the quality of the link between the Server and the table.

Yellow or red means that cards are not being tracked accurately.

> **Network**


> **Health**

Indicates the quality of the link between the Server and the Tracker. Yellow or red means that updates will be delayed or lost.

> **Stream**


> **Indicator**

Green indicates that Secure Delay is active.

> **Record**


> **Indicator**

Green indicates that recording is active; Grey indicates recording is not active.

> **Game Variant**

Switch between game variants (Hold’Em, Omaha etc).

> **Director**


> **Console**

Opens a new window that shows a graphical layout of the physical table and the status of each player.

> **Statistics**


> **Console**

Opens a new window that shows player chip counts and statistics.

> **Close Tracker**

Shut down the Tracker application.

> **Window Size**

Action Tracker is designed for use on a touch tablet, and always starts in full screen mode. To facilitate use on a standard PC, touch the ‘Window Size’ icon to shrink the window to a smaller size.

> **Register Deck**

Touch this icon to start the Playing Card registration procedure, as described at the start of the manual. Useful if the Server PC is not visible from the table.

> **Community**


> **Cards**

Display of any community cards that have been dealt.

> **Track The**


> **Action**

Switch into bet tracking mode.  If the ‘Track The Action’ button isn’t visible, ensure the ‘AT

> **Updates’ setting is enabled in PokerGFX Server.**


> **Player Status**

Each player is represented by a player status icon.

The player icon turns red to indicate a player is sitting in that seat, and grey when the seat is vacant.

A card graphic will appear to indicate that a player has been dealt cards. When the player folds, the card graphic is greyed out.

When a player sits out, the player icon is dimmed.  If a player sits out or leaves the game, touch that player’s

> **icon. This is important in Action Tracker mode because any**


> **named player will be displayed on the graphic overlay even if**


> **he/she hasn’t been dealt any cards.**

 In Auto mode, players are only displayed on the graphic

> **overlay only if they are named AND have been dealt cards.**

 To add a new player, touch the grey numbered icon and enter

> **the new player’s name.**

Additional functionality is available by touching a player icon:

> **Delete**

Remove the player from the game.

> **Move Seat**

Move the player to another seat (eg for heads up play).

> **Sit Out**

Temporarily sit the player out.

> **Change Name**

Change the player’s name.

> **Leaderboard**


> **Name**

An option extended name to display in the Leaderboard for this player.

> **Photo**

Touch the camera button to snap a player photo. Player photos will be automatically displayed on screen during the game.

> **NOTE: This option is only available with a Pro license.**


> **Country**

Select the player’s country for display of a country flag in the player and leaderboard graphics.

> **NOTE: This option is only available with a Pro server license.**


### Hand Pre-Start

Touch the ‘Track The Action’ button to put the system into Action Tracker mode. The Hand Pre-Start screen is displayed:

![Icon](user-manual-images/page087_img2.png)


![UI element](user-manual-images/page087_img3.png)


![Icon](user-manual-images/page087_img4.png)


![UI element](user-manual-images/page087_img5.png)


![Icon](user-manual-images/page087_img9.png)


![Icon](user-manual-images/page087_img7.png)


![UI element](user-manual-images/page087_img8.png)


![UI element](user-manual-images/page087_img6.png)


![PokerGFX Screenshot](user-manual-images/page087_img1.png)


![Icon](user-manual-images/page087_img10.png)


![Icon](user-manual-images/page087_img11.png)


![Icon](user-manual-images/page087_img14.png)


![Icon](user-manual-images/page087_img13.png)


![Icon](user-manual-images/page087_img12.png)


![Icon](user-manual-images/page087_img15.png)


![Icon](user-manual-images/page087_img17.png)


![Icon](user-manual-images/page087_img16.png)

- Touch the SETTINGS button to enter the Event Name, Ante Type, Number of
Blinds, Game Type (Cash Game, Feature Table, Final Table, Sit N Go), Game Variant (Hold’Em, Omaha etc), and Payouts.  Both flavors of the Big Blind Ante are supported; depending on this

> **selection, either the ante or the Big Blind amount is taken first from the**


> **player’s stack.**

 A LIVE ANTE is a special type of ante that is treated as a live bet. This is

> **essentially the same as every player posting a blind of the same amount**


> **in addition to any other blinds that are payable. When this type of ante is**


> **selected, straddle bets cannot be used.**

 When the FIXED LIMIT betting structure is selected, bet and raise

> **amounts are set automatically as follows. For FLOP & DRAW games, Pre**


> **and Post-Flop – BB;  Turn & River - BB x 2. For STUD games, 3rd & 4th**


> **streets – Low Limit; 5th to 7th streets – High Limit.**

 VPIP statistics can be reset from this screen. This is handy for tracking

> **players in games where there’s a penalty or bonus for achieving a certain**


> **VPIP over a fixed period of time.**

- Ensure the Ante and Blind amounts are correct;
- Bets across all streets may be capped by entering a value in the CAP box;
- A BUTTON BLIND (common in Short Deck Hold’Em games, commonly called an
extra button ante) may be configured.
- When playing TEXAS HOLD’EM, entering a value in the 7-DEUCE box will cause
that amount to be deducted from every losing player in the hand when a hand is won by a player that has 7-2, whether by fold or showdown (the player must scoop the main pot).
- For FLOP and DRAW games, when a value is entered in the BOMB POT box, the
value of the bomb pot is deducted from each players stack at the start of the hand as if it were a Big Blind, and the first betting round is skipped. Blinds, Antes and Straddle bets are ignored and the action goes immediately to the flop or first draw.
- Select a SINGLE, DOUBLE or TRIPLE board.
- Enter the value of the lowest denomination chip on the table into the ‘Min
Chip’ box. This ensures that split pots are rounded correctly.
- Enter player names by touching the player buttons numbered 1-10.
- Ensure the starting chip count for each player is accurate. Enter chip counts by
touching the orange button below each player.  Winnings are automatically distributed to players at the end of each

> **hand according to the game being played, but must be adjusted manually**


> **to take into account external events such as rake, add-ons and rebuys.**

 A player without chips is considered to be inactive, and will be skipped as

> **if sitting out. The Big Blind position may not be moved to a player**


> **without chips.**

- Ensure that the system has detected cards for each active player (card entry
button will turn BLUE;
- If Action Tracker is being used without an RFID table, and you have a
conventional hole card camera table, enter players’ hole cards using the card buttons.  The card buttons stay visible throughout the entire hand, so cards don’t

> **have to be entered before the hand starts.**

 When an RFID table is not connected, you will also be prompted to

> **manually enter the community cards as the hand progresses.**

- If Action Tracker is being used with an RFID table, it’s still possible to manually
enter player cards during a hand, in case they have not been automatically detected by the table (for example if a player does not place their cards on the player antenna).  The system will not display the NEXT HAND button until enough player

> **cards are known for the pot to be correctly allocated.**

- Ensure all player positions are correct. Use the Position arrow buttons to move
the Dealer Button, Small Blind and Big Blind to the correct seats for the hand that is about to start.  At the end of each hand, the DLR, SML & BIG positions will be

> **automatically advanced to the next active player using the dead button**


> **method, however these positions may not be correct if a player has left**


> **the game, or a new player has entered.**

- Enter any additional blind bets by touching the green STRADDLE buttons.
 Straddles that are entered for players where the preceding player (the

> **player to the right) has posted any pre-flop bet (blind or straddle), are**


> **considered LIVE. The player is given the final option to check on the first**


> **betting round. This would include the UTG player, and UTG+1 if**


> **re-straddling is allowed.**

 If there is no pre-flop bet posted by the preceding player, the straddle is

> **treated as a SLEEPER straddle or a MISSISSIPPI straddle, depending on**


> **the setting in GFX2 settings. Sleeper straddles are taken back, or**


> **cancelled, by any previous player calling or raising the Big Blind. The**


> **straddling player may or may not get final action. This behaviour can also**


> **be configured in the GFX2 settings tab.**

 Straddling players are indicated by the ‘|S’ symbol appended to the

> **player position graphic.**

 The player seated in between the button and the small blind may ‘buy the

> **button’ by posting a blind equal to the Small Blind + Big Blind before the**


> **start of the hand. The SB portion of the bet goes into the pot and is**


> **considered dead, the BB portion is live, the players in the SB and BB**


> **positions don’t post, and action starts with the player in the SB position.**

- When all the information is correct, touch the ‘GO’ button to start the hand.
The Action screen is now displayed.  Touch the ‘Back to Auto mode’ button to exit Action Tracker mode.

> **Graphics will be displayed automatically again.**


### During the Hand

While the hand is being played, the Action screen is displayed:

When the player has acted, touch one of the green Action Buttons:
- If the player folds, touch the ‘Fold’ button;
- If the player calls, touch the ‘Call’ button;
- If the player makes a bet or raise, touch the ‘Bet/Raise To’ button and enter
the amount.  Raise amounts are always entered as the total ‘raise to’ amount, not the

> **size of the additional bet.**

- If the player goes all in, touch the ‘All In’ button.

![PokerGFX Screenshot](user-manual-images/page092_img1.png)


![Icon](user-manual-images/page092_img5.png)


![UI element](user-manual-images/page092_img2.png)


![Icon](user-manual-images/page092_img4.png)


![UI element](user-manual-images/page092_img6.png)


![Icon](user-manual-images/page092_img3.png)


![UI element](user-manual-images/page092_img7.png)

 If you touch the wrong button in error or enter an incorrect amount, touch

> **the ‘UNDO’ arrow button to undo the most recent action.**

 Touch the ‘MISS DEAL’ button to return the hand to the Pre-Start screen. All

> **stacks and positions will be restored as if no actions had occurred.**

 Touch the ‘Hide GFX’ button to temporarily hide on screen graphics while

> **using the Back Arrow button to undo errors. Touch ‘Hide GFX’ again when**


> **the action is correct to re-enable the graphics.**

- Touch the ‘Next Hand’ button to clear the graphic overlay and advance the
dealer, small and big blinds ready for the next hand.  The ‘Next Hand’ button will only be visible after all cards have been

> **gathered in, and valid hole cards are known for all remaining players in a**


> **showdown. This means that any unknown cards must be entered**


> **manually before the next hand can start.**

 If a player folds out of turn, or a player still in the hand mucks unknown

> **cards at showdown, touch the yellow player cards button as if entering**


> **known cards, and then touch the red MUCKED button, folding the player.**

- Touch the ‘Adjust Stack’ button to manually update the chip count for the
current player (eg. Before an All In, if the chip count has become inaccurate).
- To mark the current hand as a favourite, touch the ‘Tag Hand’ button. Enter a
note for the hand (eg. ‘Bryan’s Flush’), and the Tag Hand button turns yellow to indicate that the current hand is tagged.  Tagged hands are automatically pre-selected in the Studio for easy

> **identification. You can use the tagging feature to pre-select only the**


> **interesting hands from a game.**


### Run It Twice or Three times

When no more betting can occur in a hand and all players still involved agree, the remaining community cards can be dealt more than once, creating multiple separate boards from that point in the hand. The pot is split in equal proportions between the winner(s) of each board. To ‘run it twice’, touch the ‘RUNNING IT X1’ button any time before the first river card is dealt. Boards may be run X1, X2 or X3.

When each board has been dealt and there’s another board still to come, the community card graphics can be manually cleared in preparation for the next board by using the NEXT RUN OUT button. If this button isn’t used the graphics will automatically clear when the first card of the next board is dealt.

### Double & Triple Boards

When playing a hand with a double or triple board, touch the SINGLE / DOUBLE / TRIPLE BOARD button on the hand pre-start screen to enable this feature. The dealer should first deal the community cards to the normal single board position on the table, followed by the second board above these cards, and the third board (if applicable) below.  There’s no sensor under the second and third boards, so these cards must be

> **entered manually in Action Tracker by touching the ‘ENTER CARDS’ button.**

 ‘Run It Twice’ can’t be used in a hand that has a double or triple board.

### Chops

In a cash game, players might agree to ‘chop the pot’ at any time there’s no action pending. In this case, use the CHOP button. The hand will end immediately with the pot being split equally between players still in the hand.

### The Nit Game

In the Nit game (also called the Stand Up game), the last player to win a hand pays a bounty to each other player. To start a Nit game, enter a bounty amount in the NIT GAME box in the hand pre-start screen. The bounty amount and number of players left in the game are displayed. To cancel a Nit game in progress, touch the NIT GAME box again.  All players with an active stack when the Nit game is started are included in the

> **Nit game, regardless of their SIT OUT status. Players who enter the game after**


> **the Nit game starts are not included.**

 To win a hand and be marked as safe, a player must scoop the main pot. Split pots and side pots do not count. Double, triple and 'run it twice' boards are all

> **counted normally.**

 If the losing player does not have enough chips to pay the bounty it is assumed

> **the shortfall will be paid out of his own pocket to the other players' stacks.**

 When a Nit game is active, an individual player’s status may be manually

> **toggled between SAFE and AT RISK by touching the player name button.**


### Adjusting Chip Counts & Cumulative Winnings

Chip counts can be adjusted either during a hand when action is on a player (for example a player goes all in, there’s a chip count and it’s different to the stack size in PokerGFX), or between hands (chip count updates during a break, or when a new player enters the game.) To adjust a player stack size, use the appropriate button with the chip icon.

Adjusting chip counts in this way does NOT change the Cumulative Winnings player statistic. Cumulative Winnings is adjusted automatically at the end of each hand, however sometimes you will want to make an adjustment manually. The most common reason for this is a side bet or game feature that isn’t directly supported by PokerGFX.

For example, the 7-Deuce bounty is supported by PokerGFX and Cumulative Winnings are automatically updated to reflect this when there’s a winner, but the 10-Deuce bounty isn’t supported. In this case, use the TRANSFER CHIPS button. This is the chip button next to the START HAND button in the hand pre-start screen in Action Tracker.

Using this feature allows you to quickly transfer chips between players while keeping Cumulative Winnings up to date.

### Keyboard Shortcuts

When Action Tracker is running on a device that has a keyboard, the keyboard can be used to enter player names and any numerical amount such as stack size or a bet.

Additionally the following keyboard shortcuts can be used instead of buttons:

> **C**

Call or Check

> **B or R**

Bet or Raise

> **A**

All In

> **F**

Fold

> **[BACKSPACE]**

Undo previous action

> **[ENTER]**

Next Hand / Start Hand / Enter Amount

> **. OR ,**

Adds ‘000’ when entering a bet or stack amount.

### Payouts


> **NOTE: This option is only available with a Pro license.**

When running a final table tourney, player payouts (prizes) can be displayed.
- Touch the ‘Payouts’ button on the Action Tracker Hand Pre-Start screen to enter
the payout amount for each finishing position.
- Payouts can be displayed automatically at the end of each hand using the ‘Show
leaderboard’ feature (Server Graphics Settings), or manually from the Action Tracker GFX console.
- If the ‘Rank’ feature (Server Graphics Settings) is enabled, already eliminated
players will be displayed in the Payout and Chip count leaderboard graphics.

### GFX Console

Touch the GFX button at the top of the display to open the GFX Console.

Player and game statistics are displayed and updated in real time. To superimpose this information on the video at any time, touch one of the buttons. Touch the button again to remove from the display.

The display overlays available are:

> **Seat**

Displays a list of active players by seat number, with chip counts.

> **Stack**

Displays player chip counts, sorted in descending order. If the ‘Rank’ option is enabled, eliminated players are also displayed in order of elimination. If Payouts have been entered, the payout for each eliminated player is displayed.

> **VPIP%**

Displays VPIP (Voluntary Put In Pot) = pre-flop calls divided by total hands played, as a percentage.

> **PFR%**

Displays Pre Flop Raise% = number of pre-flop raises divided by total hands played, as a percentage.

> **AGRfq%**

Aggression Frequency% = number of bets & raises divided by the total number of bets, raises, calls and folds.

> **WTSD%**

Displays Went To Showdown% = number of times went to showdown divided by flops seen, as a percentage.

> **WIN**

Displays net winnings / losses for each player (cash game only).

Effectively the same as each player’s stack less their buy-ins.

> **Field**

Displays the number of entrants in a tourney, and players remaining.

Use the REMAIN and TOTAL buttons to enter the correct player numbers, then the FIELD button to display or hide the Field element.

> **Payouts**

[Pro only] Displays a list of all player payouts. If the ‘Rank’ feature is enabled in the Server Graphics Settings tab, players already eliminated are also displayed.

> **PIP**

Forces display of the Picture In Picture (PIP) feature. See the section titled ‘PIP Remote Display’ for detailed information on this feature.

> **Ticker**

Touch this button and enter a message to display the scrolling ticker.

Your message will scroll from right to left across the display.  The keyboard can be used to enter your message. Use the Ctrl-V

> **key combination to paste the contents of the Windows clipboard.**


###  Player statistics are calculated over every hand played since the current game


> **was started by touching the START NEW GAME button in the GAME SETTINGS**


> **screen.**


### Delayed Commentary Stats & GFX


> **NOTE: This option is only available with a Pro license.**

When the secure delay feature is active, touch the ‘LIVE’ button to toggle between Live and Delayed stats. This enables commentators to commentate on a delayed stream while seeing matching player statistics that are synced with the delay.

For example, if the secure delay is 30 minutes, commentators see 'live' stats from 30 minutes ago. In this mode, when a button is touched to superimpose a leaderboard over the video, the graphic appears live (with stats that are 30 minutes old), not delayed by 30 minutes.

### Director Console

Touch the camera button at the top of the display to open the Director console. The Director console shows a graphical representation of the action at the table and allows the operator to manually control the switching of video sources by temporarily overriding the auto camera switching features.
- Touch a camera button to switch the display to that source.
 The ‘Auto camera control’ setting in the Sources settings tab in PokerGFX

> **Server is disabled when a camera is manually selected and can be re-enabled**


> **using the appropriate button in the Director Console. This ensures the**


> **camera view doesn’t change in response to in-game events until auto**


> **camera control has been explicitly re-enabled by the operator.**

Touching the OVL button at the top of the console toggles Overlay mode. Overlay mode is designed to be superimposed on a live birds-eye camera vide of the table.  In Overlay mode the background is green suitable for external chroma

> **keying.**

 Players and the Board graphic can be dragged and dropped to any position

> **to match the physical layout of the table.**


## MultiGFX

The MultiGFX feature allows you to generate multiple video streams simultaneously from a single RFID table, each with its own independent graphics, delay and video settings.

This is achieved by running multiple copies of PokerGFX on separate computers which are networked together. Enabling the ‘MultiGFX’ option forces PokerGFX to use another running copy of PokerGFX as a data source instead of a physical RFID table.

To get started with a MultiGFX configuration, follow these steps:
- Connect the RFID table via USB and start PokerGFX normally (this will be the
primary PokerGFX that controls the other secondary PokerGFXs).
- Ensure that both a table name and password have been configured in the
primary PokerGFX.
- Start PokerGFX on another computer (the secondary PokerGFX) that is
networked on the same Local Area Network as the primary PokerGFX.
- Ensure the table name and password settings in the secondary PokerGFX
match the settings configured in the primary PokerGFX.
- Enable the ‘MultiGFX’ check box (on the secondary server only, not the
primary). The table USB icon will indicate a link symbol.

The table USB icon should turn green, indicating the link is now active. Any game event that occurs in the primary PokerGFX will be transmitted to the secondary PokerGFX, as if the secondary were directly connected to the RFID table itself.

You can now modify any settings in the secondary PokerGFX to customize the secondary stream as required, including when to show hole cards, graphics ‘skin’ (Pro version only), video resolution and stream delay (or none, if you want a live stream).

### Limitations and requirements for MultiGFX mode

- Action Tracker won’t connect to a secondary PokerGFX. Action Tracker always
connects to the primary PokerGFX and all player actions are propagated to the secondaries from the primary. Manual control of graphics via Action Tracker is also propagated (for example displaying a player Leaderboard graphic).
- Only game data is transmitted to the secondaries over the network. The
background video must be fed separately to each secondary. This means the video and camera input settings will usually be different on each secondary.

Here are two common scenarios:

> **Dedicated**


> **Vision**


> **Switcher**

Connect a second output of the program feed from the switcher to a capture device in the secondary. This ensures that the video background on both secondary and primary is synchronized.

> **Single Camera**


> **for the**


> **secondary**

Connect a stand-alone camera to the secondary, which will provide a static video background for the graphics.
- Each copy of PokerGFX requires a separate computer. It’s not possible to run
both primary and secondary on the same physical computer.
- All primary and secondary computers must be networked on the same Local
Area Network.
- There is no limit to the number of secondaries that can be connected to a
primary; it would be possible for example to run 100 secondaries simultaneously from a single table, each generating a unique video stream with different resolutions, graphics settings and delays.
- The primary and all secondaries must be the same version of PokerGFX.
- Each copy of PokerGFX must be separately licensed. A separate software-only
license is required for each secondary. The software-only license is provided on a USB security key, which must be plugged directly into the secondary computer.
- ATEM switching and Twitch ChatBot features are automatically disabled on
secondary servers if the primary server is configured identically for these features, for maximum configuration flexibility:  Prevents both servers trying to control the same ATEM switcher simultaneously but permits simultaneous control of different switchers.  Prevents both servers from responding to chat commands in the same Twitch channel but permits both servers to respond to commands in different channels.
- The following settings are automatically propagated to the secondary server:
- Show as eliminated when player loses stack
- Show knockout rank in Leaderboard
- Currency symbol On/Off
- Move button after Bomb Pot
- Straddle not on the button or UTG is sleeper
- Sleeper straddle gets final action
- The secondary server can be configured to automatically start and stop the
secure delay whenever the primary starts and stops.
- When Secure Delay is enabled on any one PokerGFX, live preview on every
other PokerGFX is automatically switched to hole cards DOWN.
- The secondary server can be configured to automatically synchronize its skin
from the primary server.

### Table Icon colour codes

Normally, the USB table icon indicates the status of the link between PokerGFX and the RFID table. In MultiGFX Secondary mode, this icon indicates the status of the link between the secondary and the primary:

> **Green**

The primary-secondary link is operating normally.

> **Yellow**

Secondary and primary passwords do not match, or secondary and primary are running different versions.

> **Red**

No connection to the primary. Check that the primary server is running, the table names match and both computers are networked correctly.

### High Availability

The MultiGFX feature can be used to guarantee high availability – that is, a configuration where downtime can be eliminated in the case of a catastrophic failure on the primary server.

Assuming the MultiGFX feature has been configured and is active when the primary server fails, the link status icon on the secondary PokerGFX will turn red. Follow this procedure to promote the secondary PokerGFX to primary status:
- If applicable, ensure the primary server is completely shut down.
- If the table is connected via USB cable to the primary server, unplug it and plug
it into the secondary server (skip this step if using a WIFI table connection).
- On the secondary server, go to System Settings and disable the MultiGFX
Secondary checkbox. This will reconfigure it as the primary server and force it to connect directly to the recently connected table.
- On all remaining secondary servers (if any), disable and then re-enable the
‘MultiGFX’ checkbox in System Settings. This will cause them to reconnect directly to the recently promoted primary server.
- Close and restart all copies of Action Tracker. This will cause Action Tracker to
reconnect directly to the recently promoted primary server.

The secondary server will now be running as the primary, with all game data and unaired delayed video preserved.  Playing card registration data is automatically propagated from the primary

> **server to all secondary servers, so cards only need to be registered on the**


> **primary, not secondaries.**


## Studio


### **Pro Software License Required


### Introduction

The Studio is a fully featured editing environment that allows you to fit the automatically generated graphics to the edited video of the game. This is necessary because the final version of the video is different to the raw footage; boring hands are removed, and the hands that are included are usually edited so the timing of the original game is changed and no longer matches the live data.
- As the game is played, the PokerGFX Server captures all of the live data coming
from the table and saves it into a database;
- The final video edit of the game is assembled using standard 3rd party tools;
- The final video edit is loaded into the Studio, where all the data that was
captured during the game is manipulated to ‘fit’ the edited video;
- The finished hand timeline is used to render the graphics on to the video.
During the editing process, some of the things you can do include:
- Changing the start and stop time of a hand, and the times at which each
individual action occurs within a hand;
- Fix any incorrect betting data that was entered into the Action Tracker during
the game;
- Remove unwanted hands;
- Add new hands that weren’t originally recorded;
- Work with multiple videos and seamlessly move hands between them;

### Using the Studio

Start by clicking on the ‘Studio’ button. Select the folder of the saved game you wish to work on and click ‘OK’. The Studio window is displayed:

![Icon](user-manual-images/page106_img2.png)


![Icon](user-manual-images/page106_img3.png)


![Icon](user-manual-images/page106_img4.png)


![PokerGFX Screenshot](user-manual-images/page106_img1.png)


![Icon](user-manual-images/page106_img5.png)


![Icon](user-manual-images/page106_img6.png)


![Icon](user-manual-images/page106_img7.png)


### Video Player

The middle-right section of the Studio contains the player video display and controls.

When a video is selected in the Video Library, the controls can be used to play, pause, stop and position the video. The track bar is a convenient way to quickly seek to any position in the video.

The following keyboard shortcuts may also be used to control video playback:

> **J**

Play reverse

> **JJ**

Play reverse x2 speed

> **JJJ**

Play reverse x4 speed

> **K**

Pause

> **L**

Play

> **LL**

Play x2 speed

> **LLL**

Play x4 speed The video position can also be changed by entering a value in the numerical boxes that represent hours, minutes, seconds and frame number.

### Video Library

The Video Library is used to organise your video files. These are the edited game videos to which you will fit individual hands. To add a video, click the ‘Import File’ button and select the file to import.

Each video in the library is represented as a thumbnail image, the file name, duration and number of hands currently assigned to it.
- To remove a video, select it by clicking on it and click the ‘Remove’ button.
 The first entry in the library, represented by the card icon, is a special item

> **that cannot be removed. Any hands that are not assigned to a real video are**


> **stored here.**

Select an entry that contains some hands by clicking on the thumbnail image, and a list of hands is displayed. This is the Playlist.

### Playlist

- To delete a hand, click on the hand to delete and then click the ‘Delete’
button.
- To add a new, empty hand, click on the ‘New’ button. The new hand is inserted
immediately below the currently selected hand.
- To move a hand to another video, click and hold down the left mouse button
on the hand to be moved, and drag it into the Video Library. Release the mouse button when the pointer is on top of the video to which the hand is to be moved.  Multiple hands can be moved by using the CTRL or SHIFT key to select

> **more than one hand before dragging and dropping.**

Individual hands can be hidden by turning off their checkmarks and then clicking on the ‘Hide Unselected’ button.  Hands that have been selected as favourites in Action Tracker with the ‘Tag

> **Hand’ button appear as selected by default.**

 When a hand is hidden, it is completely disabled, and will not be rendered.
- To synchronize the start time of a hand with the video, use the Player controls to
move the video to the correct position, and then click on the hand while holding down the ALT key.

It is possible to export the hand data to a text file, for use in other applications. To export:
- Select the hand(s) to export from the Playlist;
- Click the ‘Export’ button and enter the name of the file to export to.

### Hand Editor

When a hand is selected in the playlist, detailed information for the hand is displayed.

The Hand Editor shows the initial set up for the hand, and can be used to adjust the ante, blinds, player names, cards and starting chip counts.  The numerical box immediately to the right of the player’s cards should be used

> **to indicate any initial bet made before the hand starts which is NOT a blind or**


> **ante – for example a straddle or missed blind.**

 Starting chip counts are entered in the next box to the right.  The information in the Hand Editor is exactly the same as the ‘Hand Pre-Start’

> **screen which is described in detail in the Action Tracker section.**

- Click the ‘Paste Info’ button to copy the ante, blinds and player name
information from the current hand into every subsequent hand in the Playlist.

### Event Editor

To the immediate right of the Hand Editor, the Event Editor displays a list of every action that occurs during the currently selected hand.
- To add a new event, click the ‘New’ button. The new event will be inserted
immediately after the currently selected event, if any.
- To delete an event, click the ‘Del’ button.
- To change an existing event, click the ‘Edit’ button.
- The ‘Linger’ value determines how long the graphics remain on-screen after the
last event has occurred – for example after a final CALL event. The default period is 3,000 milliseconds.  To make the graphics disappear at a specific moment in the video, navigate

> **to the correct moment with the Player controls, and then click on the ‘Linger’**


> **box while holding down the ALT key.**

- To change the time an event occurs, use the Player controls to move the video to
the correct moment in the video, and then click on the event to move while holding down the ALT key.  No checking is performed on the validity of events.

### Rendering the Video

The final stage is to produce the finished video by rendering the graphics. Ensure the correct video to render is selected from the Video Library and click the ‘Render’ button.  The video will be rendered using the current settings in the main PokerGFX

> **window.**

- To render the graphics over a green screen background instead of the video, check
the ‘Chroma Key’ option.  The background colour can be selected by clicking the ‘Background Key

> **Colour’ button in the Sources Settings window.**

- To render only hands that have been checked in the Playlist, check the ‘Selected
Only’ option (un-checking this option will cause all hands, including those unchecked, to be rendered).
- If the ‘Entire Video’ box is checked, the rendered output will contain the entire
source video from start to finish. If unchecked, the rendered output video will start at the same time as the first rendered hand, and finish at the end of the last rendered hand. This option is useful if you only want to render a small portion of the video that contains only a few hands.
- Audio from the source video can be muted from the output video by enabling the
‘Mute’ option.  The rendering process can be stopped at any time by clicking the ‘Cancel’

> **button.**

 The Studio window cannot be closed while rendering is in progress.  During rendering, a preview of the final output is displayed in the main Preview

> **window.**


## FCC WARNING

This device complies with part 15 of the FCC Rules. Operation is subject to the following two conditions: (1) this device may not cause harmful interference, and (2) this device must accept any interference received, including interference that may cause undesired operation.

Any changes or modifications not expressly approved by the party responsible for compliance could void the user's authority to operate the equipment.

NOTE: This equipment has been tested and found to comply with the limits for a Class B digital device, pursuant to Part 15 of the FCC Rules. These limits are designed to provide reasonable protection against harmful interference in a residential installation. This equipment generates, uses and can radiate radio frequency energy and, if not installed and used in accordance with the instructions, may cause harmful interference to radio communications.

However, there is no guarantee that interference will not occur in a particular installation. If this equipment does cause harmful interference to radio or television reception, which can be determined by turning the equipment off and on, the user is encouraged to try to correct the interference by one or more of the following measures: -- Reorient or relocate the receiving antenna. -- Increase the separation between the equipment and receiver. -- Connect the equipment into an outlet on a circuit different from that to which the receiver is connected. -- Consult the dealer or an experienced radio/TV technician for help.

To maintain compliance with FCC’s RF Exposure guidelines, This equipment should be installed and operated with minimum 20cm distance between the radiator and your body: Use only the supplied antenna.

## IC Caution

English:

This device complies with Industry Canada licence-exempt RSS standard(s).

Operation is subject to the following two conditions: (1) This device may not cause interference, and (2) This device must accept any interference, including interference that may cause undesired operation of the device.

To maintain compliance with RSS-102 RF Exposure guidelines, This equipment should be installed and operated with minimum 20cm distance between the radiator and your body: Use only the supplied antenna.

French:

Le présentappareilestconf orme aux CNR d' Industrie Canada applicables aux appareils radio exempts de licence. L'exploitationestautorisée aux deux conditions suivantes: (1) l'appareil ne doit pas produire de brouillage, et (2) l' utilisateur de l'appareildoit accepter tout brouillageradioélectriquesubi, mêmesi le brouillageest susceptible d'encompromettre le fonctionnement.

Pour être conforme aux lignes directrices d’exposition RF RSS-102, cet équipement doit être installé et exploité à une distance minimale de 20cm entre le radiateur et votre corps: n’utilisez que l’antenne fournie.