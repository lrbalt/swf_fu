require File.dirname(__FILE__)+'/test_helper'
require File.dirname(__FILE__)+'/results'

class SwfFuTest < ActionView::TestCase
  def assert_same_stripped(expect, test)
    expect, test = [expect, test].map{|s| s.split("\n").map(&:strip).join("\n")}
    STDOUT << "\n\n---- Actual result: ----\n" << test << "\n---------\n" unless expect == test
    assert_equal expect, test
  end

  context "swf_path" do   
    context "with no special asset host" do
      should "deduce the extension" do
        assert_equal swf_path("example.swf"), swf_path("example")
        assert_starts_with "/swfs/example.swf", swf_path("example.swf")
      end
      
      should "accept relative paths" do
        assert_starts_with "/swfs/whatever/example.swf", swf_path("whatever/example.swf")
      end
      
      should "leave full paths alone" do
        ["/full/path.swf", "http://www.example.com/whatever.swf"].each do |p|
          assert_starts_with p, swf_path(p)
        end
      end
    end
    
    context "with custom asset host" do
      HOST = "http://assets.example.com"
      setup do
        ActionController::Base.asset_host = HOST
      end
      
      teardown do
        ActionController::Base.asset_host = nil
      end
      
      should "take it into account" do
        assert_equal "#{HOST}/swfs/whatever.swf", swf_path("whatever")
      end
    end
  end
      
  context "swf_tag" do
    COMPLEX_OPTIONS = { :width => "456", :height => 123,
                        :flashvars => {:flashVar1 => "value 1 > 2", :flashVar2 => 42},
                        :parameters => {:allowscriptaccess => "always", :play => true},
                        :html_options => {:class => "lots", :style => "hot"},
                        :javascript_class => "SomeClass",
                        :initialize => {:be => "good", :eat => "well"}
                      }
      
    should "understand size" do
      assert_equal  swf_tag("hello", :size => "123x456"),
                    swf_tag("hello", :width => 123, :height => "456")
    end
  
    should "only accept valid modes" do
      assert_raise(ArgumentError) { swf_tag("xyz", :mode => :xyz)  }
    end

    context "with custom defaults" do
      setup do
        test = {:flashvars=> {:xyz => "abc"}, :mode => :static, :size => "400x300"}
        @expect = swf_tag("test", test)
        ActionView::Base.swf_default_options = test
      end
      
      should "respect them" do
        assert_equal @expect, swf_tag("test")
      end
      
      teardown { ActionView::Base.swf_default_options = {} }        
    end

    context "with static mode" do
      setup { ActionView::Base.swf_default_options = {:mode => :static} }

      should "deal with string flashvars" do
        assert_equal  swf_tag("hello", :flashvars => "xyz=abc", :mode => :static),
                      swf_tag("hello", :flashvars => {:xyz => "abc"}, :mode => :static)
      end

      should "produce the expected code" do
        assert_same_stripped STATIC_RESULT, swf_tag("mySwf", COMPLEX_OPTIONS)
      end
      
      teardown { ActionView::Base.swf_default_options = {} }
    end
    
    context "with dynamic mode" do
      should "produce the expected code" do
        assert_same_stripped DYNAMIC_RESULT, swf_tag("mySwf", COMPLEX_OPTIONS)
      end
      
    end
  end

  context "flashobject_tag" do
    should "be the same as swf_tag with different defaults" do
      assert_same_stripped swf_tag("mySwf",
        :auto_install     => nil,
        :parameters       => {:scale => "noscale", :bgcolor => "#ffffff"},
        :flashvars        => {:lzproxied => false},
        :id               => "myFlash"
      ), flashobject_tag("mySwf", :flash_id => "myFlash")
    end
  
  end
end

