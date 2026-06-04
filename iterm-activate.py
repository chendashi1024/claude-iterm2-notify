import iterm2
import sys
import subprocess

async def main(conn):
    session_id = sys.argv[1]
    uuid = session_id.split(":")[-1]

    app = await iterm2.async_get_app(conn)

    for window in app.windows:
        for tab in window.tabs:
            for session in tab.sessions:
                if session.session_id == uuid:
                    await session.async_activate()
                    await window.async_activate()
                    subprocess.run(["open", "-b", "com.googlecode.iterm2"], timeout=5)
                    return

    sys.exit(1)

iterm2.run_until_complete(main, True)
