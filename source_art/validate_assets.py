"""Validate raster/audio deliverables and make a source-art contact sheet."""
from pathlib import Path
from PIL import Image, ImageDraw
import json, wave
import numpy as np

ROOT=Path(__file__).resolve().parents[1]
manifest=json.loads((ROOT/'source_art/art_manifest.json').read_text())
tiles=[]
for name,entry in manifest.items():
    path=ROOT/entry['runtime']
    with Image.open(path) as im:
        im.load()
        assert im.mode=='RGBA', f'{name}: transparency format'
        assert im.size==(entry['width'],entry['height']), f'{name}: dimensions'
        assert (ROOT/'source_art/layers'/path.name).exists(), f'{name}: source PNG'
        tile=Image.new('RGB',(200,190),'#26303b')
        picture=im.copy(); picture.thumbnail((188,160),Image.Resampling.NEAREST)
        tile.paste(picture,((200-picture.width)//2,6),picture)
        ImageDraw.Draw(tile).text((7,172),name,fill='#d5cdb0')
        tiles.append(tile)
sheet=Image.new('RGB',(1000,((len(tiles)+4)//5)*190),'#101624')
for i,tile in enumerate(tiles):sheet.paste(tile,((i%5)*200,(i//5)*190))
sheet.save(ROOT/'source_art/contact_sheet.png')
audio=[]
for path in sorted((ROOT/'assets/audio').glob('*.wav')):
    with wave.open(str(path)) as w:
        assert w.getnchannels()==1 and w.getsampwidth()==2 and w.getframerate()==22050
        samples=np.frombuffer(w.readframes(w.getnframes()),dtype='<i2').astype(float)/32768
        peak=float(np.abs(samples).max());rms=float(np.sqrt(np.mean(samples*samples)))
        assert 0.001<rms<.3 and 0.01<peak<.9, f'{path.name}: unexpected levels'
        audio.append({'name':path.name,'seconds':round(len(samples)/22050,3),'peak':round(peak,4),'rms':round(rms,4)})
report={'images':len(manifest),'audio_files':len(audio),'all_image_formats_dimensions_and_source_pngs_valid':True,'all_audio_formats_and_amplitudes_valid':True,'audio':audio,'visual_qa':'Exterior, interior, logo, winner, death, customer and living product inspected visually; contact sheet generated for remaining sprites. Audio file data validated; listening quality was not evaluated by this script.'}
(ROOT/'source_art/validation_report.json').write_text(json.dumps(report,indent=2)+'\n')
print(f'PASS: {len(manifest)} RGBA assets, preserved source PNGs, {len(audio)} PCM audio files. Contact sheet saved.')
