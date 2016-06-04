#!/usr/bin/env ruby
# coding: utf-8
# This script is a simple wrapper which pre/appends each i3status line with
# custom information.
#
# To use it, ensure your ~/.i3status.conf contains this line:
#     output_format = "i3bar"
# in the 'general' section.
# Then, in your ~/.i3/config, use:
#     status_command ~/.i3/i3status.rb
# In the 'bar' section.
#
# © 2014+ Joan Blackmoore (a.k.a JoanBM), <blackmoore.joan@gmail.com>
#
# This program is free software. It comes without any warranty, to the extent
# permitted by applicable law. You can redistribute it and/or modify it under
# the terms of the Do What The Fuck You Want To Public License (WTFPL), Version
# 2, as published by Sam Hocevar. See http://sam.zoy.org/wtfpl/COPYING for more
# details.
require 'json'
require 'timeout'


def main
  I3Status.new(timeout: 5).main_loop
end


class I3Status
  DEFAULT_TIMEOUT = 0
  STATUS_CMD = ['i3status', '-c', "#{ENV['HOME']}/.i3/i3status.conf"]
  IO_POLLING_TIMEOUT = Rational(1,10)

  def initialize(timeout: DEFAULT_TIMEOUT, ext_cmd: STATUS_CMD)
    STDOUT.sync, STDIN.sync = true, true
    STDIN.flush

    @timeout       = timeout
    @ext_cmd       = ext_cmd
    @ext_io        = nil
    @i3bar_version = 1

    @xkb_label = {'name'       => 'xkb',
                  'full_text'  => '',
                  'color'      => '#ffff00'}
    begin
      require 'xkb'
    rescue LoadError => exc
      STDERR.puts exc
      @@xkb = nil
    else
      @@xkb = Xkb::XKeyboard.new
    end

    Signal.trap('SIGINT'){ @ext_io.close if @ext_io && !@ext_io.closed?; exit }
  end

  def main_loop
    cached_row = []
    init_status
    prefix = ''

    loop do
    begin
      row = read_status cached_row
    rescue JSON::JSONError
      sleep 1
      next
    rescue Timeout::Error
      row = cached_row
    rescue EOFError => exc
      STDERR.puts exc.message
    ensure
      # echo back new encoded JSON
      unless row.nil? || row.empty?
        STDOUT.puts(prefix + JSON.fast_generate(row))
        prefix = ','
      end
    end
    end
  end

  # returns has with updated current xkb group
  def xkb_status
    xkb_label = @xkb_label.dup
    xkb_label['full_text'] = @@xkb ? @@xkb.current_group_symbol.upcase : '--'
    xkb_label
  end

  protected
  def init_status
    if @ext_cmd && !@ext_cmd.empty?
      @ext_io = IO.popen @ext_cmd

      ver = JSON.parse(@ext_io.readline)['version']
      unless ver && ver.integer?
        raise TypeError, 'i3bar\'s version expected !'
      else
        @i3bar_version = ver
      end
      unless @ext_io.readline.strip == '['
        raise TypeError, 'Opening bracket expected !'
      end
    end

    # Print header format preceding an infinite loop
    STDOUT.print JSON.fast_generate({'version' => @i3bar_version}) + "\n[\n"
  end

  def read_status(cached_row)
    Timeout.timeout(@timeout) do
      input_fds = (@ext_io && !@ext_io.closed? ? [@ext_io] : [])

      loop do
        # handle adhoc events first
        return cached_row if adhoc_status! cached_row
        # setting of non-blocking mode won't work for stdin
        # using IO::select instead
        ios_ready = IO.select(input_fds, [], [], IO_POLLING_TIMEOUT)
        if ios_ready
          # handle external command output
          if ios_ready[0].member? @ext_io
            line = @ext_io.readline
            # ignore comma at start of lines
            line = line.match(/^,?(.*)/)[1]
            # parse output from JSON format
            return merge_rows!( cached_row, JSON.parse(line) )
          end
        end
      end

    end
    return res
  end

  def adhoc_status!(cached_row)
    # XKB status
    xkb_label = xkb_status
    unless cached_row.member? xkb_label
      merge_rows! cached_row, [xkb_label], true
      true
    else
      false
    end
  end

  private
  # merge arrays of hashes in-place
  # row1 - being updated
  # row2 - hashes taken from
  # append - way how new hashes are added:
  #           appended at the end or inserted at row2 positions
  def merge_rows!(row1, row2, append=false)
    row2.each_with_index do
      |hsh, ix|
      elem = row1.detect {|h| h['name'] == hsh['name']}
      if elem
        elem.replace hsh
      else
        append ? row1 << hsh : row1.insert(ix, hsh)
      end
    end
    row1
  end
end


if __FILE__ == $0
  main
end
