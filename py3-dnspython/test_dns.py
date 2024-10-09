import dns.resolver

def query_dns(domain, record_type):
    """Perform a DNS query for the specified record type."""
    try:
        # Create a DNS resolver instance
        resolver = dns.resolver.Resolver()

        # Resolve the specified record type for the domain
        answer = resolver.resolve(domain, record_type)

        # Print the results for the queried record type
        print(f"\n{record_type} records for {domain}:")
        for rdata in answer:
            print(f" - {rdata.to_text()}")
    except dns.resolver.NoAnswer:
        print(f"No {record_type} record found for {domain}.")
    except dns.resolver.NXDOMAIN:
        print(f"Domain {domain} does not exist.")
    except Exception as e:
        print(f"An error occurred: {e}")

# List of DNS record types to query
record_types = ["A", "MX", "NS", "TXT"]

# Domain to query
domain = "example.com"

# Query each DNS record type for the specified domain
for record_type in record_types:
    query_dns(domain, record_type)
