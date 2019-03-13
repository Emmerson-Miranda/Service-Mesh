server = false
datacenter = "dc-dev"
data_dir = "/opt/consul"
encrypt = "Luj2FZWwlt8475wD1WtwUQ=="
enable_script_checks = true
enable_debug = true
enable_syslog = true
log_level = "DEBUG"
connect {
    enabled = true
    proxy {
        allow_managed_api_registration = true
        allow_managed_root = true
    }
}