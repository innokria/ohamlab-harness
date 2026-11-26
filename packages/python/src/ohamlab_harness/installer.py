
"""Install OhamLab Harness and Python integrations with optional branding."""

import json
import os
import shutil
import sys
import tempfile
from pathlib import Path

from .runtime import default_home, executable, require_tools, run


REPO = "https://github.com/innokria/ohamlab-harness.git"


def install(
    home=None,
    repo=None,
    harness_tag=None,
    integration_tag=None,
    force=False,
):
    require_tools("git", "node", "pnpm")

    pnpm = executable("pnpm")

    home = (
        Path(home).expanduser().resolve()
        if home else default_home()
    )

    dsh_home = Path(
        os.environ.get("DSH_HOME", home / "data")
    ).expanduser().resolve()

    plugin_env = os.environ.copy()
    plugin_env["DSH_HOME"] = str(dsh_home)

    repo = repo or os.environ.get("OHAMLAB_REPO_URL", REPO)

    harness_tag = (
        harness_tag
        or os.environ.get("OHAMLAB_HARNESS_TAG", "main")
    )

    integration_tag = (
        integration_tag
        or os.environ.get("OHAMLAB_INTEGRATION_TAG", "2.0")
    )

    app = home / "app"

    if app.exists() and not force:
        raise RuntimeError(
            f"{app} already exists; use --force to reinstall."
        )

    home.mkdir(parents=True, exist_ok=True)
    dsh_home.mkdir(parents=True, exist_ok=True)

    for directory in (
        dsh_home / "plugins",
        dsh_home / "profiles",
        dsh_home / "sessions",
        dsh_home / "cache",
        dsh_home / "logs",
    ):
        directory.mkdir(parents=True, exist_ok=True)

    # Keep backups until the new installation has passed verification.
    backup_app = home / "app.previous"
    app_backed_up = False
    new_app_deployed = False

    try:
        with tempfile.TemporaryDirectory(
            prefix="ohamlab-build-",
            dir=home,
        ) as temp:

            tmp = Path(temp)
            source = tmp / "app"
            integration = tmp / "integration"

            # -------------------------------------------------
            # 1. Clone Harness
            # -------------------------------------------------

            print("[OHAMLAB] Cloning Harness...")

            run([
                "git",
                "clone",
                "--branch",
                harness_tag,
                "--depth",
                "1",
                repo,
                str(source),
            ])

            # -------------------------------------------------
            # 2. Clone OhamLab integration
            # -------------------------------------------------

            vendor = source / "vendor" / "ohamlab"

            requirements = (
                vendor / "gateway" / "requirements.txt"
            )

            skills = vendor / "skills"

            for required in (requirements, skills):
                if not required.exists():
                    raise RuntimeError(
                        f"Required integration file missing: {required}"
                    )

            # -------------------------------------------------
            # 3. Copy complete integration into Harness
            #
            # Keep this existing location unchanged.
            # Agent and Search use this integration tree.
            # -------------------------------------------------

            target_vendor = (
                source / "ohamlab" / "vendor" / "ohamlab"
            )

            target_vendor.parent.mkdir(
                parents=True,
                exist_ok=True,
            )

            if target_vendor.exists():
                shutil.rmtree(target_vendor)

            shutil.copytree(vendor, target_vendor)

            # -------------------------------------------------
            # 4. Copy branding to a stable plugin location
            #
            # This is separate from the Agent/Search location.
            # -------------------------------------------------

            brand_source = (
                vendor / "plugins" / "harness-brand"
            )

            brand_plugin = (
                home / "plugins" / "harness-brand"
            )

            if brand_source.is_dir():
                brand_plugin.parent.mkdir(
                    parents=True,
                    exist_ok=True,
                )

                if brand_plugin.exists():
                    shutil.rmtree(brand_plugin)

                shutil.copytree(
                    brand_source,
                    brand_plugin,
                )

                print(
                    f"[OHAMLAB] Branding source copied to: {brand_plugin}"
                )
            else:
                print(
                    f"[WARNING] Branding source not found: {brand_source}"
                )

            # -------------------------------------------------
            # 5. Install Python integrations
            #
            # Preserve existing Agent and Search dependencies.
            # -------------------------------------------------

            python = (
                os.environ.get("OHAM_PYTHON")
                or os.environ.get("PYTHON")
                or sys.executable
            )

            print("[OHAMLAB] Installing Python dependencies...")

            run([
                python,
                "-m",
                "pip",
                "install",
                "-r",
                str(requirements),
            ])

            run([
                python,
                "-m",
                "pip",
                "install",
                "ohamlab-agent==0.1.2",
                "ohamlab-agent-lab[server]==7.0.0",
            ])

            run([
                python,
                "-m",
                "pip",
                "check",
            ])

            # -------------------------------------------------
            # 6. Install Harness dependencies
            # -------------------------------------------------

            print("[OHAMLAB] Installing Harness dependencies...")

            run(
                [pnpm, "install"],
                cwd=source,
            )

            # -------------------------------------------------
            # 7. Back up existing Harness
            # -------------------------------------------------

            if app.exists():
                if backup_app.exists():
                    shutil.rmtree(backup_app)

                app.rename(backup_app)
                app_backed_up = True

            # -------------------------------------------------
            # 8. Deploy new Harness
            # -------------------------------------------------

            shutil.move(str(source), str(app))
            new_app_deployed = True

            # -------------------------------------------------
            # 9. Build Harness
            # -------------------------------------------------

            print("[OHAMLAB] Building Harness...")

            run(
                [pnpm, "run", "build"],
                cwd=app,
            )

            print("[OHAMLAB] Harness build completed.")

            # -------------------------------------------------
            # 10. Install and activate branding plugin
            #
            # Optional: failure must not break Harness,
            # Agent or Search installation.
            # -------------------------------------------------

            print("[OHAMLAB] Branding and voice are built into the web application.")

        # -------------------------------------------------
        # 11. Remove backup after successful core deployment
        # -------------------------------------------------

        if backup_app.exists():
            shutil.rmtree(backup_app)

    except Exception:
        print(
            "[OHAMLAB] Installation failed. "
            "Restoring previous app..."
        )

        if new_app_deployed and app.exists():
            shutil.rmtree(app)

        if app_backed_up and backup_app.exists():
            backup_app.rename(app)

        raise

    print("========================================")
    print("[OHAMLAB] Installation successful")
    print(f"[OHAMLAB] Harness: {app}")
    print(f"[OHAMLAB] DSH_HOME: {dsh_home}")
    print(f"[OHAMLAB] Branding: {brand_plugin}")
    print("========================================")

    return app
