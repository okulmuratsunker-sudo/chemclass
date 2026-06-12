from PIL import Image, ImageDraw, ImageFont

SIZE = 1024
FONT_PATH = "/mnt/skills/examples/canvas-design/canvas-fonts/BricolageGrotesque-Bold.ttf"

TEACHER_BG = (29, 78, 216)   # AppColors.primary #1D4ED8
STUDENT_BG = (22, 163, 74)   # AppColors.success #16A34A
WHITE = (255, 255, 255)


def draw_centered_text(draw, text, font, cy, fill=WHITE):
    bbox = draw.textbbox((0, 0), text, font=font)
    w = bbox[2] - bbox[0]
    h = bbox[3] - bbox[1]
    x = (SIZE - w) / 2 - bbox[0]
    y = cy - h / 2 - bbox[1]
    draw.text((x, y), text, font=font, fill=fill)
    return h


def make_icon(bg_color, subtitle, out_path):
    img = Image.new("RGB", (SIZE, SIZE), bg_color)
    draw = ImageDraw.Draw(img)

    cc_font = ImageFont.truetype(FONT_PATH, 460)

    if subtitle:
        draw_centered_text(draw, "C-C", cc_font, SIZE * 0.42)
        sub_font = ImageFont.truetype(FONT_PATH, 110)
        # add letter spacing manually
        spaced = " ".join(subtitle.upper())
        draw_centered_text(draw, spaced, sub_font, SIZE * 0.72)
    else:
        draw_centered_text(draw, "C-C", cc_font, SIZE * 0.5)

    img.save(out_path)


make_icon(TEACHER_BG, None, "/home/user/chemclass/apps/chemclass_flutter/assets/icon/icon_teacher.png")
make_icon(STUDENT_BG, "Student", "/home/user/chemclass/apps/chemclass_flutter/assets/icon/icon_student.png")
print("done")
