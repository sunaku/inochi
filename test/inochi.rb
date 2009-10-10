#--
# Copyright protects this work.
# See LICENSE file for details.
#++

require 'dfect/mini'

class << Object.new
  describe 'Inochi.calc_program_name' do
    it 'converts input into lower-case' do
      c('foo').must_equal('foo')
      c('foO').must_equal('foo')
      c('Foo').must_equal('foo')
      c('FoO').must_equal('foo')
    end

    it 'converts camel case into snake case' do
      c('FooBar').must_equal('foo_bar')
      c('AnXMLParser').must_equal('an_xml_parser')
      c('fOo').must_equal('f_oo')
      c('FOo').must_equal('f_oo')
    end
  end

  def self.c *args
    Inochi.calc_program_name(*args)
  end
end

class << Object.new
  describe 'Inochi.calc_project_symbol' do
    it 'capitalizes first letter like a ruby constant' do
      c('foo').must_equal('Foo')
    end

    it 'preserves exisitng capitalization' do
      c('FoO').must_equal('FoO')
      c('fooBaR').must_equal('FooBaR')
    end

    it 'converts non-word characters into underscores' do
      c('a!b#c').must_equal('A_b_c')
    end

    it 'squeezes mulitple underscores' do
      c('foo!!bar$$qux').must_equal('Foo_bar_qux')
    end

    it 'ignores surrounding whitespace' do
      c('  a  ').must_equal('A')
    end

    it 'ignores surrounding underscores' do
      c('_a').must_equal('A')
      c('a_').must_equal('A')
      c('_a_').must_equal('A')
      c('__a__').must_equal('A')
    end

    it 'ignores surrounding non-word characters' do
      c('!a').must_equal('A')
      c('a!').must_equal('A')
      c('!a!').must_equal('A')
      c('!!a!!').must_equal('A')
      c('!@a#$').must_equal('A')
    end
  end

  def self.c *args
    Inochi.calc_project_symbol(*args).to_s
  end
end

class << Object.new
  describe 'Inochi.camel_to_snake_case' do
    it 'supports empty input' do
      c('').must_equal('')
    end

    it 'supports normal camel case' do
      c('fooBar').must_equal('foo_Bar')
      c('FooBar').must_equal('Foo_Bar')
      c('Foobar').must_equal('Foobar')
    end

    it 'supports nested abbreviations' do
      c('AnXMLParser').must_equal('An_XML_Parser')
      c('ANXMLParser').must_equal('ANXML_Parser')
      c('AnXmLPaRsEr').must_equal('An_Xm_L_Pa_Rs_Er')
    end

    it 'preserves non-word characters' do
      c(' a!!b#c').must_equal(' a!!b#c')
    end

    it 'preserves exsiting underscores' do
      c('foo_bar').must_equal('foo_bar')
      c('foo_Bar').must_equal('foo_Bar')
      c('Foo_Bar').must_equal('Foo_Bar')
      c('Foo_bar').must_equal('Foo_bar')

      c('Foo___b_a__r').must_equal('Foo___b_a__r')
      c('_').must_equal('_')
      c('_a').must_equal('_a')
      c('a_').must_equal('a_')
      c('_a_').must_equal('_a_')
    end
  end

  def self.c *args
    Inochi.camel_to_snake_case(*args)
  end
end
