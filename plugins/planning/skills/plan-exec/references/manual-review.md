# Manual review

How a debussy skill picks up after the user has reviewed a file by hand (a plan,
a manual). Every debussy plugin with a manual review step ships an identical
copy of this file.

When you hand the file over, tell the user its path and the note markers in
effect (`noteMarkers` in `settings.md`), so they know how to leave notes. They
write notes in their own editor or in
[PlanCake](https://github.com/Oire/plan-cake), which shows the file rendered
and writes each note into it, and then say they are done: "done", "go",
"continue", "ready", or anything like it. At that point the word means "act on
what I put in the file", not "carry on with the plan". Then:

1. **Find every note.** Search the file for each configured marker as a fixed
   string, not a regular expression: markers like `[usernote]` or `%%%` contain
   characters a regex would misread. Count them. Notes can sit anywhere,
   including inside code blocks, tables, and HTML.

   When `plancake` is on the PATH (`plancake.exe` under WSL, given a relative
   path), let PlanCake find them instead: run `plancake list <file> --json`
   once per configured marker, and pass the marker, so it reads the markers in
   effect here rather than the ones in its own settings:
   `--open-marker '[usernote]' --close-marker '[/usernote]'` for a pair,
   `--open-marker '!USERNOTE!' --single-token` for a token. Each entry gives
   the note's first and last line, its `text` with the indentation taken off,
   and the block it belongs to: `blockStartLine`, `blockEndLine`, `blockKind`,
   and `blockExcerpt`. Exit code 1 is an error, printed on the error output;
   say so and fall back to the search.
2. **Find the edits made without a marker.** With the file committed,
   `git diff -- <file>` shows every line the user added, changed, or deleted;
   otherwise compare with the version you last wrote. Those edits are the
   user's intent too: keep them, and treat a deletion as deliberate.
3. **Understand each note where it stands:** what it is attached to, and
   whether it is an instruction, an objection, or a question. A question gets
   an answer in your reply, and a change to the file when the answer implies
   one.
   - A note is Markdown. It can run over several lines and hold lists,
     emphasis, links, code spans, and fenced code: that is how the user wrote
     it, not text to copy into the file. A list is several requests, and a code
     span names a thing. A fence inside a pair-marked note belongs to the note,
     so the closing marker after it still ends the note.
   - PlanCake writes a note on its own lines right after the block it is
     about: a paragraph, heading, list item, table row, or code block. Notes on
     the same block follow it in the order they were left. Each line of a note
     is indented to match its block, out to the text of a list item, and that
     indentation is not part of the note. `plancake list` names that block for
     you; a note in the middle of a line belongs to the block it sits in.
4. **Stop and ask at the slightest doubt.** The user reviews by hand because
   they want their intent carried out exactly, so a guess costs more than a
   question. A note is in doubt when:
   - it can be read more than one way, or where it ends is unclear;
   - it conflicts with another note, a direct edit, or something the user said
     earlier;
   - carrying it out needs a decision the note does not make (a name, an
     approach, the scope);
   - it would mean changing something the note does not point at;
   - something looks like a note but does not use a configured marker (`TODO:`,
     `??`, a different marker);
   - a marker may be quoted rather than used, as in a code span or a passage
     that documents the markers themselves.

   Ask about every doubtful note in one round, quoting each note and where it
   sits, and wait for the answer. Meanwhile, carry out the clear notes, unless a
   doubtful one could change them.
5. **Act, then remove.** Carry out each note, then delete the note and its
   markers from the file: notes are instructions, not content. A note on lines
   of its own goes with those lines, indentation included, and the blank lines
   around it stay as they were; a note inside a line leaves the rest of that
   line. Leave a note in place only while its question to the user is open.
6. **Verify.** Search again for every marker. Only notes still waiting on the
   user may remain. With PlanCake, run `plancake check <file>` with the same
   marker options as before: it prints the count, and exits with 0 when no
   note is left, 3 when some are, and 1 on an error.
7. **Report:** how many notes you found; one line per note saying what you did,
   or the question it is waiting on; and the direct edits you noticed and how
   you treated them. Then offer another round of review, since the user may
   want to check the result.
