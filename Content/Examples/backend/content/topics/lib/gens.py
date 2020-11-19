import math
import random
import datetime


def rgb2hex(r, g, b):
    return "{:02x}{:02x}{:02x}".format(r, g, b)


def random_gif(item_count, distance=0, random_y=True, template={}):
    content = {}
    response = {}

    # o_info = "This is an animated gif with the default billboard orientation"

    demo_gifs = []

    for i in range(45):
        if i < 10:
            demo_gifs.append("https://s3.amazonaws.com/aulae-examples/sources/gifs/0" + str(i) + ".gif")
        else:
            demo_gifs.append("https://s3.amazonaws.com/aulae-examples/sources/gifs/" + str(i) + ".gif")


    for i in range(item_count):
        for y in range(-1, 2):

            x_pos = math.sin(((math.pi * 2) / item_count) * (i + 1))
            z_pos = math.cos(((math.pi * 2) / item_count) * (i + 1))

            random.seed()
            if distance < 1:
                distance = 3 #random.randint(int(len(item_list) * 0.25), int((len(item_list) * 1.1)))

            response[str(i)+"_"+str(y)] = {
                "name": "Gif " + str(i),
                "id":  str(int(random.random() * 1000)),
                "version": int(random.random() * 1000),
                "info": "",

                "type": "gif",
                "url": random.choice(demo_gifs),

                "world_position": False,
                "world_scale":    False,

                "content_link": "https://www.abstraqata.com/aulae",
                "chat_url": "https://suoccr4nm0.execute-api.us-east-1.amazonaws.com/dev",

                "x_pos": x_pos * distance,
                "y_pos": y     * distance,
                "z_pos": z_pos * distance
        }

    return response