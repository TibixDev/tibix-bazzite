"""Exercise shortcut migration without touching the user's KDE session."""

from pathlib import Path
import runpy
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
SETUP = runpy.run_path(str(ROOT / "system_files/usr/libexec/tibix-bazzite/lumine-capture-setup"))
COMPONENT = SETUP["COMPONENT"]
PRINT = 0x01000009
META_SHIFT_S = 0x12000053


class FakeShortcuts:
    def __init__(self, bindings):
        self.bindings = {identity: list(keys) for identity, keys in bindings.items()}

    def register(self, identity):
        self.bindings.setdefault(tuple(identity[:2]), [])

    def owner(self, key):
        for (component, action), keys in self.bindings.items():
            if key in keys:
                return [component, action, component, action]
        return []

    def get(self, identity):
        return self.bindings[tuple(identity[:2])]

    def set(self, identity, keys):
        for key in keys:
            owner = self.owner(key)
            if owner and owner[:2] != identity[:2]:
                raise RuntimeError("Key still belongs to another action")
        self.bindings[tuple(identity[:2])] = list(keys)


class MigrationTests(unittest.TestCase):
    def test_flameshot_and_spectacle_keys_move_without_losing_other_bindings(self):
        old = ("net.local.flatpak.desktop", "_launch")
        spectacle = ("org.kde.spectacle.desktop", "_launch")
        api = FakeShortcuts({old: [PRINT, 123], spectacle: [META_SHIFT_S]})
        SETUP["migrate"](api, [("_launch", [PRINT, META_SHIFT_S])], {old[0], spectacle[0]})
        self.assertEqual(api.bindings[old], [123])
        self.assertEqual(api.bindings[spectacle], [])
        self.assertEqual(set(api.bindings[COMPONENT, "_launch"]), {PRINT, META_SHIFT_S})

    def test_unrelated_apps_keep_their_shortcuts(self):
        other = ("user-custom.desktop", "_launch")
        api = FakeShortcuts({other: [PRINT]})
        SETUP["migrate"](api, [("_launch", [PRINT, META_SHIFT_S])], set())
        self.assertEqual(api.bindings[other], [PRINT])
        self.assertEqual(api.bindings[COMPONENT, "_launch"], [META_SHIFT_S])

    def test_reapplying_is_idempotent_and_preserves_extra_lumine_keys(self):
        api = FakeShortcuts({(COMPONENT, "_launch"): [123]})
        for _ in range(2):
            SETUP["migrate"](api, [("_launch", [PRINT, META_SHIFT_S])], set())
        self.assertEqual(api.bindings[COMPONENT, "_launch"], [123, PRINT, META_SHIFT_S])

    def test_desktop_entry_defines_expected_actions_and_qt_keys(self):
        actual = dict(SETUP["desktop_actions"](ROOT / "build_files/lumine-capture/lumine-capture.desktop"))
        self.assertEqual(actual, {
            "_launch": [PRINT, META_SHIFT_S],
            "Region": [0x05000009],
            "FullScreenSave": [0x03000009],
            "FullScreenCopy": [0x07000009],
            "ActiveWindow": [0x09000009],
        })

    def test_dbus_failure_is_not_reported_as_success(self):
        class FailingShortcuts(FakeShortcuts):
            def set(self, identity, keys):
                raise RuntimeError("KDE service unavailable")

        with self.assertRaisesRegex(RuntimeError, "unavailable"):
            SETUP["migrate"](FailingShortcuts({}), [("_launch", [PRINT])], set())

    def test_image_handoff_preserves_cached_launcher_and_user_shortcuts(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            data, state = root / "data", root / "state"
            (data / "applications").mkdir(parents=True)
            state.mkdir()
            entry = data / "applications" / COMPONENT
            entry.write_text(SETUP["LOCAL_MARKER"] + "\n")
            (state / "shortcuts-v1.done").write_text("1\n")
            system_entry, system_binary = root / "system.desktop", root / "system-binary"
            system_entry.touch()
            system_binary.touch()
            promote = SETUP["promote_image_install"]
            self.assertTrue(promote(data, state, system_entry, system_binary))
            self.assertFalse(entry.exists())
            self.assertTrue((state / "local-install.desktop").exists())
            launcher = data / "tibix-bazzite/lumine-capture/bin/lumine-capture"
            self.assertEqual(launcher.resolve(), system_binary)
            self.assertEqual((state / "shortcuts-v1.done").read_text(), "1\n")
            self.assertFalse(promote(data, state, system_entry, system_binary))

    def test_image_handoff_leaves_unmanaged_desktop_entry_alone(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "applications").mkdir()
            entry = root / "applications" / COMPONENT
            entry.write_text("[Desktop Entry]\nName=My custom LumineCapture\n")
            system_binary = root / "system-binary"
            system_binary.touch()
            self.assertFalse(SETUP["promote_image_install"](root, root, entry, system_binary))
            self.assertIn("My custom", entry.read_text())


if __name__ == "__main__":
    unittest.main()
