# io_delimited_ios_hotpatch.cr
There is a problem with IO::Delimited in recent versions of Crystal (the boundaries are not clear yet, but sometime after 1.6.2, and definitely in 1.12.2) that causes file upload failures with iOS. This patch works around the problem while it is being isolated and fixed upstream.
