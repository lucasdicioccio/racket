
#require File.join(File.dirname(__FILE__), '..', 'lib', 'racket')
#require File.join(File.dirname(__FILE__), '..', 'lib', 'field')

require 'rubygems'
require 'racket'

include Racket

class DumbPayload < Packet
  fields [:head, Char],
    [:data, HexPair]
end

class DumbPacket < Packet

  fields [:header, 'a2a2'],
    [:midamble, 'a3'],
    [:chksum, 'a2', 'hi'],
    [:payload, '?'],
    [:trailer, 'a2'],
    [:padding, 'a*']

  encode_order :header, :midamble, :payload, :trailer, :padding, :chksum

  def encode_chksum
    puts self.to_s
    'ZZ'
  end

  def size_for_payload
    400000 # just to show that we yield
  end

  def decode_payload
    @payload = DumbPayload.new(@trailing_data)
    @payload.decode!
  end

  def encode_payload
    @payload.encode!
    @payload.to_s
  end

  def before_decoding
    puts "starting to decode"
  end

  def after_decoding
    puts "done decoding"
  end

  def before_encoding
    puts "starting to encode"
  end

  def after_encoding
    puts "done encoding"
  end
end


string = "abcdefghijklmnopqrstuvwxyz"

pkt = DumbPacket.new(string)
pkt.decode! do |f|
  puts "yielded, not enough data"
  sleep 1 #simulate long to come IO
  pkt.trailing_data << ".blablathatcameafter"
end
puts pkt.inspect

pkt.encode!

puts pkt.to_s
