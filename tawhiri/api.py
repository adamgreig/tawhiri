# Copyright 2014 (C) Priyesh Patel
#
# This file is part of Tawhiri.
#
# Tawhiri is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Tawhiri is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Tawhiri.  If not, see <http://www.gnu.org/licenses/>.

"""
Provide the HTTP API for Tawhiri.
"""

import itertools

from flask import Flask, jsonify, request, abort
import strict_rfc3339
from werkzeug.exceptions import BadRequest
import jinja2

from tawhiri import solver, models, interpolate
from tawhiri.dataset import Dataset as WindDataset
from tawhiri.warnings import WarningCounts
from ruaumoko import Dataset as ElevationDataset

app = Flask(__name__)

API_VERSION = 1
PROFILE_STANDARD = "standard"
PROFILE_FLOAT = "float"
PROFILES = {PROFILE_STANDARD, PROFILE_FLOAT}
PREDICTION_COUNT_LIMIT = 200

ruaumoko_ds = None

jinja_loader = jinja2.PackageLoader("tawhiri", "")
jinja_env = jinja2.Environment(loader=jinja_loader,
                               extensions=['jinja2.ext.autoescape'],
                               undefined=jinja2.StrictUndefined)
kml_template = jinja_env.get_template("template.kml")


# Setup #######################################################################
@app.before_first_request
def open_ruaumoko_ds():
    global ruaumoko_ds
    ds_loc = app.config.get('ELEVATION_DATASET',
                            ElevationDataset.default_location)
    ruaumoko_ds = ElevationDataset(ds_loc)


# Util functions ##############################################################
def open_dataset():
    ds_dir = app.config.get('WIND_DATASET_DIR', WindDataset.DEFAULT_DIRECTORY)
    return WindDataset.open_latest(persistent=True, directory=ds_dir)


def timestamp_to_rfc3339(dt):
    """Convert from a UNIX timestamp to a RFC3339 timestamp."""
    return strict_rfc3339.timestamp_to_rfc3339_utcoffset(dt)


def json_error(err):
    if hasattr(err, "to_json"):
        return err.to_json()
    else:
        return {
            "type": type(err).__name__,
            "description": str(err)
        }


# Exceptions ##################################################################
class RequestException(BadRequest):
    pass


class MissingParameter(RequestException, KeyError):
    def __init__(self, key):
        self.key = key

    def __str__(self):
        return "Missing {}".format(self.key)

    def to_json(self):
        return {
            "type": "MissingParameter",
            "key": self.key,
            "description": self.key
        }


class InvalidParameter(RequestException, ValueError):
    def __init__(self, key, value):
        self.key = key
        self.value = value

    def __str__(self):
        return "Invalid {0.key}: {0.value}".format(self)

    def to_json(self):
        return {
            "type": "InvalidParameter",
            "key": self.key,
            "value": self.value,
            "description": str(self)
        }


class TooManyPredictions(RequestException):
    def __init__(self, n):
        super().__init__(str(n))
        self.n = n

    def __str__(self):
        return "Too many predictions: {}".format(self.n)

    def to_json(self):
        return {
            "type": "TooManyPredictions",
            "n": self.n,
            "description": str(self)
        }


