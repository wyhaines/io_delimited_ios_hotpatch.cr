require "./version"

class IO::Delimited < IO
  private def read_with_peek(slice : Bytes, peek : Bytes) : Int32
    # If there's nothing else to peek, we reached EOF
    if peek.empty?
      @finished = true

      if @active_delimiter_buffer.empty?
        return 0
      else
        # If we have something in the active delimiter buffer,
        # but we don't have any more data to read, that wasn't
        # the delimiter so we must include it in the slice.
        return read_from_active_delimited_buffer(slice)
      end
    end

    first_byte = @read_delimiter[0]

    # If we have something in the active delimiter buffer
    unless @active_delimiter_buffer.empty?
      # This is the rest of the delimiter we have to match
      delimiter_remaining = @read_delimiter[@active_delimiter_buffer.size..]

      # This is how much we can actually match of that (peek might not have enough data!)
      min_size = Math.min(delimiter_remaining.size, peek.size)

      # See if what remains to match in the delimiter matches whatever
      # we have in peek, limited to what's available
      if delimiter_remaining[0, min_size] == peek[0, min_size]
        # If peek has enough data to match the entire rest of the delimiter...
        if peek.size >= delimiter_remaining.size
          # We found the delimiter!
          @io.skip(min_size)
          @active_delimiter_buffer = Bytes.empty
          @finished = true
          return 0
        else
          # Copy the remaining of peek to the active delimiter buffer for now
          (@delimiter_buffer + @active_delimiter_buffer.size).copy_from(peek)
          @active_delimiter_buffer = @delimiter_buffer[0, @active_delimiter_buffer.size + peek.size]

          # Skip whatever we had in peek, and try reading more
          @io.skip(peek.size)
          return read_internal(slice)
        end
      else
        # No match.
        # We first need to check if the delimiter could actually start in this active buffer.
        next_index = @active_delimiter_buffer.index(first_byte, 1)

        # We read up to that new match, if any, or the entire buffer
        read_bytes = Math.min(next_index || @active_delimiter_buffer.size, slice.size)

        slice.copy_from(@active_delimiter_buffer[0, read_bytes])
        slice += read_bytes
        @active_delimiter_buffer += read_bytes
        return read_bytes + read_internal(slice)
      end
    end

    index =
      if slice.size == 1
        # For a size of 1, this is much faster
        first_byte == peek[0] ? 0 : nil
      elsif slice.size < peek.size
        peek[0, slice.size].index(first_byte)
      else
        peek.index(first_byte)
      end

    # If we can't find the delimiter's first byte we can just read from peek
    unless index
      # If we have more in peek than what we need to read, read all of that
      if peek.size >= slice.size
        if slice.size == 1
          # For a size of 1, this is much faster
          slice[0] = peek[0]
        else
          slice.copy_from(peek[0, slice.size])
        end
        @io.skip(slice.size)
        return slice.size
      else
        # Otherwise, read from peek for now
        slice.copy_from(peek)
        @io.skip(peek.size)
        return peek.size
      end
    end

    # If the delimiter is just a single byte, we can stop right here
    if @delimiter_buffer.size == 1
      slice.copy_from(peek[0, index])
      @io.skip(index + 1)
      @finished = true
      return index
    end

    # If the delimiter fits the rest of the peek buffer,
    # we can check it right now.
    if index + @delimiter_buffer.size <= peek.size
      # If we found the delimiter, we are done
      if peek[index, @delimiter_buffer.size] == @read_delimiter
        slice.copy_from(peek[0, index])
        @io.skip(index + @delimiter_buffer.size)
        @finished = true
        return index
      else
        # Otherwise, we can read up to past that byte for now
        slice.copy_from(peek[0, index + 1])
        @io.skip(index + 1)
        slice += index + 1
        return index + 1
      end
    end

    # If the part past in the peek buffer past the matching index
    # doesn't match the read delimiter's portion, we can move on
    rest = peek[index..]
    unless rest == @read_delimiter[0, rest.size]
      # We can read up to past that byte for now
      safe_to_read = peek[0, index + 1]
      slice.copy_from(safe_to_read)
      @io.skip(safe_to_read.size)
      slice += safe_to_read.size
      return safe_to_read.size
    end

    # Copy up to index into slice
    slice.copy_from(peek[0, index])
    slice += index

    # Copy the rest of the peek buffer into delimited buffer
    @delimiter_buffer.copy_from(rest)
    @active_delimiter_buffer = @delimiter_buffer[0, rest.size]

    @io.skip(peek.size)

    index + read_internal(slice)
  end
end
