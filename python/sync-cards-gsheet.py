#!/usr/bin/env python3

import json
import sys

import gspread

if __name__ == "__main__":
    key = sys.argv[1]
    sheet = sys.argv[2]
    gc = gspread.service_account()
    CONSEQUENCES = "10t0OzEWHRAJ8D84j-clgkAbbtjnCdQNXn_sqWWqbo1I"
    GENERAL_WOUNDS = "General Wounds"
    spreadsheet = gc.open_by_key(key)
    worksheet = spreadsheet.worksheet(sheet)
    data = worksheet.get_all_records()
    print(json.dumps(data))
