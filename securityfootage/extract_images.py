import re

# Path to the saved video stream file
input_file = 'video.mjpeg'

# Read the binary content
data = open(input_file, 'rb').read()

# Find all JPEGs (start FF D8 ... end FF D9)
matches = [m for m in re.finditer(b'\xff\xd8.*?\xff\xd9', data, re.DOTALL)]

# Extract each found image
for i, m in enumerate(matches):
    with open(f'image_{i}.jpg', 'wb') as f:
        f.write(m.group(0))

print(f'Extracted {len(matches)} images.')
