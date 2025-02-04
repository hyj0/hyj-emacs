import sys
import os
import types

import mysql.connector
from mysql.connector import Error
import json
import datetime

def db_fetch_data(self, connection, query):
    import datetime
    import decimal
    connection.ping (reconnect=True)
    if not connection.is_connected ():
        raise "connect loss"
    cursor = connection.cursor()
    cursor.execute(query)

    if not cursor.description:
        # update ,
        connection.commit ()
        rowcount = cursor.rowcount
        cursor.close ()
        return ["rowcount", [{"rowcount": rowcount}]]

    field_names = tuple([i[0] for i in cursor.description])
    res = []
    results = cursor.fetchall()
    for row in results:
        formatted_row = {}
        for idx in range (len (row)) :
            item = row [idx]
            if isinstance(item, datetime.datetime):
                formatted_item = item.strftime('%Y-%m-%d %H:%M:%S')
                formatted_row [field_names [idx]] =  formatted_item
            elif isinstance (item, decimal.Decimal):
                formatted_row [field_names [idx]] = float (item)
            elif isinstance (item, datetime.date):
                formatted_item = item.strftime('%Y-%m-%d')
                formatted_row [field_names [idx]] =  formatted_item
            else:
                formatted_row [field_names [idx]] =  item
        res.append(formatted_row)
    cursor.close()
    return [field_names, tuple(res)]
def db_query (self):
    import traceback
    import json
    result_data = {
        "code": -1,
        "msg":"",
        "data": {}
    }
    f = open("/tmp/db_result.json", "w")
    f.write(json.dumps (result_data, indent=4))
    f.close ()
    key = get_emacs_var ("*db_key*")
    sql = get_emacs_var ("*db_sql*")
    print (key, sql)
    try:
        field_names,result = self.db_fetch_data (self.database [key], sql)
    except Exception as e:
        result_data ["msg"] = repr (e)
        result_data ["msg"] = traceback.format_exc ()
        set_emacs_var ("*db_result*", json.dumps (result_data, indent=4))
        f = open("/tmp/db_result.json", "w")
        f.write(json.dumps (result_data, indent=4))
        f.close ()
        traceback.print_exc ()
        return

    result_data = {
               "code": 0,
               "msg":"",
               "data": {"field_names": field_names,
                        "rows": result}
               }

    set_emacs_var ("*db_result*", json.dumps (result_data, indent=4))
    f = open("/tmp/db_result.json", "w")
    f.write(json.dumps (result_data, indent=4))
    f.flush ()
    f.close ()
    print("sql query ok! count=%d" % (len(result),))
if False:
    conn = mysql.connector.connect ()
    conn.is_connected ()
    conn.ping (reconnect=True)

if True:
    self.db_fetch_data = types.MethodType (db_fetch_data,  self)
    self.db_query = types.MethodType (db_query,  self)
    if not hasattr (self, 'database'):
        self.database = {}
    message_to_emacs ("database ok")
