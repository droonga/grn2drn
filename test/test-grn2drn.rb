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

class Grn2DrnTest < Test::Unit::TestCase
  private
  def grn2drn
    File.join(File.dirname(__FILE__), "..", "bin", "grn2drn")
  end

  def run_grn2drn(groonga_command, *arguments)
    input = Tempfile.new("grn2drn-input")
    input.puts(groonga_command)
    input.flush
    output = Tempfile.new("grn2drn-output")
    error = Tempfile.new("grn2drn-error")
    env = {}
    options = {
      :in  => input.path,
      :out => output.path,
      :err => error.path,
    }
    spawn_arguments = [env, RbConfig.ruby, grn2drn, *arguments]
    spawn_arguments << options
    pid = spawn(*spawn_arguments)
    _, status = Process.waitpid2(pid)
    if status.success?
      output.read.lines.collect do |line|
        JSON.parse(line)
      end
    else
      error.read
    end
  end

  class DatasetTest < self
    def run_grn2drn(*arguments)
      command = <<-COMMAND.chomp
table_create Terms TABLE_NO_KEY
      COMMAND
      response = super(command, *arguments)
      if response.is_a?(Array)
        response.collect do |message|
          message["dataset"]
        end
      else
        response
      end
    end

    def test_dataset
      assert_equal(["Droonga"],
                   run_grn2drn("--dataset", "Droonga"))
    end
  end
end
