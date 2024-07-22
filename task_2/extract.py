import requests
from datetime import date, timedelta
import pandas as pd
import json
from time import sleep


API_KEY = "fca_live_cfUb34OqMX99R78TYhyh2qSlACz3YilZYdJJMnNM"

url = f"https://api.freecurrencyapi.com/v1/historical?apikey={API_KEY}&currencies=EUR"


def extract():
  end_date = date(2024, 7, 18)
  start_date = end_date - timedelta(days=37)

  data = {}

  while (start_date <= end_date):
    response = requests.get(url + f"&date={start_date.strftime('%Y-%m-%d')}").json()
    try:
      exchange_date, exchange_currencies = list(response['data'].items())[0]
    except KeyError:
      print(start_date)
      print(response)
      print("Sleeping for 30 sec")
      sleep(30)
      continue
    data[exchange_date] = exchange_currencies['EUR']
    start_date += timedelta(days=1)
  
  return data


def transform(data: dict):
  items = list(data.items())
  df = pd.DataFrame(items, columns=['date', 'rate'])
  return df


def load(df):
  df.to_csv("task_2/rates.csv", index=False)


if __name__ == "__main__":
  data = extract()
  df = transform(data)
  load(df)