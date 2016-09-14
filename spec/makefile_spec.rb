require 'spec_helper'
require 'plato/makefile'

describe Plato::Makefile do
  it 'can be initialised' do
    mkfile = Plato::Makefile.new 'tmp'
    expect(mkfile).not_to be nil
  end

  it 'generates output as expected' do
    mkfile = Plato::Makefile.new 'tmp'
    expected_output = "VAR1=/some/path\nVAR2=/another/path\n\n"
    expected_output += "all:\n\tgcc -o test.o -c test.c\n\n"

    mkfile.add_var('VAR1', '/some/path')
    mkfile.add_var('VAR2', '/another/path')
    mkfile.add_target('all', 'gcc -o test.o -c test.c')

    expect(expected_output).to eq(mkfile.to_s)
  end
end
