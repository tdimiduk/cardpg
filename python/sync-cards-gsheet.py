#!/usr/bin/env python3

from collections.abc import Callable
from dataclasses import dataclass, field
from itertools import zip_longest
from typing import TypeVar

from google.oauth2 import service_account
from googleapiclient.discovery import build

T = TypeVar("T")

type Input = dict[str, str | None]

type CardParser[T] = Callable[[Input], T]

@dataclass
class DeckSpec[T]:
    t: type[T]
    spreadsheet_id: str
    sheet_range: str
    parse: None | CardParser[T] = None


def get_deck(s: DeckSpec[T], credentials_file: str) -> list[T]:
    values = read_sheet_data(credentials_file, s.spreadsheet_id, s.sheet_range)

    if not values:
        print("No data found.")
        return []

    header = values[0]

    def create_object_from_row(row: list[str]) -> T:
        d = row_dict(header, row)
        return s.t(**d) if s.parse is None else s.parse(d)

    data = [create_object_from_row(row) for row in values[1:]]

    return data


def row_dict(header: list[str], row: list[str]) -> dict[str, str | None]:
    return {
        col: value if value != "" else None for col, value in zip_longest(header, row)
    }

def read_sheet_data(
    credentials_file: str, spreadsheet_id: str, sheet_range: str
) -> list[list[str]]:
    """
    Fetches raw data (list of lists) from a Google Sheet.

    Args:
        credentials_file: Path to the service account credentials JSON file.
        spreadsheet_id: The ID of the Google Sheet.
        sheet_range: The range of cells to read.

    Returns:
        A list of lists representing the raw data from the sheet.
        Returns an empty list if no data is found.
    """
    SCOPES = ["https://www.googleapis.com/auth/spreadsheets.readonly"]
    creds = service_account.Credentials.from_service_account_file(
        credentials_file, scopes=SCOPES
    )

    service = build("sheets", "v4", credentials=creds)
    sheet = service.spreadsheets()
    result = (
        sheet.values().get(spreadsheetId=spreadsheet_id, range=sheet_range).execute()
    )
    return result.get("values", [])
