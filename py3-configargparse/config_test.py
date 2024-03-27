import configargparse

p = configargparse.ArgParser(default_config_files=['/etc/app/conf.d/*.conf', '~/.my_settings'])
p.add('-c', '--my-config', required=True, is_config_file=True, help='config file path')
p.add('--genome', required=True, help='path to genome file')  # this option can be set in a config file because it starts with '--'
p.add('-v', help='verbose', action='store_true')
p.add('-d', '--dbsnp', help='known variants .vcf', env_var='DBSNP_PATH')  # this option can be set in a config file because it starts with '--'
p.add('vcf', nargs='+', help='variant file(s)')

options = p.parse_args()

print(options)
print("----------")
print(p.format_help())
print("----------")
print(p.format_values())    # useful for logging where different settings came from
