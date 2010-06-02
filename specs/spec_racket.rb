
require File.join(File.dirname(__FILE__), '..', 'lib', 'racket')

include Racket

describe "Packet definition" do

  before(:each) do
    @klass = Class.new(Packet)
    @klass.fields [:a, '?', 'aaa'],
      [:b, 'H2'],
      [:c, '?']
  end

  after(:each) do
    @klass = nil
  end

  it "should create correct fields" do
    @klass.fields.should have(3).fields
  end

  it "should create accessors" do
    @klass.new().should respond_to(:a, :a=, :b, :b=, :c, :c=)
  end

  it "should find fields for name" do
    @klass.field_for_name(:a).should eql(@klass.fields.first)
    @klass.field_for_name(:a).should be_a(FieldDefinition)
  end

  def tst_order(direction, expect_failure, *args)
    val = if direction == :decode
            lambda {@klass.decode_order(*args)}
          else
            lambda {@klass.encode_order(*args)}
          end

    if expect_failure == :ko
      val.should raise_error(ArgumentError)
    else
      val.should_not raise_error(ArgumentError)
    end
  end

  it "should complains about ordering" do
    [[:a], [:a,:b,:c,:d]].each do |set|
      tst_order(:decode, :ko, *set)
      tst_order(:encode, :ko, *set)
    end
  end

  it "should not complains about ordering" do
    [[:a,:b,:c], [:a,:c,:b], [:b, :a, :c],
      [:b, :c, :a], [:c, :a, :b], [:c, :b, :a]].each do |set|
      tst_order(:decode, :ok, *set)
      tst_order(:encode, :ok, *set)
      end
  end


end

describe "Packet decoding" do

  before(:each) do
    @klass = Class.new(Packet)
    @klass.fields [:a, '?', 'aaa'],
      [:b, 'H2'],
      [:c, '?']
    @klass.decode_order :a, :c, :b
    @klass.encode_order :c, :b, :a
    @klass.class_eval %{
      def decode_c
        puts "hello"
      end
    }
  end

  after(:each) do
    @klass = nil
  end

  it "should iterate each field correctly" do
    pkt = @klass.new
    ary = Enumerable::Enumerator.new(pkt, :each_field).map{|f| f.name}
    ary.should eql([:a,:b,:c])
  end

  it "should iterate with decoding order" do
    pkt = @klass.new
    ary = Enumerable::Enumerator.new(pkt, :each_field, :decode).map{|f| f.name}
    ary.should eql([:a,:c,:b])
  end

  it "should iterate with encoding order" do
    pkt = @klass.new
    ary = Enumerable::Enumerator.new(pkt, :each_field, :encode).map{|f| f.name}
    ary.should eql([:c,:b,:a])
  end

  it "should simply work, no?" do
    pkt = @klass.new
    pkt.decode! do |f|
      puts f
    end
  end

  it "should yield before" do
  end

  it "should yield each item" do
  end

  it "should yield after" do
  end


end
