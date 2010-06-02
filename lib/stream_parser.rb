#stream_parser.rb

=begin

This file is part of Racket.

Racket is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

Racket is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with Racket.  If not, see <http://www.gnu.org/licenses/>.

Copyright (c) 2009, Lucas Di Cioccio

=end

require File.join(File.dirname(__FILE__), 'racket')

module Racket
  class StreamParser

    attr_reader :io, :pkt_klass, :bufsize
    def initialize(io, klass, bufsize=1024)
      raise ArgumentError.new("klass should be a Packet") unless pkt_klass.ancestors.include? Packet
      @io = io
      @pkt_klass = klass
      @bufsize = bufsize
    end

    def each_pkt
      loop do
        pkt = @pkt_klass.new
        pkt.decode! do
          #read data from io if not enough
          data = @io.read(@bufsize)
          #TODO: check on data
          pkt.trailing_data << data
        end
      end
    end

  end
end
