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

require "groonga/command/parser"

module Grn2Drn
  class SchemaConverter
    def initialize(options={})
      @options = options
    end

    def convert(input)
      schema = Schema.new

      command_parser = Groonga::Command::Parser.new
      command_parser.on_command do |command|
        case command.name
        when "table_create"
          schema.on_table_create_command(command)
        when "column_create"
          schema.on_column_create_command(command)
        end
      end

      input.each_line do |line|
        command_parser << line
      end
      command_parser.finish

      schema.to_droonga_schema
    end

    class Schema
      def initialize
        @tables = {}
      end

      def on_table_create_command(command)
        @tables[command[:name]] = Table.new(command)
      end

      def on_column_create_command(command)
        @tables[command.table].add_column(command[:name],
                                          Column.new(command))
      end

      def to_droonga_schema
        droonga_schema = {}
        @tables.each do |name, table|
          droonga_schema[name] = table.to_droonga_schema
        end
        droonga_schema
      end
    end

    class Table
      def initialize(table_create_command)
        @command = table_create_command
        @columns = {}
      end

      def add_column(name, column)
        @columns[name] = column
      end

      def to_droonga_schema
        schema = {}
        set_schema_item(schema, "type", type)
        set_schema_item(schema, "keyType", key_type)
        set_schema_item(schema, "tokenizer", tokenizer)
        set_schema_item(schema, "normalizer", normalizer)
        set_schema_item(schema, "columns", droonga_schema_columns)
        schema
      end

      private
      def set_schema_item(schema, key, value)
        return if value.nil?
        schema[key] = value
      end

      def type
        if @command.table_no_key?
          "Array"
        elsif @command.table_hash_key?
          "Hash"
        elsif @command.table_pat_key?
          "PatriciaTrie"
        elsif @command.table_dat_key?
          "DoubleArrayTrie"
        else
          "Hash"
        end
      end

      def key_type
        type = @command.key_type
        case type
        when /\AInt/, /\AUInt/
          "Integer"
        else
          type
        end
      end

      def tokenizer
        @command.default_tokenizer
      end

      def normalizer
        @command.normalizer
      end

      def droonga_schema_columns
        return nil if @columns.empty?
        schema = {}
        @columns.each do |name, column|
          schema[name] = column.to_droonga_schema
        end
        schema
      end
    end

    class Column
      def initialize(column_create_command)
        @command = column_create_command
      end

      def to_droonga_schema
        schema = {}
        set_schema_item(schema, "type", type)
        set_schema_item(schema, "valueType", value_type)
        set_schema_item(schema, "vectorOptions", vector_options)
        set_schema_item(schema, "indexOptions", index_options)
        schema
      end

      private
      def set_schema_item(schema, key, value)
        return if value.nil?
        schema[key] = value
      end

      def type
        if @command.column_scalar?
          "Scalar"
        elsif @command.column_vector?
          "Vector"
        elsif @command.column_index?
          "Index"
        else
          "Scalar"
        end
      end

      def value_type
        @command.type
      end

      def vector_options
        return nil unless @command.column_vector?
        {
          "weight" => @command.with_weight?,
        }
      end

      def index_options
        return nil unless @command.column_index?
        {
          "section"  => @command.with_section?,
          "weight"   => @command.with_weight?,
          "position" => @command.with_position?,
          "sources"  => @command.sources,
        }
      end
    end
  end
end
