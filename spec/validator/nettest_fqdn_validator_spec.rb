#!/usr/bin/env rspec

require 'spec_helper'
require File.join(File.dirname(__FILE__), '../../', 'validator', 'nettest_fqdn.rb')

module MCollective
  module Validator
    describe Nettest_fqdnValidator do
      describe "#validate" do
        it 'should validate a valid ip address' do
          Validator.expects(:validate).with('1.2.3.4', :ipv4address).returns(nil)
          Nettest_fqdnValidator.validate('1.2.3.4')
        end

        it 'should validate a valid hostname' do
          Nettest_fqdnValidator.validate('host1.example.com')
          Nettest_fqdnValidator.validate('exmaple.com')
          Nettest_fqdnValidator.validate('localhost')
        end

        it 'should fail if passed an invalid fqdn' do
          expect{
            Nettest_fqdnValidator.validate('not a hostname')
          }.to raise_error ValidatorError
        end
      end
    end
  end
end
