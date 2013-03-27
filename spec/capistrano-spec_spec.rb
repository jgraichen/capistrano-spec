require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Capistrano::Spec do

  require 'capistrano'

  module Capistrano
    module Foo
      def self.load_into(configuration)
        configuration.load do
          set :bar, "baz"
        end
      end
    end
  end

  if Capistrano::Configuration.instance
    Capistrano::Foo.load_into(Capistrano::Configuration.instance)
  end

  before do
    @configuration = Capistrano::Configuration.new
    @configuration.extend(Capistrano::Spec::ConfigurationExtension)
    @configuration.extend(Capistrano::Foo)
    Capistrano::Foo.load_into(@configuration)
  end

  describe Capistrano::Spec::Matchers do
    it "should have a #callback matcher" do
      expect{@configuration.should callback("fake_task")}.to_not raise_error(NoMethodError)
    end

    it "should have a #have_uploaded matcher" do
      expect{@configuration.should have_uploaded("fake_upload")}.to_not raise_error(NoMethodError)
    end

    it "should have a #have_run matcher" do
      expect{@configuration.should have_run("fake_task")}.to_not raise_error(NoMethodError)
    end
  end

end