# Request #####################################################################
class MultiRequest:
    def __init__(self, data):
        self.launch_latitude = self._get_lat(data, "launch_latitude")
        self.launch_longitude = self._get_lon(data, "launch_longitude")
        self.launch_datetime = self._get_datetime(data, "launch_datetime")
        self.launch_altitude = \
            self._get_single_float(data, "launch_altitude", optional=True)
        self.profile = self._get_profile(data)
        self.skip_paths = self._get_bool(data, "skip_paths")
        self.ascent_rate = self._get_multi_flts(data, "ascent_rate")

        if -180 <= self.launch_longitude < 0:
            self.launch_longitude += 360

        if self.profile == PROFILE_STANDARD:
            self.burst_altitude = self._get_multi_flts(data, "burst_altitude")
            self.descent_rate = self._get_multi_flts(data, "descent_rate")
        elif self.profile == PROFILE_FLOAT:
            self.float_altitude = self._get_multi_flts(data, "float_altitude")

            def stvd(x):
                return x > self.launch_datetime

            self.stop_datetime = \
                self._get_datetime(data, "stop_datetime", validator=stvd)

        l = len(self)
        assert l != 0
        if l > PREDICTION_COUNT_LIMIT:
            raise TooManyPredictions(l)

    def set_default_launch_alt(self, ruaumoko):
        if self.launch_altitude is None:
            self.launch_altitude = ruaumoko.get(
                self.launch_latitude, self.launch_longitude)

    def _get_bool(self, data, key, default=False):
        try:
            r = data[key].lower()
        except KeyError:
            return default

        if r not in ("true", "false"):
            raise InvalidParameter(key, r)

        return r == "true"

    def _get_single_float(self, data, key, optional=False, validator=None):
        try:
            r = data[key]
        except KeyError:
            if optional:
                return None
            else:
                raise MissingParameter(key)

        try:
            r = float(r)
        except ValueError:
            raise InvalidParameter(key, r)

        if validator and not validator(r):
            raise InvalidParameter(key, r)

        return r

    def _get_lat(self, data, key):
        return self._get_single_float(data, key,
                                      validator=lambda x: -90 <= x <= 90)

    def _get_lon(self, data, key):
        return self._get_single_float(data, key,
                                      validator=lambda x: 0 <= x < 360)

    def _get_datetime(self, data, key, validator=None):
        try:
            r = data[key]
        except KeyError:
            raise MissingParameter(key)

        try:
            r = strict_rfc3339.rfc3339_to_timestamp(r)
        except KeyError:
            raise InvalidParameter(key, r)

        if validator is not None and not validator(r):
            raise InvalidParameter(key, r)

        return r

    def _get_profile(self, data):
        try:
            p = data["profile"]
        except KeyError:
            p = PROFILE_STANDARD

        if p not in PROFILES:
            raise InvalidParameter("dataset", p)

        return p

    def _get_multi_flts(self, data, key, validator=None):
        try:
            vals = data.getlist(key) + data.getlist(key + "[]")
        except KeyError:
            raise MissingParameter(key)

        if vals == []:
            raise MissingParameter(key)

        if not isinstance(vals, list):
            vals = [vals]

        def cast_and_validate(x):
            try:
                x = float(x)
            except ValueError:
                raise InvalidParameter(key, x)

            if validator is not None and not validator(x):
                raise InvalidParameter(key, x)

            return x

        vals = [cast_and_validate(x) for x in vals]
        return vals

    def __len__(self):
        prod = len(self.ascent_rate)

        if self.profile == PROFILE_STANDARD:
            prod *= len(self.burst_altitude)
            prod *= len(self.descent_rate)

        elif self.profile == PROFILE_FLOAT:
            prod *= len(self.float_altitude)

        return prod

    def __iter__(self):
        if self.profile == PROFILE_STANDARD:
            p = itertools.product(self.ascent_rate, self.burst_altitude,
                                  self.descent_rate)
            for asc, balt, desc in p:
                yield Request(self, ascent_rate=asc, burst_altitude=balt,
                              descent_rate=desc)

        elif self.profile == PROFILE_FLOAT:
            p = itertools.product(self.ascent_rate, self.float_altitude)
            for asc, falt in p:
                yield Request(self, ascent_rate=asc, float_altitude=falt)


class Request:
    def __init__(self, parent, **specialisation):
        self.parent = parent
        if parent.profile == PROFILE_STANDARD:
            assert set(specialisation) == {
                "ascent_rate", "burst_altitude", "descent_rate"}
            self.ascent_rate = specialisation["ascent_rate"]
            self.burst_altitude = specialisation["burst_altitude"]
            self.descent_rate = specialisation["descent_rate"]
        elif parent.profile == PROFILE_FLOAT:
            assert set(specialisation) == {"ascent_rate", "float_altitude"}
            self.ascent_rate = specialisation["ascent_rate"]
            self.float_altitude = specialisation["float_altitude"]

    def __getattr__(self, key):
        return getattr(self.parent, key)

    def to_json(self):
        ts_to_rfc3339 = strict_rfc3339.timestamp_to_rfc3339_utcoffset

        r = {
            "launch_latitude": self.launch_latitude,
            "launch_longitude": self.launch_longitude,
            "launch_datetime": ts_to_rfc3339(self.launch_datetime),
            "launch_altitude": self.launch_altitude,
            "profile": self.profile,
            "skip_paths": self.skip_paths,
            "ascent_rate": self.ascent_rate
        }

        if self.profile == PROFILE_STANDARD:
            r["burst_altitude"] = self.burst_altitude
            r["descent_rate"] = self.descent_rate
        elif self.profile == PROFILE_FLOAT:
            r["float_altitude"] = self.float_altitude
            r["stop_datetime"] = self.stop_datetime

        return r


# Results #####################################################################
class Result:
    ok = "Unclear"

    def __init__(self, req, actual_ds_used):
        self.request = req
        self.actual_ds_used = actual_ds_used


