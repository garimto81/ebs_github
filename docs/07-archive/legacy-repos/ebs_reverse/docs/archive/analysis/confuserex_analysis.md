# ConfuserEx Obfuscation Analysis Report

**Target**: `C:\Program Files\PokerGFX\Server\PokerGFX-Server.exe`
**Generated**: 2026-02-12 18:58:17
**Analyzer**: confuserex_analyzer.py

---

## 1. PE Header & Sections

| Property | Value |
|----------|-------|
| Machine | x64 (0x8664) |
| Entry Point | 0x0 |
| Image Base | 0x400000 |

| Section | VirtAddr | VirtSize | RawSize | Entropy | Notes |
|---------|----------|----------|---------|---------|-------|
| `.text` | 0x2000 | 372,505,936 | 372,506,112 | 7.963 | HIGH ENTROPY |
| `.rsrc` | 0x16342000 | 10,100 | 10,240 | 7.25 |  |

## 2. .NET Metadata

- **Metadata Version**: v4.0.30319
- **Entry Point**: `vpt_server.Program.Main` (token 0x60002ce)
- **Assembly**: vpt_server v3.2.985.0

### Metadata Tables

| Table | Rows |
|-------|------|
| MethodDef | 14,460 |
| Field | 6,793 |
| Param | 4,836 |
| MemberRef | 3,208 |
| TypeDef | 2,602 |
| CustomAttribute | 1,950 |
| MethodSemantics | 1,760 |
| Property | 981 |
| TypeRef | 866 |
| StandAloneSig | 770 |
| Constant | 485 |
| NestedClass | 353 |
| TypeSpec | 293 |
| MethodSpec | 291 |
| PropertyMap | 138 |
| ManifestResource | 136 |
| InterfaceImpl | 73 |
| AssemblyRef | 36 |
| MethodImpl | 31 |
| Event | 30 |
| EventMap | 20 |
| FieldRVA | 19 |
| ImplMap | 16 |
| ClassLayout | 15 |
| GenericParam | 11 |
| ModuleRef | 4 |
| FieldMarshal | 2 |
| Module | 1 |
| Assembly | 1 |

### Streams

| Stream | Size |
|--------|------|
| `#Blob` | 79,088 |
| `#GUID` | 16 |
| `#Strings` | 280,872 |
| `#US` | 141,176 |
| `#~` | 520,924 |

## 3. ConfuserEx Detection

**Detection Result**: CONFIRMED

### Encryption Constants

| Constant | Value |
|----------|-------|
| XOR Key (decimal) | `7595413275715305912` |
| XOR Key (hex) | `0x69685421cd4c01b8` |
| ldc.i4 constant A | `544109938` (0x206e7572) |
| ldc.i4 constant B | `542330692` (0x20534f44) |

### Obfuscated Namespaces (2028)

- `(global).A021nFjeGJED8914GOt`
- `(global).A4E8jeVoQB4H8BgdXbU`
- `(global).A4SM3An0LV6LbWXCsvi`
- `(global).A56fqGedxkCq8R6G6pH`
- `(global).A5efObuiHODNKq1BoHn`
- `(global).A7FGQ2sStPUguG6JKa0`
- `(global).A7SygRa6g2DUfP4V2ru`
- `(global).AAb3kyX0TOOFAYqmwy5`
- `(global).AArZDSM4emxKr9AoSlX`
- `(global).AGa6pmJZgsoh0psIsjg`
- `(global).AHoIJ5JWaE8RO9k6XUib`
- `(global).AI09RHQWhTR5hhGxR3J`
- `(global).AKQ5c1AF34cSVdsfOeS`
- `(global).AKRU3KUlQulodY86jTA`
- `(global).AOsFjGkF5ISCg72T42M`
- `(global).ARi6XZ0R7T4DaMhyT6a`
- `(global).AS6FQAtIwCkg1u0Ure9`
- `(global).ATr1sgB67BmfILZmQVH`
- `(global).AUlQ34vADEKvRocGfcU`
- `(global).AVynL2JJkIRcnbiuxx3p`

