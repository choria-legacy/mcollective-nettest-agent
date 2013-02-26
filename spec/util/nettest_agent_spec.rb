#!/usr/bin/evn rspec

require 'spec_helper'
require File.join(File.dirname(__FILE__), File.join('../../', 'util', 'nettest_agent.rb'))

module MCollective
  module Util
    describe NettestAgent do
      describe '#is_hostname?' do
        it 'should return true on valid hostname' do
          NettestAgent.is_hostname?('host1.example.com').should be_true
          NettestAgent.is_hostname?('example.com').should be_true
          NettestAgent.is_hostname?('localhost').should be_true
        end

        it 'should return false on ip address' do
          NettestAgent.is_hostname?('1.2.3.4').should be_false
        end

        it 'should return false on anything else' do
          NettestAgent.is_hostname?("this string is not a hostname").should be_false
          NettestAgent.is_hostname?("www.rspec.com/rspec").should be_false
          NettestAgent.is_hostname?("localhost#").should be_false
        end
      end

      describe '#get_ip_from_hostname' do
        let(:ipaddress) { '1.2.3.4' }

        it 'should return the hostname if hostname is an ip address' do
          NettestAgent.expects(:is_hostname?).returns(false)
          NettestAgent.get_ip_from_hostname('1.2.3.4').should == '1.2.3.4'
        end

        it 'should return the resolved ip address if hostname can be found' do
          NettestAgent.expects(:is_hostname?).returns(true)
          Resolv.expects(:getaddress).with('example.com').returns('1.2.3.4')

          NettestAgent.get_ip_from_hostname('example.com').should == '1.2.3.4'
        end

        it 'should return nil if hostname cannot be resolved' do
          NettestAgent.expects(:is_hostname?).returns(true)
          Resolv.expects(:getaddress).raises(Resolv::ResolvError)

          NettestAgent.get_ip_from_hostname('example.com').should be_nil
        end
      end
    end
  end
end
