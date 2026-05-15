# Vexlo Audio Tools

This folder is the minimal offline pipeline for generating, screening, and preparing Vexlo sound assets without touching runtime code.

## Requirements

- `ELEVENLABS_API_KEY` exported in the shell for generation
- Python 3
- macOS `afconvert` available if you want automatic MP3 -> WAV conversion for QC/trim

## 1. Generate a batch

```bash
cd ~/Desktop/Vexlo
export ELEVENLABS_API_KEY=...
python3 Tools/audio/generate_audio_batch.py
```

Optional subset:

```bash
python3 Tools/audio/generate_audio_batch.py --events validPlace lineClear comboX2
```

## 2. Run QC

Point QC at a generated batch folder or a single WAV file:

```bash
python3 Tools/audio/audio_qc.py Tools/audio/batches/<batch-name>
```

If `afconvert` was unavailable during generation, QC will fail cleanly until WAV files exist.

## 3. Finalize one selected candidate

```bash
python3 Tools/audio/audio_trim.py \
  Tools/audio/batches/<batch-name>/validPlace/candidate_01.wav \
  --event validPlace
```

Default output goes to:

- `Tools/audio/final/<canonical filename>`

Use `--force` only when you intentionally want to replace an existing finalized file.

## Notes

- Canonical filenames are governed by `Docs/VEXLO_AUDIO_ASSET_CONTRACT.md`
- Missing API key causes clean failure with no partial runtime changes
- These tools do not import assets into the app bundle or modify Xcode project settings
