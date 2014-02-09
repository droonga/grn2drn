# Copyright (C) 2013-2014 Droonga Project
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

require "grn2drn/converter"

class ConverterTest < Test::Unit::TestCase
  private
  def converter
    options = {
      :base_id => "test",
      :date => date,
      :reply_to => reply_to,
      :dataset => dataset,
    }
    Grn2Drn::Converter.new(options)
  end

  def convert(groonga_commands)
    droonga_messages = []
    converter.convert(groonga_commands) do |droonga_message|
      droonga_messages << droonga_message
    end
    droonga_messages
  end

  def date
    Time.utc(2013, 11, 29, 0, 0, 0)
  end

  def formatted_date
    "2013-11-29T00:00:00Z"
  end

  def reply_to
    "localhost:20033"
  end

  def dataset
    "test-dataset"
  end

  class TableCreateTest < self
    def test_tokenizer_normalizer
      command = <<-COMMAND.chomp
table_create Terms TABLE_PAT_KEY ShortText \
  --default_tokenizer TokenBigram --normalizer NormalizerAuto
      COMMAND
      assert_equal([
                     {
                       "id" => "test:0",
                       "date" => formatted_date,
                       "replyTo" => reply_to,
                       "dataset" => dataset,
                       "type" => "table_create",
                       "body" => {
                         "name" => "Terms",
                         "flags" => "TABLE_PAT_KEY",
                         "key_type" => "ShortText",
                         "default_tokenizer" => "TokenBigram",
                         "normalizer" => "NormalizerAuto",
                       },
                     },
                   ],
                   convert(command))
    end
  end

  class ColumnCreateTest < self
    def test_index
      command = <<-COMMAND.chomp
column_create Terms Users_name COLUMN_INDEX|WITH_POSITION Users name
      COMMAND
      assert_equal([
                     {
                       "id" => "test:0",
                       "date" => formatted_date,
                       "replyTo" => reply_to,
                       "dataset" => dataset,
                       "type" => "column_create",
                       "body" => {
                         "table" => "Terms",
                         "name" => "Users_name",
                         "flags" => "COLUMN_INDEX|WITH_POSITION",
                         "type" => "Users",
                         "source" => "name",
                       },
                     },
                   ],
                   convert(command))
    end
  end

  class LoadTest < self
    def test_array_style
      command = <<-COMMAND.chomp
load --table Users
[
["_key","name"],
["user","Abe Shinzo"]
]
      COMMAND
      assert_equal([
                     {
                       "id" => "test:0",
                       "date" => formatted_date,
                       "replyTo" => reply_to,
                       "dataset" => dataset,
                       "type" => "add",
                       "body" => {
                         "table" => "Users",
                         "key" => "user",
                         "values" => {
                           "name" => "Abe Shinzo",
                         },
                       },
                     },
                   ],
                   convert(command))
    end

    def test_object_style
      command = <<-COMMAND.chomp
load --table Users
[
{"_key": "user", "name": "Abe Shinzo"}
]
      COMMAND
      assert_equal([
                     {
                       "id" => "test:0",
                       "date" => formatted_date,
                       "replyTo" => reply_to,
                       "dataset" => dataset,
                       "type" => "add",
                       "body" => {
                         "table" => "Users",
                         "key" => "user",
                         "values" => {
                           "name" => "Abe Shinzo",
                         },
                       },
                     },
                   ],
                   convert(command))
    end

    def test_multi_records
      command = <<-COMMAND.chomp
load --table Users
[
["_key","name"],
["user0","Abe Shinzo"],
["user1","Noda Yoshihiko"],
["user2","Kan Naoto"]
]
      COMMAND
      assert_equal([
                     {
                       "id" => "test:0",
                       "date" => formatted_date,
                       "replyTo" => reply_to,
                       "dataset" => dataset,
                       "type" => "add",
                       "body" => {
                         "table" => "Users",
                         "key" => "user0",
                         "values" => {
                           "name" => "Abe Shinzo",
                         },
                       },
                     },
                     {
                       "id" => "test:1",
                       "date" => formatted_date,
                       "replyTo" => reply_to,
                       "dataset" => dataset,
                       "type" => "add",
                       "body" => {
                         "table" => "Users",
                         "key" => "user1",
                         "values" => {
                           "name" => "Noda Yoshihiko",
                         },
                       },
                     },
                     {
                       "id" => "test:2",
                       "date" => formatted_date,
                       "replyTo" => reply_to,
                       "dataset" => dataset,
                       "type" => "add",
                       "body" => {
                         "table" => "Users",
                         "key" => "user2",
                         "values" => {
                           "name" => "Kan Naoto",
                         },
                       },
                     },
                   ],
                   convert(command))
    end
  end

  class SelectTest < self
    def test_key_value_style
      command = <<-COMMAND.chomp
select --filter "age<=30" --output_type "json" --table "Users"
      COMMAND
      assert_equal([
                     {
                       "id" => "test:0",
                       "date" => formatted_date,
                       "replyTo" => reply_to,
                       "dataset" => dataset,
                       "type" => "select",
                       "body" => {
                         "table" => "Users",
                         "filter" => "age<=30",
                         "output_type" => "json",
                       },
                     },
                   ],
                   convert(command))
    end
  end

  class MultipleCommandsTest < self
    def test_schema
      commands = <<-COMMANDS.chomp
table_create Terms TABLE_PAT_KEY ShortText \
  --default_tokenizer TokenBigram --normalizer NormalizerAuto
column_create Terms Users_name COLUMN_INDEX|WITH_POSITION Users name
      COMMANDS
      assert_equal([
                     {
                       "id" => "test:0",
                       "date" => formatted_date,
                       "replyTo" => reply_to,
                       "dataset" => dataset,
                       "type" => "table_create",
                       "body" => {
                         "name" => "Terms",
                         "flags" => "TABLE_PAT_KEY",
                         "key_type" => "ShortText",
                         "default_tokenizer" => "TokenBigram",
                         "normalizer" => "NormalizerAuto",
                       },
                     },
                     {
                       "id" => "test:1",
                       "date" => formatted_date,
                       "replyTo" => reply_to,
                       "dataset" => dataset,
                       "type" => "column_create",
                       "body" => {
                         "table" => "Terms",
                         "name" => "Users_name",
                         "flags" => "COLUMN_INDEX|WITH_POSITION",
                         "type" => "Users",
                         "source" => "name",
                       },
                     },
                   ],
                   convert(commands))
    end
  end
end
