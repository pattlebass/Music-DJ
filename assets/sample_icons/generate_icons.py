import subprocess

source = open("sample_source.svg").read()

for i in range(1, 33):
    output = source.replace("{s}", str(i))

    open(f"sample_{i}.svg", "w").write(output)

    subprocess.run(
        [
            "inkscape",
            f"sample_{i}.svg",
            "--export-text-to-path",
            "--export-plain-svg",
            "--export-filename",
            f"sample_{i}.svg",
        ]
    )
    print(f"Generated sample_{i}.svg")
