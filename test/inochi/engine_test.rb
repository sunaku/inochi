require 'inochi/engine'

D 'calc_package_name' do
  def c(*args)
    Inochi::Engine.calc_package_name(*args)
  end

  D 'converts input into lower-case' do
    T c('foo') == 'foo'
    T c('foO') == 'foo'
    T c('Foo') == 'foo'
    T c('FoO') == 'foo'
  end

  D 'converts camel case into snake case' do
    T c('FooBar') == 'foo_bar'
    T c('AnXMLParser') == 'an_xml_parser'
    T c('fOo') == 'f_oo'
    T c('FOo') == 'f_oo'
  end
end

D 'calc_library_name' do
  def c(*args)
    Inochi::Engine.calc_library_name(*args).to_s
  end

  D 'capitalizes first letter like a ruby constant' do
    T c('foo') == 'Foo'
  end

  D 'preserves exisitng capitalization' do
    T c('FoO') == 'FoO'
    T c('fooBaR') == 'FooBaR'
  end

  D 'converts non-word characters into underscores' do
    T c('a!b#c') == 'A_b_c'
  end

  D 'squeezes mulitple underscores' do
    T c('foo!!bar$$qux') == 'Foo_bar_qux'
  end

  D 'ignores surrounding whitespace' do
    T c('  a  ') == 'A'
  end

  D 'ignores surrounding underscores' do
    T c('_a') == 'A'
    T c('a_') == 'A'
    T c('_a_') == 'A'
    T c('__a__') == 'A'
  end

  D 'ignores surrounding non-word characters' do
    T c('!a') == 'A'
    T c('a!') == 'A'
    T c('!a!') == 'A'
    T c('!!a!!') == 'A'
    T c('!@a#$') == 'A'
  end
end

D 'camel_to_snake_case' do
  def c(*args)
    Inochi::Engine.camel_to_snake_case(*args)
  end

  D 'supports empty input' do
    T c('') == ''
  end

  D 'supports normal camel case' do
    T c('fooBar') == 'foo_Bar'
    T c('FooBar') == 'Foo_Bar'
    T c('Foobar') == 'Foobar'
  end

  D 'supports nested abbreviations' do
    T c('AnXMLParser') == 'An_XML_Parser'
    T c('ANXMLParser') == 'ANXML_Parser'
    T c('AnXmLPaRsEr') == 'An_Xm_L_Pa_Rs_Er'
  end

  D 'preserves non-word characters' do
    T c(' a!!b#c') == ' a!!b#c'
  end

  D 'preserves exsiting underscores' do
    T c('foo_bar') == 'foo_bar'
    T c('foo_Bar') == 'foo_Bar'
    T c('Foo_Bar') == 'Foo_Bar'
    T c('Foo_bar') == 'Foo_bar'

    T c('Foo___b_a__r') == 'Foo___b_a__r'
    T c('_') == '_'
    T c('_a') == '_a'
    T c('a_') == 'a_'
    T c('_a_') == '_a_'
  end
end
