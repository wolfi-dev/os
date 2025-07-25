import dns.resolver

def query_dns(domain, record_type):
    """Perform a DNS query for the specified record type."""
    try:
        resolver = dns.resolver.Resolver()
        answer = resolver.resolve(domain, record_type)
        print(f"\n{record_type} records for {domain}:")
        for rdata in answer:
            print(f" - {rdata.to_text()}")
    except dns.resolver.NoAnswer:
        print(f"No {record_type} record found for {domain}.")
    except dns.resolver.NXDOMAIN:
        print(f"Domain {domain} does not exist.")
    except Exception as e:
        print(f"An error occurred: {e}")

record_types = ["A", "MX", "NS", "TXT"]

domain = "cgr.dev"

for record_type in record_types:
    query_dns(domain, record_type)
