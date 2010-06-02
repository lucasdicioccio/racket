#racket.rb

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

require File.join(File.dirname(__FILE__), 'field')
require File.join(File.dirname(__FILE__), 'errors')

module Racket
  class Packet

    class << self
      # define new fields in their appeareance order
      # if no argument is passed, simply acts as a getter
      def fields(*args)
        if args.empty?
          @fields || []
        else
          @fields = []
          args.each {|ary| parse_field_args(ary)}
        end
      end

      # parse the fields arguments and create a new field
      # TODO some more verifications
      def parse_field_args(ary)
        sym = ary.shift
        decoder = ary.shift
        default = ary.shift

        attr_accessor sym #TODO: beter than that

        field = if decoder == '?'
                  DynamicFieldDefinition.new(sym, default)
                elsif decoder.is_a? String
                  RawFieldDefinition.new(sym, decoder, default)
                elsif (decoder.is_a? Class) and 
                  (decoder.ancestors.include?  StandardFieldDefinition)
                  decoder.new(sym, default)
                end

        @fields << field
      end

      # set the decoding order of the fields, 
      # they can be different from the reading/writing 
      # order (e.g. checksum in the header)
      def decode_order(*args)
        if args.empty?
          @fields_decode_order || []
        else
          check_order_args args
          @fields_decode_order = *args
        end
      end

      # same as decode_order but for encoding
      def encode_order(*args)
        if args.empty?
          @fields_encode_order || []
        else
          check_order_args args
          @fields_encode_order = *args
        end
      end

      # returns the instance of FieldDefinition given its name (should be a symbol)
      def field_for_name(name)
        @fields.find{|f| f.name == name}
      end

      private

      # helper to check if the decode_order or encode_order arguments
      # are well formed (i.e. all the fieldnames are present and none is added)
      def check_order_args(ary)
        tst = ary.select{|i| not field_for_name i}
        if not tst.empty?
          raise ArgumentError.new("#{tst.inspect} not declared field in #{self}")
        else
          tst = @fields.map{|f| f.name}.select{|i| not ary.include?(i)}
          if not tst.empty?
            raise ArgumentError.new("#{tst.inspect} declared field in #{self} but not in the ordering ary")
          end
        end
      end
    end

    attr_reader :trailing_data, :data_chunks, :coding_state
    attr_accessor :pkt_timestamp

    # initialize a new Packet setting its trailing_data to raw argument
    def initialize(raw='')
      @trailing_data = raw
      @data_chunks = {}
      @coding_state = :building
      yield self if block_given?
      @coding_state = :pending
    end

    # pretty way of printing a packet with its fields 
    # and other included packets
    def inspect
      str = '+--- '
      str << self.class.to_s
      str << ": #{self.pkt_timestamp} + #{self.pkt_timestamp.usec}usec" if self.pkt_timestamp
      str << "\n"
      each_field(:decode) do  |f| 
        str << inspect_field(f)
      end
      str << "+--\n"
      str
    end

    # build the part of the packet.inspect string for a field
    # first tries with an inspect_<fieldname>
    def inspect_field(f)
      meth = "inspect_#{f.name.to_s}"
      str = if respond_to? meth
              send meth
            else
              a = get_field(f)
              if a.is_a? Packet
                '|   ' + f.name.to_s + ': ' + "\n" + a.inspect.gsub(/^/,"|   ")
              else
                '| ' + f.name.to_s + ': ' + a.inspect + "\n"
              end
            end
    end

    # decode the  fields one after each other
    # the detailed process is the following:
    # - call before_decoding
    # - yield field if block_given
    # - decode each field by calling the decode_#{fieldname} method
    # - call after_decoding
    # - returns the remaining data that was not read
    def decode!
      @coding_state = :decoding
      send(:before_decoding) if self.respond_to? :before_decoding
      each_field(:decode) do  |f| 
        if block_given?
          yield(f) unless enough_data_for_field?(f)
        end
        decode_field(f)
      end
      send(:after_decoding) if self.respond_to? :after_decoding
      @coding_state = :pending
      @trailing_data
    end

    # prepare the decoding of all chunks and store them in the @data_chunks ivar
    def encode!
      @data_chunks = {}
      @coding_state = :encoding

      send(:before_encoding) if self.respond_to? :before_encoding
      each_field(:encode) do  |f| 
        @data_chunks[f] = f.default_value
        val = encode_field(f)
        @data_chunks[f] = val if val
      end
      send(:after_encoding) if self.respond_to? :after_encoding
      @coding_state = :pending
    end

    # returns a raw string from the various encoded chunks, missing chunks
    # are ignored
    # oredering is the original one (definition in the fields class method)
    def to_s
      str = ''
      each_field(:original) do |f|
        str << if @data_chunks[f].nil?
                 f.default_value || ''
        else
          @data_chunks[f].to_s
        end
      end
      str
    end

    # yield each field of the structure given the desired ordering
    # defaults to the assignement with the Packet.fields method
    def each_field(direction=nil)
      ary = if direction == :decode
              self.class.decode_order
            elsif direction == :encode
              self.class.encode_order
            elsif direction == :original
              self.class.fields.map{|f| f.name}
            else
              []
            end

      if ary.empty?
        self.class.fields.each {|f| yield(f)}
      else
        ary.each {|f| yield(self.class.field_for_name(f))}
      end
    end

    # calls the decode_#{fieldname} method except for rawfields that are known
    def decode_field(field)
      meth = "decode_#{field.name.to_s}"
      @trailing_data = if respond_to? meth
                         send meth
                       elsif field.is_a? RawFieldDefinition
                         decode_rawfield field
                       else
                         raise DecodingError.new("don't know how to decode #{field}")
                       end
    end

    # calls the encode_#{fieldname} method except for rawfields that are known
    def encode_field(field)
      meth = "encode_#{field.name.to_s}"
      string = if respond_to? meth
                 send meth
               elsif field.is_a? RawFieldDefinition
                 if get_field(field).nil?
                   nil
                 else
                   encode_rawfield field
                 end
               else
                 raise EncodingError.new("don't know how to encode #{field}")
               end
      string
    end

    # tries to see if there is enough in the @trailing_data to decode a given field
    def enough_data_for_field?(field)
      (size_for_field(field) <= @trailing_data.size)
    end

    # gets the size that will be needed to parse a field
    # - if the field respond to :size, then use that
    # - else tries to send :size_for_<fieldname>
    # - else returns 0, that is, the next parsing might completely fail
    #   if there is not enough data left in @trailing_data
    def size_for_field(field)
      if field.respond_to? :size
        field.size
      elsif field.is_a? DynamicFieldDefinition
        meth = "size_for_#{field.name.to_s}"
        val = send meth if self.respond_to? meth
        val || 0
      else
        0
      end
    end

    # get an attribute given a field definition via the accessor meth
    def get_field(field)
      meth = "#{field.name.to_s}"
      send meth
    end

    # set an attribute given a field definition via the accessor meth
    def set_field(field, val)
      meth = "#{field.name.to_s}="
      send meth, val
    end

    # decode a rawfield, basically it calls unpack on the remaining data
    def decode_rawfield(field)
      field = self.class.field_for_name(field) if field.is_a? Symbol
      decoded = @trailing_data.unpack(field.pack_atom + 'a*')
      ret = decoded.pop
      decoded = decoded.first if decoded.size == 1
      set_field field, decoded
      ret
    end

    # get a field value an pack it
    def encode_rawfield(field)
      val = get_field(field)
      val = [val] unless val.is_a? Array
      encoded = val.pack(field.pack_atom)
      encoded
    end

  end
end

