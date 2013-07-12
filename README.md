minifyBackup
============

Name
----

minify_backup.sh - reduce backup size by compressing images and replacing large files with dummy content

Synopsis
--------

    minify_backup.sh [-aiopv] -s /path/to/backup -t /path/to/minified-backup

Description
-----------

    -s
        path to source directory (required)
    -t
        path to target directory (required)
    -a
        minify audio files (optional)
    -i
        compress images (optional)
    -o
        minify other files (optional)
    -p
        minify PDF documents (optional)
    -v
        minify video files (optional)

Todo
----

* Add dummy content for audio and video files instead of replacing them with an empty text file
* Add option to exclude folders from processing (eg. typo3, t3lib, user-defined test content)
* Add more precondition checks (eg. availability of convert, rsync)
* Add error handling