### Module Type Initializer (<Module>.cctor)

- **RVA**: 0x2048
- **Code Size**: 234 bytes
- **First Bytes**: `2005000000fe0e00003800000000fe0c00004506000000720000004d000000ba...`

### Anti-Tamper Indicators

- **proxy_delegates**: 2006 instances
  - `SwitcherEventHandler`
  - `SFU4mbT3GMret7THonf`
  - `cm45EmljCI9da67B9E`
  - `RN9hgsBnkpbxnmW0wo`
  - `RUvdKxw7aF79Zc41x9`

## 4. Control Flow Obfuscated Method Bodies

| Metric | Count |
|--------|-------|
| Total Methods | 14,460 |
| Methods with RVA | 10,132 |
| Abstract/Extern (no RVA) | 4,328 |
| **CF Obfuscated** | **2,914** (28.8%) |
| Normal | 7,218 |
| Unique Initial States | 73 |

### Control Flow Switch Distribution

| Switch Targets | Methods |
|----------------|---------|
| 10 | 55 |
| 101 | 1 |
| 1020 | 1 |
| 103 | 1 |
| 108 | 1 |
| 11 | 40 |
| 114 | 3 |
| 116 | 1 |
| 119 | 1 |
| 12 | 28 |
| 125 | 1 |
| 127 | 1 |
| 129 | 1 |
| 13 | 31 |
| 14 | 35 |
| 143 | 1 |
| 145 | 1 |
| 15 | 28 |
| 155 | 1 |
| 16 | 25 |
| 17 | 18 |
| 18 | 18 |
| 19 | 11 |
| 191 | 1 |
| 194 | 1 |
| 2 | 1,178 |
| 20 | 9 |
| 21 | 13 |
| 22 | 10 |
| 23 | 7 |
| ... 73 more | 1,391 |

### Obfuscated Methods by Type (Top 25)

| Type | Obfuscated Methods |
|------|--------------------|
| `vpt_server.main_form` | 296 |
| `vpt_server.GameTypes.GameType` | 158 |
| `vpt_server.PlayerElement` | 100 |
| `vpt_server.playback` | 96 |
| `vpt_server.Features.Common.ConfigurationPresets.Models.ConfigurationPreset` | 94 |
| `vpt_server.GraphicElement` | 85 |
| `<>c` | 79 |
| `vpt_server.slave` | 68 |
| `vpt_server.gfx` | 67 |
| `vpt_server.skin_edit` | 64 |
| `vpt_server.video` | 57 |
| `vpt_server.gfx_edit` | 56 |
| `vpt_server.log` | 51 |
| `vpt_server.Helper` | 48 |
| `vpt_server.GameTypes.Services.GamePlayersService` | 47 |
| `vpt_server.Tags` | 46 |
| `vpt_server.BoardElement` | 37 |
| `vpt_server.config` | 32 |
| `vpt_server.ChipCount` | 32 |
| `vpt_server.Features.Common.Dongle.KEYLOK.KeylokDongle` | 27 |
| `vpt_server.GameTypes.Services.GameCardsService` | 27 |
| `vpt_server.ColorAdjustment` | 26 |
| `vpt_server.vlive` | 26 |
| `vpt_server.Services.UpdatePlayerService` | 25 |
| `vpt_server.wcf.client_ping` | 24 |
| ... 255 more types | |

### Code Size Distribution (All Methods)

| Size Range | Count |
|------------|-------|
| 1-16 1 16 | 6,406 |
| 17-64 17 64 | 348 |
| medium 65 256 | 2,220 |
| large 257 1024 | 840 |
| very large 1025 plus | 318 |

### ConfuserEx Control Flow Obfuscation IL Pattern

