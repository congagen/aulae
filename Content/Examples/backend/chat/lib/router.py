import random
import time
import math


def agent_info(topic="misc"):
    response = "X:" + str(random.randint(1, 1000)) + " Y:" + str(random.randint(1, 1000)) + " Z:" + str(
        random.randint(1, 1000)
    )
    return response


def app_info():
    pass


def smalltalk():
    pass


def menu():

    a = "Info: \n    /agent\n    /aulae"
    b = "Inspo: \n    /color\n    /shapes\n    /space"

    return a + "\n\n" + b

print(menu())


def instrument_suggestion(random_seed, item_count=2):
    random.seed(random_seed)

    objects = ["Sun Catchers", "Air Mallets", "Singing Pyramids", "Piezo Mics", "Bell Plates", "Wobble boards",
               "Aeolian Harps", "Diverging Mirrors", "Air Cymbals", "Solenoids", "Dome Mirrors"]

    ops = [" ^ ", " * ", " + ", " - ", " / "]
    obj_v = random.sample(objects, 2)

    rt_str = ""

    for i in range(len(obj_v)):
        rt_str += obj_v[i]
        if i != len(obj_v) - 1:
            rt_str += random.choice(ops)

    return rt_str


def route(a_id, client_msg, client_msg_wlist):


    response = instrument_suggestion(random_seed=client_msg) + "?"

    if len(set(client_msg_wlist).intersection(["file formats", "supported file formats"])) > 0:
        a = "Aulae supports the following file formats: \n\n"
        b = "Images:    JPG (1:1), PNG (1:1) \n"
        c = "Animation: GIF (1:1), USDZ \n"
        d = "3D-Models: USDZ  \n"
        e = "Audio:     Mp3  \n"

        return a + b + c + d + e


    if len(set(client_msg_wlist).intersection(["where", "you"])) > 1:
        random.seed()
        response = "X:" + str(random.randint(1, 1000)) + " Y:" + str(random.randint(1, 1000)) + " Z:" + str(
            random.randint(1, 1000)
        )

    if len(set(client_msg_wlist).intersection(["hi", "hello", "hiya", "yo"])) > 0:
        gre = ["Greetings!", "Hello!", "Saluton!"]
        response = random.choice(gre)

    if len(set(client_msg_wlist).intersection(["shape", "/shape"])) > 0:
        print("OK")
        random.seed(time.time())
        sl_a = ["Rhombic", "Triangular", "Spherical", "Globular", "Recursive"]
        sl_b = ["Triacontahedron", "Tetrahedron", "Cube", "Hexagon", "Icosahedron", "Circle", "Sierpinski"]
        l = [[random.randint(1, 100), random.randint(1, 100), random.randint(1, 100)] for i in range(10)]
        response = random.choice(sl_a) + " " + random.choice(sl_b)

    if len(set(client_msg_wlist).intersection(["inspo", "/inspo", "assignment", "task"])) > 0:
        ops = [" ^ ", " * ", " + ", " - ", " / "]

        objs = [
            "Sun Catchers", "Air Mallets", "Singing Pyramids", "Piezo Mics", "Bell Plates", "Wobble boards",
            "Aeolian Harps", "Diverging Mirrors", "Air Cymbals", "Solenoids", "Dome Mirrors"
        ]
        obj_v = random.sample(objs, 7)
        rt_str = ""

        for i in range(len(obj_v)):
            rt_str += obj_v[i]
            if i != len(obj_v) - 1:
                rt_str += random.choice(ops)

        return str(rt_str)

    if len(set(client_msg_wlist).intersection(["color", "/color"])) > 0:
        c_dct = {}
        colors = ['Absolute Zero: #0048BA', 'Acid green: #B0BF1A', 'Aero: #7CB9E8', 'Aero blue: #C9FFE5',
                  'Alabaster: #EDEAE0', 'Alice blue: #F0F8FF', 'Alloy orange: #C46210', 'Almond: #EFDECD',
                  'Amaranth: #E52B50', 'Amaranth (M&P): #9F2B68', 'Amaranth pink: #F19CBB', 'Amaranth purple: #AB274F',
                  'Amaranth red: #D3212D', 'Amazon: #3B7A57', 'Amber: #FFBF00', 'Amber (SAE/ECE): #FF7E00',
                  'Amethyst: #9966CC', 'Android green: #A4C639', 'Ao (English): #008000', 'Apple green: #8DB600',
                  'Apricot: #FBCEB1', 'Aqua: #00FFFF', 'Aquamarine: #7FFFD4', 'Arctic lime: #D0FF14',
                  'Army green: #4B5320', 'Artichoke: #8F9779', 'Arylide yellow: #E9D66B', 'Ash gray: #B2BEB5',
                  'Asparagus: #87A96B', 'Atomic tangerine: #FF9966', 'Auburn: #A52A2A', 'Aureolin: #FDEE00',
                  'Avocado: #568203', 'Azure: #007FFF', 'Azure (X11/web color): #F0FFFF', 'Baby blue: #89CFF0',
                  'Baby blue eyes: #A1CAF1', 'Baby pink: #F4C2C2', 'Baby powder: #FEFEFA', 'Baker-Miller pink: #FF91AF',
                  'Banana Mania: #FAE7B5', 'Barbie Pink: #DA1884', 'Barn red: #7C0A02', 'Battleship grey: #848482',
                  'Beau blue: #BCD4E6', 'Beaver: #9F8170', "B'dazzled blue: #2E5894", 'Big dip o’ruby: #9C2542',
                  'Bisque: #FFE4C4', 'Black: #000000', 'Black bean: #3D0C02', 'Black chocolate: #1B1811',
                  'Black coffee: #3B2F2F', 'Black coral: #54626F', 'Black olive: #3B3C36', 'Black Shadows: #BFAFB2',
                  'Blanched almond: #FFEBCD', 'Blast-off bronze: #A57164', 'Bleu de France: #318CE7',
                  'Blizzard blue: #ACE5EE', 'Blond: #FAF0BE', 'Blood red: #660000', 'Blue: #0000FF',
                  'Blue (Crayola): #1F75FE', 'Blue (Munsell): #0093AF', 'Blue (NCS): #0087BD',
                  'Blue (Pantone): #0018A8', 'Blue (pigment): #333399', 'Blue (RYB): #0247FE', 'Blue bell: #A2A2D0',
                  'Blue-gray: #6699CC', 'Blue-green: #0D98BA', 'Blue-green (color wheel): #064E40',
                  'Blue sapphire: #126180', 'Blue-violet: #8A2BE2', 'Blue-violet (Crayola): #7366BD',
                  'Blue-violet (color wheel): #4D1A7F', 'Blue yonder: #5072A7', 'Yin Min Blue: #3C69E7',
                  'Blush: #DE5D83', 'Bole: #79443B', 'Bone: #E3DAC9', 'Bottle green: #006A4E', 'Brandy: #87413F',
                  'Brick red: #CB4154', 'Bright green: #66FF00', 'Bright lilac: #D891EF', 'Bright maroon: #C32148',
                  'Bright navy blue: #1974D2', 'Bright yellow (Crayola): #FFAA1D', 'Brilliant rose: #FF55A3',
                  'Brink pink: #FB607F', 'British racing green: #004225', 'Bronze: #CD7F32', 'Brunswick green: #1B4D3E',
                  'Bud green: #7BB661', 'Burgundy: #800020', 'Burlywood: #DEB887', 'Byzantine: #BD33A4',
                  'Byzantium: #702963', 'Cadet: #536872', 'Cadet blue: #5F9EA0', 'Cadet blue (Crayola): #A9B2C3',
                  'Cadet grey: #91A3B0', 'Cadmium green: #006B3C', 'Cadmium orange: #ED872D', 'Cadmium red: #E30022',
                  'Cadmium yellow: #FFF600', 'Café au lait: #A67B5B', 'Café noir: #4B3621', 'Cambridge blue: #A3C1AD',
                  'Camel: #C19A6B', 'Cameo pink: #EFBBCC', 'Canary: #FFFF99', 'Canary yellow: #FFEF00',
                  'Candy apple red: #FF0800', 'Candy pink: #E4717A', 'Capri: #00BFFF', 'Caput mortuum: #592720',
                  'Cardinal: #C41E3A', 'Caribbean green: #00CC99', 'Carmine: #960018', 'Carmine (M&P): #D70040',
                  'Carnation pink: #FFA6C9', 'Carnelian: #B31B1B', 'Carolina blue: #56A0D3', 'Carrot orange: #ED9121',
                  'Castleton green: #00563F', 'Catawba: #703642', 'Cedar Chest: #C95A49', 'Celadon: #ACE1AF',
                  'Celadon blue: #007BA7', 'Celadon green: #2F847C', 'Celeste: #B2FFFF', 'Celtic blue: #246BCE',
                  'Cerise: #DE3163', 'Cerulean: #007BA7', 'Cerulean blue: #2A52BE', 'Cerulean frost: #6D9BC3',
                  'Cerulean (Crayola): #1DACD6', 'CG blue: #007AA5', 'CG red: #E03C31', 'Champagne: #F7E7CE',
                  'Champagne pink: #F1DDCF', 'Charcoal: #36454F', 'Charleston green: #232B2B', 'Charm pink: #E68FAC',
                  'Chartreuse (traditional): #DFFF00', 'Chartreuse (web): #7FFF00', 'Cherry blossom pink: #FFB7C5',
                  'Chestnut: #954535', 'China pink: #DE6FA1', 'China rose: #A8516E', 'Chinese red: #AA381E',
                  'Chinese violet: #856088', 'Chinese yellow: #FFB200', 'Chocolate (traditional): #7B3F00',
                  'Chocolate (web): #D2691E', 'Chrome yellow: #FFA700', 'Cinereous: #98817B', 'Cinnabar: #E34234',
                  'Cinnamon Satin: #CD607E', 'Citrine: #E4D00A', 'Citron: #9FA91F', 'Claret: #7F1734',
                  'Cobalt blue: #0047AB', 'Coffee: #6F4E37', 'Columbia Blue: #B9D9EB', 'Congo pink: #F88379',
                  'Cool grey: #8C92AC', 'Coquelicot: #FF3800', 'Coral: #FF7F50', 'Coral pink: #F88379',
                  'Cordovan: #893F45', 'Corn: #FBEC5D', 'Cornflower blue: #6495ED', 'Cornsilk: #FFF8DC',
                  'Cosmic cobalt: #2E2D88', 'Cosmic latte: #FFF8E7', 'Cotton candy: #FFBCD9', 'Cream: #FFFDD0',
                  'Crimson: #DC143C', 'Crimson (UA): #9E1B32', 'Cultured: #F5F5F5', 'Cyan: #00FFFF',
                  'Cyan (process): #00B7EB', 'Cyber grape: #58427C', 'Cyber yellow: #FFD300', 'Cyclamen: #F56FA1',
                  'Dartmouth green: #00703C', "Davy's grey: #555555", 'Deep cerise: #DA3287', 'Deep champagne: #FAD6A5',
                  'Deep chestnut: #B94E48', 'Deep jungle green: #004B49', 'Deep pink: #FF1493', 'Deep saffron: #FF9933',
                  'Deep sky blue: #00BFFF', 'Deep Space Sparkle: #4A646C', 'Deep taupe: #7E5E60', 'Denim: #1560BD',
                  'Denim blue: #2243B6', 'Desert: #C19A6B', 'Desert sand: #EDC9AF', 'Dim gray: #696969',
                  'Dodger blue: #1E90FF', 'Dogwood rose: #D71868', 'Drab: #967117', 'Duke blue: #00009C',
                  'Dutch white: #EFDFBB', 'Earth yellow: #E1A95F', 'Ebony: #555D50', 'Ecru: #C2B280',
                  'Eerie black: #1B1B1B', 'Eggplant: #614051', 'Eggshell: #F0EAD6', 'Egyptian blue: #1034A6',
                  'Electric blue: #7DF9FF', 'Electric green: #00FF00', 'Electric indigo: #6F00FF',
                  'Electric lime: #CCFF00', 'Electric purple: #BF00FF', 'Electric violet: #8F00FF', 'Emerald: #50C878',
                  'Eminence: #6C3082', 'English green: #1B4D3E', 'English lavender: #B48395', 'English red: #AB4B52',
                  'English vermillion: #CC474B', 'English violet: #563C5C', 'Erin: #00FF40', 'Eton blue: #96C8A2',
                  'Fallow: #C19A6B', 'Falu red: #801818', 'Fandango: #B53389', 'Fandango pink: #DE5285',
                  'Fashion fuchsia: #F400A1', 'Fawn: #E5AA70', 'Feldgrau: #4D5D53', 'Fern green: #4F7942',
                  'Field drab: #6C541E', 'Fiery rose: #FF5470', 'Firebrick: #B22222', 'Fire engine red: #CE2029',
                  'Fire opal: #E95C4B', 'Flame: #E25822', 'Flax: #EEDC82', 'Flickr Blue: #0063dc',
                  'Flickr Pink: #FB0081', 'Flirt: #A2006D', 'Floral white: #FFFAF0', 'Fluorescent blue: #15F4EE',
                  'Forest green (Crayola): #5FA777', 'Forest green (traditional): #014421',
                  'Forest green (web): #228B22', 'French blue: #0072BB', 'French fuchsia: #FD3F92',
                  'French lilac: #86608E', 'French lime: #9EFD38', 'French mauve: #D473D4', 'French pink: #FD6C9E',
                  'French raspberry: #C72C48', 'French rose: #F64A8A', 'French sky blue: #77B5FE',
                  'French violet: #8806CE', 'Frostbite: #E936A7', 'Fuchsia: #FF00FF', 'Fuchsia (Crayola): #C154C1',
                  'Fuchsia purple: #CC397B', 'Fuchsia rose: #C74375', 'Fulvous: #E48400', 'Fuzzy Wuzzy: #CC6666']

        random.seed(int(time.time()) * math.pi)
        response = random.choice(colors)

    if len(set(client_msg_wlist).intersection(["who", "you"])) > 1:
        random.seed()
        response = "Demobot #" + str(random.randint(1, 9999999))

    # if len(set(client_msg_wlist).intersection(["help", "menu", "help"])) > 0:
    #    response = "/color \n/inspo"

    return response