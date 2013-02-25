#!/usr/bin/env rspec

require 'spec_helper'
require File.join(File.dirname(__FILE__), File.join('../../', 'aggregate', 'nettest_mma.rb'))

module MCollective
  class Aggregate
    describe Nettest_mma do
      let(:mma) { Nettest_mma.new(:test, [], nil, :test_action) }

      describe '#startup_hook' do
        it 'should correctly setup the result hash and aggregate format' do
          mma.result[:value].should == [0.0, 0.0, 0.0]
          mma.result[:type].should == :numeric
          mma.aggregate_format.should == "Min: %.3f  Max: %.3f  Average: %.3f"
        end

        it 'should override the format value if one is supplied' do
          mma = Nettest_mma.new(:test, [], "rspec", :test_action)
          mma.aggregate_format.should == "rspec"
        end
      end

      describe '#process_result' do
        it 'should return if the value parameter is not a numeric value' do
          result = mma.process_result(:rspec, :test => :rspec)
          result.should == nil
        end

        it 'should add a new min value to the mma array if value is < min' do
          mma.process_result('1.0', :test => '1.0')
          mma.result[:value][0].should == 1.0
          mma.process_result('0.9', :test => '0.9')
          mma.result[:value][0].should == 0.9
          mma.process_result('1.0', :test => '1.0')
          mma.result[:value][0].should == 0.9
        end

        it 'should add a new max value to the mma array if value is > max' do
          mma.process_result('1.0', :test => '1.0')
          mma.result[:value][1].should == 1.0
          mma.process_result('2.0', :test => '2.0')
          mma.result[:value][1].should == 2.0
          mma.process_result('1.0', :test => '1.0')
          mma.result[:value][1].should == 2.0
        end

        it 'should correctly increment the count instance variable' do
          mma.process_result('1.0', :test => '1.0')
          mma.process_result('1.0', :test => '1.0')
          mma.process_result('1.0', :test => '1.0')
          mma.instance_variable_get(:@count).should == 3
        end

        it 'should increase the value of average in the mma array' do
          mma.process_result('1.0', :test => '1.0')
          mma.process_result('2.5', :test => '2.5')
          mma.process_result('8.0', :test => '8.0')
          mma.result[:value][2].should == 11.5
       end
      end

      describe 'summarize' do
       it 'should not calculate an average if the count instance variable is smaller or equal to 1' do
          mma.process_result('5.0', :test => '5.0')
          mma.summarize
          mma.result[:value][2].should == 5.0
        end

        it 'should correctly calculate an average' do
          mma.process_result('5.0', :test => '5.0')
          mma.process_result('15.0', :test => '15.0')
          mma.process_result('10.0', :test => '10.0')
          mma.summarize
          mma.result[:value][2].should == 10.0
        end
      end
    end
  end
end
