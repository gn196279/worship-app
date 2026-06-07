from PIL import Image, ImageDraw
import os, re

def make_icon(size, radius=0.2):
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    bg = (0xEC, 0xC8, 0x13, 255)
    fg = (0x1B, 0x19, 0x0D, 255)
    r = int(size * radius)
    draw.rounded_rectangle([(0,0),(size, size)], radius=r, fill=bg)
    head_r = int(size * 0.10)
    head_cx = int(size * 0.46)
    head_cy = int(size * 0.60)
    draw.ellipse((head_cx-head_r, head_cy-head_r, head_cx+head_r, head_cy+head_r), fill=fg)
    stem_w = int(size * 0.06)
    stem_h = int(size * 0.38)
    stem_x = head_cx + head_r - int(stem_w/2)
    stem_y = head_cy - int(stem_h*0.85)
    draw.rectangle((stem_x, stem_y, stem_x+stem_w, stem_y+stem_h), fill=fg)
    flag_w = int(size * 0.22)
    flag_h = int(size * 0.10)
    flag_x = stem_x + stem_w - int(size*0.01)
    flag_y = stem_y
    draw.rounded_rectangle((flag_x, flag_y, flag_x+flag_w, flag_y+flag_h), radius=int(flag_h/2), fill=fg)
    return img

base = make_icon(1024, radius=0.22)
base.save('assets_style1_icon_1024.png')

android_sizes = {
    'mdpi':48,
    'hdpi':72,
    'xhdpi':96,
    'xxhdpi':144,
    'xxxhdpi':192,
}
for density, size in android_sizes.items():
    path = f'android/app/src/main/res/mipmap-{density}/ic_launcher.png'
    os.makedirs(os.path.dirname(path), exist_ok=True)
    base.resize((size, size), Image.LANCZOS).save(path)

# iOS app icon sizes based on filenames
ios_dir = 'ios/Runner/Assets.xcassets/AppIcon.appiconset'
if os.path.isdir(ios_dir):
    for name in os.listdir(ios_dir):
        if not name.lower().endswith('.png'):
            continue
        m = re.search(r'(\d+)(?:\.(\d+))?x(\d+)(?:\.(\d+))?@?(\dx)?', name)
        if m:
            w = float(m.group(1) + ('.' + m.group(2) if m.group(2) else ''))
            scale = 1
            if m.group(5):
                scale = int(m.group(5)[0])
            size = int(round(w * scale))
            out = base.resize((size, size), Image.LANCZOS)
            out.save(os.path.join(ios_dir, name))

# iOS launch images
launch_dir = 'ios/Runner/Assets.xcassets/LaunchImage.imageset'
if os.path.isdir(launch_dir):
    for name in os.listdir(launch_dir):
        if not name.lower().endswith('.png'):
            continue
        size = 1200
        if '@2x' in name:
            size = 1600
        if '@3x' in name:
            size = 2400
        bg = Image.new('RGBA', (size, size), (0xF8, 0xF8, 0xF6, 255))
        icon = base.resize((int(size*0.35), int(size*0.35)), Image.LANCZOS)
        x = (size - icon.size[0])//2
        y = (size - icon.size[1])//2
        bg.paste(icon, (x, y), icon)
        bg.save(os.path.join(launch_dir, name))

# Web icons
web_icons = {
    'web/icons/Icon-192.png':192,
    'web/icons/Icon-512.png':512,
    'web/icons/Icon-maskable-192.png':192,
    'web/icons/Icon-maskable-512.png':512,
    'web/favicon.png':48,
}
for path, size in web_icons.items():
    os.makedirs(os.path.dirname(path), exist_ok=True)
    base.resize((size, size), Image.LANCZOS).save(path)

# macOS icons
mac_dir = 'macos/Runner/Assets.xcassets/AppIcon.appiconset'
if os.path.isdir(mac_dir):
    for name in os.listdir(mac_dir):
        if not name.lower().endswith('.png'):
            continue
        m = re.search(r'(\d+)', name)
        if m:
            size = int(m.group(1))
            base.resize((size, size), Image.LANCZOS).save(os.path.join(mac_dir, name))

print('Generated style1 icons.')
