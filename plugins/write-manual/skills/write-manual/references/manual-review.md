# Manual review

How a debussy skill picks up after the user has reviewed a file by hand (a plan,
a manual). Every debussy plugin with a manual review step ships an identical
copy of this file.

When you hand the file over, tell the user its path and the note markers in
effect (`noteMarkers` in `settings.md`), so they know how to leave notes. They
edit the file in their own editor and then say they are done: "done", "go",
"continue", "ready", or anything like it. At that point the word means "act on
what I put in the file", not "carry on with the plan". Then:

1. **Find every note.** Search the file for each configured marker as a fixed
   string, not a regular expression: markers like `[usernote]` or `%%%` contain
   characters a regex would misread. Count them. Notes can sit anywhere,
   including inside code blocks, tables, and HTML.
2. **Find the edits made without a marker.** With the file committed,
   `git diff -- <file>` shows every line the user added, changed, or deleted;
   otherwise compare with the version you last wrote. Those edits are the
   user's intent too: keep them, and treat a deletion as deliberate.
3. **Understand each note where it stands:** what it is attached to, and
   whether it is an instruction, an objection, or a question. A question gets
   an answer in your reply, and a change to the file when the answer implies
   one.
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
     `??`, a different marker).

   Ask about every doubtful note in one round, quoting each note and where it
   sits, and wait for the answer. Meanwhile, carry out the clear notes, unless a
   doubtful one could change them.
5. **Act, then remove.** Carry out each note, then delete the note and its
   markers from the file: notes are instructions, not content. Leave a note in
   place only while its question to the user is open.
6. **Verify.** Search again for every marker. Only notes still waiting on the
   user may remain.
7. **Report:** how many notes you found; one line per note saying what you did,
   or the question it is waiting on; and the direct edits you noticed and how
   you treated them. Then offer another round of review, since the user may
   want to check the result.
