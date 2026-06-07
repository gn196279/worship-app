from PIL import Image, ImageDraw, ImageChops

size = 256
img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
draw = ImageDraw.Draw(img)

# Google colors
blue = (66, 133, 244, 255)
red = (219, 68, 55, 255)
yellow = (244, 180, 0, 255)
green = (15, 157, 88, 255)

margin = int(size * 0.12)
thickness = int(size * 0.18)
box = [margin, margin, size - margin, size - margin]

# arcs (degrees: 0 at 3 o'clock, CCW)
# Red (top-left)
draw.arc(box, start=45, end=135, fill=red, width=thickness)
# Yellow (bottom-left)
draw.arc(box, start=135, end=225, fill=yellow, width=thickness)
# Green (bottom-right)
draw.arc(box, start=225, end=315, fill=green, width=thickness)
# Blue (top-right) split
# 315->360
if True:
    draw.arc(box, start=315, end=360, fill=blue, width=thickness)
    draw.arc(box, start=0, end=45, fill=blue, width=thickness)

# Blue bar to make G
bar_width = int(size * 0.28)
bar_height = thickness
bar_x = size // 2
bar_y = size // 2 - bar_height // 2

draw.rectangle([bar_x, bar_y, bar_x + bar_width, bar_y + bar_height], fill=blue)

# Cut inner circle to create ring
inner_margin = margin + thickness
inner_box = [inner_margin, inner_margin, size - inner_margin, size - inner_margin]
mask = Image.new('L', (size, size), 0)
mask_draw = ImageDraw.Draw(mask)
mask_draw.ellipse(inner_box, fill=255)
alpha = img.split()[-1]
alpha = ImageChops.subtract(alpha, mask)
img.putalpha(alpha)

# Repaint bar over cutout
img2 = img.copy()
draw2 = ImageDraw.Draw(img2)
draw2.rectangle([bar_x, bar_y, bar_x + bar_width, bar_y + bar_height], fill=blue)

img2.save('assets/google_g.png')
print('Generated assets/google_g.png')
