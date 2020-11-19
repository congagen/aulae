import boto3


class DynaDB(object):

    def __init__(self, table_name, primary_key, init_item_schema=None, init_item_key=""):
        self.primary_key = primary_key
        self.ddb = boto3.resource("dynamodb")
        self.table = self.ddb.Table(table_name)
        self.item_schema = init_item_schema

        if init_item_key != "" and init_item_schema != None:
            default_item_data = self.get_item(init_item_key)

            if "Item" not in default_item_data.keys():
                self.table.put_item(Item=init_item_schema)


    def get_item(self, item_key, initiate=True):
        item_data = self.table.get_item(
            Key={self.primary_key: item_key}
        )

        if "Item" not in item_data.keys() and initiate:
            if self.item_schema != None:
                self.table.put_item(Item=self.item_schema)

        r_data = self.table.get_item(
            Key={self.primary_key: item_key}
        )

        return r_data


    def put_item(self, item_data):
        try:
            put_response = self.table.put_item(Item=item_data)
            return put_response
        except Exception as e:
            return {"Error": str(e)}


    def update_item(self, p_key, item_data):
        try:
            update_response = self.table.delete_item(
                Key=p_key
            )
            self.put_item(item_data)

            return update_response
        except Exception as e:
            return {"Error": str(e)}