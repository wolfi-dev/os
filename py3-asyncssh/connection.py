import asyncio
import asyncssh
import sys

async def run_client(host, port, key):
    try:
        print(f"Connecting to {host}:{port}...", flush=True)
        async with asyncssh.connect(
            host, port,
            known_hosts=None,
            username='test',
            client_keys=[key],
            connect_timeout=5
        ) as conn:
            stdin, stdout, stderr = await conn.open_session()
            stdin.write('hi\n')
            await stdin.drain()
            stdin.write_eof()

            response = await stdout.read()
            print("SSH command result")
            print(response.strip())
            return True
    except Exception as e:
        print(f"Client error: {e}", file=sys.stderr, flush=True)
        import traceback
        traceback.print_exc()
        return False

async def run_server():
    try:
        key = asyncssh.generate_private_key('ssh-rsa')
        async def handle_session(stdin, stdout, stderr):
            data = await stdin.read()
            print(f"Server: received {len(data)} bytes", flush=True)
            stdout.write(data)
            await stdout.drain()
            stdout.close()
        authorized_keys = asyncssh.import_authorized_keys(key.export_public_key().decode())

        server = await asyncssh.listen(
            '127.0.0.1', 0,
            server_host_keys=[key],
            authorized_client_keys=authorized_keys,
            session_factory=handle_session
        )

        port = server.sockets[0].getsockname()[1]

        await asyncio.sleep(0.1)

        success = await run_client('127.0.0.1', port, key)

        server.close()
        await server.wait_closed()

        if not success:
            sys.exit(1)
    except Exception as e:
        print(f"Server error: {e}", file=sys.stderr, flush=True)
        import traceback
        traceback.print_exc()
        sys.exit(1)

asyncio.run(run_server())
