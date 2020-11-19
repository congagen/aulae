import math
import time
import random


def rgb2hex(r, g, b):
    return "{:02x}{:02x}{:02x}".format(r, g, b)


def asciimon_gen(item_count, lat, lng):
    rsp = []

    eyes   = "^ * ⊙ ◕ ♦ ♣ ♠ ♥ =".split(" ")
    mouths = "ω v ◡ ▿ ൠ ∀".split(" ")
    misc   = "✧ ₊︎ ๑ ˳".split(" ")

    roud_lat = int(float(lat) * 100)
    roud_lng = int(float(lng) * 100)
    comp_pos = roud_lat + roud_lng

    for x in range(item_count):

        random.seed(roud_lat)
        head_a = ''.join(map(str, random.sample(misc, 3)))

        random.seed(roud_lng * 12345)
        head_b = ''.join(map(str, random.sample(misc, 3)))

        eye   =   eyes[int(abs(math.sin(comp_pos * (x * 0.5))) * len(eyes))]
        mouth = mouths[int(abs(math.sin(comp_pos * (x * 0.5))) * len(mouths))]

        face  = eye + mouth + eye
        composite = head_a + face + head_b

        rsp.append(composite)

    return rsp


def demo_info(name, lat, long):
    random.seed(lat, long)

    stage     = "Stage: "   + str(random.randint(1, 10)) + "\n"
    a_type    = "Type: "    + str(random.randint(33, 340)) + "\n"
    origin    = "Origin: "  + str(int(lat) + int(long)) + "\n\n"

    power     = "Mood: "    + str(random.randint(50, 1000)) + "\n"
    abilitis  = "Energy: "  + str(random.randint(30, 43000)) + "\n\n"

    comp = stage + a_type + origin + power + abilitis

    return comp


def content_ring(lat, lng, item_list, distance=0, random_y=True):
    response = {}

    round_lat = int(float(lat) * 100)
    round_lng = int(float(lng) * 100)

    for i in range(len(item_list)):
        curr_itm = item_list[i]

        r = int(100 * abs(math.sin(round_lat)))
        b = int(100 * abs(math.sin(round_lng))) + 150
        obj_color = rgb2hex(r, 255-r, b)

        x_pos = math.sin(((3.14 * 2) / len(item_list)) * (i + 1))
        y_pos = 0 if not random_y else random.randint(-distance, distance)
        z_pos = math.cos(((3.14 * 2) / len(item_list)) * (i + 1))

        distance = len(item_list) if distance == 0 else distance
        obj_info = demo_info(curr_itm, round_lat * (i+1), round_lng * (i+1))

        response[str(i)] = {
            "name": curr_itm,
            "id": str(time.time()),
            "version": int(time.time()),

            "type": "text",
            "text": curr_itm,
            "hex_color": obj_color,

            "world_position": False,
            "world_scale": False,

            "info": obj_info,
            "content_link": "https://www.abstraqata.com/aulae",
            "chat_url": "https://suoccr4nm0.execute-api.us-east-1.amazonaws.com/dev",

            "x_pos": x_pos * distance,
            "y_pos": y_pos,
            "z_pos": z_pos * distance
        }

    return response
