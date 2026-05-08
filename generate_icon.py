"""
Simple script to generate placeholder app icons for TalkNotify.
Requires: pip install Pillow
"""
import os

try:
    from PIL import Image, ImageDraw, ImageFont

    sizes = {
        'mipmap-mdpi': 48,
        'mipmap-hdpi': 72,
        'mipmap-xhdpi': 96,
        'mipmap-xxhdpi': 144,
        'mipmap-xxxhdpi': 192,
    }

    base = 'android/app/src/main/res'

    for folder, size in sizes.items():
        img = Image.new('RGB', (size, size), color=(33, 150, 243))  # Blue
        draw = ImageDraw.Draw(img)
        # Draw a simple mic circle
        margin = size // 6
        draw.ellipse([margin, margin, size - margin, size - margin], fill=(255, 255, 255))
        # Inner blue circle
        m2 = size // 3
        draw.ellipse([m2, m2, size - m2, size - m2], fill=(33, 150, 243))
        path = os.path.join(base, folder, 'ic_launcher.png')
        img.save(path)
        print(f'Created {path}')

    print('Icons generated successfully!')

except ImportError:
    # Pillow not available — copy a minimal valid PNG manually
    # This is a 1x1 blue pixel PNG (valid minimal PNG)
    import struct, zlib

    def create_png(width, height, color=(33, 150, 243)):
        def chunk(name, data):
            c = name + data
            return struct.pack('>I', len(data)) + c + struct.pack('>I', zlib.crc32(c) & 0xffffffff)

        signature = b'\x89PNG\r\n\x1a\n'
        ihdr_data = struct.pack('>IIBBBBB', width, height, 8, 2, 0, 0, 0)
        ihdr = chunk(b'IHDR', ihdr_data)

        raw_data = b''
        for _ in range(height):
            raw_data += b'\x00'
            for _ in range(width):
                raw_data += bytes(color)

        compressed = zlib.compress(raw_data)
        idat = chunk(b'IDAT', compressed)
        iend = chunk(b'IEND', b'')
        return signature + ihdr + idat + iend

    sizes = {
        'mipmap-mdpi': 48,
        'mipmap-hdpi': 72,
        'mipmap-xhdpi': 96,
        'mipmap-xxhdpi': 144,
        'mipmap-xxxhdpi': 192,
    }

    base = 'android/app/src/main/res'
    for folder, size in sizes.items():
        path = os.path.join(base, folder, 'ic_launcher.png')
        with open(path, 'wb') as f:
            f.write(create_png(size, size))
        print(f'Created {path}')

    print('Icons generated successfully!')
