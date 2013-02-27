#!/usr/bin/env rspec

require 'spec_helper'
require File.join(File.dirname(__FILE__), '../../', 'util', 'nettest_agent.rb')
require File.join(File.dirname(__FILE__), "../../", "agent", "nettest.rb")

module MCollective
  module Agent
    class Nettest
      describe "nettest agent" do
        before do
          agent_file = File.join(File.dirname(__FILE__), "../../", "agent", "nettest.rb")
          @agent = MCollective::Test::LocalAgentTest.new("nettest", :agent_file => agent_file).plugin
        end

        describe "ping_action" do
          it 'should set the rtt if ping was successful' do
            Util::NettestAgent.expects(:get_ip_from_hostname).with('example.com').returns('1.2.3.4')
            Nettest.expects(:testping).with('1.2.3.4').returns(1234)

            result = @agent.call(:ping, :fqdn => 'example.com')
            result.should be_successful
            result.should have_data_items({:rtt => 1234})
          end

          it 'should fail if host cannot be reached' do
            Util::NettestAgent.expects(:get_ip_from_hostname).with('example.com').returns('1.2.3.4')
            Nettest.expects(:testping).with('1.2.3.4').returns(nil)

            result = @agent.call(:ping, :fqdn => 'example.com')
            result.should be_aborted_error
          end

          it 'should fail if hostname cannot be resolved' do
            Util::NettestAgent.expects(:get_ip_from_hostname).with('example.com').returns(nil)

            result = @agent.call(:ping, :fqdn => 'example.com')
            result.should be_aborted_error
          end
        end

        describe "connect_action" do
          it 'should set the connect, connect_status and connect_time fields if successful' do
            Util::NettestAgent.expects(:get_ip_from_hostname).with('example.com').returns('1.2.3.4')
            Nettest.expects(:testconnect).with('1.2.3.4', 8080).returns([true, 'Connected', 5])

            result = @agent.call(:connect, :fqdn => 'example.com', :port => 8080)
            result.should be_successful
            result.should have_data_items({:connect => true, :connect_status => 'Connected', :connect_time => 5})
          end

          it 'should set connect to false if connection could not be made' do
            Util::NettestAgent.expects(:get_ip_from_hostname).with('example.com').returns('1.2.3.4')
            Nettest.expects(:testconnect).with('1.2.3.4', 8080).returns([false, 'Connection Refused', 5])

            result = @agent.call(:connect, :fqdn => 'example.com', :port => 8080)
            result.should be_successful
            result.should have_data_items({:connect => false, :connect_status => 'Connection Refused', :connect_time => 5})
          end

          it 'should fail if hostname cannot be resolved' do
            Util::NettestAgent.expects(:get_ip_from_hostname).with('example.com').returns(nil)
            result = @agent.call(:connect, :fqdn => 'example.com', :port => 8080)

            result.should be_aborted_error
          end
        end

        describe "#testping" do
          let(:icmp) { mock }

          class Net
            class Ping
              class ICMP
              end
            end
          end

          it 'should return the ping time if ping was successful' do
            Net::Ping::ICMP.expects(:new).with('1.2.3.4').returns(icmp)
            icmp.expects(:ping?).returns(true)
            icmp.expects(:duration).returns(0.005)

            result = Nettest.testping('1.2.3.4')
            result.should == 5
          end

          it 'should return nil if ping was unsuccessful' do
            Net::Ping::ICMP.expects(:new).with('1.2.3.4').returns(icmp)
            icmp.expects(:ping?).returns(false)

            result = Nettest.testping('1.2.3.4')
            result.should == nil
          end
        end

        describe "#testconnect" do
          let(:socket) { mock }

          it 'should return the status, status string and time for a successful connection' do
            Time.expects(:now).twice.returns(1,2)
            TCPSocket.stubs(:new).with('1.2.3.4', 8080).returns(socket)
            socket.stubs(:close)

            connected, connect_string, connect_time = Nettest.testconnect('1.2.3.4', 8080)
            connected.should be_true
            connect_string.should == "Connected"
            connect_time.should == 1
          end

          it 'should return the status, status string and time for a refused connection' do
            Time.expects(:now).raises('error')

            connected, connect_string, connect_time = Nettest.testconnect('1.2.3.4', 8080)
            connected.should be_false
            connect_string.should == "Connection Refused"
            connect_time.should == nil
          end

          it 'should return the status, status string and time for a timed out connection' do
            Timeout.expects(:timeout).with(2).raises(Timeout::Error)

            connected, connect_string, connect_time = Nettest.testconnect('1.2.3.4', 8080)
            connected.should be_false
            connect_string.should == "Connection Timeout"
            connect_time.should == nil

          end
        end
      end
    end
  end
end
