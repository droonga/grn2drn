# Copyright (C) 2014 Droonga Project
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License version 2.1 as published by the Free Software Foundation.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

require "rbconfig"
require "tempfile"
require "stringio"

class Grn2DrnSchemaTest < Test::Unit::TestCase
  def test_convert
    assert_equal({
                   "Users" => {
                     "type" => "Hash",
                     "keyType" => "ShortText",
                     "columns" => {
                       "name" => {
                         "type" => "Scalar",
                         "valueType" => "ShortText",
                       },
                     },
                   },
                 },
                 run_grn2drn_schema(<<-GROONGA_SCHEMA))
table_create Users TABLE_HASH_KEY ShortText
column_create Users name COLUMN_SCALAR ShortText
    GROONGA_SCHEMA
  end

  private
  def grn2drn_schema
    File.join(File.dirname(__FILE__), "..", "bin", "grn2drn-schema")
  end

  def run_grn2drn_schema(groonga_command, *arguments)
    input = Tempfile.new("grn2drn-schema-input")
    input.puts(groonga_command)
    input.flush
    output = Tempfile.new("grn2drn-schema-output")
    error = Tempfile.new("grn2drn-schema-error")
    env = {}
    options = {
      :in  => input.path,
      :out => output.path,
      :err => error.path,
    }
    spawn_arguments = [env, RbConfig.ruby, grn2drn_schema, *arguments]
    spawn_arguments << options
    pid = spawn(*spawn_arguments)
    _, status = Process.waitpid2(pid)
    if status.success?
      JSON.parse(output.read)
    else
      error.read
    end
  end
end
