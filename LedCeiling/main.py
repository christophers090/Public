import os
import cv2
import shutil
from PIL import Image, ImageSequence

def delete_all_files_and_folders(directory):
    for filename in os.listdir(directory):
        filepath = os.path.join(directory, filename)
        try:
            if os.path.isfile(filepath):
                os.unlink(filepath)
            elif os.path.isdir(filepath):
                shutil.rmtree(filepath)
        except Exception as e:
            print(f"Failed to delete {filepath}. Reason: {e}")


def scale_colors(r, g, b):
    if g == 0: g = 1  # Prevent division by zero
    if b == 0: b = 1  # Prevent division by zero

    red_to_green = r / g
    red_to_blue = r / b

    scaling_factor_green = (red_to_green / (red_to_green + 1)) ** 2  # Square to make it more aggressive
    scaling_factor_blue = (red_to_blue / (red_to_blue + 1)) ** 2     # Square to make it more aggressive

    new_g = int(g * (1 - scaling_factor_green))
    new_b = int(b * (1 - scaling_factor_blue))

    return r, new_g, new_b



def process_image(filepath, output_directory):

    image = Image.open(filepath)
    image = image.convert("RGB")
    # Get original dimensions
    orig_width, orig_height = image.size
    # Calculate dimensions for 1:2 aspect ratio crop
    new_width = orig_width
    new_height = int(orig_width / 2)

    # Calculate cropping box
    left = 0
    top = (orig_height - new_height) // 2
    right = orig_width
    bottom = (orig_height + new_height) // 2

    # Crop and resize the image
    image = image.crop((left, top, right, bottom))
    image = image.resize((155,48), Image.LANCZOS)

    rgb_data = []
    for y in range(48):  # Height
        for x in range(155):  # Width
            pixel = image.getpixel((x, y))
            # Use the scale_colors function to adjust the pixel values
            new_pixel = scale_colors(pixel[0], pixel[1], pixel[2])

            rgb_data.append(new_pixel)  # new_pixel is a tuple (R, G, B)

    filename = os.path.basename(filepath)
    save_path_sample = os.path.join(output_directory, 'SAMPLE/IMAGES', filename)

    unique_folder = os.path.join(output_directory, 'TXT', filename)  # Unique folder for this image

    # Create the unique folder if it doesn't exist
    os.makedirs(unique_folder, exist_ok=True)


    save_path_output = os.path.join(unique_folder, "0")


    with open(f"{save_path_output}.txt", "w") as f:
        for pixel in rgb_data:
            f.write(f"{pixel[0]},{pixel[1]},{pixel[2]}\n")

    image.save(save_path_sample, "JPEG")

def process_video(filepath, output_directory):
    # Initialize video capture
    cap = cv2.VideoCapture(filepath)

    # Get video properties
    orig_width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
    orig_height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
    fps = int(cap.get(cv2.CAP_PROP_FPS))

    # Calculate cropping box to get the middle 1/2 of the video
    x1 = int(orig_width * 0.25)
    x2 = int(orig_width * 0.75)
    y1 = int(orig_height * 0.25)
    y2 = int(orig_height * 0.75)

    # Initialize video writer
    fourcc = cv2.VideoWriter_fourcc(*'mp4v')
    filename = os.path.basename(filepath).split('.')[0]
    save_path_sample = os.path.join(output_directory, 'SAMPLE/ANIMATION', filename)
    save_path_output_base = os.path.join(output_directory, 'TXT', filename)
    os.makedirs(save_path_output_base, exist_ok=True)

    out = cv2.VideoWriter(save_path_sample + '.mp4', fourcc, fps, (155, 48))

    frame_idx = 0  # Initialize frame index

    while True:
        ret, frame = cap.read()
        if not ret:
            break

        # Crop the middle 1/2 of the frame
        cropped_frame = frame[y1:y2, x1:x2]

        # Resize frame
        resized_frame = cv2.resize(cropped_frame, (155, 48), interpolation=cv2.INTER_LANCZOS4)

        # Process RGB data
        frame_rgb_data = []
        for y in range(48):
            for x in range(155):
                pixel = resized_frame[y, x]
                frame_rgb_data.append((pixel[2], pixel[1], pixel[0]))  # OpenCV uses BGR

        # Save RGB data to text file
        frame_text_path = os.path.join(save_path_output_base, f"{frame_idx}.txt")
        with open(frame_text_path, "w") as f:
            for pixel in frame_rgb_data:
                f.write(f"{pixel[0]},{pixel[1]},{pixel[2]}\n")

        # Write frame to new video
        out.write(resized_frame)

        frame_idx += 1  # Increment the frame index

    # Release video objects
    cap.release()
    out.release()





