import argparse
import sys


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
    check_types(config_variables)
    check_file_paths(config_variables)
    check_number_of_weights(config_variables)
    print("Config file is valid")
