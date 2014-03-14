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

require "grn2drn/schema-converter"

class SchemaConverterTest < Test::Unit::TestCase
  def convert(groonga_commands)
    converter = Grn2Drn::SchemaConverter.new
    converter.convert(groonga_commands)
  end

  class TableCreateTest < self
    def test_name
      command = <<-COMMAND.chomp
table_create Logs
      COMMAND
      assert_equal(["Logs"],
                   convert(command).keys)
    end

    class TypeTest < self
      def type(command)
        convert(command).values.first["type"]
      end

      def test_default
        command = <<-COMMAND.chomp
table_create Logs
        COMMAND
        assert_equal("Hash", type(command))
      end

      def test_no_key
        command = <<-COMMAND.chomp
table_create Logs TABLE_NO_KEY
        COMMAND
        assert_equal("Array", type(command))
      end

      def test_hash
        command = <<-COMMAND.chomp
table_create Logs TABLE_HASH_KEY
        COMMAND
        assert_equal("Hash", type(command))
      end

      def test_pat_key
        command = <<-COMMAND.chomp
table_create Logs TABLE_PAT_KEY
        COMMAND
        assert_equal("PatriciaTrie", type(command))
      end

      def test_dat_key
        command = <<-COMMAND.chomp
table_create Logs TABLE_DAT_KEY
        COMMAND
        assert_equal("DoubleArrayTrie", type(command))
      end
    end

    class KeyTypeTest < self
      def key_type(command)
        convert(command).values.first["keyType"]
      end

      def test_default
        command = <<-COMMAND.chomp
table_create Users TABLE_HASH_KEY
        COMMAND
        assert_nil(key_type(command))
      end

      def test_no_key
        command = <<-COMMAND.chomp
table_create Logs TABLE_NO_KEY
        COMMAND
        assert_equal({
                       "type" => "Array",
                       "columns" => [],
                     },
                     convert(command)["Logs"])
      end

      def test_same_type
        command = <<-COMMAND.chomp
table_create Users TABLE_HASH_KEY ShortText
        COMMAND
        assert_equal("ShortText", key_type(command))
      end

      def test_signed_integer
        command = <<-COMMAND.chomp
table_create Users TABLE_HASH_KEY Int32
        COMMAND
        assert_equal("Integer", key_type(command))
      end

      def test_unsigned_integer
        command = <<-COMMAND.chomp
table_create Users TABLE_HASH_KEY UInt32
        COMMAND
        assert_equal("Integer", key_type(command))
      end
    end

    class TokenizerTest < self
      def tokenizer(command)
        convert(command).values.first["tokenizer"]
      end

      def test_default
        command = <<-COMMAND.chomp
table_create Users TABLE_HASH_KEY ShortText
        COMMAND
        assert_nil(tokenizer(command))
      end

      def test_specified
        command = <<-COMMAND.chomp
table_create Users TABLE_HASH_KEY ShortText --default_tokenizer TokenBigram
        COMMAND
        assert_equal("TokenBigram", tokenizer(command))
      end
    end

    class NormalizerTest < self
      def normalizer(command)
        convert(command).values.first["normalizer"]
      end

      def test_default
        command = <<-COMMAND.chomp
table_create Users TABLE_HASH_KEY ShortText
        COMMAND
        assert_nil(normalizer(command))
      end

      def test_specified
        command = <<-COMMAND.chomp
table_create Users TABLE_HASH_KEY ShortText --normalizer NormalizerAuto
        COMMAND
        assert_equal("NormalizerAuto", normalizer(command))
      end
    end
  end
end
