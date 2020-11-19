import time
import pprint
import math
from lib import features


def lambda_handler(event, context):

    if "sid" in event.keys() and "lat" in event.keys() and "lng" in event.keys():
        source_info = "Demo source"

        lat = str(event["lat"]) if event["lat"] != "" else "0"
        lng = str(event["lng"]) if event["lng"] != "" else "0"

        itm_count = int(abs(math.sin(float(lat) + float(lng))) * 6) + 6

        if str(event["lat"]) == "0" and str(event["lng"]) == "0":
            source_info = "Please enable location sharing"
            response_content = {}
        else:
            a_content = features.asciimon_gen(itm_count, float(lat), float(lng))
            response_content = features.content_ring(lat, lng, a_content)

        response = {
            "name":        "Asciimon GO",    "info":        source_info,
            "id":          int(time.time()), "version":     int(time.time()),
            "updated_utx": int(time.time()), "content":     response_content
        }

        return response
    else:
        return {}


#if __name__ == "__main__":
#    r = lambda_handler({"lat": 43.4324, "lng": 12.546534, "sid": 1}, "")
#    pprint.pprint(r)