```
IL_0000: ldc.i4    <initial_state>       // State machine initial value
IL_0005: stloc     <state_var>           // Store in local variable
IL_0009: br        <loop_header>          // Jump to switch dispatcher
IL_000e: ldloc     <state_var>           // Load current state
IL_0012: switch    [N targets]            // Dispatch to state handlers
         target_0 -> IL_xxxx              // Each state contains a block
         target_1 -> IL_xxxx              // of the original method logic
         ...                              // with state transitions
         target_N -> IL_xxxx
IL_xxxx: <original code block>           // Flattened code blocks
         ldc.i4    <next_state>           // Set next state
         stloc     <state_var>
         br        <loop_header>          // Loop back to dispatcher
```

**Byte pattern**: `20 xx xx xx xx FE 0E xx xx 38 xx xx xx xx FE 0C xx xx 45`

## 5. String Encryption Analysis

| Metric | Value |
|--------|-------|
| #US Heap Size | 141,176 bytes |
| Total Strings | 3,120 |
| Printable | 3,111 |
| Suspicious | 6 |
| Potential Encrypted | 5 |

### String Categories

#### api_endpoints (34)

- `Network services initialization completed in {0}ms`
- `Monitoring services and ticker setup completed in {0}ms`
- `Starting network services...`
- `Starting monitoring services...`
- `API_Live`

#### crypto_keys (21)

- `Sources_Chroma_Key`
- `Output_Key_And_Fill_Live`
- `Output_Key_And_Fill_Delay`
- `Capture_Encryption`
- `Background key colour`

#### file_paths (101)

- `Image Files|*.png`
- `GFXUpdater.exe`
- `vpt_server.Skins.default.skn`
- `Image Files| *.png`
- `*.png`

#### license_related (65)

- `{{ SerialNumber = {0}, ExpirationDate = {1}, License = {2} }}`
- `LicenseRenew: {0}`
- `LicenseCheckActivation:`
- `LicenseStartEvaluationMode: Evaluation mode starting`
- `LicenseStartEvaluationMode: Timer is null, creating a new one`

#### poker_terms (147)

- `PokerGFX Server `
- `PokerGFX Server is starting..

PERFORMANCE WARNING! Plug all displays into the
NVIDIA GPU ONLY and r`
- `PokerGFX is already running!`
- `PokerGFX Server is starting..

PERFORMANCE WARNING! Disable onboard Intel graphics
adapter in BIOS o`
- `Move the card to BOARD antenna 3`

#### sql_queries (34)

- `Launching application update process`
- `Select Folder`
- `Select Background Image`
- `Select Media Folder`
- `COULD NOT SELECT THIS DEVICE!`

#### urls (6)

- `To activate the new camera, click in the 'Input / Format / URL' column and enter the URL for the cam`
- `https://api.twitch.tv/kraken/channels/`
- `https://id.twitch.tv/oauth2/authorize?response_type=token&scope=user:edit+chat:edit+chat:read+channe`
- `http://videopokertable.net/twitch_oauth.aspx`
- `https://id.twitch.tv/oauth2/validate`

#### wcf_endpoints (2)

- `VPTWCFServiceUrl`
- `http://videopokertable.net/wcf.svc`

### etype ASCII Encoding (2 methods)