def process_gif(input_filepath, output_directory):
    # Open the original GIF
    image = Image.open(input_filepath)

    # Initialize a list to hold processed frames
    processed_frames = []

    # Loop through each frame in the GIF
    for frame in ImageSequence.Iterator(image):

        orig_width, orig_height = image.size

        new_width = orig_width
        new_height = int(orig_width / 2)

        # Calculate cropping box
        left = 0
        top = (orig_height - new_height) // 2
        right = orig_width
        bottom = (orig_height + new_height) // 2

        frame = frame.crop((left, top, right, bottom))
        new_frame = frame.resize((155,48), Image.LANCZOS)

        # Inside the for loop in process_gif function
        frame_rgb_data = []
        for y in range(48):  # Height
            for x in range(155):  # Width
                pixel = new_frame.getpixel((x, y))
                if isinstance(pixel, int):  # Check if pixel is an integer
                    pixel = (pixel, pixel, pixel)  # Convert to tuple
                frame_rgb_data.append(pixel)

        save_path_output = os.path.join(output_directory, 'TXT', filename)

        with open(f"{save_path_output}_rgb.txt", "a") as f:
            for pixel in frame_rgb_data:
                f.write(f"{pixel[0]},{pixel[1]},{pixel[2]}\n")


        # Append the processed frame to the list
        processed_frames.append(new_frame)

    save_path_sample = os.path.join(output_directory, 'SAMPLE/IMAGES', filename)
    processed_frames[0].save(save_path_sample, format="GIF", save_all=True, append_images=processed_frames[1:])


def zero_padded(x):
    return f"{x:03}"

import os

def packRGB(r, g, b):
    # Assuming the function for packing RGB values is defined
    # This is a placeholder; replace with your actual function
    return r << 16 | g << 8 | b

def generate_folder_path(frame_counter):
    tens = frame_counter // 10 % 10
    hundreds = frame_counter // 100 % 10
    thousands = frame_counter // 1000 % 10
    tenthousands = frame_counter // 10000 % 10
    return os.path.join("TTH" + str(tenthousands), "TH" + str(thousands), "H" + str(hundreds), "T" + str(tens))


def slicer(input_directory, output_directory):
    animation_counter = 0
    frames_txt_filepath = os.path.join(output_directory, 'animations', 'frames.txt')

    if not os.path.exists(frames_txt_filepath):
        with open(frames_txt_filepath, 'w') as f_init:
            pass

    for subdir_name in os.listdir(input_directory):
        subdir_path = os.path.join(input_directory, subdir_name)

        if os.path.isdir(subdir_path):
            animation_number = animation_counter
            new_animation_folder_base = os.path.join(output_directory, 'animations', f"A{animation_number}")
            os.makedirs(new_animation_folder_base, exist_ok=True)

            frame_counter = 0

            while True:
                frame_filename = f"{frame_counter}.txt"
                frame_path = os.path.join(subdir_path, frame_filename)

                if os.path.exists(frame_path):
                    folder_path = generate_folder_path(frame_counter)
                    new_animation_folder = os.path.join(new_animation_folder_base, folder_path)
                    os.makedirs(new_animation_folder, exist_ok=True)
                    concatenated_data = bytearray()
                    text_data = []

                    with open(frame_path, 'r') as f:
                        lines = f.readlines()

                    for super_strip in range(48):
                        # Reverse super strips within each group of 8
                        remapped_super_strip = (super_strip // 8) * 8 + (7 - (super_strip % 8))

                        row = remapped_super_strip
                        cut_start = (row * 155)
                        cut_end = cut_start + 155

                        segment = lines[cut_start:cut_end]
                        segment.reverse()

                        for line in segment:
                            r, g, b = map(int, line.strip().split(','))
                            packed = packRGB(r, g, b)
                            concatenated_data.extend(packed.to_bytes(3, 'big'))

                            text_data.append(f"{r} {g} {b}")

                    # Save binary data
                    output_filepath = os.path.join(new_animation_folder, f"F{frame_counter}.bin")
                    with open(output_filepath, 'wb') as f_out:
                        f_out.write(concatenated_data)

                    frame_counter += 1
                else:
                    break

            with open(frames_txt_filepath, 'a') as frames_txt:
                frames_txt.write(f"{frame_counter}\n")

            animation_counter += 1


SKY_Input_directory = '/Users/chrissheehan/Desktop/SKY/INPUT'
SKY_Text_in = '/Users/chrissheehan/Desktop/SKY/TXT'
SKY_out_directory = '/Users/chrissheehan/Desktop/SKY'

# Loop through all files in the directory

delete_all_files_and_folders("/Users/chrissheehan/Desktop/SKY/animations")
delete_all_files_and_folders("/Users/chrissheehan/Desktop/SKY/TXT")
delete_all_files_and_folders("/Users/chrissheehan/Desktop/SKY/SAMPLE/ANIMATION")
delete_all_files_and_folders("/Users/chrissheehan/Desktop/SKY/SAMPLE/IMAGES")


for filename in os.listdir(SKY_Input_directory):
    filepath = os.path.join(SKY_Input_directory, filename)

    if filename.endswith('.jpeg') or filename.endswith('.jpg') or filename.endswith('.png'):
        process_image(filepath, SKY_out_directory)

    elif filename.endswith('.mp4') or filename.endswith('.mov'):
        process_video(filepath, SKY_out_directory)

    elif filename.endswith('.gif'):
        process_gif(filepath, SKY_out_directory)

# Loop through all text files in the directory
slicer("/Users/chrissheehan/Desktop/SKY/TXT", SKY_out_directory)
