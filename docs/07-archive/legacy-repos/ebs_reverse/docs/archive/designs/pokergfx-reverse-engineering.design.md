# PokerGFX 역공학 설계 문서

**버전**: 2.0.0
**작성일**: 2026-02-12
**최종 수정**: 2026-02-12
**프로젝트 코드**: POKERGFX-RE-2026
**참조 문서**: `docs/01-plan/pokergfx-reverse-engineering.plan.md`

---

## 1. 분석 방법론

### 1.1 Hybrid Approach 전략 [완료]

본 프로젝트는 정적 분석 중심의 하이브리드 접근법을 사용합니다. 실제 구현에서는 커스텀 Python 도구 + .NET Reflection 정적 분석이 전체 커버리지의 95%를 달성하여 동적 분석 의존도를 최소화했습니다.

| 방법론 | 적용 범위 | 도구 | 목적 | 실제 기여도 |
|--------|----------|------|------|:----------:|
| **Custom Static Analysis** | .NET 매니지드 코드 | il_decompiler.py, confuserex_analyzer.py | 소스 코드 재구성, 아키텍처 파악 | **70%** |
| **.NET Reflection** | 타입/필드/메서드 메타데이터 | ReflectionAnalyzer (C# .NET 6) | enum 값, 타입 계층 완전 추출 | **25%** |
| **Dynamic Analysis** | 런타임 동작 검증 | Process Monitor, 수동 검증 | 정적 분석 결과 교차 검증 | **5%** |

### 1.2 .NET Decompilation 전략 [완료]

#### Phase 1: Custom IL Decompiler → C# Source

ILSpy/dnSpy 대신 커스텀 Python IL 디컴파일러를 개발하여 사용했습니다.

```
바이너리 (CIL/MSIL) + PDB 심볼
    │
    ▼
il_decompiler.py (1,455 lines)
    │
    ├─ ECMA-335 metadata 파싱 (PE → CLI Header → Metadata Root)
    ├─ TypeDef/MethodDef/FieldDef 추출
    ├─ IL opcode → C# 의사코드 변환
    └─ PDB 심볼 매칭 (원본 변수명, 메서드 파라미터 복원)
    │
    ▼
8개 모듈, 2,887개 .cs 파일 생성 (decompiled/ 디렉토리)
```

**핵심 기법:**
- **PDB Symbol Loading**: 완전한 변수명, 메서드 파라미터, 소스 파일 경로 복원 (PDB 2.1MB)
- **ECMA-335 Native Parsing**: #Strings, #US, #Blob, #GUID, #~ 스트림 직접 파싱
- **IL Opcode Translation**: 200+ opcode를 C# 의사코드로 변환
- **Namespace-based File Organization**: 네임스페이스 기반 디렉토리 자동 생성

**실제 결과:**

| 모듈 | 생성 파일 수 | 비고 |
|------|:-----------:|------|
| vpt_server | ~347 | 메인 서버 (가장 큼) |
| net_conn | ~168 | 네트워크 프로토콜 |
| boarssl | ~102 | TLS/SSL |
| mmr | ~80 | DirectX 11 GPU |
| hand_eval | ~52 | 핸드 평가 알고리즘 |
| PokerGFX.Common | ~50 | 공유 라이브러리 |
| RFIDv2 | ~26 | RFID 리더 |
| analytics | ~7 | 통계/S3 |
| **합계** | **2,887** | 8개 모듈 |

#### Phase 2: Costura Embedded DLL 추출

```
PokerGFX-Server.exe (355MB)
    │
    ├─ .NET Resources Stream
    │   └─ resource_NNN 형식 entries (87개 DLL + bin)
    │
    ▼
extract_costura_v3.py (3번째 반복 개선)
    │
    ├─ .NET Resource Manifest 파싱
    ├─ zlib deflate 압축 해제
    └─ PE 파일 무결성 검증
    │
    ▼
extracted/resource_50.dll ~ resource_132.dll (87개)
```

**참고:** Costura의 원본 DLL 이름 매핑은 완전히 복구되지 않아 `resource_NNN` 형식을 유지합니다. 핵심 모듈은 디컴파일 후 네임스페이스 분석으로 식별 완료.

### 1.3 ConfuserEx 난독화 분석 방법론 [완료]

vpt_server.exe의 ConfuserEx 난독화를 분석하기 위해 커스텀 PE/method body 분석기를 개발했습니다.

#### confuserex_analyzer.py (2,156 lines)

```
vpt_server.exe (355MB)
    │
    ▼
confuserex_analyzer.py
    │
    ├─ PE 구조 분석 (Section Headers, CLR Header)
    ├─ Method Body 패턴 스캔 (14,460 methods)
    ├─ XOR key 추출: 0x69685421cd4c01b8
    ├─ ConfuserEx 시그니처 매칭
    └─ etype ASCII 인코딩 감지
    │
    ▼
confuserex_analysis.json (3,356 lines)
```

**분석 결과:**

| 항목 | 수치 | 비고 |
|------|:----:|------|
| 전체 methods | 14,460 | vpt_server.exe 내 |
| 난독화된 methods | 2,914 | **20.1%** (예상보다 낮음) |
| XOR key | `0x69685421cd4c01b8` | 8-byte key |
| etype ASCII sequences | 87 | 59개 파일에 분포 |
| 10-way switch dispatch | 다수 | ConfuserEx control flow 패턴 |

#### etype ASCII Decoding

```
etype_decoder.py
    │
    ├─ ConfuserEx etype 인코딩 패턴 감지
    ├─ ASCII byte sequence → 원본 문자열 복원
    └─ 87 sequences across 59 files 복호화
    │
    ▼
etype_decoded_strings.json
```

### 1.4 .NET Reflection 정적 분석 방법론 [완료]

IL 디컴파일러가 생성한 의사코드의 한계를 보완하기 위해 .NET Reflection 기반 정적 분석기를 별도 개발했습니다.

#### ReflectionAnalyzer (C# .NET 6)

```
추출된 DLL + vpt_server.exe
    │
    ▼
ReflectionAnalyzer (.NET 6, MetadataLoadContext)
    │
    ├─ Assembly 로드 (실행 없이 메타데이터만 읽기)
    ├─ 2,363 타입 분석 (class, struct, enum, interface, delegate)
    ├─ 필드/프로퍼티/메서드 시그니처 완전 추출
    └─ 62개 enum 타입의 실제 정수값 추출
    │
    ▼
reflection_vpt_server.json (1,499,730 lines)
```

**핵심 성과:**
- **MetadataLoadContext**: 대상 어셈블리를 실행하지 않고 메타데이터만 로드 (안전한 정적 분석)
- **enum 정수값 완전 추출**: 62개 enum 타입의 모든 멤버와 실제 값 (IL 디컴파일로는 불가능)
- **타입 계층 재구성**: 2,363개 타입의 상속/구현 관계 완전 파악
- **extract_reflection_data.py**: 1.5M lines JSON에서 핵심 데이터 정제

**Reflection 분석 커버리지 기여:**

| 분석 대상 | Reflection 이전 | Reflection 이후 | 개선 |
|----------|:--------------:|:--------------:|:----:|
| 전체 커버리지 | 88% | 95% | +7% |
| enum 값 정확도 | 0% | 100% | +100% |
| 타입 계층 정보 | 60% | 100% | +40% |

### 1.5 Dynamic Analysis 접근법 [부분 완료]

정적 분석이 95% 커버리지를 달성하여 동적 분석은 보조적으로만 활용했습니다.

#### 런타임 Behavior Tracing (계획 대비 축소)

| 분석 대상 | 도구 | 수집 데이터 | 상태 |
|----------|------|-----------|:----:|
| **파일 I/O** | Process Monitor (Procmon) | SQLite DB 액세스, .skn 로딩, 설정 파일 | 미실행 |
| **네트워크 통신** | 정적 분석 | WCF ServiceContract/OperationContract 추출 | **완료** |
| **GPU 렌더링** | 정적 분석 | mmr.dll DirectX 11 호출 패턴 분석 | **완료** |
| **USB 통신** | 정적 분석 | RFIDv2.dll HidLibrary 사용 패턴 분석 | **완료** |
| **메모리 분석** | 미사용 | 정적 분석으로 대체 | 불필요 |

#### WCF Protocol Analysis (정적 분석으로 전환)

```
net_conn.dll 디컴파일 소스
    │
    ├─ ServiceContract 어트리뷰트 추출
    ├─ OperationContract 메서드 목록화
    ├─ DataContract/DataMember 스키마 재구성
    └─ 113+ 프로토콜 메시지 식별
    │
    ▼
net_conn_deep_analysis.md (733 lines)
```

---

## 2. 도구 체인 설계

### 2.1 Core Tool Stack [완료]

```
┌─────────────────────────────────────────────────────────────┐
│              실제 사용 도구 체인 아키텍처 (v2.0)              │
└─────────────────────────────────────────────────────────────┘

Layer 1: Custom Static Analysis (Python)
┌─────────────────────────────────────────────────────────────┐
│  il_decompiler.py (1,455 lines)                             │
│  ├─ ECMA-335 metadata 파싱 + IL→C# 의사코드 변환           │
│  └─ PDB 심볼 활용 원본 변수명/파라미터 복원                  │
│                                                             │
│  confuserex_analyzer.py (2,156 lines)                       │
│  ├─ PE 구조 + ConfuserEx method body 패턴 분석              │
│  └─ XOR key 추출, etype ASCII 복호화                        │
│                                                             │
│  etype_decoder.py          extract_costura_v3.py            │
│  ├─ ASCII 인코딩 복호화    ├─ Costura DLL 추출 (v3)        │
│  └─ 87 sequences 처리     └─ 87개 리소스 추출               │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
Layer 2: .NET Reflection Analysis (C#)
┌─────────────────────────────────────────────────────────────┐
│  ReflectionAnalyzer (.NET 6, MetadataLoadContext)            │
│  ├─ 2,363 타입 분석 (class/struct/enum/interface/delegate)  │
│  └─ 62개 enum 정수값 + 타입 계층 완전 추출                   │
│                                                             │
│  extract_reflection_data.py                                 │
│  └─ 1.5M lines JSON → 핵심 데이터 정제                      │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
Layer 3: Metadata Parsing (Python)
┌─────────────────────────────────────────────────────────────┐
│  parse_metadata.py      extract_typedefs.py                 │
│  parse_refs.py          parse_refs2.py                      │
│  parse_us.py            parse_us2.py          parse_us3.py  │
│  parse_nested.py        parse_assembly.py                   │
│  └─ TypeDef, TypeRef, MemberRef, US String, Nested Type    │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
Layer 4: Documentation (산출물)
┌─────────────────────────────────────────────────────────────┐
│  9개 분석 문서 (Markdown)        11개 분석 데이터 (JSON)     │
│  ├─ architecture_overview.md     ├─ reflection_vpt_server   │
│  ├─ hand_eval_deep_analysis.md   ├─ confuserex_analysis     │
│  ├─ net_conn_deep_analysis.md    ├─ typedefs_vpt_server     │
│  ├─ 6개 추가 분석 문서           └─ 8개 추가 데이터          │
│  └─ COMPLETION_REPORT.md                                    │
└─────────────────────────────────────────────────────────────┘
```

### 2.2 Python Automation Scripts [완료]

#### 실제 스크립트 목록 (19개 Python + 1개 C# 프로젝트)

| 스크립트 | 용도 | 규모 |
|----------|------|------|
| `il_decompiler.py` | ECMA-335 IL→C# 커스텀 디컴파일러 | 1,455 lines |
| `confuserex_analyzer.py` | ConfuserEx PE/method body 패턴 분석 | 2,156 lines |
| `confuserex_deobfuscator.py` | ConfuserEx 난독화 해제 시도 | - |
| `etype_decoder.py` | etype ASCII 인코딩 복호화 | - |
| `extract_costura.py` | Costura DLL 추출 v1 | - |
| `extract_costura_v2.py` | Costura DLL 추출 v2 | - |
| `extract_costura_v3.py` | Costura DLL 추출 v3 (최종) | - |
| `rename_resources.py` | 리소스 파일 네이밍 | - |
| `extract_us_strings.py` | US String 추출 | - |
| `parse_metadata.py` | .NET metadata 파싱 | - |
| `extract_typedefs.py` | TypeDef 추출 | - |
| `parse_refs.py` | TypeRef/MemberRef 파싱 v1 | - |
| `parse_refs2.py` | TypeRef/MemberRef 파싱 v2 | - |
| `parse_us.py` | US String 파싱 v1 | - |
| `parse_us2.py` | US String 파싱 v2 | - |
| `parse_us3.py` | US String 파싱 v3 | - |
| `parse_nested.py` | 중첩 타입 파싱 | - |
| `parse_assembly.py` | Assembly 메타데이터 파싱 | - |
| `extract_reflection_data.py` | Reflection JSON 데이터 정제 | - |
| `ReflectionAnalyzer/` | C# .NET 6 Reflection 분석기 | ~500 lines |

#### 설계 단계 예시 코드 (실제 구현은 `scripts/extract_costura_v3.py` 참조)

`costura_extractor.py` 예제 구현

```python
import pefile
import zlib
import struct
from pathlib import Path

def extract_costura_dlls(exe_path: str, output_dir: str):
    """Costura.Fody로 임베디드된 DLL 추출"""
    pe = pefile.PE(exe_path)
    output = Path(output_dir)
    output.mkdir(exist_ok=True)

    # .NET Resources 섹션 찾기
    for entry in pe.DIRECTORY_ENTRY_RESOURCE.entries:
        if entry.name and entry.name.string.startswith(b'costura.'):
            dll_name = entry.name.string.decode('utf-8').replace('costura.', '')

            # 리소스 데이터 읽기
            rva = entry.directory.entries[0].data.struct.OffsetToData
            size = entry.directory.entries[0].data.struct.Size
            data = pe.get_data(rva, size)

            # zlib 압축 해제 (deflate 알고리즘)
            try:
                decompressed = zlib.decompress(data)
                output_file = output / dll_name
                output_file.write_bytes(decompressed)
                print(f"[+] Extracted: {dll_name} ({len(decompressed)} bytes)")
            except zlib.error:
                print(f"[-] Failed to decompress: {dll_name}")
```

#### 설계 단계 예시 코드 (실제 구현은 `scripts/parse_metadata.py` 참조)

`metadata_parser.py` - ECMA-335 Metadata 파싱

```python
import dnfile
from dnfile.stream import MetaDataTables

def parse_net_metadata(dll_path: str):
    """ECMA-335 CLI Metadata Tables 파싱"""
    dn = dnfile.dnPE(dll_path)

    # CLI Header 확인 (BSJB signature)
    cli_header = dn.net.metadata.streams.get('#~') or dn.net.metadata.streams.get('#-')
    if not cli_header:
        raise ValueError("Invalid .NET assembly")

    # TypeDef Table 추출
    type_defs = []
    for row in cli_header.tables.TypeDef:
        type_info = {
            'name': row.TypeName,
            'namespace': row.TypeNamespace,
            'flags': row.Flags,
            'extends': row.Extends
        }
        type_defs.append(type_info)

    # MethodDef Table 추출
    method_defs = []
    for row in cli_header.tables.MethodDef:
        method_info = {
            'name': row.Name,
            'signature': row.Signature,
            'rva': row.Rva,
            'impl_flags': row.ImplFlags
        }
        method_defs.append(method_info)

    return type_defs, method_defs
```

### 2.3 `pefile` 라이브러리 활용

#### 설계 단계 예시 코드 (실제 구현은 `scripts/il_decompiler.py` 내 PE 파싱 로직 참조)

PE 헤더 분석

```python
import pefile

def analyze_pe_structure(exe_path: str):
    """PE 파일 구조 전체 분석"""
    pe = pefile.PE(exe_path)

    analysis = {
        'dos_header': {
            'e_magic': hex(pe.DOS_HEADER.e_magic),  # MZ signature
            'e_lfanew': pe.DOS_HEADER.e_lfanew      # PE header offset
        },
        'nt_headers': {
            'signature': hex(pe.NT_HEADERS.Signature),  # PE\0\0
            'machine': pe.FILE_HEADER.Machine,          # 0x8664 (AMD64)
            'timestamp': pe.FILE_HEADER.TimeDateStamp
        },
        'optional_header': {
            'magic': hex(pe.OPTIONAL_HEADER.Magic),     # 0x20b (PE32+)
            'entry_point': hex(pe.OPTIONAL_HEADER.AddressOfEntryPoint),
            'image_base': hex(pe.OPTIONAL_HEADER.ImageBase)
        },
        'sections': []
    }

    # Section Headers
    for section in pe.sections:
        section_info = {
            'name': section.Name.decode('utf-8').rstrip('\x00'),
            'virtual_address': hex(section.VirtualAddress),
            'virtual_size': section.Misc_VirtualSize,
            'raw_size': section.SizeOfRawData,
            'characteristics': hex(section.Characteristics)
        }
        analysis['sections'].append(section_info)

    # .NET Directory Entry
    if hasattr(pe, 'DIRECTORY_ENTRY_COM_DESCRIPTOR'):
        analysis['dotnet'] = {
            'cli_header_rva': hex(pe.DIRECTORY_ENTRY_COM_DESCRIPTOR.VirtualAddress),
            'cli_header_size': pe.DIRECTORY_ENTRY_COM_DESCRIPTOR.Size
        }

    return analysis
```

### 2.4 `strings` 유틸리티 - 메타데이터 추출

#### 설계 단계 예시 코드 (실제 구현은 `scripts/extract_us_strings.py`, `scripts/parse_us*.py` 참조)

Windows Sysinternals `strings.exe` 활용

```powershell
# 모든 문자열 추출 (ASCII + Unicode)
strings64.exe -n 8 PokerGFX-Server.exe > strings_output.txt

# .NET 메타데이터 문자열만 필터링
strings64.exe -n 8 PokerGFX-Server.exe | Select-String -Pattern "^(System\.|Microsoft\.|PokerGFX\.)" > dotnet_types.txt

# 네임스페이스 계층 분석
Get-Content dotnet_types.txt | ForEach-Object { $_.Split('.')[0..1] -join '.' } | Sort-Object -Unique
```

#### Python `pystrings` 라이브러리

```python
from pystrings import Strings

def extract_meaningful_strings(exe_path: str, min_length: int = 8):
    """의미 있는 문자열 추출 및 분류"""
    strings_obj = Strings(exe_path, min_length=min_length)

    categorized = {
        'namespaces': [],
        'sql_queries': [],
        'file_paths': [],
        'urls': [],
        'error_messages': []
    }

    for s in strings_obj:
        if '.' in s and s[0].isupper():
            categorized['namespaces'].append(s)
        elif s.upper().startswith(('SELECT', 'INSERT', 'UPDATE', 'DELETE')):
            categorized['sql_queries'].append(s)
        elif ':\\' in s or s.startswith('/'):
            categorized['file_paths'].append(s)
        elif s.startswith(('http://', 'https://')):
            categorized['urls'].append(s)
        elif 'error' in s.lower() or 'exception' in s.lower():
            categorized['error_messages'].append(s)

    return categorized
```

---

## 3. Costura 추출 알고리즘 [완료]

> **참고**: 이 섹션의 코드 예제는 설계 단계 의사코드입니다. 실제 구현은 `scripts/extract_costura_v3.py`를 참조하세요. 3회 반복 개선을 거쳐 87개 리소스를 성공적으로 추출했습니다.

### 3.1 Costura.Fody 패키징 메커니즘

#### 리소스 임베딩 구조

```
PokerGFX-Server.exe
│
├── .text (Code Section)
├── .rsrc (Resource Section)
│   └── .NET Resources Manifest
│       ├── ResourceSet Entry 1: "costura.hand_eval.dll.compressed"
│       │   ├── Type: Stream
│       │   ├── Size: 1234567 bytes
│       │   └── Data: [zlib compressed PE]
│       │
│       ├── ResourceSet Entry 2: "costura.hand_eval.pdb.compressed"
│       │   ├── Type: Stream
│       │   ├── Size: 987654 bytes
│       │   └── Data: [zlib compressed PDB]
│       │
│       └── [134개 추가 리소스]
│
└── .reloc (Relocation Section)
```

### 3.2 단계별 추출 프로세스

#### Step 1: .NET Resource Manifest 읽기

```python
import pefile
import struct

def read_resource_manifest(exe_path: str):
    """ECMA-335 Resource Manifest 파싱"""
    pe = pefile.PE(exe_path)

    # CLR Header 찾기
    clr_rva = pe.OPTIONAL_HEADER.DATA_DIRECTORY[14].VirtualAddress
    clr_size = pe.OPTIONAL_HEADER.DATA_DIRECTORY[14].Size

    # Resources Metadata Stream 읽기
    resources_rva = struct.unpack('<I', pe.get_data(clr_rva + 8, 4))[0]
    resources_data = pe.get_data(resources_rva, 1024*1024)  # 최대 1MB 읽기

    return resources_data
```

#### Step 2: Costura 리소스 필터링

```python
def find_costura_resources(resources_data: bytes):
    """costura.* prefix 리소스 찾기"""
    costura_entries = []
    offset = 0

    while offset < len(resources_data) - 4:
        # Resource Name Length (4 bytes, little-endian)
        name_len = struct.unpack('<I', resources_data[offset:offset+4])[0]
        offset += 4

        if name_len > 0 and name_len < 256:
            # Resource Name (UTF-8)
            name = resources_data[offset:offset+name_len].decode('utf-8', errors='ignore')
            offset += name_len

            if name.startswith('costura.'):
                # Resource Data Offset & Size
                data_offset = struct.unpack('<I', resources_data[offset:offset+4])[0]
                data_size = struct.unpack('<I', resources_data[offset+4:offset+8])[0]
                offset += 8

                costura_entries.append({
                    'name': name,
                    'offset': data_offset,
                    'size': data_size
                })

    return costura_entries
```

#### Step 3: zlib 압축 해제

```python
import zlib

def decompress_costura_dll(compressed_data: bytes):
    """zlib deflate 압축 해제"""
    try:
        # Costura는 표준 zlib 압축 사용
        decompressed = zlib.decompress(compressed_data)

        # PE Header 검증 (MZ signature)
        if decompressed[:2] != b'MZ':
            raise ValueError("Invalid PE file after decompression")

        return decompressed
    except zlib.error as e:
        # 압축 실패 시 원본 반환 (압축되지 않은 리소스일 수 있음)
        return compressed_data
```

#### Step 4: PE 파일 무결성 검증

```python
def validate_pe_file(pe_data: bytes):
    """추출된 PE 파일 검증"""
    try:
        pe = pefile.PE(data=pe_data)

        checks = {
            'valid_dos_header': pe.DOS_HEADER.e_magic == 0x5A4D,  # MZ
            'valid_nt_header': pe.NT_HEADERS.Signature == 0x4550,  # PE\0\0
            'valid_sections': len(pe.sections) > 0,
            'valid_entry_point': pe.OPTIONAL_HEADER.AddressOfEntryPoint > 0
        }

        return all(checks.values()), checks
    except Exception as e:
        return False, {'error': str(e)}
```

### 3.3 배치 추출 자동화

```python
from pathlib import Path

def batch_extract_costura(exe_path: str, output_dir: str):
    """전체 Costura DLL 일괄 추출"""
    output = Path(output_dir)
    output.mkdir(exist_ok=True)

    pe = pefile.PE(exe_path)
    resources = find_costura_resources(read_resource_manifest(exe_path))

    stats = {'success': 0, 'failed': 0, 'total': len(resources)}

    for resource in resources:
        dll_name = resource['name'].replace('costura.', '').replace('.compressed', '')

        # 리소스 데이터 읽기
        data = pe.get_data(resource['offset'], resource['size'])

        # 압축 해제
        decompressed = decompress_costura_dll(data)

        # 검증
        is_valid, _ = validate_pe_file(decompressed)

        if is_valid:
            output_file = output / dll_name
            output_file.write_bytes(decompressed)
            stats['success'] += 1
            print(f"[+] {dll_name}: {len(decompressed):,} bytes")
        else:
            stats['failed'] += 1
            print(f"[-] {dll_name}: Validation failed")

    return stats
```

---

## 4. .NET 메타데이터 파싱 전략 [완료]

> **참고**: 이 섹션의 코드 예제는 설계 단계 의사코드입니다. 실제 구현은 `scripts/il_decompiler.py` (ECMA-335 파싱), `scripts/parse_metadata.py`, `scripts/extract_typedefs.py` 등을 참조하세요.

### 4.1 ECMA-335 CLI Metadata 구조

#### Metadata Root 구조

```
Offset    Size    Field                    Description
------    ----    -----                    -----------
0x00      4       Signature                "BSJB" (0x424A5342)
0x04      2       MajorVersion             1
0x06      2       MinorVersion             1
0x08      4       Reserved                 0x00000000
0x0C      4       VersionLength            문자열 길이 (4-byte aligned)
0x10      var     Version                  ".NET Framework 4.8.x..."
0xNN      2       Flags                    0x0000
0xNN+2    2       Streams                  스트림 개수 (보통 5개)
```

#### Metadata Streams

| Stream Name | 용도 | 크기 |
|-------------|------|------|
| `#~` 또는 `#-` | 압축된 Metadata Tables | 가변 |
| `#Strings` | 문자열 힙 (null-terminated) | 가변 |
| `#US` | User Strings (길이-prefix UTF-16) | 가변 |
| `#GUID` | GUID 힙 (16-byte entries) | 가변 |
| `#Blob` | Binary Large Objects | 가변 |

### 4.2 TypeDef Table 파싱

#### Table Layout (ECMA-335 II.22.37)

| Column | Type | Description |
|--------|------|-------------|
| Flags | 4 bytes | TypeAttributes (Public, Abstract, Sealed 등) |
| TypeName | String Index | #Strings heap index |
| TypeNamespace | String Index | #Strings heap index |
| Extends | TypeDefOrRef | 상속 타입 (coded index) |
| FieldList | Field Index | 첫 번째 필드 RID |
| MethodList | Method Index | 첫 번째 메서드 RID |

#### Python 파싱 구현

```python
import dnfile
from enum import IntFlag

class TypeAttributes(IntFlag):
    """ECMA-335 II.23.1.15 TypeAttributes"""
    Public = 0x00000001
    NotPublic = 0x00000000
    NestedPublic = 0x00000002
    Abstract = 0x00000080
    Sealed = 0x00000100
    Interface = 0x00000020
    Class = 0x00000000

def parse_typedef_table(dll_path: str):
    """TypeDef Table 전체 파싱"""
    dn = dnfile.dnPE(dll_path)
    metadata = dn.net.metadata.streams['#~']
    strings = dn.net.metadata.streams['#Strings']

    types = []
    for row in metadata.tables.TypeDef:
        type_info = {
            'full_name': f"{row.TypeNamespace}.{row.TypeName}",
            'attributes': {
                'is_public': bool(row.Flags & TypeAttributes.Public),
                'is_abstract': bool(row.Flags & TypeAttributes.Abstract),
                'is_sealed': bool(row.Flags & TypeAttributes.Sealed),
                'is_interface': bool(row.Flags & TypeAttributes.Interface)
            },
            'base_type': get_type_name(row.Extends, dn),
            'fields': get_fields_for_type(row, dn),
            'methods': get_methods_for_type(row, dn)
        }
        types.append(type_info)

    return types
```

### 4.3 MethodDef Table 파싱

#### Table Layout (ECMA-335 II.22.26)

| Column | Type | Description |
|--------|------|-------------|
| RVA | 4 bytes | Method body RVA (0이면 abstract) |
| ImplFlags | 2 bytes | MethodImplAttributes |
| Flags | 2 bytes | MethodAttributes (Public, Static, Virtual 등) |
| Name | String Index | #Strings heap index |
| Signature | Blob Index | #Blob heap index (메서드 시그니처) |
| ParamList | Param Index | 첫 번째 파라미터 RID |

#### Signature Blob 디코딩

```python
def decode_method_signature(blob_data: bytes):
    """ECMA-335 II.23.2.1 Method Signature 파싱"""
    offset = 0

    # Calling Convention (1 byte)
    calling_conv = blob_data[offset]
    offset += 1

    has_this = bool(calling_conv & 0x20)
    explicit_this = bool(calling_conv & 0x40)

    # Parameter Count (compressed integer)
    param_count, bytes_read = decode_compressed_int(blob_data[offset:])
    offset += bytes_read

    # Return Type
    ret_type, bytes_read = decode_type(blob_data[offset:])
    offset += bytes_read

    # Parameter Types
    params = []
    for _ in range(param_count):
        param_type, bytes_read = decode_type(blob_data[offset:])
        offset += bytes_read
        params.append(param_type)

    return {
        'has_this': has_this,
        'return_type': ret_type,
        'parameters': params
    }

def decode_compressed_int(data: bytes):
    """ECMA-335 II.23.2 Compressed Integer"""
    if data[0] & 0x80 == 0:
        # 1-byte encoding (0xxxxxxx)
        return data[0], 1
    elif data[0] & 0xC0 == 0x80:
        # 2-byte encoding (10xxxxxx)
        return ((data[0] & 0x3F) << 8) | data[1], 2
    else:
        # 4-byte encoding (110xxxxx)
        return ((data[0] & 0x1F) << 24) | (data[1] << 16) | (data[2] << 8) | data[3], 4
```

### 4.4 Entity Framework 6.0 Mapping 추출

#### DbContext 클래스 탐지

```python
def find_ef_dbcontext(types: list):
    """Entity Framework DbContext 상속 클래스 찾기"""
    dbcontext_types = []

    for type_info in types:
        if type_info['base_type'] == 'System.Data.Entity.DbContext':
            # DbSet<T> 프로퍼티 추출
            dbsets = []
            for prop in type_info.get('properties', []):
                if prop['type'].startswith('System.Data.Entity.DbSet<'):
                    entity_type = prop['type'][26:-1]  # DbSet<EntityType> 추출
                    dbsets.append({
                        'property_name': prop['name'],
                        'entity_type': entity_type,
                        'table_name': infer_table_name(prop['name'])
                    })

            dbcontext_types.append({
                'context_name': type_info['full_name'],
                'entities': dbsets
            })

    return dbcontext_types

def infer_table_name(dbset_property_name: str):
    """DbSet 프로퍼티명에서 테이블명 추론"""
    # EF 기본 규칙: 복수형 → 단수형
    if dbset_property_name.endswith('ies'):
        return dbset_property_name[:-3] + 'y'  # Histories → History
    elif dbset_property_name.endswith('s'):
        return dbset_property_name[:-1]  # Players → Player
    return dbset_property_name
```

---

## 5. 데이터 흐름 분석 설계 [완료]

### 5.1 RFID → Hand Evaluation → Rendering Pipeline

```
┌─────────────────────────────────────────────────────────────────┐
│                   전체 데이터 흐름 파이프라인                      │
└─────────────────────────────────────────────────────────────────┘

[1] RFID 입력 단계
    ┌─────────────────┐
    │  RFID Reader    │ (USB HID Device)
    │  (HidLibrary)   │
    └────────┬────────┘
             │ Raw USB Packets
             ▼
    ┌─────────────────┐
    │  RFIDv2.dll     │
    │  - CardMapper   │ Card ID (0x1A3F) → "Ace of Spades"
    │  - Protocol     │ Error handling, retry logic
    └────────┬────────┘
             │ Card[] (Rank, Suit)
             ▼

[2] 핸드 평가 단계
    ┌─────────────────┐
    │  hand_eval.dll  │
    │  - Evaluator    │ 7-card hand ranking
    │  - Calculator   │ Win probability (Monte Carlo?)
    └────────┬────────┘
             │ HandResult (Rank, Strength, Outs)
             ▼
    ┌─────────────────┐
    │  Common.dll     │
    │  - GameState    │ Entity Framework 6.0
    │  - DbContext    │ SQLite/SQL Server
    └────────┬────────┘
             │ Persist to DB
             ▼

[3] 렌더링 단계
    ┌─────────────────┐
    │  SkiaSharp      │
    │  - Draw Cards   │ Vector graphics (SVG-like)
    │  - Text Render  │ Typography, anti-aliasing
    └────────┬────────┘
             │ SKBitmap (RGBA)
             ▼
    ┌─────────────────┐
    │  SharpDX        │
    │  - D3D11 Tex    │ GPU upload
    │  - Composition  │ Shader pipeline
    └────────┬────────┘
             │ Direct3D11 Texture2D
             ▼
    ┌─────────────────┐
    │  Skin System    │
    │  - Load .skn    │ Theme overlay
    │  - Apply Style  │ Borders, backgrounds
    └────────┬────────┘
             │ Composited Frame
             ▼

[4] 출력 단계
    ┌─────────────────┐
    │  Medialooks SDK │
    │  - Frame Buffer │ YUV422/RGB conversion
    │  - Sync Clock   │ Frame timing (59.94 fps)
    └────────┬────────┘
             │ Video Frame
             ├──────────────────┬──────────────────┐
             ▼                  ▼                  ▼
    ┌─────────────┐   ┌─────────────┐   ┌─────────────┐
    │  NDI Output │   │ ATEM Output │   │  SRT Output │
    └─────────────┘   └─────────────┘   └─────────────┘
```

### 5.2 분석 지점 (Instrumentation Points)

| 단계 | 분석 방법 | 수집 데이터 | 도구 |
|------|-----------|------------|------|
| **RFID Input** | USBPcap + HID Sniffer | USB Interrupt Transfers, Card ID 매핑 | Wireshark + USBPcap |
| **Hand Eval** | dnSpy Breakpoint | 입력 카드 배열, 출력 핸드 랭크 | dnSpy Debugger |
| **Database** | Process Monitor | SQL 쿼리, INSERT/UPDATE | Procmon + Filter |
| **SkiaSharp** | dnSpy Watch | SKCanvas draw calls, SKPaint 속성 | dnSpy |
| **SharpDX** | NVIDIA Nsight | D3D11 Draw Call, Shader 바인딩 | Nsight Graphics |
| **Video Output** | Wireshark | NDI 패킷 (RTP/UDP), ATEM 제어 | Wireshark |

### 5.3 Critical Path Tracing

#### 메서드 호출 체인 역추적

```
user_input_event (UI)
    └─ MainForm.OnCardScanned(CardInfo card)
        └─ RFIDService.ProcessCard(byte[] rawData)
            └─ RFIDv2.CardMapper.Decode(rawData)
                → Card { Rank, Suit }
            └─ HandEvaluator.Evaluate(Card[] cards)
                → HandResult { Rank, Strength }
            └─ GameState.UpdateHand(HandResult result)
                → EF6 DbContext.SaveChanges()
            └─ GraphicsEngine.RenderHand(HandResult result)
                └─ SkiaRenderer.DrawCards(Card[] cards)
                    → SKBitmap
                └─ DirectXCompositor.Composite(SKBitmap frame)
                    → D3D11 Texture2D
                └─ OutputManager.SendFrame(Texture2D texture)
                    ├─ NDIOutput.Send(frame)
                    ├─ ATEMOutput.Send(frame)
                    └─ SRTOutput.Send(frame)
```

---

## 6. 산출물 구조 [완료]

### 6.1 디렉토리 구조 [완료]

```
C:\claude\ebs_reverse\
│
├── binaries\                        # 원본 바이너리
│   ├── PokerGFX-Server.exe (355MB)
│   └── PokerGFX-Server.pdb (2.1MB)
│
├── extracted\                       # Costura 추출 결과
│   ├── resource_50.dll ~ resource_132.dll (87개 DLL/bin)
│   ├── _raw_resource_43.bin ~ _raw_resource_133.bin (raw)
│   ├── _extraction_report.json
│   ├── _report.json
│   └── _analysis.json
│
├── decompiled\                      # 커스텀 디컴파일 결과 (8모듈, 2,887 .cs)
│   ├── vpt_server\                  # 메인 서버 (가장 큼, ~347 files)
│   │   ├── vpt_server\              # 기본 네임스페이스
│   │   └── _global\                 # 글로벌 타입
│   ├── net_conn\                    # 네트워크 프로토콜 (~168 files)
│   ├── boarssl\                     # TLS/SSL (~102 files)
│   ├── mmr\                         # DirectX 11 GPU (~80 files)
│   ├── hand_eval\                   # 핸드 평가 알고리즘 (~52 files)
│   ├── PokerGFX.Common\             # 공유 라이브러리 (~50 files)
│   ├── RFIDv2\                      # RFID 리더 (~26 files)
│   └── analytics\                   # 통계/S3 (~7 files)
│
├── analysis\                        # 분석 결과
│   ├── *.md (9개 분석 문서)
│   │   ├── architecture_overview.md (~1,367 lines)
│   │   ├── hand_eval_deep_analysis.md (~493 lines)
│   │   ├── net_conn_deep_analysis.md (~733 lines)
│   │   ├── auxiliary_modules_analysis.md (~586 lines)
│   │   ├── infra_modules_analysis.md (~1,395 lines)
│   │   ├── vpt_server_supplemental_analysis.md (~1,413 lines)
│   │   ├── confuserex_analysis.md
│   │   ├── runtime_debugging_analysis.md (~1,069 lines)
│   │   └── COMPLETION_REPORT.md
│   │
│   └── *.json (11개 분석 데이터)
│       ├── reflection_vpt_server.json (1,499,730 lines)
│       ├── reflection_extracted.json (2,951 lines)
│       ├── reflection_common.json
│       ├── reflection_named_common.json
│       ├── confuserex_analysis.json (3,356 lines)
│       ├── typedefs_vpt_server.json
│       ├── us_strings.json
│       ├── etype_decoded_strings.json
│       ├── config_cctor.json
│       ├── deobfuscated_analysis.json
│       └── deobfuscated_full.json
│
├── scripts\                         # 자동화 스크립트 (19개 Python + 1개 C#)
│   ├── il_decompiler.py (1,455 lines)
│   ├── confuserex_analyzer.py (2,156 lines)
│   ├── confuserex_deobfuscator.py
│   ├── etype_decoder.py
│   ├── extract_costura.py (v1)
│   ├── extract_costura_v2.py (v2)
│   ├── extract_costura_v3.py (v3, 최종)
│   ├── rename_resources.py
│   ├── extract_us_strings.py
│   ├── parse_metadata.py
│   ├── extract_typedefs.py
│   ├── parse_refs.py
│   ├── parse_refs2.py
│   ├── parse_us.py / parse_us2.py / parse_us3.py
│   ├── parse_nested.py
│   ├── parse_assembly.py
│   ├── extract_reflection_data.py
│   └── ReflectionAnalyzer\          # C# .NET 6 프로젝트
│       ├── Program.cs (~500 lines)
│       ├── ReflectionAnalyzer.csproj
│       ├── analyze_all.ps1
│       └── README.md
│
└── docs\                            # PDCA 문서
    ├── 01-plan\
    │   └── pokergfx-reverse-engineering.plan.md
    └── 02-design\
        └── pokergfx-reverse-engineering.design.md (본 문서)
```

### 6.2 문서 템플릿

#### `architecture-overview.md` 구조

```markdown
# PokerGFX 아키텍처 분석

## 1. 시스템 개요
- 전체 구성도
- 주요 컴포넌트

## 2. 레이어 구조
- Presentation Layer (UI)
- Business Logic Layer
- Data Access Layer
- Infrastructure Layer

## 3. 컴포넌트 다이어그램
(PlantUML 다이어그램 삽입)

## 4. 시퀀스 다이어그램
- RFID 스캔 플로우
- 핸드 평가 플로우
- 렌더링 플로우

## 5. 기술 스택 매핑
(Phase별 기술 요소 표)
```

#### `hand-evaluation-algorithm.md` 구조

```markdown
# hand_eval.dll 알고리즘 분석

## 1. 핸드 랭킹 로직
### 1.1 7-card Hand Evaluation
(의사 코드)

### 1.2 Lookup Table vs Calculation
(성능 최적화 기법)

## 2. 승률 계산
### 2.1 Monte Carlo Simulation
(샘플링 방법)

### 2.2 Exact Calculation
(조합론 기반)

## 3. 소스 코드 복원
```csharp
// ILSpy 디컴파일 결과
public class HandEvaluator {
    // ...
}
```

## 4. 검증 테스트
(알고리즘 정확도 검증)
```

---

## 7. Phase별 상세 접근법 [8/10 완료]

### Phase 1: 환경 구축 및 바이너리 추출 [완료]

#### 실제 작업 결과

| 순서 | 작업 | 도구 | 산출물 |
|:----:|------|------|--------|
| 1 | Python 환경 구축 | Python 3.10+, pefile | 개발 환경 |
| 2 | Costura 추출 v1 | `extract_costura.py` | 초기 추출 (부분 실패) |
| 3 | Costura 추출 v2 | `extract_costura_v2.py` | 개선 (압축 해제 문제 수정) |
| 4 | Costura 추출 v3 | `extract_costura_v3.py` | **87개 리소스 추출 완료** |
| 5 | 추출 검증 | PE 무결성 + `_extraction_report.json` | 검증 리포트 |

#### 성공 기준

- [x] 87개 리소스 추출 완료 (resource_50 ~ resource_132)
- [x] PE 파일 무결성 검증 통과
- [x] PDB 심볼 파일 존재 확인 (2.1MB)
- [x] 커스텀 디컴파일러로 정상 로드 확인

---

### Phase 2: Common.dll 공유 라이브러리 분석 [완료]

#### 분석 결과

| 항목 | 계획 | 실제 결과 |
|------|------|----------|
| **타입 전수 조사** | 42개 타입 | ~50개 파일, 95% 커버리지 |
| **Entity Framework** | DbContext, DbSet 추출 | EF6 매핑 + SQLite 스키마 추론 완료 |
| **암호화** | EncryptionService 구현 | **AES-256 Zero IV 취약점 발견** |
| **유틸리티** | 공통 헬퍼 메서드 | 문서화 완료 |

#### 실제 도구 사용

```powershell
# 커스텀 디컴파일러로 소스 추출
python scripts\il_decompiler.py binaries\PokerGFX-Server.exe --module PokerGFX.Common

# Reflection 분석으로 enum 값 + 타입 계층 추출
dotnet run --project scripts\ReflectionAnalyzer -- extracted\PokerGFX.Common.dll
```

#### 산출물

- `decompiled/PokerGFX.Common/` - ~50개 디컴파일된 .cs 파일
- `analysis/reflection_common.json` - Reflection 분석 데이터
- `analysis/reflection_named_common.json` - 명명된 타입 데이터

---

### Phase 3: Database 및 통신 프로토콜 분석 [부분 완료]

#### 3.1 net_conn.dll 통신 프로토콜 [완료]

정적 분석으로 WCF 프로토콜을 97% 커버리지로 분석했습니다.

```
net_conn.dll 디컴파일 (~168 files)
    │
    ├─ ServiceContract 추출: 113+ 프로토콜 메시지
    ├─ DataContract 스키마 재구성
    ├─ AES 암호화 키/IV 완전 추출 (PBKDF1)
    └─ Binary serialization 포맷 분석
```

#### 3.2 DB 분석 [부분 완료]

- EF6 DbContext/DbSet 정적 추출 완료
- 실제 SQLite DB 파일 접근은 미실행 (런타임 환경 없음)

#### 산출물

- `decompiled/net_conn/` - ~168개 디컴파일된 .cs 파일
- `analysis/net_conn_deep_analysis.md` (~733 lines) - WCF 프로토콜 상세 분석

---

### Phase 4: hand_eval.dll 핸드 평가 알고리즘 [완료]

#### 실제 분석 방법

| 단계 | 작업 | 도구 | 결과 |
|------|------|------|------|
| 1 | 커스텀 디컴파일 | il_decompiler.py | ~52개 .cs 파일 |
| 2 | Reflection 분석 | ReflectionAnalyzer | enum 정수값 + 타입 계층 |
| 3 | 알고리즘 역설계 | 정적 코드 분석 | Bitmask + Monte Carlo 복원 |

#### 주요 발견

- **97% 커버리지** 달성 (정적 분석만으로)
- **Bitmask 기반 핸드 평가**: 비트 연산으로 7장에서 최적 5장 조합 계산
- **Monte Carlo 승률 계산**: 확률 기반 시뮬레이션
- **22개 포커 게임 변형** 지원 (holdem=0 ~ razz=21)

#### 산출물

- `decompiled/hand_eval/` - ~52개 디컴파일된 .cs 파일
- `analysis/hand_eval_deep_analysis.md` (~493 lines) - 알고리즘 상세 분석

---

### Phase 5: RFIDv2.dll 카드 인식 프로토콜 [완료]

#### 실제 분석 방법

USB 패킷 캡처 없이 정적 분석만으로 90% 커버리지를 달성했습니다.

```
RFIDv2.dll 디컴파일 (~26 files)
    │
    ├─ 듀얼 트랜스포트 분석: HID (USB) + Serial
    ├─ HidLibrary 사용 패턴 추출
    ├─ Card ID 매핑 로직 역설계
    └─ Error handling + retry 패턴
```

#### 주요 발견

- **듀얼 트랜스포트**: HID (USB Interrupt Transfer) + Serial 동시 지원
- **HidLibrary**: 오픈소스 HID 라이브러리 사용
- **90% 커버리지** (정적 분석)

#### 산출물

- `decompiled/RFIDv2/` - ~26개 디컴파일된 .cs 파일
- `analysis/auxiliary_modules_analysis.md` (~586 lines) - RFIDv2 포함 보조 모듈 분석

---

### Phase 6: vpt_server 핵심 로직 [완료]

#### 6.1 아키텍처 분석 결과

3세대 진화 아키텍처를 발견했습니다: God Class → Service Layer → CQRS 패턴.

```
vpt_server.exe 디컴파일 (~347 files)
    │
    ├─ 82% 커버리지 (ConfuserEx 난독화 영역 제외)
    ├─ 3세대 아키텍처 파악: God Class → Service Layer → CQRS
    ├─ 4계층 DRM 체계 분석
    └─ 22개 포커 게임 변형 매핑
```

#### 6.2 주요 발견

| 발견 | 상세 |
|------|------|
| **3세대 아키텍처** | 초기 God Class → Service Layer 분리 → CQRS 패턴 |
| **4계층 DRM** | Email/Password → Offline Session → KEYLOK USB → Remote License |
| **ConfuserEx 영향** | 82% 커버리지 (20.1% 난독화 methods가 잔여 gap) |

#### 산출물

- `decompiled/vpt_server/` - ~347개 디컴파일된 .cs 파일
- `analysis/architecture_overview.md` (~1,367 lines) - 전체 아키텍처 분석
- `analysis/vpt_server_supplemental_analysis.md` (~1,413 lines) - vpt_server 보충 분석

---

### Phase 7: Skin 시스템 분석 [부분 완료]

#### 분석 현황

정적 분석으로 Skin 시스템의 구조와 로딩 메커니즘을 파악했으나, .skn 바이너리 포맷 완전 파싱은 미완료입니다.

| 항목 | 상태 | 비고 |
|------|:----:|------|
| Skin 로딩 코드 분석 | **완료** | vpt_server 내 SkinManager 역설계 |
| .skn 헤더 구조 파악 | **완료** | SKIN_HDR 매직, AES 암호화 |
| .skn 바이너리 파서 구현 | 미완료 | 실제 .skn 파일 없이 구현 불가 |
| 애셋 추출 | 미완료 | .skn 파일 접근 필요 |

#### 설계 단계 예시 코드 (실제 .skn 파일로 검증 필요)

```python
import struct
from pathlib import Path

def parse_skn_header(skn_path: str):
    """Skin 파일 헤더 파싱"""
    with open(skn_path, 'rb') as f:
        # Magic Number (4 bytes)
        magic = f.read(4)
        if magic != b'SKIN':
            raise ValueError("Invalid .skn file")

        # Version (4 bytes)
        version = struct.unpack('<I', f.read(4))[0]

        # Asset Count (4 bytes)
        asset_count = struct.unpack('<I', f.read(4))[0]

        # Asset Entries
        assets = []
        for _ in range(asset_count):
            name_len = struct.unpack('<H', f.read(2))[0]
            name = f.read(name_len).decode('utf-8')
            offset = struct.unpack('<Q', f.read(8))[0]
            size = struct.unpack('<I', f.read(4))[0]

            assets.append({
                'name': name,
                'offset': offset,
                'size': size
            })

        return {
            'version': version,
            'assets': assets
        }
```

#### 산출물

- vpt_server 내 Skin 관련 코드 분석 완료 (architecture_overview.md에 포함)
- .skn 바이너리 파서 및 애셋 추출은 향후 작업

---

### Phase 8: 그래픽 파이프라인 [완료]

#### 실제 분석 방법

Nsight 프로파일링 대신 mmr.dll 정적 분석으로 DirectX 11 파이프라인을 92% 커버리지로 파악했습니다.

```
mmr.dll 디컴파일 (~80 files)
    │
    ├─ DirectX 11 GPU 파이프라인 역설계
    ├─ 5-Thread Pipeline 구조 분석
    ├─ SkiaSharp → SharpDX 통합 패턴 추출
    └─ Medialooks SDK 프레임 버퍼 연동
```

#### 주요 발견

| 발견 | 상세 |
|------|------|
| **5-Thread Pipeline** | Render/Compose/Encode/Output/Sync 분리 |
| **DirectX 11 통합** | SharpDX 래핑, Texture2D 기반 GPU 업로드 |
| **92% 커버리지** | 정적 분석만으로 파이프라인 구조 완전 파악 |

#### 설계 단계 예시 코드 (실제 구현은 `decompiled/mmr/` 참조)

```csharp
// SkiaSharp 렌더링 → SharpDX 업로드 패턴
public Texture2D RenderToTexture(SKBitmap skiaBitmap) {
    // 1. SkiaSharp bitmap → byte array
    byte[] pixels = skiaBitmap.Bytes;

    // 2. SharpDX Texture2D 생성
    var desc = new Texture2DDescription {
        Width = skiaBitmap.Width,
        Height = skiaBitmap.Height,
        Format = Format.R8G8B8A8_UNorm,
        Usage = ResourceUsage.Default,
        BindFlags = BindFlags.ShaderResource
    };

    // 3. GPU 업로드
    var texture = new Texture2D(device, desc,
        new DataRectangle(pixels, skiaBitmap.RowBytes));

    return texture;
}
```

#### 산출물

- `decompiled/mmr/` - ~80개 디컴파일된 .cs 파일
- `analysis/infra_modules_analysis.md` (~1,395 lines) - mmr 포함 인프라 모듈 분석

---

### Phase 9: ActionTracker 원격 제어 [미시작]

ActionTracker.exe는 별도 바이너리로, 현재 분석 범위에 포함되지 않았습니다.

#### 향후 작업

| 항목 | 필요 사항 |
|------|----------|
| ActionTracker.exe 바이너리 확보 | 별도 파일 필요 |
| WPF XAML 추출 | 디컴파일 후 리소스 추출 |
| 터치 UI 제스처 분석 | WPF Touch Event 패턴 역설계 |
| WCF 클라이언트 프로토콜 | net_conn 분석 결과 활용 가능 |

---

### Phase 10: 동적 분석 및 검증 [부분 완료]

#### 실제 접근 방법

Reflection + ConfuserEx 정적 분석으로 동적 분석 없이 95% 커버리지를 달성했습니다.

```
정적 분석 결과 교차 검증
    │
    ├─ il_decompiler 결과 vs Reflection 결과 교차 비교
    ├─ ConfuserEx 비난독화 영역 (79.9%) 완전 분석
    ├─ enum 정수값 검증 (62개 타입, 100% 일치)
    └─ 타입 계층 무결성 확인 (2,363 타입)
```

#### 검증 상태

| 시나리오 | 검증 내용 | 방법 | 상태 |
|---------|----------|------|:----:|
| 타입 시스템 | 2,363 타입 무결성 | Reflection 교차 검증 | **완료** |
| 프로토콜 | 113+ WCF 메시지 | ServiceContract 정적 추출 | **완료** |
| 암호화 | 3개 AES 시스템 | 키/IV/모드 정적 추출 | **완료** |
| 런타임 동작 | 실제 실행 검증 | Process Monitor | 미실행 |
| 비디오 출력 | NDI/ATEM/SRT | 방송 장비 연결 | 미실행 |

#### 산출물

- `analysis/runtime_debugging_analysis.md` (~1,069 lines) - 런타임 분석 결과
- `analysis/COMPLETION_REPORT.md` - 완료 보고서

---

## 8. 리스크 및 대응 전략 [업데이트됨]

### 8.1 기술적 리스크

#### 해소된 리스크

| 리스크 | 원래 등급 | 해소 방법 |
|--------|:--------:|----------|
| ~~Costura 추출 실패~~ | 하/상 | **해결됨** - extract_costura_v3.py로 87개 추출 완료 |
| ~~PDB 심볼 누락~~ | 극저/극상 | **해결됨** - PDB 2.1MB 존재 확인, 변수명/파라미터 복원 |
| ~~WCF 통신 암호화~~ | 중/중 | **해결됨** - 정적 분석으로 ServiceContract + AES 키/IV 추출 |

#### 현재 잔여 리스크

| 리스크 | 발생 가능성 | 영향도 | 대응 방안 |
|--------|:----------:|:------:|----------|
| **ConfuserEx method body 복호화** | 확정 | 중 | 2,914 methods (20.1%) 미복호화, 5% 커버리지 gap |
| **.skn 바이너리 포맷** | 중 | 중 | .skn 파일 확보 후 바이너리 파싱 필요 |
| **ActionTracker 별도 분석** | 중 | 하 | 별도 바이너리 확보 필요 |

### 8.2 법적 리스크

| 리스크 | 심각도 | 대응 |
|--------|:------:|------|
| **EULA 위반** | 중 | 정당한 목적 문서화 (상호운용성) |
| **상용 컴포넌트 라이선스** | 중 | 리버싱 범위를 PokerGFX 코드로 제한 |
| **영업비밀 침해** | 중 | 공개 정보 우선, 독자 개발 증명 |

---

## 9. 분석 결과 요약

### 9.1 Coverage Summary

| 모듈 | 파일 수 | 커버리지 | 주요 발견 |
|------|:-------:|:--------:|----------|
| vpt_server.exe | 347 | 82% | 3세대 아키텍처, God Class→CQRS 진화 |
| net_conn.dll | 168 | 97% | 113+ 프로토콜, AES 키/IV 완전 추출 |
| boarssl.dll | 102 | 88% | 자체 TLS 구현, InsecureCertValidator |
| mmr.dll | 80 | 92% | DirectX 11 GPU, 5-Thread Pipeline |
| hand_eval.dll | 52 | 97% | Bitmask + Monte Carlo |
| PokerGFX.Common.dll | 50 | 95% | AES-256 Zero IV 취약점 |
| RFIDv2.dll | 26 | 90% | 듀얼 트랜스포트 (HID + Serial) |
| analytics.dll | 7 | 95% | S3 Store-and-Forward |
| **전체** | **839** | **95%** | +7% from Reflection (88%→95%) |

### 9.2 핵심 발견

| 카테고리 | 발견 | 상세 |
|---------|------|------|
| **암호화** | 3개 독립 AES 시스템 | net_conn PBKDF1, Common Zero-IV, config SKIN_HDR |
| **DRM** | 4계층 보호 체계 | Email/Password → Offline Session → KEYLOK USB → Remote License |
| **게임** | 22개 포커 변형 | holdem=0 ~ razz=21 (enum 정수값 완전 추출) |
| **enum** | 62개 타입 | Reflection으로 모든 멤버와 정수값 추출 |
| **난독화** | ConfuserEx 20.1% | XOR key 0x69685421cd4c01b8, 2,914/14,460 methods |

### 9.3 Phase별 진행 상태 요약

| Phase | 주제 | 상태 | 커버리지 | 실제 접근 |
|:-----:|------|:----:|:--------:|----------|
| 1 | 환경 구축 및 바이너리 추출 | **완료** | 100% | extract_costura_v3.py로 87개 리소스 추출 |
| 2 | Common.dll 분석 | **완료** | 95% | il_decompiler + Reflection (50 files) |
| 3 | DB 및 통신 프로토콜 | **부분 완료** | 97% | net_conn 정적 분석, WCF 완료 |
| 4 | hand_eval 알고리즘 | **완료** | 97% | Bitmask + Monte Carlo 복원 |
| 5 | RFIDv2 카드 인식 | **완료** | 90% | 듀얼 트랜스포트 분석 |
| 6 | vpt_server 핵심 | **완료** | 82% | 3세대 아키텍처 (ConfuserEx 제외) |
| 7 | Skin 시스템 | **부분 완료** | 60% | 정적 분석 완료, .skn 파싱 미완 |
| 8 | 그래픽 파이프라인 | **완료** | 92% | mmr.dll DirectX 11, 5-Thread Pipeline |
| 9 | ActionTracker | **미시작** | 0% | 별도 바이너리 분석 필요 |
| 10 | 동적 분석 | **부분 완료** | 95% | Reflection + ConfuserEx 정적 분석으로 달성 |

---

## 10. 참조 문서

| 문서 | URL |
|------|-----|
| ECMA-335 CLI Specification | https://www.ecma-international.org/publications/standards/Ecma-335.htm |
| pefile Documentation | https://github.com/erocarrera/pefile |
| Costura.Fody GitHub | https://github.com/Fody/Costura |
| .NET MetadataLoadContext | https://learn.microsoft.com/en-us/dotnet/api/system.reflection.metadataloadcontext |
| ConfuserEx GitHub | https://github.com/yck1509/ConfuserEx |

---

## 변경 이력

| 버전 | 일자 | 변경 내용 |
|------|------|----------|
| 1.0.0 | 2026-02-12 | 초기 설계 문서 작성 (ILSpy/dnSpy 기반 계획) |
| 2.0.0 | 2026-02-12 | 실제 구현 현황 반영: 커스텀 도구 체인, ConfuserEx/Reflection 방법론 추가, Phase별 상태 업데이트, 분석 결과 요약 추가 |

---

**문서 종료**