| Method | Decoded String |
|--------|----------------|
| `vpt_server.Services.UpdatePlayerService..ctor` | `DhPqq`XT\` |

## 6. PDB Analysis

- **Size**: 2,149,888 bytes
- **Format**: MSF 7.0 (Classic Windows PDB)
- **Source Files Found**: 50

  - `C:\CI_WS\Ws\274459\Source\Costura_Fody\src\Costura.Template\Common.cs`
  - `C:\CI_WS\Ws\274459\Source\Costura_Fody\src\Costura.Template\ILTemplateWithUnmanagedHandler.cs`
  - `C:\pgfx\source\pokergfx2.0\vpt\vpt_server\ChipCount.cs`
  - `C:\pgfx\source\pokergfx2.0\vpt\vpt_server\Features\Common\Authentication\AuthenticationService.cs`
  - `C:\pgfx\source\pokergfx2.0\vpt\vpt_server\Features\Common\Authentication\Models\RemoteLoginRequest.cs`
  - `C:\pgfx\source\pokergfx2.0\vpt\vpt_server\Features\Common\Authentication\Models\RemoteLoginResponse.cs`
  - `C:\pgfx\source\pokergfx2.0\vpt\vpt_server\Features\Common\ConfigurationPresets\ConfigurationPresetService.cs`
  - `C:\pgfx\source\pokergfx2.0\vpt\vpt_server\Features\Common\ConfigurationPresets\ConfigurationPresetSettings.cs`
  - `C:\pgfx\source\pokergfx2.0\vpt\vpt_server\Features\Common\ConfigurationPresets\Models\ConfigurationPreset.cs`
  - `C:\pgfx\source\pokergfx2.0\vpt\vpt_server\Features\Common\ConfigurationPresets\Models\Preset.cs`
  - `C:\pgfx\source\pokergfx2.0\vpt\vpt_server\Features\Common\Dongle\DongleService.cs`
  - `C:\pgfx\source\pokergfx2.0\vpt\vpt_server\Features\Common\Dongle\KEYLOk\KLClientCodes.cs`
  - `C:\pgfx\source\pokergfx2.0\vpt\vpt_server\Features\Common\Dongle\KEYLOk\KeylokDongle.cs`
  - `C:\pgfx\source\pokergfx2.0\vpt\vpt_server\Features\Common\IdentityInformationCache\IdentityInformationCacheService.cs`
  - `C:\pgfx\source\pokergfx2.0\vpt\vpt_server\Features\Common\IdentityInformationCache\Models\IdentityInformation.cs`

### Source Directories

- `C:\CI_WS\Ws\274459\Source\Costura_Fody\src\Costura.Template/` (2 files)
- `C:\pgfx\source\pokergfx2.0\vpt\vpt_server/` (20 files)
- `C:\pgfx\source\pokergfx2.0\vpt\vpt_server\Features\Common\Authentication/` (1 files)
- `C:\pgfx\source\pokergfx2.0\vpt\vpt_server\Features\Common\Authentication\Models/` (2 files)
- `C:\pgfx\source\pokergfx2.0\vpt\vpt_server\Features\Common\ConfigurationPresets/` (2 files)
- `C:\pgfx\source\pokergfx2.0\vpt\vpt_server\Features\Common\ConfigurationPresets\Models/` (2 files)
- `C:\pgfx\source\pokergfx2.0\vpt\vpt_server\Features\Common\Dongle/` (1 files)
- `C:\pgfx\source\pokergfx2.0\vpt\vpt_server\Features\Common\Dongle\KEYLOk/` (2 files)
- `C:\pgfx\source\pokergfx2.0\vpt\vpt_server\Features\Common\IdentityInformationCache/` (1 files)
- `C:\pgfx\source\pokergfx2.0\vpt\vpt_server\Features\Common\IdentityInformationCache\Models/` (1 files)

## Summary

### ConfuserEx Protection Features Detected

- Method body encryption (XOR-based)
- Name obfuscation (2028 namespaces)
- Runtime initialization via <Module>.cctor
- Proxy delegate injection
- Control flow obfuscation (2,914 methods, switch-based state machine)
- String encryption (5 potential)
- etype ASCII signature encoding

### Deobfuscation Strategy

1. **Control Flow Deobfuscation**: Reconstruct original control flow from switch state machine
   - Trace initial state through state transitions
   - Map each switch target to its original basic block
   - Eliminate state variable and dispatcher, reconnect blocks in order
2. **Name Recovery**: Cross-reference PDB source file paths with obfuscated type names
3. **Proxy Delegate Resolution**: Resolve obfuscated delegate types to their target methods
4. **Dynamic Analysis**: Attach debugger, break at <Module>.cctor, dump post-initialization state
5. **etype Decoding**: Decode ASCII-encoded strings from method signature etype parameters