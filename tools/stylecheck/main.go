// Command stylecheck enforces the rules in STYLE.md that a program can check.
//
// In every text file it rejects em-dashes and emojis. In markdown, outside
// code, it also rejects a double hyphen used as a dash and paragraphs that
// are hard-wrapped across lines. Inside markdown code blocks it rejects
// ASCII box diagrams; draw those as SVG files instead.
//
// Usage: go run ./tools/stylecheck [root]
package main

import (
	"bufio"
	"fmt"
	"io/fs"
	"os"
	"path/filepath"
	"regexp"
	"strings"
)

// Folders the check skips. The archive keeps the old course as it was.
var skipDirs = map[string]bool{".git": true, "archive": true, "node_modules": true}

var textExt = map[string]bool{".md": true, ".go": true, ".sh": true, ".yaml": true, ".yml": true, ".json": true}

var (
	inlineCode = regexp.MustCompile("`[^`]*`")
	dashLike   = regexp.MustCompile(`\s--\s`)
	// A line that starts a markdown block other than a plain paragraph.
	blockStart = regexp.MustCompile(`^(\s*[-*+] |\s*\d+\. |#|\||>|\s*<|!\[|\[\^|\s{4})`)
	// A box corner such as "+-----" in an ASCII diagram.
	asciiBox = regexp.MustCompile(`\+-{3,}`)
)

type problem struct {
	file string
	line int
	msg  string
}

func main() {
	root := "."
	if len(os.Args) > 1 {
		root = os.Args[1]
	}
	var problems []problem
	err := filepath.WalkDir(root, func(path string, d fs.DirEntry, err error) error {
		if err != nil {
			return err
		}
		if d.IsDir() {
			if skipDirs[d.Name()] && path != root {
				return filepath.SkipDir
			}
			return nil
		}
		if textExt[filepath.Ext(path)] || d.Name() == "Makefile" {
			p, err := checkFile(path)
			if err != nil {
				return err
			}
			problems = append(problems, p...)
		}
		return nil
	})
	if err != nil {
		fmt.Fprintln(os.Stderr, "stylecheck:", err)
		os.Exit(2)
	}
	for _, p := range problems {
		fmt.Printf("%s:%d: %s\n", p.file, p.line, p.msg)
	}
	if len(problems) > 0 {
		fmt.Printf("%d style problem(s)\n", len(problems))
		os.Exit(1)
	}
	fmt.Println("stylecheck: ok")
}

func checkFile(path string) ([]problem, error) {
	f, err := os.Open(path)
	if err != nil {
		return nil, err
	}
	defer f.Close()

	isMarkdown := filepath.Ext(path) == ".md"
	var out []problem
	inFence := false
	prevPlain := false
	n := 0
	sc := bufio.NewScanner(f)
	sc.Buffer(make([]byte, 1024*1024), 1024*1024)
	for sc.Scan() {
		n++
		line := sc.Text()
		if strings.ContainsRune(line, rune(0x2014)) {
			out = append(out, problem{path, n, "em-dash"})
		}
		if hasEmoji(line) {
			out = append(out, problem{path, n, "emoji"})
		}
		if !isMarkdown {
			continue
		}
		if strings.HasPrefix(strings.TrimSpace(line), "```") {
			inFence = !inFence
			prevPlain = false
			continue
		}
		if inFence {
			if asciiBox.MatchString(line) {
				out = append(out, problem{path, n, "ASCII diagram (draw it as an SVG in the chapter's images/ folder)"})
			}
			continue
		}
		prose := inlineCode.ReplaceAllString(line, "")
		if dashLike.MatchString(prose) {
			out = append(out, problem{path, n, "double hyphen used as a dash"})
		}
		plain := strings.TrimSpace(line) != "" && !blockStart.MatchString(line)
		if plain && prevPlain {
			out = append(out, problem{path, n, "hard-wrapped paragraph (join it with the line above)"})
		}
		prevPlain = plain
	}
	return out, sc.Err()
}

func hasEmoji(s string) bool {
	for _, r := range s {
		switch {
		case r >= 0x1F300 && r <= 0x1FAFF, // pictographs, emoticons, transport, symbols
			r >= 0x2600 && r <= 0x27BF,   // miscellaneous symbols and dingbats
			r >= 0x1F1E6 && r <= 0x1F1FF, // regional indicators (flags)
			r == 0xFE0F:                  // emoji presentation selector
			return true
		}
	}
	return false
}
