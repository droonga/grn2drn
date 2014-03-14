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
        assert_equal({ "type" => "Array" },
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

  class ColumnCreateTest < self
    def test_name
      command = <<-COMMAND.chomp
table_create Logs TABLE_NO_KEY
column_create Logs date COLUMN_SCALAR Time
      COMMAND
      assert_equal(["date"],
                   convert(command)["Logs"]["columns"].keys)
    end

    class TypeTest < self
      def type(command)
        convert(command).values.first["columns"].values.first["type"]
      end

      def test_default
        command = <<-COMMAND.chomp
table_create Logs TABLE_NO_KEY
column_create Logs content
        COMMAND
        assert_equal("Scalar", type(command))
      end

      def test_scalar
        command = <<-COMMAND.chomp
table_create Logs TABLE_NO_KEY
column_create Logs content COLUMN_SCALAR
        COMMAND
        assert_equal("Scalar", type(command))
      end

      def test_vector
        command = <<-COMMAND.chomp
table_create Logs TABLE_NO_KEY
column_create Logs tags COLUMN_VECTOR
        COMMAND
        assert_equal("Vector", type(command))
      end

      def test_index
        command = <<-COMMAND.chomp
table_create Tags TABLE_PAT_KEY ShortText
column_create Tags index COLUMN_INDEX
        COMMAND
        assert_equal("Index", type(command))
      end
    end

    class ValueTypeTest < self
      def value_type(command)
        convert(command).values.first["columns"].values.first["valueType"]
      end

      def test_default
        command = <<-COMMAND.chomp
table_create Logs TABLE_NO_KEY
column_create Logs content COLUMN_SCALAR
        COMMAND
        assert_nil(value_type(command))
      end

      def test_specified
        command = <<-COMMAND.chomp
table_create Logs TABLE_NO_KEY
column_create Logs content COLUMN_SCALAR ShortText
        COMMAND
        assert_equal("ShortText", value_type(command))
      end
    end

    class VectorOptionsTest < self
      def vector_options(command)
        convert(command).values.first["columns"].values.first["vectorOptions"]
      end

      def test_scalar
        command = <<-COMMAND.chomp
table_create Logs TABLE_NO_KEY
column_create Logs tag COLUMN_SCALAR ShortText
        COMMAND
        assert_nil(vector_options(command))
      end

      def test_default
        command = <<-COMMAND.chomp
table_create Logs TABLE_NO_KEY
column_create Logs tags COLUMN_VECTOR ShortText
        COMMAND
        assert_equal({ "weight" => false },
                     vector_options(command))
      end

      def test_with_weight
        command = <<-COMMAND.chomp
table_create Logs TABLE_NO_KEY
column_create Logs tags COLUMN_VECTOR|WITH_WEIGHT ShortText
        COMMAND
        assert_equal({ "weight" => true },
                     vector_options(command))
      end
    end

    class IndexOptionsTest < self
      def index_options(command)
        convert(command).values.last["columns"].values.first["indexOptions"]
      end

      def test_scalar
        command = <<-COMMAND.chomp
table_create Logs TABLE_NO_KEY
column_create Logs tag COLUMN_SCALAR ShortText
        COMMAND
        assert_nil(index_options(command))
      end

      def test_default
        command = <<-COMMAND.chomp
table_create Memos TABLE_HASH_KEY ShortText

table_create Terms TABLE_PAT_KEY ShortText --default_tokenizer TokenBigram
column_create Terms index COLUMN_INDEX Memos
        COMMAND
        assert_equal({
                       "section"  => false,
                       "weight"   => false,
                       "position" => false,
                       "sources"  => [],
                     },
                     index_options(command))
      end

      def test_with_section
        command = <<-COMMAND.chomp
table_create Memos TABLE_HASH_KEY ShortText

table_create Terms TABLE_PAT_KEY ShortText --default_tokenizer TokenBigram
column_create Terms index COLUMN_INDEX|WITH_SECTION Memos
        COMMAND
        assert_equal({
                       "section"  => true,
                       "weight"   => false,
                       "position" => false,
                       "sources"  => [],
                     },
                     index_options(command))
      end

      def test_with_weight
        command = <<-COMMAND.chomp
table_create Memos TABLE_HASH_KEY ShortText

table_create Terms TABLE_PAT_KEY ShortText --default_tokenizer TokenBigram
column_create Terms index COLUMN_INDEX|WITH_WEIGHT Memos
        COMMAND
        assert_equal({
                       "section"  => false,
                       "weight"   => true,
                       "position" => false,
                       "sources"  => [],
                     },
                     index_options(command))
      end

      def test_with_position
        command = <<-COMMAND.chomp
table_create Memos TABLE_HASH_KEY ShortText

table_create Terms TABLE_PAT_KEY ShortText --default_tokenizer TokenBigram
column_create Terms index COLUMN_INDEX|WITH_POSITION Memos
        COMMAND
        assert_equal({
                       "section"  => false,
                       "weight"   => false,
                       "position" => true,
                       "sources"  => [],
                     },
                     index_options(command))
      end

      def test_sources
        command = <<-COMMAND.chomp
table_create Memos TABLE_HASH_KEY ShortText
column_create Memos content COLUMN_SCALAR Text

table_create Terms TABLE_PAT_KEY ShortText --default_tokenizer TokenBigram
column_create Terms index COLUMN_INDEX|WITH_SECTION|WITH_POSITION \
   Memos _key,content
        COMMAND
        assert_equal({
                       "section"  => true,
                       "weight"   => false,
                       "position" => true,
                       "sources"  => ["_key", "content"],
                     },
                     index_options(command))
      end
    end
  end
end
