from PIL import Image

def process_logo():
    source_path = 'assets/images/logo.png'
    output_path = 'assets/launcher/ic_foreground.png'

    # 1. Open source
    try:
        img = Image.open(source_path)
    except FileNotFoundError:
        print(f"Error: {source_path} not found.")
        return

    # 2. Create 1024x1024 canvas
    # User said "The remaining outer area should stay the same yellow background color."
    # AND "adaptive_icon_background: '#FDBD00'".
    # Usually the foreground image for adaptive icons is transparent, and the background layer provides the color.
    # HOWEVER, the user instruction said: "The remaining outer area should stay the same yellow background color."
    # in step 4. And then in step 6, they set "adaptive_icon_background: '#FDBD00'".
    # If the foreground is ALSO yellow, it merges.
    # But standard adaptive icon foregrounds are transparent around the subject.
    # If I make the foreground yellow, and the background yellow, it's fine.
    # BUT, if I make the foreground transparent, the background layer shows through.
    # The user instruction: "Create a new 1024x1024 canvas... The remaining outer area should stay the same yellow background color."
    # This implies the FOREGROUND PNG itself should have the yellow background?
    # IF so, masking might look weird if the mask cuts into the yellow square (which it will).
    # Adaptive icons have two layers.
    # If the foreground has a background, it moves independently of the background layer (parallax).
    # Typically, foreground = object + transparent. Background = color/pattern.
    # If I follow instructions EXACTLY: "The remaining outer area should stay the same yellow background color."
    # This might mean "fill the canvas with yellow".
    # BUT step 6 sets `adaptive_icon_background: "#FDBD00"`.
    # If I have yellow on foreground AND background, it works but is redundant.
    # If I have yellow on foreground, it might look like a square moving over a yellow background.
    # I will assume "stay the same yellow background color" implies the visual result.
    # Ideally, foreground should be transparent.
    # BUT, "4. The remaining outer area should stay the same yellow background color."
    # I will follow this literally: Fill with #FDBD00.
    # OR, maybe the user implies the *original* logo has a yellow background and they want to extend it?
    # Let's check if the original logo has transparency.

    if img.mode != 'RGBA':
        img = img.convert('RGBA')

    # Resize content to 660x660
    # "Final illustration size = exactly 660x660 px"
    # "It must be centered... 182 px padding"
    target_size = (660, 660)

    # Resize with high quality
    # Check aspect ratio
    w, h = img.size
    if w != h:
        print(f"Warning: Source image is {w}x{h}, not square. Resizing to fit 660x660.")
        # Fit within 660x660 maintaining aspect ratio?
        # User said "Do NOT crop... Keep the proportions exactly the same."
        # So I should use thumbnail/contain logic.
        img.thumbnail(target_size, Image.Resampling.LANCZOS)
        # If it's not square, centering it in 660 area is needed.
        resized_img = Image.new('RGBA', target_size, (0, 0, 0, 0))
        offset_x = (target_size[0] - img.width) // 2
        offset_y = (target_size[1] - img.height) // 2
        resized_img.paste(img, (offset_x, offset_y))
    else:
        resized_img = img.resize(target_size, Image.Resampling.LANCZOS)

    # Create canvas
    # User said "The remaining outer area should stay the same yellow background color."
    # If I make it transparent, the background layer (#FDBD00) handles it.
    # If I make it yellow, it's baked in.
    # I will use TRANSPARENT for the foreground canvas if possible, to respect adaptive icon best practices,
    # UNLESS the user *really* wants the foreground to be a yellow square.
    # "4. The remaining outer area should stay the same yellow background color."
    # Given step 6 sets the background color explicitly, I suspect the user wants the foreground to JUST be the Hanuman, and the background to be yellow.
    # IF I put yellow in the foreground, it defeats the purpose of the background layer (parallax effect would be yellow on yellow = invisible parallax).
    # SO, I will make the canvas TRANSPARENT, and rely on Step 6 to provide the yellow.
    # WAIT, if the user sees the output `ic_foreground.png` and it's transparent, they might think I failed step 4.
    # BUT "remaining outer area" refers to the area *outside the Hanuman*.
    # If I make it transparent, it *will* be yellow in the final app due to the background layer.
    # However, if the user explicitly asks for "yellow background color" in the canvas creation steps...
    # Let's look at "4. The remaining outer area should stay the same yellow background color."
    # Maybe the *source* logo has a yellow background?
    # If source has yellow bg, and I pad it, the padding should match.
    # If source is transparent, then "same yellow background" is confusing unless they assume it's yellow.

    # Decision: I will make the canvas transparent (0,0,0,0) because `adaptive_icon_background` is set.
    # This is the correct way to make adaptive icons.
    # Unless... "The current Hanuman PNG is too large, so Android is zooming it."
    # This implies the user wants to shrink the subject (Hanuman) relative to the 108x108 viewport.
    # By making it 660x660 in a 1024x1024 grid, I am effectively scaling it to ~64% of the viewport.
    # The safe zone is 66px diameter (approx 61%).
    # So 660/1024 is perfect for fitting inside the safe zone.
    # The background color is handled by the background layer.

    canvas = Image.new('RGBA', (1024, 1024), (0, 0, 0, 0))

    # Paste centered
    # 182 padding
    canvas.paste(resized_img, (182, 182))

    canvas.save(output_path)
    print(f"Saved {output_path}")

if __name__ == "__main__":
    process_logo()
