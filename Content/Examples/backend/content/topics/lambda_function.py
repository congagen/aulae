import json
import random
import time
import os
import pprint

from lib import gens
from lib import google
from lib import dynamo
from decimal import Decimal

CACHE_TIMEOUT = 300

# ------------------------------------------------------------------------------


def lambda_handler_proxy(event, context):
    # TODO implement
    response = {}
    response["isBase64Encoded"] = False
    response["statusCode"] = "200"
    response["body"] = str(event)

    # return source_search_response("test")

    if "path" in event.keys() and "body" in event.keys():
        s_term = event["path"][1:]

        r_body = {}

        if type(event["body"]) == dict:
            r_body = event["body"]

        if type(event["body"]) == str:
            r_body = json.loads(event["body"])

        response["body"] = str(api_source_response(s_term, r_body))

    return response


def demo_feed_response():
    rsp = {
        "id": "Demo Source A",
        "name": "Demo Source A",
        "info": "Random gifs",
        "version": random.randint(1, 99999),
        "updated_utx": 1,
        "content": gens.random_gif(10)
    }

    return rsp


def api_source_response(search_term, event):
    latlong = [event["lat"], event["lng"]]

    g = google.place_search("", search_term, latlong=latlong, radius="9999")

    rsp = {
        "id": search_term.capitalize(),
        "name": search_term.capitalize(),
        "info": "Topic Source",
        "version": 1,
        "updated_utx": 1,
        "content": google.format_response(g, search_term, 100)
    }

    return rsp


def get_cache(db_itm_key):
    resp_db = dynamo.DynaDB("aulae_cache", "cache_key")
    db_resp = resp_db.get_item(db_itm_key, False)
    print("Response:")
    print(db_resp)

    if "Item" in db_resp.keys():
        return db_resp["Item"]
    else:
        return {}


def store_cache(db_itm_key, itm_data):
    utx_stamp = int(time.time())

    itm_composite = {
        "cache_key": db_itm_key,
        "updated_utx": utx_stamp,
        "data": itm_data
    }

    formatted = json.loads(json.dumps(itm_composite), parse_float=Decimal)

    resp_db = dynamo.DynaDB("aulae_cache", "cache_key")
    db_resp = resp_db.put_item(formatted)
    print(db_resp)


def lambda_handler(event, context):
    if "sid" in event.keys() and "lat" in event.keys() and "lng" in event.keys() and "kwd" in event.keys():
        if event["kwd"] != "":
            db_itm_key = "ggl_places" + event["sid"] + event["kwd"]

            c = get_cache(db_itm_key)

            if len(c.keys()) > 0:
                print(int(time.time()) - int(c["updated_utx"]))
                if int(time.time()) - int(c["updated_utx"]) < CACHE_TIMEOUT:
                    print("Cached")
                    return c["data"]

            print("Fresh")
            itm_data = api_source_response(event["kwd"], event)
            store_cache(db_itm_key, itm_data)
            return itm_data

        else:

            rsp = {
                "id": "Demo Source A",
                "name": "Demo Source A",
                "info": "Random gifs",
                "version": random.randint(1, 99999),
                "updated_utx": 1,
                "content": gens.random_gif(4)
            }

            return rsp

    return {}


# pprint.pprint(lambda_handler({"sid":"", "lat":"", "lng":"", "kwd":""}, ""))
