#!/usr/bin/env node
/**
 * Claude Vision 분석 결과를 JSON 파일로 저장
 *
 * Usage:
 *   node save-subtitles.js --input='{"subtitles":[...]}'
 *   node save-subtitles.js --input='{"subtitles":[...]}' --output=./output/subtitles.json
 *
 * Input JSON format:
 *   {
 *     "subtitles": [
 *       {
 *         "id": "photo_id",
 *         "file": "photo_id.jpg",
 *         "phase": "overview|before|process|after",
 *         "subtitle": "15자 이내 마케팅 문구",
 *         "confidence": 0.0-1.0
 *       }
 *     ]
 *   }
 */

import { writeFileSync, mkdirSync, existsSync } from 'fs';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const projectRoot = join(__dirname, '../../..');

// Parse arguments
const args = process.argv.slice(2);
const inputArg = args.find(a => a.startsWith('--input='));
const outputArg = args.find(a => a.startsWith('--output='));

if (!inputArg) {
  console.error('Usage: node save-subtitles.js --input=\'{"subtitles":[...]}\'');
  console.error('');
  console.error('Options:');
  console.error('  --input=<JSON>     Claude Vision 분석 결과 (필수)');
  console.error('  --output=<path>    출력 파일 경로 (기본: ./output/subtitles.json)');
  console.error('');
  console.error('Input JSON format:');
  console.error('  {');
  console.error('    "subtitles": [');
  console.error('      {');
  console.error('        "id": "photo_id",');
  console.error('        "file": "photo_id.jpg",');
  console.error('        "phase": "overview|before|process|after",');
  console.error('        "subtitle": "15자 이내 마케팅 문구",');
  console.error('        "confidence": 0.0-1.0');
  console.error('      }');
  console.error('    ]');
  console.error('  }');
  process.exit(1);
}

// Parse input JSON
let input;
try {
  const inputJson = inputArg.slice('--input='.length);
  input = JSON.parse(inputJson);
} catch (err) {
  console.error(`❌ JSON 파싱 오류: ${err.message}`);
  process.exit(1);
}

// Validate input
if (!input.subtitles || !Array.isArray(input.subtitles)) {
  console.error('❌ 입력에 subtitles 배열이 없습니다.');
  process.exit(1);
}

// Determine output path (relative to current working directory)
const outputPath = outputArg
  ? outputArg.slice('--output='.length)
  : join(process.cwd(), 'output', 'subtitles.json');

// Ensure output directory exists
const outputDir = dirname(outputPath);
if (!existsSync(outputDir)) {
  mkdirSync(outputDir, { recursive: true });
}

// Phase order for sorting
const phaseOrder = { overview: 0, before: 1, process: 2, after: 3 };

// Sort subtitles by phase
const sortedSubtitles = [...input.subtitles].sort((a, b) => {
  const orderA = phaseOrder[a.phase] ?? 99;
  const orderB = phaseOrder[b.phase] ?? 99;
  return orderA - orderB;
});

// Build output object
const output = {
  generated_at: new Date().toISOString(),
  model: 'claude-opus-4.5',
  total_count: input.subtitles.length,
  phase_summary: {
    overview: input.subtitles.filter(s => s.phase === 'overview').length,
    before: input.subtitles.filter(s => s.phase === 'before').length,
    process: input.subtitles.filter(s => s.phase === 'process').length,
    after: input.subtitles.filter(s => s.phase === 'after').length,
  },
  recommended_order: sortedSubtitles.map(s => s.id),
  subtitles: sortedSubtitles
};

// Save to file
try {
  writeFileSync(outputPath, JSON.stringify(output, null, 2), 'utf-8');
  console.log(`✅ 저장됨: ${outputPath}`);
  console.log('');
  console.log('📊 Phase 분포:');
  console.log(`   overview: ${output.phase_summary.overview}개`);
  console.log(`   before:   ${output.phase_summary.before}개`);
  console.log(`   process:  ${output.phase_summary.process}개`);
  console.log(`   after:    ${output.phase_summary.after}개`);
  console.log('');
  console.log(`📝 총 ${output.total_count}개 자막`);
} catch (err) {
  console.error(`❌ 파일 저장 오류: ${err.message}`);
  process.exit(1);
}
