# -*- coding: utf-8 -*-
"""
harbour-meteopl - Meteogram fetcher and cache engine for Sailfish OS
Uses Python 3.11 standard library features
"""

import os
import re
import urllib.request
import urllib.parse
from datetime import datetime, timezone, timedelta
import json

class MeteogramFetcher:
    def __init__(self):
        # Coordinates for popular Polish cities
        self.popular_cities = [
            {"name": "Warszawa", "row": 406, "col": 250, "id": 2216, "voivodeship": "mazowieckie"},
            {"name": "Kraków", "row": 466, "col": 232, "id": 466, "voivodeship": "małopolskie"},
            {"name": "Łódź", "row": 418, "col": 223, "id": 1438, "voivodeship": "łódzkie"},
            {"name": "Wrocław", "row": 444, "col": 188, "id": 1752, "voivodeship": "dolnośląskie"},
            {"name": "Poznań", "row": 412, "col": 182, "id": 385, "voivodeship": "wielkopolskie"},
            {"name": "Gdańsk", "row": 346, "col": 210, "id": 346, "voivodeship": "pomorskie"},
            {"name": "Szczecin", "row": 370, "col": 142, "id": 142, "voivodeship": "zachodniopomorskie"},
            {"name": "Gdynia", "row": 344, "col": 208, "id": 208, "voivodeship": "pomorskie"},
            {"name": "Katowice", "row": 461, "col": 215, "id": 694, "voivodeship": "śląskie"},
            {"name": "Gliwice", "row": 460, "col": 209, "id": 691, "voivodeship": "śląskie"},
            {"name": "Zakopane", "row": 487, "col": 232, "id": 661, "voivodeship": "małopolskie"}
        ]

    def get_latest_fdate(self) -> str:
        """
        Calculates the latest available model run code on meteo.pl
        UM model runs are refreshed at approx:
        00 UTC run -> available after ~04:30 UTC
        06 UTC run -> available after ~10:30 UTC
        12 UTC run -> available after ~16:30 UTC
        18 UTC run -> available after ~22:30 UTC
        """
        now = datetime.now(timezone.utc)
        minutes_since_midnight = now.hour * 60 + now.minute
        
        run_date = now.date()
        run_hour = "18"
        
        if minutes_since_midnight >= 22 * 60 + 30:
            run_hour = "18"
        elif minutes_since_midnight >= 16 * 60 + 30:
            run_hour = "12"
        elif minutes_since_midnight >= 10 * 60 + 30:
            run_hour = "06"
        elif minutes_since_midnight >= 4 * 60 + 30:
            run_hour = "00"
        else:
            run_date = run_date - timedelta(days=1)
            run_hour = "18"
            
        return f"{run_date.strftime('%Y%m%d')}{run_hour}"

    def strip_diacritics(self, text: str) -> str:
        """Removes Polish diacritics for query normalization."""
        diacritics = {
            'ą': 'a', 'ć': 'c', 'ę': 'e', 'ł': 'l', 'ń': 'n', 'ó': 'o', 'ś': 's', 'ź': 'z', 'ż': 'z',
            'Ą': 'A', 'Ć': 'C', 'Ę': 'E', 'Ł': 'L', 'Ń': 'N', 'Ó': 'O', 'Ś': 'S', 'Ź': 'Z', 'Ż': 'Z'
        }
        return "".join(diacritics.get(char, char) for char in text)

    def search_places(self, query: str) -> list:
        """Queries the meteo.pl nominatim proxy search engine and resolves grid coordinates."""
        if not query.strip():
            return []
            
        clean_query = self.strip_diacritics(query)
        user_agent = 'harbour-meteopl/1.5 SailfishOS'
        
        # 1. Search places on nominatim proxy
        search_url = f"https://nom-proxy.dev.meteo.pl/geo/search.php?q={urllib.parse.quote(clean_query)}&format=json&addressdetails=1&polygon_svg=0&various_place=city&limit=5"
        
        import ssl
        try:
            context = ssl._create_unverified_context()
        except AttributeError:
            context = None
            
        try:
            req = urllib.request.Request(search_url, headers={'User-Agent': user_agent})
            if context:
                with urllib.request.urlopen(req, context=context, timeout=8) as response:
                    places = json.loads(response.read().decode('utf-8'))
            else:
                with urllib.request.urlopen(req, timeout=8) as response:
                    places = json.loads(response.read().decode('utf-8'))
        except Exception as e:
            print(f"Error calling nominatim proxy search: {e}")
            return []
            
        if not places:
            return []
            
        # 2. Get available dates from meteo.pl api
        avail_url = 'https://devmgramapi.meteo.pl/meteorograms/available'
        target_date = 1784440800 # default fallback
        try:
            req = urllib.request.Request(avail_url, headers={'User-Agent': user_agent})
            if context:
                with urllib.request.urlopen(req, context=context, timeout=5) as response:
                    dates_data = json.loads(response.read().decode('utf-8'))
            else:
                with urllib.request.urlopen(req, timeout=5) as response:
                    dates_data = json.loads(response.read().decode('utf-8'))
            dates = dates_data.get('um4_60', [])
            if dates:
                target_date = dates[-1]
        except Exception as e:
            print(f"Error fetching available model dates: {e}")
            
        results = []
        for p in places:
            name = p.get('display_name', '')
            # Clean display name if it has trailing ', Polska'
            if name.endswith(', Polska'):
                name = name[:-8]
                
            lat_str = p.get('lat')
            lon_str = p.get('lon')
            place_id = p.get('place_id', 0)
            
            if not lat_str or not lon_str:
                continue
                
            try:
                lat = float(lat_str)
                lon = float(lon_str)
            except ValueError:
                continue
                
            # 3. Resolve row and col for this coordinate
            post_url = 'https://devmgramapi.meteo.pl/meteorograms/um4_60'
            payload = json.dumps({'date': target_date, 'point': {'lat': lat, 'lon': lon}}).encode('utf-8')
            
            row = None
            col = None
            try:
                req = urllib.request.Request(post_url, data=payload, headers={'User-Agent': user_agent, 'Content-Type': 'application/json'})
                if context:
                    with urllib.request.urlopen(req, context=context, timeout=5) as response:
                        resp_data = json.loads(response.read().decode('utf-8'))
                else:
                    with urllib.request.urlopen(req, timeout=5) as response:
                        resp_data = json.loads(response.read().decode('utf-8'))
                        
                data_dict = resp_data.get('data', {})
                point = None
                for key, val in data_dict.items():
                    if isinstance(val, dict) and 'point' in val:
                        point = val['point']
                        break
                if point:
                    row = point.get('row')
                    col = point.get('col')
            except Exception as e:
                print(f"Error resolving coordinates for {name}: {e}")
                
            if row is not None and col is not None:
                results.append({
                    "name": name,
                    "id": place_id,
                    "row": row,
                    "col": col
                })
                
        return results

    def get_coordinates_from_id(self, city_id: int) -> tuple[int | None, int | None]:
        """Scrapes the town page to extract Row/Col variables if not predefined."""
        url = f"http://www.meteo.pl/um/php/meteorogram_id_um.php?ntype=0u&id={city_id}"
        try:
            req = urllib.request.Request(url, headers={'User-Agent': 'harbour-meteopl/1.5'})
            with urllib.request.urlopen(req, timeout=5) as response:
                html = response.read().decode('utf-8', errors='ignore')
                
            # Try to grab from image tag
            img_pattern = r'mgram_pict\.php\?ntype=0u&fdate=\d+&row=(\d+)&col=(\d+)'
            match = re.search(img_pattern, html, re.I)
            if match:
                return int(match.group(1)), int(match.group(2))
                
            # Try finding act_x and act_y (newer variables)
            var_act_x = re.search(r'var\s+act_x\s*=\s*(\d+)', html, re.I)
            var_act_y = re.search(r'var\s+act_y\s*=\s*(\d+)', html, re.I)
            if var_act_x and var_act_y:
                return int(var_act_y.group(1)), int(var_act_x.group(1))

            # Or from javascript variables
            var_row = re.search(r'var\s+row\s*=\s*(\d+)', html, re.I)
            var_col = re.search(r'var\s+col\s*=\s*(\d+)', html, re.I)
            if var_row and var_col:
                return int(var_row.group(1)), int(var_col.group(2))
        except Exception as e:
            print(f"Failed to scrape coordinates for ID {city_id}: {e}")
        return None, None

    def fetch_mgram_image(self, city_id: int, row: int, col: int, cache_dir: str, force_refresh: bool = False) -> dict:
        """
        Loads the meteogram image, caching it inside local storage.
        Returns a dict containing filePath, isCached, fetchedAt, and error.
        """
        # Coordinate resolution fallback
        if not row or not col:
            if city_id:
                row, col = self.get_coordinates_from_id(city_id)
                
        if not row or not col:
            return {"error": "Brak współrzędnych siatki."}
            
        fdate = self.get_latest_fdate()
        file_name = f"mgram_r{row}_c{col}_{fdate}.png"
        
        # Ensure cache directory exists
        os.makedirs(cache_dir, exist_ok=True)
        file_path = os.path.join(cache_dir, file_name)
        
        # Return immediately if file is already in offline cache and not force refreshing
        if not force_refresh and os.path.exists(file_path):
            return {
                "filePath": file_path,
                "isCached": True,
                "fetchedAt": int(os.path.getmtime(file_path)),
                "size": f"{os.path.getsize(file_path) / 1024:.1f} KB",
                "row": row,
                "col": col
            }
            
        # Try retrieving image from old.meteo.pl
        mgram_url = f"http://www.meteo.pl/um/metco/mgram_pict.php?ntype=0u&fdate={fdate}&row={row}&col={col}&lang=pl"
        try:
            req = urllib.request.Request(mgram_url, headers={'User-Agent': 'harbour-meteopl/1.5 SailfishOS'})
            with urllib.request.urlopen(req, timeout=10) as response:
                img_data = response.read()
                
            # Clean old cached files for this city to save storage space
            prefix = f"mgram_r{row}_c{col}_"
            for f in os.listdir(cache_dir):
                if f.startswith(prefix) and f != file_name:
                    try:
                        os.remove(os.path.join(cache_dir, f))
                    except Exception:
                        pass
                        
            # Save new meteogram image
            with open(file_path, 'wb') as out_file:
                out_file.write(img_data)
                
            return {
                "filePath": file_path,
                "isCached": False,
                "fetchedAt": int(os.path.getmtime(file_path)),
                "size": f"{len(img_data) / 1024:.1f} KB",
                "row": row,
                "col": col
            }
        except Exception as e:
            # Check if we can fall back to any older cached file for this grid point
            prefix = f"mgram_r{row}_c{col}_"
            old_files = sorted([f for f in os.listdir(cache_dir) if f.startswith(prefix)], reverse=True)
            if old_files:
                fallback_path = os.path.join(cache_dir, old_files[0])
                return {
                    "filePath": fallback_path,
                    "isCached": True,
                    "fetchedAt": int(os.path.getmtime(fallback_path)),
                    "size": f"{os.path.getsize(fallback_path) / 1024:.1f} KB",
                    "row": row,
                    "col": col,
                    "warning": "Wczytano starszą prognozę z pamięci (brak sieci)."
                }
            return {"error": f"Nie udało się połączyć z meteo.pl: {str(e)}"}

    def get_cache_info(self, cache_dir: str) -> dict:
        """Returns cache size metrics and the list of cached locations."""
        if not os.path.exists(cache_dir):
            return {"totalSize": "0 KB", "files": []}
            
        total_bytes = 0
        cached_files = []
        
        for f in os.listdir(cache_dir):
            if f.endswith(".png") and f.startswith("mgram_"):
                fpath = os.path.join(cache_dir, f)
                fsize = os.path.getsize(fpath)
                mtime = os.path.getmtime(fpath)
                total_bytes += fsize
                
                # Extract row/col from filename e.g. mgram_r406_c250_2026071906.png
                match = re.search(r'mgram_r(\d+)_c(\d+)_(\d+)', f)
                row, col, fdate = (match.groups() if match else (0, 0, ""))
                
                cached_files.append({
                    "fileName": f,
                    "row": int(row),
                    "col": int(col),
                    "fdate": fdate,
                    "size": f"{fsize / 1024:.1f} KB",
                    "fetchedAt": int(mtime)
                })
                
        cached_files.sort(key=lambda x: x["fetchedAt"], reverse=True)
        
        size_str = f"{total_bytes / 1024:.1f} KB" if total_bytes < 1024*1024 else f"{total_bytes / (1024*1024):.1f} MB"
        
        return {
            "totalSize": size_str,
            "totalBytes": total_bytes,
            "files": cached_files
        }

    def clear_all_cache(self, cache_dir: str) -> bool:
        """Purges all meteograms from the cache directory."""
        if not os.path.exists(cache_dir):
            return True
            
        for f in os.listdir(cache_dir):
            if f.endswith(".png") and f.startswith("mgram_"):
                try:
                    os.remove(os.path.join(cache_dir, f))
                except Exception:
                    pass
        return True

    def save_settings(self, cache_dir: str, settings_json_str: str) -> bool:
        """Saves settings and favorite cities to JSON file in cache_dir."""
        try:
            os.makedirs(cache_dir, exist_ok=True)
            settings_path = os.path.join(cache_dir, "settings.json")
            data = json.loads(settings_json_str)
            with open(settings_path, "w", encoding="utf-8") as f:
                json.dump(data, f, ensure_ascii=False, indent=2)
            return True
        except Exception as e:
            print(f"Error saving settings: {e}")
            return False

    def load_settings(self, cache_dir: str) -> str:
        """Loads settings and favorite cities from JSON file in cache_dir."""
        try:
            settings_path = os.path.join(cache_dir, "settings.json")
            if os.path.exists(settings_path):
                with open(settings_path, "r", encoding="utf-8") as f:
                    return f.read()
        except Exception as e:
            print(f"Error loading settings: {e}")
        return json.dumps({})

# Helper instance for PyOtherSide integration
_fetcher = MeteogramFetcher()

# Public hooks called from QML / PyOtherSide
def search(query: str):
    return json.dumps(_fetcher.search_places(query))

def fetch(city_id: int, row: int, col: int, cache_dir: str, force_refresh: bool):
    return json.dumps(_fetcher.fetch_mgram_image(city_id, row, col, cache_dir, force_refresh))

def get_cache_info(cache_dir: str):
    return json.dumps(_fetcher.get_cache_info(cache_dir))

def clear_cache(cache_dir: str):
    return _fetcher.clear_all_cache(cache_dir)

def save_settings(cache_dir: str, settings_json_str: str):
    return _fetcher.save_settings(cache_dir, settings_json_str)

def load_settings(cache_dir: str):
    return _fetcher.load_settings(cache_dir)
