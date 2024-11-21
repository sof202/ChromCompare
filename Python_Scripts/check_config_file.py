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


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        prog="ChromCompare config file checker",
        description="Checks whether config file for ChromCompare is valid."
    )
    parser.add_argument('file_path')
    args = parser.parse_args()
    validate_eol_format(args.file_path)
    config_variables = get_config_variables(args.file_path)
    check_types(config_variables)
    check_file_paths(config_variables)
    check_number_of_weights(config_variables)
    print("Config file is valid")
