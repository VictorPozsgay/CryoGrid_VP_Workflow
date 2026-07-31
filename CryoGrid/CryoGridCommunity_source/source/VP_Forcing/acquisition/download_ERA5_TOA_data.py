import os
import shutil
import time
import cdsapi
from netCDF4 import Dataset #pylint:disable=no-name-in-module

def is_valid_era5_file(filename):
    """
    Check that an ERA5 TOA NetCDF file is readable and contains the
    expected variables.

    Parameters
    ----------
    filename : str
        Path to the NetCDF file.

    Returns
    -------
    bool
        True if the file is valid, False otherwise.
    """

    if not os.path.isfile(filename):
        return False

    required = ["valid_time", "tisr"]

    try:
        with Dataset(filename, "r") as nc:

            for var in required:

                if var not in nc.variables:
                    print(f"    Missing variable: {var}")
                    return False

                if nc.variables[var].size == 0:
                    print(f"    Empty variable: {var}")
                    return False

        return True

    except Exception as e: # pylint:disable=broad-exception-caught
        print(f"    Invalid NetCDF: {e}")
        return False


def download_era5_toa(
    start_year=1940,
    end_year=1941
):
    """
    Download ERA5 top-of-atmosphere incoming solar radiation yearly files.

    Files are saved as:
        era5_toa_YYYY.nc
    into folder:
        CryoGridCommunity_forcing/meteo/ERA5_test/raw

    Existing years are skipped, allowing restart after interruption.

    Parameters
    ----------
    start_year, end_year : int
        Download period.
    """

    # Find CryoGrid root directory from this script location
    script_dir = os.path.dirname(os.path.abspath(__file__))

    cryogrid_root = os.path.abspath(
        os.path.join(script_dir, "..", "..", "..", "..")
    )

    output_folder = os.path.join(
        cryogrid_root,
        "CryoGridCommunity_forcing",
        "meteo",
        "ERA5_test",
        "raw"
    )

    # ERA5 bounding box [North, West, South, East].
    area=[46.75, 5.25, 43.25, 7.75]

    # Create output folder if needed
    os.makedirs(output_folder, exist_ok=True)

    client = cdsapi.Client()

    for year in range(start_year, end_year + 1):

        outfile = os.path.join(
            output_folder,
            f"era5_toa_{year}.nc"
        )

        # Restart checker
        if os.path.isfile(outfile):
            print(f"{year}: existing file found...")
            if is_valid_era5_file(outfile):
                print("    Valid, skipping.")
                continue
            print("    Corrupted or incomplete, deleting.")
            os.remove(outfile)

        print(f"{year}: downloading...")

        request = {
            "product_type": ["reanalysis"],
            "year": [str(year)],
            "month": [
                "01", "02", "03",
                "04", "05", "06",
                "07", "08", "09",
                "10", "11", "12"
            ],
            "day": [
                f"{d:02d}" for d in range(1, 32)
            ],
            "time": [
                f"{h:02d}:00" for h in range(24)
            ],
            "data_format": "netcdf",
            "download_format": "unarchived",
            "variable": [
                "toa_incident_solar_radiation"
            ],
            "area": area
        }

        # Temporary filename
        tmpfile = os.path.join(
            output_folder,
            f"tmp_era5_toa_{year}.nc"
        )

        try:
            client.retrieve(
                "reanalysis-era5-single-levels",
                request
            ).download(tmpfile)

            # Check that file exists
            if not os.path.isfile(tmpfile):
                raise RuntimeError("Download finished but file missing")

            # Validate NetCDF contents
            if not is_valid_era5_file(tmpfile):
                raise RuntimeError("Downloaded NetCDF failed validation")

            # Rename only after successful validation
            shutil.move(tmpfile, outfile)

            print(f"{year}: saved -> {outfile}")

        except Exception as e: # pylint:disable=broad-exception-caught

            print(f"{year}: FAILED")
            print(e)

            # Remove incomplete temporary file
            if os.path.isfile(tmpfile):
                os.remove(tmpfile)

            print("Continuing with next year...\n")

            # Avoid hammering CDS after failure
            time.sleep(10)


if __name__ == "__main__":

    download_era5_toa()
