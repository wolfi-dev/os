import os

# Path to the file you want to modify
file_path = 'hatch_build.py'

# Lines to be added
lines_to_add = [
    '    "amazon",\n',
    '    "celery",\n',
    '    "cncf.kubernetes",\n',
    '    "docker",\n',
    '    "elasticsearch",\n',
    '    "google",\n',
    '    "grpc",\n',
    '    "hashicorp",\n',
    '    "microsoft.azure",\n',
    '    "mysql",\n',
    '    "odbc",\n',
    '    "openlineage",\n',
    '    "postgres",\n',
    '    "redis",\n',
    '    "sendgrid",\n',
    '    "sftp",\n',
    '    "slack",\n',
    '    "snowflake",\n',
    '    "ssh",\n',
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
        file_contents.insert(insert_index, line)
        insert_index += 1

    # Write the modified contents back to the file
    with open(file_path, 'w') as file:
        file.writelines(file_contents)

    print(f'Lines added to {file_path}')
else:
    print(f'Target line not found in {file_path}')
