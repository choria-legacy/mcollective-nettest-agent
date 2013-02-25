#!/usr/bin/env rspec

require 'spec_helper'
require File.join(File.dirname(__FILE__), '../../', 'agent', 'nettest.rb')
require File.join(File.dirname(__FILE__), '../../', 'data', 'nettest_data.rb')

module MCollective
  module Data
    describe Nettest_data do
      describe '#query_data' do
        before do
          @data_file = File.expand_path(File.join([File.dirname(__FILE__), "../../data/nettest_data.rb"]))
          @data = MCollective::Test::DataTest.new("nettest_data", :data_file => @data_file).plugin
        end

        it "should return 'true' if connection was established" do
          Agent::Nettest.expects(:testconnect).with('example.com', '8080').returns(true)
          @data.lookup('example.com:8080').should have_data_items({:connect => true})
        end

        it "should return 'false' if connection could not be established" do
          Agent::Nettest.expects(:testconnect).with('example.com', '8080').returns(false)
          @data.lookup('example.com:8080').should have_data_items({:connect => false})
        end
      end
    end
  end
end
