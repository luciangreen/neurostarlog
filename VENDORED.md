# Vendored code

The folders `s2a/` and `s2g/` are copies of the author's Spec to Algorithm
and Spec to Grammar code, kept here so NeuroStarlog runs on its own. They are
not updated automatically: a fix in the originals does not reach these
copies, and a change here does not reach the originals.

`vendored.sha256` lists a checksum for every file in both folders as they
were when this note was written (26 November 2026). To see whether the
copies have been changed since:

```sh
sha256sum -c vendored.sha256
```

When updating the copies from the originals, copy the folders over, note
here the commit of the original they came from, and regenerate the list:

```sh
find s2a s2g -type f | sort | xargs sha256sum > vendored.sha256
```

| Folder | Copy of | Original commit |
|--------|---------|-----------------|
| `s2a/` | Spec to Algorithm | not recorded (copied before this note) |
| `s2g/` | Spec to Grammar | not recorded (copied before this note) |
