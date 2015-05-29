# -*- coding: utf-8 -*-
#
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

require "digest/sha1"
require "time"
require "json"

require "groonga/command/parser"

module Grn2Drn
  class CommandConverter
    def initialize(options={})
      @options = options
      @count = 0

      @command_parser = Groonga::Command::Parser.new
    end

    def convert(input, &block)
      @command_parser.on_command do |command|
        unless command.name == "load"
          yield create_message(command.name, command_to_body(command))
        end
      end

      parsed_columns = nil
      @command_parser.on_load_columns do |command, columns|
        parsed_columns = columns
      end
      @command_parser.on_load_value do |command, value|
        yield create_add_command(command, parsed_columns, value)
        command.original_source.clear
      end

      input.each_line do |line|
        @command_parser << line
      end
      @command_parser.finish
    end

    private
    def create_message(type, body)
      id_prefix = @options[:id_prefix]
      if id_prefix.nil?
        id = new_unique_id
      else
        id = "#{id_prefix}:#{@count}"
        @count += 1
      end

      {
        "id" => id,
        "date" => format_date(@options[:date] || Time.now),
        "replyTo" => @options[:reply_to],
        "dataset" => @options[:dataset],
        "type" => type,
        "body" => body,
      }
    end

    def new_unique_id
      now = Time.now
      now_msec = now.to_i * 1000 + now.usec
      random_string = rand(36 ** 16).to_s(36) # Base36
      Digest::SHA1.hexdigest("#{now_msec}:#{random_string}")
    end

    MICRO_SECONDS_DECIMAL_PLACE = 6

    def format_date(time)
      time.utc.iso8601(MICRO_SECONDS_DECIMAL_PLACE)
    end

    def stringify_keys(hash)
      stringified_hash = {}
      hash.each do |key, value|
        stringified_hash[key.to_s] = value
      end
      stringified_hash
    end

    def command_to_body(command)
      stringify_keys(command.arguments)
    end

    def create_add_command(command, columns, record)
      table = command[:table]
      body = {
        "table" => table,
      }

      if record.is_a?(Hash)
        values = record.dup
        body["key"] = values.delete("_key")
        body["values"] = values
      else
        values = {}
        record.each_with_index do |value, column_index|
          column = columns[column_index]
          if column == "_key"
            body["key"] = value
          else
            values[column] = value
          end
        end
        body["values"] = values
      end

      create_message("add", body)
    end
  end
end
