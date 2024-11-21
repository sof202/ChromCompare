import argparse
import sys
import re
from pathlib import Path


def validate_eol_format(file_path: str) -> None:
    try:
        with open(file_path, "rb") as config_file:
            content: bytes = config_file.read()
    except IOError:
        print(
            "Could not read file",
            file_path,
            "Please ensure that this file exists and has read permissions."
        )
        sys.exit(1)
    if b'\r' in content:
        print(
            "Carriage return character found in file.",
            "Please ensure that config file uses Linux EOL characters only."
        )
        sys.exit(1)


def get_config_variables(file_path: str) -> dict:
    config_variables: dict = {}
    with open(file_path, "r") as config_file:
        for line in config_file:
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            variable, value = line.split("=", 1)
            value = value.strip('"')
            if value == "":
                print(f"No value was given for {variable}.")
                sys.exit(1)
            config_variables[variable] = value
    return config_variables


def validate_variable_existence(config_variables: dict) -> None:
    expected_variables = [
        "DEBUG_MODE",
        "REPO_DIRECTORY",
        "RSCRIPT_DIRECTORY",
        "OUTPUT_DIRECTORY",
        "BIN_SIZE",
        "MARGINS",
        "WEIGHTS",
        "MODEL_ONE_EMISSIONS_FILE",
        "MODEL_ONE_STATE_ASSIGNMENTS_FILE",
        "MODEL_TWO_EMISSIONS_FILE",
        "MODEL_TWO_STATE_ASSIGNMENTS_FILE",
        "CHROMOSOME_SIZES_FILE"
    ]
    for variable in expected_variables:
        variable_missing = False
        if variable not in config_variables:
            print(
                f"{variable} is missing from config file.",
                "Please check the example config for what is required."
            )
            variable_missing = True
        if variable_missing:
            sys.exit(1)


def is_positive_integer(x: str) -> bool:
    if not x.isdigit():
        return False
    x = int(x)
    return x > 0


def is_bash_array(x: str) -> bool:
    pattern = r'^\((\$?\{?\w+\}?\s*)+\)$'
    return bool(re.match(pattern, x))


def is_comma_separated_floats(x: str) -> bool:
    values = x.split(",")
    if len(values) == 1:
        return False
    for value in values:
        try:
            float(value)
        except ValueError:
            return False
    return True


def validate_variable_values(config_variables: dict) -> bool:
    if config_variables["DEBUG_MODE"] not in ["0", "1"]:
        print("DEBUG_MODE must be either 0 or 1.")
        return False
    if not is_positive_integer(config_variables["BIN_SIZE"]):
        print("BIN_SIZE must be a positive integer.")
        return False
    if not is_bash_array(config_variables["MARGINS"]):
        print("MARGINS must be a bash array e.g. (x y z)")
        return False
    if not is_comma_separated_floats(config_variables["WEIGHTS"]):
        print("WEIGHTS must be comma separated list of floats e.g. 0.2,0.4,..")
        return False
    return True


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        prog="ChromCompare config file checker",
        description="Checks whether config file for ChromCompare is valid."
    )
    parser.add_argument('file_path')
    args = parser.parse_args()
    validate_eol_format(args.file_path)
    config_variables = get_config_variables(args.file_path)
    validate_variable_existence(config_variables)
    if not validate_variable_values(config_variables):
        sys.exit(1)
    sys.exit(0)
