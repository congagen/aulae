import botocore.vendored.requests as requests
import math


def color_from_name(place_name, l_count=1):
    # print(place_name[0])

    r = 0
    g = int(abs(math.sin(ord(place_name[0])) * 1.125678) * 100) + 150
    b = int(abs(math.cos(ord(place_name[0])) * 0.125678) * 100) + 150

    return "{:02x}{:02x}{:02x}".format(r, g, b)


def format_response(raw_resp, topic_string, r_limit):
    resp = {}

    for itm in raw_resp["results"][:r_limit]:
        # print(itm)
        resp[itm["name"]] = {}
        resp[itm["name"]]["name"] = itm["name"]
        resp[itm["name"]]["id"] = itm["name"]
        resp[itm["name"]]["version"] = 12345

        resp[itm["name"]]["type"] = "marker"
        resp[itm["name"]]["hex_color"] = "00ff0c"  # str(color_from_name(itm["name"] + "a"))

        resp[itm["name"]]["text"] = itm["name"][:1]

        resp[itm["name"]]["url"] = itm["icon"]
        resp[itm["name"]]["world_scale"] = True

        resp[itm["name"]]["scale"] = 1

        resp[itm["name"]]["lat"] = float(itm["geometry"]["location"]["lat"])
        resp[itm["name"]]["lng"] = float(itm["geometry"]["location"]["lng"])

        # https://www.google.com/maps/place/49.46800006494457,17.11514008755796"
        # resp[itm["name"]]["content_link"] = "http://www.google.com/maps/place/" + str(resp[itm["name"]]["lat"]) + "," + str(resp[itm["name"]]["lng"])

        # http://maps.apple.com/?q=Mexican+Restaurant&sll=50.894967,4.341626&z=10&t=s

        # rspo_a = "http://maps.apple.com/&sll="
        rspo_a = "http://maps.apple.com/?q=" + topic_string
        rspo_b = str(resp[itm["name"]]["lat"]) + "," + str(resp[itm["name"]]["lng"]) + "&z=2&t=s"

        resp[itm["name"]]["content_link"] = rspo_a + rspo_b

    return resp


def place_search(place_type, s_term, api_key="", latlong=["-33", "151"], radius="9999"):
    if api_key == "":
        api_key = "AIzaSyA8GPfpWc609N8zxfM0JR2fSMzSm5i1muM"

    url = "https://maps.googleapis.com/maps/api/place/nearbysearch/json?location="
    url += latlong[0] + "," + latlong[1]
    url += "&radius=" + radius + "&type=" + place_type + "&keyword=" + s_term
    url += "&key=" + api_key

    # print(url)
    # print(api_key)
    headers = {'X-Ios-Bundle-Identifier': 'com.abstraqata.aulae'}

    r = requests.get(url, headers=headers)
    x = r.json()
    y = x['results']

    return r.json()