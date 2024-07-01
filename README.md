# io_delimited_ios_hotpatch

Recent versions of Crystal -- 1.12.2, at least, though maybe other versions, as well -- have a bug that can be exposed by doing a file upload with a multipart form, from an iOS platform. The problem is still be isolated in specific detail, but the failure is related to a Slice overrun. Something about how iOS is returning the data triggers an execution path that results in IO::Delimited#read_with_peek attempting to copy more data into a buffer than there is space for it.

This current fix doesn't address the root problem, but it does address the symptom. It adds a check to IO::Delimited#read_with_peek to ensure that the buffer has enough space for the data that is being copied into it. If it doesn't, the buffer is resized to be large enough.

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     io_delimited_ios_hotpatch:
       github: wyhaines/io_delimited_ios_hotpatch.cr
   ```

2. Run `shards install`

## Usage

```crystal
require "io_delimited_ios_hotpatch"
```

## Contributing

1. Fork it (<https://github.com/wyhaines/io_delimited_ios_hotpatch/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Kirk Haines](https://github.com/wyhaines) - creator and maintainer
