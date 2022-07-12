# Contributing
Here are the rules if you want to contribute to this repository.

1. You should first open an issue describing the changes you want. You should also mention that you want to open a pull request.
2. When writing code, make sure to follow the [style guide](#gdscript-style-guide).

## GDScript style guide
It's basically [this](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html) but with a few changes.

### Summary 
1. Use snake_case for variable names, functions and signals.
2. Signals should be in the past tense.
3. Nodes, classes and file names should use PascalCase.
4. Use 2 newlines between functions, unless they are short.
5. Use static typing as much as you can.

## Adding a new language
1. Open an issue with the `localization` label.
3. Download [this spreadsheet](https://docs.google.com/spreadsheets/d/1VEE4aROwNFXsZTRbMOShlv2E8XcYVBYYEVsRbFYKBog/edit?usp=sharing) and add your translations.
4. Export to CSV. I recommend Google Sheets or LibreOffice. Microsoft Excel doesn't support UTF-8 encoding.
5. Fork this repository and then clone your fork. If you don't want to clone it or download Godot, you can skip steps 7 and 8 and modify these files manually: `languages/text.csv`, `languages/text.csv.import` and `project.godot`. See [this commit](https://github.com/pattlebass/Music-DJ/commit/0f731ceb8ef40bb3e9e6b50cb445cd1630486db5) and [this one](https://github.com/pattlebass/Music-DJ/commit/1951c9809aba8a980f3357f04870d24ce758394e) (ignore line 87).
6. Replace `languages/text.csv` with the file you exported.
7. Open the project with the Godot version mentioned in [this file](https://github.com/pattlebass/Music-DJ/blob/main/android/.build_version).
8. In the top left, Project > Project Settings > Localization > Add > Select the language you added.
9. Commit and push the changes to your fork.
10. That's it. Now all you have to do is open a Pull Request which mentions that it fixes the issue you opened (e.g. Fixes #10).
11. Optional: If you want to update the translation whenever there are changes, I suggest subscribing to [this discussion](https://github.com/pattlebass/Music-DJ/discussions/9).
