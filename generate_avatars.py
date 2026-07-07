from PIL import Image
import colorsys

def shift_hue(image_path, output_path, target_hue):
    img = Image.open(image_path).convert('RGBA')
    data = img.getdata()
    new_data = []
    
    for item in data:
        r, g, b, a = item
        if a > 0:
            h, l, s = colorsys.rgb_to_hls(r/255.0, g/255.0, b/255.0)
            if s > 0.1: # Only tint colored parts, keep whites/blacks/grays
                r_new, g_new, b_new = colorsys.hls_to_rgb(target_hue, l, s)
                new_data.append((int(r_new*255), int(g_new*255), int(b_new*255), a))
            else:
                new_data.append(item)
        else:
            new_data.append(item)
            
    img.putdata(new_data)
    img.save(output_path)

# Yellow, Purple, Pink
shift_hue('assets/player.png', 'assets/player4.png', 0.16)
shift_hue('assets/player.png', 'assets/player5.png', 0.75)
shift_hue('assets/player.png', 'assets/player6.png', 0.90)
print("Avatars generated successfully.")
