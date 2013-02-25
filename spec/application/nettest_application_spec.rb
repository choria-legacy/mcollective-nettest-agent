#!/usr/bin/env rspec
require 'spec_helper'

module Mcollective
  describe "nettest application" do
    before do
      application_file = File.join(File.dirname(__FILE__), "../../", "application","nettest.rb")
      @util = MCollective::Test::ApplicationTest.new("nettest", :application_file => application_file)
      @app = @util.plugin
    end

    describe "#application_description" do
      it "should have a description" do
        @app.should have_a_description
      end
    end

    describe '#raise_message' do
      it 'should print the correct message if 1 is passed' do
        expect{
          @app.raise_message(:raise, 1)
        }.to raise_error("Please specify an action and optional arguments")
      end

      it 'should print the correct message if 2 is passed' do
        expect{
          @app.raise_message(:raise, 2)
        }.to raise_error("Action can only to be ping or connect")
      end

      it 'should print the correct message if 3 is passed' do
        expect{
          @app.raise_message(:raise, 3)
        }.to raise_error("Do you really want to perform network tests unfiltered? (y/n): ")
      end
    end

    describe "#post_option_parser" do
      it "should raise an exception for no arguments" do
        @app.expects(:raise_message).with(:raise, 1)
        @app.post_option_parser({})
      end

      it "should raise an exception for unknown actions" do
        ARGV << "action"
        ARGV << "rspec"

        @app.expects(:raise_message).with(:raise, 2)
        @app.post_option_parser({})
      end

      it "should set fqdn and port correctly in the configuration" do
        ARGV << "ping"
        ARGV << "rspec"

        configuration = {}
        @app.post_option_parser(configuration)

        configuration.should == {:action=>"ping", :arguments=>{:fqdn=>"rspec"}}

        ARGV << "connect"
        ARGV << "rspec"
        ARGV << "80"

        configuration = {}
        @app.post_option_parser(configuration)

        configuration.should == {:action=>"connect", :arguments=>{:port=>80, :fqdn=>"rspec"}}
      end
    end

    describe "#validate_configuration" do
      it "should check if no filter is supplied and ask confirmation expecting y or yes" do
        MCollective::Util.expects("empty_filter?").returns(true).twice

        @app.expects(:raise_message).with(:print, 3)
        @app.expects(:raise_message).with(:print, 3)
        @app.expects(:options).returns({}).twice
        STDIN.expects(:gets).returns("y")
        @app.expects("exit").with(1).never
        @app.validate_configuration({})

        STDIN.expects(:gets).returns("yes")
        @app.validate_configuration({})
      end

      it "should exit unless y or yes is supplied" do
        MCollective::Util.expects("empty_filter?").returns(true)

        @app.expects(:print).with("Do you really want to perform network tests unfiltered? (y/n): ")
        @app.expects(:options).returns({})

        @app.expects("exit").with(1)
        STDIN.expects(:gets).returns("n")
        @app.validate_configuration({})
      end
    end

    describe "#main" do
      let(:rpcclient) {mock}

      before do
        @app.expects(:rpcclient).returns(rpcclient)
      end

      it 'should output the correct results for the ping command' do
        resultset = [{:data => {:exitcode => 0,:rtt => '1.000'},:statuscode => 0,:sender => 'rspec1'}]
        @app.configuration[:action] = 'ping'
        @app.configuration[:arguments] = {:fqdn => 'www.rspec.com'}
        rpcclient.expects(:send).with('ping', :fqdn => 'www.rspec.com').returns(resultset)
        rpcclient.stubs(:verbose).returns(false)
        rpcclient.expects(:stats).returns('stats')
        @app.expects(:halt).with('stats')

        @app.expects(:puts).with("%-40s time = %s" % ['rspec1', '1.000'])
        @app.expects(:printrpcstats)

        @app.main
      end

      it 'should output the correct results for the connect command' do
        resultset = [{:data => {:exitcode => 0,:connect => 'Connected'}, :statuscode => 0, :sender => 'rspec1'}]
        @app.configuration[:action] = 'connect'
        @app.configuration[:arguments] = {:fqdn => 'www.rspec.com', :port => 80}
        rpcclient.expects(:send).with('connect', {:fqdn => 'www.rspec.com', :port => 80}).returns(resultset)
        rpcclient.stubs(:verbose).returns(false)
        @app.expects(:puts).with("%-40s status = %s" % ['rspec1', 'Connected'])
        @app.expects(:printrpcstats)
        rpcclient.expects(:stats).returns('stats')
        @app.expects(:halt).with('stats')

        @app.main
      end
    end
  end
end
