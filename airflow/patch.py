import os

# Path to the file you want to modify
file_path = 'hatch_build.py'

# Lines to be added
lines_to_add = [
    '    "amazon",',
    '    "celery",',
    '    "cncf.kubernetes",',
    '    "docker",',
    '    "elasticsearch",',
    '    "google",',
    '    "grpc",',
    '    "hashicorp",',
    '    "microsoft.azure",',
    '    "mysql",',
    '    "odbc",',
    '    "openlineage",',
    '    "postgres",',
    '    "redis",',
    '    "sendgrid",',
    '    "sftp",',
    '    "slack",',
    '    "snowflake",',
    '    "ssh",',
]

# Read the contents of the file
with open(file_path, 'r') as file:
    file_contents = file.readlines()

# Find the index of the line where the new lines should be inserted
insert_index = None
for i, line in enumerate(file_contents):
    if line.strip() == 'PRE_INSTALLED_PROVIDERS = [':
        insert_index = i + 1
        break

# If the target line is found, insert the new lines
if insert_index is not None:
    for line in lines_to_add:
        line = f'    "{line.strip()}",\n'
        file_contents.insert(insert_index, line)
        insert_index += 1

    # Write the modified contents back to the file
    with open(file_path, 'w') as file:
        file.writelines(file_contents)

    print(f'Lines added to {file_path}')
else:
    print(f'Target line not found in {file_path}')
