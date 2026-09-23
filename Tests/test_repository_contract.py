import re
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


class RepositoryContractTests(unittest.TestCase):
    def test_required_repository_files_exist(self):
        required = [
            "README.md",
            "README.zh-CN.md",
            "LICENSE",
            "PRIVACY.md",
            "SECURITY.md",
            "CHANGELOG.md",
            "Package.swift",
            ".github/workflows/ci.yml",
            "Docs/MODEL_NOTES.md",
            "Docs/PRODUCT.md",
        ]

        missing = [path for path in required if not (ROOT / path).is_file()]

        self.assertEqual(missing, [])

    def test_readme_local_links_resolve(self):
        for readme in [ROOT / "README.md", ROOT / "README.zh-CN.md"]:
            body = readme.read_text(encoding="utf-8")
            links = re.findall(r"\[[^\]]+\]\(([^)]+)\)", body)
            local_links = [
                link.split("#", 1)[0]
                for link in links
                if link and not re.match(r"^[a-z][a-z0-9+.-]*:", link)
            ]
            missing = [link for link in local_links if link and not (ROOT / link).exists()]

            self.assertEqual(missing, [], f"broken local links in {readme.name}")

    def test_swift_package_declares_app_core_and_tests(self):
        package = (ROOT / "Package.swift").read_text(encoding="utf-8")

        for expected in [
            'name: "ItoCanvas"',
            '.library(name: "ItoCanvasCore"',
            '.executable(name: "ItoCanvas"',
            '.testTarget(name: "ItoCanvasCoreTests"',
            '.testTarget(name: "ItoCanvasAppTests"',
            '.macOS(.v14)',
        ]:
            self.assertIn(expected, package)

    def test_ci_exercises_tests_build_dmg_and_signature_check(self):
        workflow = (ROOT / ".github/workflows/ci.yml").read_text(encoding="utf-8")

        for expected in [
            "python3 -m unittest discover -s Tests -p 'test_*.py' -v",
            "swift test",
            "./Scripts/build_app.sh",
            "./Scripts/create_dmg.sh",
            "codesign --verify --deep --strict",
            "dist/ItoCanvas.dmg",
        ]:
            self.assertIn(expected, workflow)


if __name__ == "__main__":
    unittest.main()
