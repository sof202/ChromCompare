import argparse

if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        prog="ChromCompare config file checker",
        description="Checks whether config file for ChromCompare is valid."
    )
    parser.add_argument('file_path')
    args = parser.parse_args()
    check_eol_type(args.file_path)
    config_variables = get_config_variables(args.file_path)
    check_types(config_variables)
    check_file_paths(config_variables)
    check_number_of_weights(config_variables)
    print("Config file is valid")