class Prediction(Result):
    ok = True

    def __init__(self, req, actual_ds_used, result, warningcounts):
        super(Prediction, self).__init__(req, actual_ds_used)
        self.result = result
        self.warningcounts = warningcounts

    def to_json(self, skip_paths=False):
        ret = {"prediction": self._stages_to_json(skip_paths)}
        ret.update(self.request.to_json())
        if self.warningcounts.any:
            ret.update({"warnings": self.warningcounts.to_dict()})
        return ret

    def _stages_to_json(self, skip_paths):
        if self.request.profile == PROFILE_STANDARD:
            assert len(self.result) == 2
            stages = [
                {"name": "launch", "type": "event",
                 "point": self.result[0][0]},
                {"name": "ascent", "type": "path",
                 "path": self.result[0]},
                {"name": "burst", "type": "event",
                 "point": self.result[0][-1]},
                {"name": "descent", "type": "path",
                 "path": self.result[1]},
                {"name": "land", "type": "event",
                 "point": self.result[1][-1]}
            ]
        elif self.request.profile == PROFILE_FLOAT:
            assert len(self.result) == 2
            stages = [
                {"name": "launch", "type": "event",
                 "point": self.result[0][0]},
                {"name": "ascent", "type": "path",
                 "path": self.result[0]},
                {"name": "float_start", "type": "event",
                 "point": self.result[0][-1]},
                {"name": "float", "type": "path",
                 "path": self.result[1]},
            ]
        else:
            raise AssertionError(self.request.profile)

        prediction = []
        ts_to_rfc3339 = strict_rfc3339.timestamp_to_rfc3339_utcoffset
        for stage in stages:
            if stage["type"] == "path":
                # Skip this leg if it's a path and we're truncating them
                if skip_paths:
                    continue

                ret = {
                    "stage": stage["name"],
                    "type": "path",
                    "path": [
                        {
                            'latitude': round(lat, 6),
                            'longitude': round(lon, 6),
                            'altitude': round(alt, 1),
                            'datetime': ts_to_rfc3339(dt)
                        } for dt, lat, lon, alt in stage["path"]
                    ]
                }

            elif stage["type"] == "event":
                point = stage["point"]
                ret = {
                    "stage": stage["name"],
                    "type": "event",
                    "datetime": ts_to_rfc3339(point[0]),
                    "latitude": round(point[1], 6),
                    "longitude": round(point[2], 6),
                    "altitude": round(point[3], 1)
                }

            prediction.append(ret)

        return prediction


class PredictionFailure(Result):
    ok = False

    def __init__(self, req, actual_ds_used, error):
        super(PredictionFailure, self).__init__(req, actual_ds_used)
        self.error = error

    def to_json(self, skip_paths=None):
        return {
            "request": self.request.to_json(),
            "error": json_error(self.error)
        }


# Response ####################################################################
def run_all_predictions(multireq, wind_ds):
    for req in multireq:
        actual_ds_used = wind_ds.ds_time.strftime("%Y-%m-%dT%H:00:00Z")
        warningcounts = WarningCounts()

        # Stages
        if req.profile == PROFILE_STANDARD:
            profile = models.standard_profile(
                req.ascent_rate, req.burst_altitude,
                req.descent_rate, wind_ds,
                ruaumoko_ds, warningcounts
            )
        elif req.profile == PROFILE_FLOAT:
            profile = models.float_profile(
                req.ascent_rate, req.float_altiutde,
                req.stop_datetime, wind_ds, warningcounts
            )
        else:
            raise AssertionError(req.profile)

        # Run solver
        try:
            result = solver.solve(
                req.launch_datetime, req.launch_latitude,
                req.launch_longitude, req.launch_altitude,
                profile
            )
        except Exception as e:
            yield PredictionFailure(req, actual_ds_used, e)
        else:
            yield Prediction(req, actual_ds_used, result, warningcounts)


def preds_to_csv(predictions):
    lines = []
    for pred_idx, prediction in enumerate(predictions):
        for stage in prediction["prediction"]:
            if stage["type"] == "event":
                lines.append((pred_idx, stage["type"], stage["stage"],
                              stage["datetime"], stage["latitude"],
                              stage["longitude"], stage["altitude"]))
            elif stage["type"] == "path":
                for point in stage["path"]:
                    lines.append((pred_idx, stage["type"], stage["stage"],
                                  point["datetime"], point["latitude"],
                                  point["longitude"], point["altitude"]))
    return "\n".join(",".join(str(x) for x in line) for line in lines)


# Flask App ###################################################################
@app.route('/api/predict', methods=['GET'])
def main():
    wind_ds = open_dataset()
    actual_ds_used = wind_ds.ds_time.strftime("%Y-%m-%dT%H:00:00Z")
    multireq = MultiRequest(request.args)
    multireq.set_default_launch_alt(ruaumoko_ds)
    predictions = list(run_all_predictions(multireq, wind_ds))

    atleast_one_success = any(p.ok for p in predictions)
    if not atleast_one_success:
        raise predictions[0].error

    predictions = [p.to_json(multireq.skip_paths) for p in predictions]

    fmt = request.args.get("format")

    if fmt == "kml":
        pass
    elif fmt == "csv":
        return preds_to_csv(predictions)
    else:
        return jsonify(dataset=actual_ds_used, predictions=predictions)


@app.route('/api/elevation', methods=['GET'])
def elevation():
    try:
        lat = float(request.args.get("latitude"))
        lng = float(request.args.get("longitude"))
        result = ruaumoko_ds.get(lat, lng)
    except ValueError:
        abort(400)
    return jsonify(elevation=result)


@app.errorhandler(BadRequest)
@app.errorhandler(400)
@app.errorhandler(interpolate.RangeError)
def handle_exception(error):
    return jsonify(error=json_error(error)), getattr(error, "code", 500)
