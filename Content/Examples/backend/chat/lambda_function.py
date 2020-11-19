import random
import json
import boto3
import csv
import time
import math

from lib import router


def get_chatbot_content(payload):
    client = boto3.client('lambda')

    response = client.invoke(
        FunctionName='Abstrabot', InvocationType='Event', LogType='None',
        ClientContext='string', Payload=json.dumps(payload)
    )

    return response


def get_recipe(random_seed, item_count=2):
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



def lambda_handler(event, context):
    # TODO implement
    response = "?"
    a_id = ""

    if "chat_msg" in event.keys() and "sid" in event.keys():
        client_msg = event["chat_msg"].lower().replace("?", "").replace("!", "").replace(".", "").replace("/", "")
        client_msg_wlist = client_msg.lower().split(" ")
        client_msg_clean = " ".join(client_msg_wlist)

        if event["chat_msg"] == "":
            return {
                'statusCode': 200,
                'chat_response': "Greetings! This is just a demo but I do have some suggestions... \n\n" + "Swipe left on messages for options"
            }
        else:
            response = router.route(a_id, client_msg, client_msg_wlist)

            return {
                'statusCode': 200,
                'chat_response': a_id + response
            }


#la = lambda_handler({"chat_msg": "1564", "sid": "43242"}, "")
#print(la)